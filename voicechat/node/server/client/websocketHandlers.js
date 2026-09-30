const { sessionIdToUserCode, userCodeToSocketId, socketIdToUserCode, activeSessionToUserCode } = require('../state');
const { sendJSON } = require('../byond/ByondCommunication');
const { createCredential, revokeCredential, getIceServers } = require('../turn');
const { resetPeer, resetPair } = require('../proximity');

function sessionIdForUserCode(userCode) {
    for (const [sessionId, code] of activeSessionToUserCode) {
        if (code === userCode) return sessionId;
    }
    return null;
}

// Fully ends a userCode's voice session: the link can no longer be used to rejoin.
function endSession(userCode, io, reason) {
    const sessionId = sessionIdForUserCode(userCode);
    if (sessionId) {
        activeSessionToUserCode.delete(sessionId);
        revokeCredential(sessionId);
    }
    const socketId = userCodeToSocketId.get(userCode);
    userCodeToSocketId.delete(userCode);
    if (socketId) {
        socketIdToUserCode.delete(socketId);
        const socket = io.sockets.sockets.get(socketId);
        if (socket) {
            if (reason) socket.emit('update', { type: 'status', data: reason });
            socket.disconnect();
        }
    }
    resetPeer(io, userCode);
}

function createConnectionHandler(byondPort, io) {
    return function handleConnection(socket) {
        console.log('A user connected:', socket.id);

        // A throw inside a socket.io handler is uncaught and kills node, taking voice down for
        // everyone, so one malformed message from any browser must never reach that far.
        const on = (event, handler) => socket.on(event, (data) => {
            try {
                handler(data && typeof data === 'object' ? data : {});
            } catch (err) {
                console.error(`error handling '${event}' from ${socket.id}:`, err);
            }
        });

        const authTimer = setTimeout(() => {
            if (!socketIdToUserCode.get(socket.id)) {
                console.log(`Unauthenticated socket ${socket.id} timed out, disconnecting`);
                socket.emit('update', { type: 'status', data: 'Disconnected: Authentication timeout' });
                socket.disconnect()
            }
        }, 5000);

        on('join', (data) => {
            if (socket.userCode) return; // already joined on this socket
            const sessionId = data.sessionId;
            // a fresh link from byond, or a browser rejoining after its connection dropped
            let userCode = sessionIdToUserCode.get(sessionId);
            const isRejoin = !userCode && activeSessionToUserCode.has(sessionId);
            if (isRejoin) userCode = activeSessionToUserCode.get(sessionId);
            if (!userCode) {
                console.log('Invalid sessionId', sessionId);
                socket.emit('update', { type: 'status', data: 'Disconnected: bad sessionId. make sure you use the verb to connect as you need a new link each time.' });
                socket.disconnect();
                return;
            }
            clearTimeout(authTimer);
            sessionIdToUserCode.delete(sessionId);
            activeSessionToUserCode.set(sessionId, userCode);
            createCredential(sessionId);

            // kick an older socket still holding this userCode (e.g. the same link opened twice)
            const oldSocketId = userCodeToSocketId.get(userCode);
            if (oldSocketId && oldSocketId !== socket.id) {
                socketIdToUserCode.delete(oldSocketId);
                const oldSocket = io.sockets.sockets.get(oldSocketId);
                if (oldSocket) {
                    oldSocket.emit('update', { type: 'status', data: 'Disconnected: opened in another tab' });
                    oldSocket.disconnect();
                }
            }

            userCodeToSocketId.set(userCode, socket.id);
            socketIdToUserCode.set(socket.id, userCode);
            socket.userCode = userCode;
            socket.sessionId = sessionId;
            console.log(`Associated userCode ${userCode} with socket ${socket.id}${isRejoin ? ' (rejoin)' : ''}`);
            socket.emit('ice_servers', getIceServers(sessionId));
            socket.emit('update', { type: 'status', data: 'Connected successfully' });
            // everyone drops any old connection to this user and rebuilds it on the next location update
            resetPeer(io, userCode);
        });

        // browser is ready for voice; also sent without a mic, those players join listen-only
        on('mic_access_granted', () => {
            const userCode = socketIdToUserCode.get(socket.id);
            if(userCode) sendJSON({ 'confirmed': userCode }, byondPort);
        })

        on('disconnect_page', () => {
            const userCode = socketIdToUserCode.get(socket.id);
            if (userCode) {
                sendJSON({disconnect: userCode}, byondPort);
                console.log(`Removed userCode ${userCode} on disconnect`);
                endSession(userCode, io, 'Disconnecting...');
            } else {
                socket.disconnect();
            }
            console.log('User disconnected:', socket.id);
        });

        // connection dropped (network, closed tab). Keep the session so the browser can rejoin.
        socket.on('disconnect', () => {
            clearTimeout(authTimer);
            const userCode = socketIdToUserCode.get(socket.id);
            socketIdToUserCode.delete(socket.id);
            if (userCode && userCodeToSocketId.get(userCode) === socket.id) {
                userCodeToSocketId.delete(userCode);
                // otherwise a player cut off mid-sentence keeps the speaking icon over their head
                sendJSON({ voice_activity: userCode, active: false }, byondPort);
                resetPeer(io, userCode);
            }
        });

        on('offer', (data) => {
            const { to, offer } = data;
            const targetSocketId = userCodeToSocketId.get(to);
            const socket_sending = io.sockets.sockets.get(targetSocketId)
            if (socket.userCode && targetSocketId && socket_sending) {
                socket_sending.emit('offer', { from: socket.userCode, offer });
            }
        });

        on('answer', (data) => {
            const { to, answer } = data;
            const targetSocketId = userCodeToSocketId.get(to);
            const socket_sending = io.sockets.sockets.get(targetSocketId)
            if (socket.userCode && targetSocketId && socket_sending) {
                socket_sending.emit('answer', { from: socket.userCode, answer });
            }
        });

        on('ice-candidate', (data) => {
            const { to, candidate } = data;
            const targetSocketId = userCodeToSocketId.get(to);
            const socket_sending = io.sockets.sockets.get(targetSocketId)
            if (socket.userCode && targetSocketId && socket_sending) {
                socket_sending.emit('ice-candidate', { from: socket.userCode, candidate });
            }
        });

        // a peer connection failed, rebuild just that pair from scratch
        on('peer_failed', (data) => {
            const userCode = socket.userCode;
            const other = data.userCode;
            if (!userCode || !other || !userCodeToSocketId.has(other)) return;
            console.log(`peer connection ${userCode} <-> ${other} failed, rebuilding`);
            resetPair(io, userCode, other);
        });

        on('ice_failed', () => {
            const userCode = socketIdToUserCode.get(socket.id);
            if(userCode) sendJSON({ 'ice_failed': userCode}, byondPort);
        });

        on('voice_activity', (data) => {
            const userCode = socketIdToUserCode.get(socket.id);
            if (!userCode) return;
            sendJSON({voice_activity: userCode, active: !!data['active']}, byondPort)
        });
    };
}

module.exports = { createConnectionHandler, endSession };
