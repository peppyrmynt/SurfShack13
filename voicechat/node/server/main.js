const { execSync } = require('child_process');
const minimist = require('minimist');
const fs = require('fs')
const { startWebSocketServer, disconnectAllClients } = require('./client/websocketServer.js');
const { startByondServer } = require('./byond/ByondServer.js');
const {startTurnServer, stopTurnServer} = require('./turn.js')
const argv = minimist(process.argv.slice(2));
const byondPort = argv['byond-port']
const nodePort = argv['node-port']
const byondPID = argv['byond-pid']
// optional: public IP to advertise for TURN relays when this machine is behind NAT
const turnExternalIp = argv['turn-external-ip']

const nodePidPath = 'node.pid'

let shuttingDown = false;
const shutdown_function = () => {
    if (shuttingDown) return;
    shuttingDown = true;
    try { fs.unlinkSync(nodePidPath) } catch (e) {}
    disconnectAllClients(io);
    stopTurnServer()
    io.close(() => {
        httpserver.close(() => {
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
const { io, httpserver } = startWebSocketServer(byondPort, nodePort);
const ByondServer = startByondServer(byondPort, io, shutdown_function);
startTurnServer(turnExternalIp)
fs.writeFileSync(nodePidPath, process.pid.toString());


process.on('SIGTERM', () => shutdown_function())
process.on('SIGINT', () => shutdown_function())
