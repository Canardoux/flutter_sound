"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.UsbmuxProtocolWriter = exports.UsbmuxProtocolReader = exports.UsbmuxProtocolClient = exports.USBMUXD_HEADER_SIZE = void 0;
const Debug = require("debug");
const plist = require("plist");
const protocol_1 = require("./protocol");
const debug = Debug('native-run:ios:lib:protocol:usbmux');
exports.USBMUXD_HEADER_SIZE = 16;
class UsbmuxProtocolClient extends protocol_1.ProtocolClient {
    constructor(socket) {
        super(socket, new protocol_1.ProtocolReaderFactory(UsbmuxProtocolReader), new UsbmuxProtocolWriter());
    }
}
exports.UsbmuxProtocolClient = UsbmuxProtocolClient;
class UsbmuxProtocolReader extends protocol_1.PlistProtocolReader {
    constructor(callback) {
        super(exports.USBMUXD_HEADER_SIZE, callback);
    }
    parseHeader(data) {
        return data.readUInt32LE(0) - exports.USBMUXD_HEADER_SIZE;
    }
    parseBody(data) {
        const resp = super.parseBody(data);
        debug(`Response: ${JSON.stringify(resp)}`);
        return resp;
    }
}
exports.UsbmuxProtocolReader = UsbmuxProtocolReader;
class UsbmuxProtocolWriter {
    constructor() {
        this.useTag = 0;
    }
    write(socket, msg) {
        // TODO Usbmux message type
        debug(`socket write: ${JSON.stringify(msg)}`);
        const { messageType, extraFields } = msg;
        const plistMessage = plist.build({
            BundleID: 'io.ionic.native-run',
            ClientVersionString: 'usbmux.js',
            MessageType: messageType,
            ProgName: 'native-run',
            kLibUSBMuxVersion: 3,
            ...extraFields,
        });
        const dataSize = plistMessage ? plistMessage.length : 0;
        const protocolVersion = 1;
        const messageCode = 8;
        const header = Buffer.alloc(exports.USBMUXD_HEADER_SIZE);
        header.writeUInt32LE(exports.USBMUXD_HEADER_SIZE + dataSize, 0);
        header.writeUInt32LE(protocolVersion, 4);
        header.writeUInt32LE(messageCode, 8);
        header.writeUInt32LE(this.useTag++, 12); // TODO
        socket.write(header);
        socket.write(plistMessage);
    }
}
exports.UsbmuxProtocolWriter = UsbmuxProtocolWriter;
