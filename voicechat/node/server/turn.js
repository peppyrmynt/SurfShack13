const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const Turn = require('node-turn');
const ChannelBind = require('node-turn/lib/methods/channelBind');
const Message = require('node-turn/lib/message');
const ChannelMsg = require('node-turn/lib/channelMessage');

let server = null;

// node-turn 0.0.6 bugs, patched here since node_modules isn't committed:
// ChannelBind success replies are sent without MESSAGE-INTEGRITY. With long-term auth,
// browsers ignore unauthenticated replies, keep retrying, and drop the relayed
// connection when the request times out, about 40 seconds after connecting.
if (!ChannelBind.prototype._integrityPatched) {
  const originalChannelBind = ChannelBind.prototype.channelBind;
  ChannelBind.prototype.channelBind = function(msg, reply) {
    const resolve = reply.resolve;
    reply.resolve = function() {
      reply.addAttribute('software', msg.server.software);
      reply.addAttribute('message-integrity');
      return resolve.apply(this, arguments);
    };
    return originalChannelBind.call(this, msg, reply);
  };
  ChannelBind.prototype._integrityPatched = true;

  // ChannelData from the browser (what it switches to once a channel is bound) is never
  // relayed: the parser only knows STUN messages and silently drops it. Forward it to the peer.
  const originalRead = Message.prototype.read;
  Message.prototype.read = function(udpMessage) {
    if (!udpMessage || udpMessage.length < 4 || (udpMessage[0] & 0xC0) !== 0x40) {
      return originalRead.call(this, udpMessage);
    }
    const allocation = this.server.allocations[this.transport.get5Tuple()];
    const channel = new ChannelMsg();
    if (!allocation || !channel.read(udpMessage)) return false;
    const peer = allocation.channelBindings[channel.channelNumber];
    const permission = peer && allocation.permissions[peer.address];
    if (!permission || permission < Date.now()) return false;
    allocation.sockets[0].send(channel.data, peer.port, peer.address, (err) => {
      if (err) this.server.debug('ERROR', err);
    });
    return false;
  };
}

// Optional, host specific. Without it the built-in relay is used. See voicechat/COTURN.md
const CONFIG_PATH = path.resolve(__dirname, '..', 'turn_config.json');
const COTURN_CREDENTIAL_TTL = 24 * 60 * 60; // seconds

let config = { mode: 'builtin' };

function loadConfig() {
  if (!fs.existsSync(CONFIG_PATH)) return config;
  try {
    config = { mode: 'builtin', ...JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf-8')) };
  } catch (err) {
    console.error(`could not read ${CONFIG_PATH}, using the built-in relay:`, err.message);
    return config;
  }
  if (config.mode === 'coturn' && (!config.secret || !Array.isArray(config.urls) || !config.urls.length)) {
    console.error('coturn mode needs "secret" and "urls" in turn_config.json, using the built-in relay');
    config.mode = 'builtin';
  }
  console.log(`TURN mode: ${config.mode}`);
  return config;
}

// externalIp: public address to hand out for relays when the host sits behind NAT
function startTurnServer(externalIp) {
  loadConfig();
  if (config.mode === 'coturn') return null; // coturn runs as its own service
  externalIp = externalIp || config.externalIp;
  const options = {
    authMech: 'long-term',
    realm: 'voicechat',
    listeningPort: 3478,
  };
  if (externalIp) options.externalIps = externalIp;
  server = new Turn(options);
  // Refresh reads these misnamed options; left undefined, every refresh (browsers send one
  // at ~9 minutes) sets the lifetime to NaN and deletes the relay allocation immediately.
  server.defaultLifetime = server.defaultAllocatetLifetime;
  server.maxAllocateTimeout = server.maxAllocateLifetime;
  server.start();
  return server;
}

function stopTurnServer() {
  if (server) server.stop();
}

function createCredential(sessionId) {
  if (server && sessionId) server.addUser(sessionId, sessionId);
}

// Function to remove credential (call this when session ends or after use)
function revokeCredential(sessionId) {
  if (server && sessionId) server.removeUser(sessionId);
}

// ICE servers for a browser. "{host}" in a url is replaced by the browser with the
// game server address it connected to.
function getIceServers(sessionId) {
  if (config.mode === 'coturn') {
    // coturn's use-auth-secret scheme: username is "expiry:id", password is its HMAC
    const username = `${Math.floor(Date.now() / 1000) + COTURN_CREDENTIAL_TTL}:${sessionId}`;
    const credential = crypto.createHmac('sha1', config.secret).update(username).digest('base64');
    return [{ urls: config.urls, username, credential }];
  }
  return [
    { urls: 'stun:{host}:3478' },
    { urls: 'turn:{host}:3478?transport=udp', username: sessionId, credential: sessionId },
  ];
}

module.exports = {startTurnServer, stopTurnServer, createCredential, revokeCredential, getIceServers};
