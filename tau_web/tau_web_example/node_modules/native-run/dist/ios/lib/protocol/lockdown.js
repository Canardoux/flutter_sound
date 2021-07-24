"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.LockdownProtocolWriter = exports.LockdownProtocolReader = exports.LockdownProtocolClient = exports.isLockdownErrorResponse = exports.isLockdownResponse = exports.LOCKDOWN_HEADER_SIZE = void 0;
const Debug = require("debug");
const plist = require("plist");
const lib_errors_1 = require("../lib-errors");
const protocol_1 = require("./protocol");
const debug = Debug('native-run:ios:lib:protocol:lockdown');
exports.LOCKDOWN_HEADER_SIZE = 4;
function isDefined(val) {
    return typeof val !== 'undefined';
}
function isLockdownResponse(resp) {
    return isDefined(resp.Status);
}
exports.isLockdownResponse = isLockdownResponse;
function isLockdownErrorResponse(resp) {
    return isDefined(resp.Error);
}
exports.isLockdownErrorResponse = isLockdownErrorResponse;
class LockdownProtocolClient extends protocol_1.ProtocolClient {
    constructor(socket) {
        super(socket, new protocol_1.ProtocolReaderFactory(LockdownProtocolReader), new LockdownProtocolWriter());
    }
}
exports.LockdownProtocolClient = LockdownProtocolClient;
class LockdownProtocolReader extends protocol_1.PlistProtocolReader {
    constructor(callback) {
        super(exports.LOCKDOWN_HEADER_SIZE, callback);
    }
    parseHeader(data) {
        return data.readUInt32BE(0);
    }
    parseBody(data) {
        const resp = super.parseBody(data);
        debug(`Response: ${JSON.stringify(resp)}`);
        if (isLockdownErrorResponse(resp)) {
            if (resp.Error === 'DeviceLocked') {
                throw new lib_errors_1.IOSLibError('Device is currently locked.', 'DeviceLocked');
            }
            throw new Error(resp.Error);
        }
        return resp;
    }
}
exports.LockdownProtocolReader = LockdownProtocolReader;
class LockdownProtocolWriter {
    write(socket, plistData) {
        debug(`socket write: ${JSON.stringify(plistData)}`);
        const plistMessage = plist.build(plistData);
        const header = Buffer.alloc(exports.LOCKDOWN_HEADER_SIZE);
        header.writeUInt32BE(plistMessage.length, 0);
        socket.write(header);
        socket.write(plistMessage);
    }
}
exports.LockdownProtocolWriter = LockdownProtocolWriter;
