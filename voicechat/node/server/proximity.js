const { userCodeToSocketId } = require('./state');

const prevPackets = new Map();

function normalizeStringify(obj) {
    if ('none' in obj) {
        return JSON.stringify({ none: 1 });
    }
    const sortedPeers = Object.fromEntries(
        Object.entries(obj.peers).sort((a, b) => a[0].localeCompare(b[0]))
    );
    return JSON.stringify({ peers: sortedPeers, own: obj.own });
}

// Forget what every client was last sent, so the next location packet is re-sent in full,
// and tell everyone to drop their connection to userCode so it gets rebuilt from scratch.
function resetPeer(io, userCode) {
    prevPackets.clear();
    io.emit('peer-reset', { userCode });
}

// Rebuild the connection between two peers only, for when their link failed.
function resetPair(io, userCodeA, userCodeB) {
    for (const [self, other] of [[userCodeA, userCodeB], [userCodeB, userCodeA]]) {
        prevPackets.delete(self);
        const socket = io.sockets.sockets.get(userCodeToSocketId.get(self));
        if (socket) socket.emit('peer-reset', { userCode: other });
    }
}

const handleLocationPacket = (packet, io) => {
    const seen = new Set();
    for (const room in packet) {
        if (room === "cmd") continue;
        const isNoProx = room.endsWith('_noprox');
        const locations = packet[room];
        const userCodes = Object.keys(locations);
        userCodes.forEach(code => seen.add(code));
        const numUsers = userCodes.length;

        // Initialize peers for all users
        const peersByUser = {};
        for (const userCode of userCodes) {
            peersByUser[userCode] = {};
        }

        if (isNoProx) { // connect everyone with distance 0
            for (let i = 0; i < numUsers; i++) {
                const userCode = userCodes[i];
                for (let j = 0; j < numUsers; j++) {
                    if (i !== j) {
                        const otherCode = userCodes[j];
                        peersByUser[userCode][otherCode] = 0;
                    }
                }
            }
        } else {
            for (let i = 0; i < numUsers; i++) {
                const userCode = userCodes[i];
                const [ux, uy] = locations[userCode];
                for (let j = i + 1; j < numUsers; j++) {
                    const otherCode = userCodes[j];
                    const [ox, oy] = locations[otherCode];
                    const dx = Math.abs(ux - ox);
                    const dy = Math.abs(uy - oy);
                    if (dx < 8 && dy < 8) {
                        const dist = Math.hypot(ux - ox, uy - oy);
                        const roundedDist = Math.round(dist * 10) / 10;
                        peersByUser[userCode][otherCode] = roundedDist;
                        peersByUser[otherCode][userCode] = roundedDist;
                    }
                }
            }
        }

        // if changed emit
        for (const userCode of userCodes) {
            const peers = peersByUser[userCode];
            const socketId = userCodeToSocketId.get(userCode);
            const socket = io.sockets.sockets.get(socketId);
            if (socketId && socket) {
                const out_packet = Object.keys(peers).length === 0
                    ? { none: 1 }
                    : { peers: peers, own: userCode };
                const newStr = normalizeStringify(out_packet);
                const prevStr = prevPackets.get(userCode);
                if (newStr !== prevStr) {
                    socket.emit('loc', out_packet);
                    prevPackets.set(userCode, newStr);
                }
            } else {
                // console.log(`No socket found for userCode: ${userCode}`);
            }
        }
    }

    // users missing from the packet (knocked out, muted trait, left voice) have no peers anymore.
    // Without this their browser keeps stale connections and never rebuilds them when they come back.
    for (const userCode of [...prevPackets.keys()]) {
        if (seen.has(userCode)) continue;
        prevPackets.delete(userCode);
        const socket = io.sockets.sockets.get(userCodeToSocketId.get(userCode));
        if (socket) socket.emit('loc', { none: 1 });
    }
};
module.exports = {handleLocationPacket, resetPeer, resetPair};
