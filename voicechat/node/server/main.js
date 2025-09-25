const { execSync } = require('child_process');
const minimist = require('minimist');

const { startWebSocketServer, disconnectAllClients } = require('./client/websocketServer.js');
const { startByondServer } = require('./byond/ByondServer.js');
const { sendJSON } = require('./byond/ByondCommunication.js');

const argv = minimist(process.argv.slice(2));
const byondPort = argv['byond-port']
const nodePort = argv['node-port']
const byondPID = argv['byond-pid']

const shutdown_function = () => {
    sendJSON({shutting_down: 1}, byondPort)
    disconnectAllClients(io);
    io.close(() => {
        wsServer.close(() => {
            ByondServer.close(() => {
                console.log('shutdown_function called');
                setTimeout(() => {
                    process.exit(0);
                }, 2000);
            });
        });
    });
};
;

function isParentRunning() {
    if (process.platform === 'win32') {
        try {
            const output = execSync(`tasklist /FI "PID eq ${byondPID}"`).toString();
            return output.includes(byondPID.toString());
        } catch (e) {
            return false;
        }
    } else {
        try {
            process.kill(byondPID, 0);
            return true;
        } catch (e) {
            return false;
        }
    }
}

function monitorParentProcess(shutdown_function) {
    setInterval(() => {
        if (!isParentRunning()) {
            console.log('Parent process terminated, shutting down Node.js server');
            shutdown_function();

        }
    }, 10000); // 10 seconds
}


monitorParentProcess(shutdown_function);

// Start servers
const { io, server: wsServer } = startWebSocketServer(byondPort, nodePort);
const ByondServer = startByondServer(byondPort, io, shutdown_function);
setTimeout(() => {
    sendJSON({ 'node_started': process.pid }, byondPort);
}, 3000);
process.on('SIGTERM', () => shutdown_function())
process.on('SIGINT', () => shutdown_function())
