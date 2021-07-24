"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.DebugserverClient = void 0;
const Debug = require("debug");
const path = require("path");
const gdb_1 = require("../protocol/gdb");
const client_1 = require("./client");
const debug = Debug('native-run:ios:lib:client:debugserver');
class DebugserverClient extends client_1.ServiceClient {
    constructor(socket) {
        super(socket, new gdb_1.GDBProtocolClient(socket));
        this.socket = socket;
    }
    async setMaxPacketSize(size) {
        return this.sendCommand('QSetMaxPacketSize:', [size.toString()]);
    }
    async setWorkingDir(workingDir) {
        return this.sendCommand('QSetWorkingDir:', [workingDir]);
    }
    async checkLaunchSuccess() {
        return this.sendCommand('qLaunchSuccess', []);
    }
    async attachByName(name) {
        const hexName = Buffer.from(name).toString('hex');
        return this.sendCommand(`vAttachName;${hexName}`, []);
    }
    async continue() {
        return this.sendCommand('c', []);
    }
    halt() {
        // ^C
        debug('Sending ^C to debugserver');
        return this.protocolClient.socket.write('\u0003');
    }
    async kill() {
        const msg = { cmd: 'k', args: [] };
        return this.protocolClient.sendMessage(msg, (resp, resolve, reject) => {
            this.protocolClient.socket.write('+');
            const parts = resp.split(';');
            for (const part of parts) {
                if (part.includes('description')) {
                    // description:{hex encoded message like: "Terminated with signal 9"}
                    resolve(Buffer.from(part.split(':')[1], 'hex').toString('ascii'));
                }
            }
        });
    }
    // TODO support app args
    // https://sourceware.org/gdb/onlinedocs/gdb/Packets.html#Packets
    // A arglen,argnum,arg,
    async launchApp(appPath, executableName) {
        const fullPath = path.join(appPath, executableName);
        const hexAppPath = Buffer.from(fullPath).toString('hex');
        const appCommand = `A${hexAppPath.length},0,${hexAppPath}`;
        return this.sendCommand(appCommand, []);
    }
    async sendCommand(cmd, args) {
        const msg = { cmd, args };
        debug(`Sending command: ${cmd}, args: ${args}`);
        const resp = await this.protocolClient.sendMessage(msg);
        // we need to ACK as well
        this.protocolClient.socket.write('+');
        return resp;
    }
}
exports.DebugserverClient = DebugserverClient;
