const Turn = require('node-turn');

let server = null;

// externalIp: public address to hand out for relays when the host sits behind NAT
function startTurnServer(externalIp) {
  const options = {
    authMech: 'long-term',
    realm: 'voicechat',
    listeningPort: 3478,
  };
  if (externalIp) options.externalIps = externalIp;
  server = new Turn(options);
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
