"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ClientManager = void 0;
const stream_1 = require("stream");
const tls = require("tls");
const afc_1 = require("./client/afc");
const debugserver_1 = require("./client/debugserver");
const installation_proxy_1 = require("./client/installation_proxy");
const lockdownd_1 = require("./client/lockdownd");
const mobile_image_mounter_1 = require("./client/mobile_image_mounter");
const usbmuxd_1 = require("./client/usbmuxd");
class ClientManager {
    constructor(pairRecord, device, lockdowndClient) {
        this.pairRecord = pairRecord;
        this.device = device;
        this.lockdowndClient = lockdowndClient;
        this.connections = [lockdowndClient.socket];
    }
    static async create(udid) {
        const usbmuxClient = new usbmuxd_1.UsbmuxdClient(usbmuxd_1.UsbmuxdClient.connectUsbmuxdSocket());
        const device = await usbmuxClient.getDevice(udid);
        const pairRecord = await usbmuxClient.readPairRecord(device.Properties.SerialNumber);
        const lockdownSocket = await usbmuxClient.connect(device, 62078);
        const lockdownClient = new lockdownd_1.LockdowndClient(lockdownSocket);
        await lockdownClient.doHandshake(pairRecord);
        return new ClientManager(pairRecord, device, lockdownClient);
    }
    async getUsbmuxdClient() {
        const usbmuxClient = new usbmuxd_1.UsbmuxdClient(usbmuxd_1.UsbmuxdClient.connectUsbmuxdSocket());
        this.connections.push(usbmuxClient.socket);
        return usbmuxClient;
    }
    async getLockdowndClient() {
        const usbmuxClient = new usbmuxd_1.UsbmuxdClient(usbmuxd_1.UsbmuxdClient.connectUsbmuxdSocket());
        const lockdownSocket = await usbmuxClient.connect(this.device, 62078);
        const lockdownClient = new lockdownd_1.LockdowndClient(lockdownSocket);
        this.connections.push(lockdownClient.socket);
        return lockdownClient;
    }
    async getLockdowndClientWithHandshake() {
        const lockdownClient = await this.getLockdowndClient();
        await lockdownClient.doHandshake(this.pairRecord);
        return lockdownClient;
    }
    async getAFCClient() {
        return this.getServiceClient('com.apple.afc', afc_1.AFCClient);
    }
    async getInstallationProxyClient() {
        return this.getServiceClient('com.apple.mobile.installation_proxy', installation_proxy_1.InstallationProxyClient);
    }
    async getMobileImageMounterClient() {
        return this.getServiceClient('com.apple.mobile.mobile_image_mounter', mobile_image_mounter_1.MobileImageMounterClient);
    }
    async getDebugserverClient() {
        try {
            // iOS 14 added support for a secure debug service so try to connect to that first
            return await this.getServiceClient('com.apple.debugserver.DVTSecureSocketProxy', debugserver_1.DebugserverClient);
        }
        catch {
            // otherwise, fall back to the previous implementation
            return this.getServiceClient('com.apple.debugserver', debugserver_1.DebugserverClient, true);
        }
    }
    async getServiceClient(name, ServiceType, disableSSL = false) {
        const { port: servicePort, enableServiceSSL } = await this.lockdowndClient.startService(name);
        const usbmuxClient = new usbmuxd_1.UsbmuxdClient(usbmuxd_1.UsbmuxdClient.connectUsbmuxdSocket());
        let usbmuxdSocket = await usbmuxClient.connect(this.device, servicePort);
        if (enableServiceSSL) {
            const tlsOptions = {
                rejectUnauthorized: false,
                secureContext: tls.createSecureContext({
                    secureProtocol: 'TLSv1_method',
                    cert: this.pairRecord.RootCertificate,
                    key: this.pairRecord.RootPrivateKey,
                }),
            };
            // Some services seem to not support TLS/SSL after the initial handshake
            // More info: https://github.com/libimobiledevice/libimobiledevice/issues/793
            if (disableSSL) {
                // According to https://nodejs.org/api/tls.html#tls_tls_connect_options_callback we can
                // pass any Duplex in to tls.connect instead of a Socket. So we'll use our proxy to keep
                // the TLS wrapper and underlying usbmuxd socket separate.
                const proxy = new UsbmuxdProxy(usbmuxdSocket);
                tlsOptions.socket = proxy;
                await new Promise((res, rej) => {
                    const timeoutId = setTimeout(() => {
                        rej('The TLS handshake failed to complete after 5s.');
                    }, 5000);
                    tls.connect(tlsOptions, function () {
                        clearTimeout(timeoutId);
                        // After the handshake, we don't need TLS or the proxy anymore,
                        // since we'll just pass in the naked usbmuxd socket to the service client
                        this.destroy();
                        res();
                    });
                });
            }
            else {
                tlsOptions.socket = usbmuxdSocket;
                usbmuxdSocket = tls.connect(tlsOptions);
            }
        }
        const client = new ServiceType(usbmuxdSocket);
        this.connections.push(client.socket);
        return client;
    }
    end() {
        for (const socket of this.connections) {
            // may already be closed
            try {
                socket.end();
            }
            catch (err) {
                // ignore
            }
        }
    }
}
exports.ClientManager = ClientManager;
class UsbmuxdProxy extends stream_1.Duplex {
    constructor(usbmuxdSock) {
        super();
        this.usbmuxdSock = usbmuxdSock;
        this.usbmuxdSock.on('data', data => {
            this.push(data);
        });
    }
    _write(chunk, encoding, callback) {
        this.usbmuxdSock.write(chunk);
        callback();
    }
    _read(size) {
        // Stub so we don't error, since we push everything we get from usbmuxd as it comes in.
        // TODO: better way to do this?
    }
    _destroy() {
        this.usbmuxdSock.removeAllListeners();
    }
}
