const sessionIdToUserCode = new Map();
const userCodeToSocketId = new Map();
const socketIdToUserCode = new Map();
// sessions that already joined once, kept so a browser can rejoin after a dropped connection
const activeSessionToUserCode = new Map();

module.exports = {
    sessionIdToUserCode,
    userCodeToSocketId,
    socketIdToUserCode,
    activeSessionToUserCode,
};
