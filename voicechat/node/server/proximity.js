const { userCodeToSocketId } = require('./state');

const prevPackets = new Map();

// must match ROOM_GHOST in code/__DEFINES/__SURFSHACK/voicechat_rooms.dm
const GHOST_ROOM = 'room_ghost';
// same box as the normal proximity check
const HEARING_RANGE = 8;

function normalizeStringify(obj) {
    if ('none' in obj) {
        return JSON.stringify({ none: 1 });
    }
    const sorted = (o) => Object.fromEntries(Object.entries(o || {}).sort((a, b) => a[0].localeCompare(b[0])));
    return JSON.stringify({ peers: sorted(obj.peers), own: obj.own, modes: sorted(obj.modes) });
}

function distanceIfInRange([ux, uy], [ox, oy]) {
    if (Math.abs(ux - ox) >= HEARING_RANGE || Math.abs(uy - oy) >= HEARING_RANGE) return null;
    return Math.round(Math.hypot(ux - ox, uy - oy) * 10) / 10;
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

// packet keys that aren't rooms
const NOT_ROOMS = new Set(['cmd', 'listeners', 'cant_speak', 'cant_hear']);

const handleLocationPacket = (packet, io) => {
    const seen = new Set();
    // mutes/mimes aren't heard, the deaf don't hear. Everyone else in range hears each other.
    const cantSpeak = new Set(Array.isArray(packet.cant_speak) ? packet.cant_speak : []);
    const cantHear = new Set(Array.isArray(packet.cant_hear) ? packet.cant_hear : []);
    const heardBy = (speaker, listener) => !cantSpeak.has(speaker) && !cantHear.has(listener);
    // userCode -> {otherCode: distance}, across all rooms
    const peersByUser = {};
    // userCode -> {otherCode: 'listen' | 'talk'} for one-way pairs, see below
    const modesByUser = {};
    const addUser = (code) => {
        seen.add(code);
        if (!peersByUser[code]) peersByUser[code] = {};
    };
    // connect a and b if either can hear the other. One-way pairs get a mode on each side:
    // 'talk' = only the other side hears me (I don't play their audio), 'listen' = the reverse
    const connect = (a, b, dist, aToB, bToA) => {
        if (!aToB && !bToA) return;
        peersByUser[a][b] = dist;
        peersByUser[b][a] = dist;
        if (aToB && bToA) return;
        (modesByUser[a] = modesByUser[a] || {})[b] = aToB ? 'talk' : 'listen';
        (modesByUser[b] = modesByUser[b] || {})[a] = bToA ? 'talk' : 'listen';
    };

    for (const room in packet) {
        if (NOT_ROOMS.has(room)) continue;
        const isNoProx = room.endsWith('_noprox');
        const locations = packet[room];
        if (!locations || typeof locations !== 'object') continue;
        const userCodes = Object.keys(locations);
        userCodes.forEach(addUser);
        const numUsers = userCodes.length;

        for (let i = 0; i < numUsers; i++) {
            const userCode = userCodes[i];
            for (let j = i + 1; j < numUsers; j++) {
                const otherCode = userCodes[j];
                const dist = isNoProx ? 0 : distanceIfInRange(locations[userCode], locations[otherCode]);
                if (dist === null) continue;
                connect(userCode, otherCode, dist, heardBy(userCode, otherCode), heardBy(otherCode, userCode));
            }
        }
    }

    // Ghosts that hear the living: { userCode: [x, y, z] }. They get a one-way pair with each
    // living player in range on their z level: the ghost only listens ('listen'), the living
    // side only talks ('talk') and keeps the ghost silent, so a modified page can't be heard.
    const listeners = packet.listeners && typeof packet.listeners === 'object' ? packet.listeners : {};
    for (const listener in listeners) {
        if (!Array.isArray(listeners[listener])) continue;
        const [lx, ly, lz] = listeners[listener];
        addUser(listener);
        for (const room in packet) {
            if (NOT_ROOMS.has(room) || room.endsWith('_noprox')) continue;
            if (!room.startsWith(`${lz}_`) || room === `${lz}_${GHOST_ROOM}`) continue;
            if (!packet[room] || typeof packet[room] !== 'object') continue;
            for (const living in packet[room]) {
                if (living === listener || peersByUser[listener][living] !== undefined) continue;
                const dist = distanceIfInRange([lx, ly], packet[room][living]);
                if (dist === null) continue;
                // never ghost -> living
                connect(listener, living, dist, false, heardBy(living, listener));
            }
        }
    }

    // if changed emit
    for (const userCode in peersByUser) {
        const peers = peersByUser[userCode];
        const socket = io.sockets.sockets.get(userCodeToSocketId.get(userCode));
        if (!socket) continue;
        const out_packet = Object.keys(peers).length === 0
            ? { none: 1 }
            : { peers: peers, own: userCode, modes: modesByUser[userCode] || {} };
        const newStr = normalizeStringify(out_packet);
        if (newStr !== prevPackets.get(userCode)) {
            socket.emit('loc', out_packet);
            prevPackets.set(userCode, newStr);
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
