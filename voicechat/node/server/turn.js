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

// externalIp: public address to hand out for relays when the host sits behind NAT
function startTurnServer(externalIp) {
  const options = {
    authMech: 'long-term',
    realm: 'voicechat',
    listeningPort: 3478, defaultAllocatetLifetime: 70, debugLevel: 'ALL', debug: (l, m) => { if (/refresh/.test(String(m))) console.log('TURN', String(m).slice(0,120)); },
    debugLevel: 'ALL',
    debug: (l, m) => { if (!/relaying data|permission fail|relayed/.test(m)) console.log(Date.now(), l, String(m).slice(0, 160)); },
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

function createCredential(sessionId) {
  if (server && sessionId) server.addUser(sessionId, sessionId);
}

// Function to remove credential (call this when session ends or after use)
function revokeCredential(sessionId) {
  if (server && sessionId) server.removeUser(sessionId);
}

module.exports = {startTurnServer, createCredential, revokeCredential};
