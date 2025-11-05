const express = require('express');
const https = require('https');
const fs = require('fs');
const path = require('path');
const { Server } = require('socket.io');
const { createConnectionHandler } = require('./websocketHandlers');

const node_path = path.resolve(process.cwd(), 'voicechat/node')
const cert_path = path.resolve(node_path, "certs")

function startWebSocketServer(byondPort, nodePort) {
    const options = {
        key: fs.readFileSync(path.resolve(cert_path, 'key.pem')),
        cert: fs.readFileSync(path.resolve(cert_path, 'cert.pem'))
    };
    const app = express();
    const server = https.createServer(options, app);
    const io = new Server(server);
    const public_path = path.resolve(node_path,  'public')
    app.use(express.static(public_path));
    app.get('/', (req, res) => {
        res.sendFile(path.resolve(public_path, 'voicechat.html'));
    });

    const handleConnection = createConnectionHandler(byondPort, io);
    io.on('connection', handleConnection);

    const PORT = nodePort;
    server.listen(PORT, () => {
        console.log(`HTTPS server running on port ${PORT}`);
    });

    return { io, server };
}

function disconnectAllClients(io) {
    io.emit('server-shutdown');
    setTimeout(() => {
        io.sockets.sockets.forEach((socket) => {
            socket.emit('update', { type: 'update', data: 'Disconnected: Disconnecting all clients' });
            socket.disconnect(true);
        });
    }, 2000);
}

module.exports = { startWebSocketServer, disconnectAllClients };