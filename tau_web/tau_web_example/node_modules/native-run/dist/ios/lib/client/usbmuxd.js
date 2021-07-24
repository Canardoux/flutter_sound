"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.UsbmuxdClient = void 0;
const Debug = require("debug");
const net = require("net");
const plist = require("plist");
const usbmux_1 = require("../protocol/usbmux");
const client_1 = require("./client");
const debug = Debug('native-run:ios:lib:client:usbmuxd');
function isUsbmuxdConnectResponse(resp) {
    return resp.MessageType === 'Result' && resp.Number !== undefined;
}
function isUsbmuxdDeviceResponse(resp) {
    return resp.DeviceList !== undefined;
}
function isUsbmuxdPairRecordResponse(resp) {
    return resp.PairRecordData !== undefined;
}
class UsbmuxdClient extends client_1.ServiceClient {
    constructor(socket) {
        super(socket, new usbmux_1.UsbmuxProtocolClient(socket));
        this.socket = socket;
    }
    static connectUsbmuxdSocket() {
        debug('connectUsbmuxdSocket');
        if ('win32' === process.platform) {
            return net.connect({ port: 27015, host: 'localhost' });
        }
        else {
            return net.connect({ path: '/var/run/usbmuxd' });
        }
    }
    async connect(device, port) {
        debug(`connect: ${device.DeviceID} on port ${port}`);
        const resp = await this.protocolClient.sendMessage({
            messageType: 'Connect',
            extraFields: {
                DeviceID: device.DeviceID,
                PortNumber: htons(port),
            },
        });
        if (isUsbmuxdConnectResponse(resp) && resp.Number === 0) {
            return this.protocolClient.socket;
        }
        else {
            throw new client_1.ResponseError(`There was an error connecting to ${device.DeviceID} on port ${port}`, resp);
        }
    }
    async getDevices() {
        debug('getDevices');
        const resp = await this.protocolClient.sendMessage({
            messageType: 'ListDevices',
        });
        if (isUsbmuxdDeviceResponse(resp)) {
            return resp.DeviceList;
        }
        else {
            throw new client_1.ResponseError('Invalid response from getDevices', resp);
        }
    }
    async getDevice(udid) {
        debug(`getDevice ${udid ? 'udid: ' + udid : ''}`);
        const devices = await this.getDevices();
        if (!devices.length) {
            throw new Error('No devices found');
        }
        if (!udid) {
            return devices[0];
        }
        for (const device of devices) {
            if (device.Properties && device.Properties.SerialNumber === udid) {
                return device;
            }
        }
        throw new Error(`No device with udid ${udid} found`);
    }
    async readPairRecord(udid) {
        debug(`readPairRecord: ${udid}`);
        const resp = await this.protocolClient.sendMessage({
            messageType: 'ReadPairRecord',
            extraFields: { PairRecordID: udid },
        });
        if (isUsbmuxdPairRecordResponse(resp)) {
            // the pair record can be created as a binary plist
            const BPLIST_MAGIC = Buffer.from('bplist00');
            if (BPLIST_MAGIC.compare(resp.PairRecordData, 0, 8) === 0) {
                debug('Binary plist pair record detected.');
                const bplistParser = await Promise.resolve().then(() => require('bplist-parser'));
                return bplistParser.parseBuffer(resp.PairRecordData)[0];
            }
            else {
                return plist.parse(resp.PairRecordData.toString()); // TODO: type guard
            }
        }
        else {
            throw new client_1.ResponseError(`There was an error reading pair record for udid: ${udid}`, resp);
        }
    }
}
exports.UsbmuxdClient = UsbmuxdClient;
function htons(n) {
    return ((n & 0xff) << 8) | ((n >> 8) & 0xff);
}
