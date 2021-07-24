"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.LockdowndClient = void 0;
const Debug = require("debug");
const tls = require("tls");
const lockdown_1 = require("../protocol/lockdown");
const client_1 = require("./client");
const debug = Debug('native-run:ios:lib:client:lockdownd');
function isLockdowndServiceResponse(resp) {
    return (resp.Request === 'StartService' &&
        resp.Service !== undefined &&
        resp.Port !== undefined);
}
function isLockdowndSessionResponse(resp) {
    return resp.Request === 'StartSession';
}
function isLockdowndAllValuesResponse(resp) {
    return resp.Request === 'GetValue' && resp.Value !== undefined;
}
function isLockdowndValueResponse(resp) {
    return (resp.Request === 'GetValue' &&
        resp.Key !== undefined &&
        typeof resp.Value === 'string');
}
function isLockdowndQueryTypeResponse(resp) {
    return resp.Request === 'QueryType' && resp.Type !== undefined;
}
class LockdowndClient extends client_1.ServiceClient {
    constructor(socket) {
        super(socket, new lockdown_1.LockdownProtocolClient(socket));
        this.socket = socket;
    }
    async startService(name) {
        debug(`startService: ${name}`);
        const resp = await this.protocolClient.sendMessage({
            Request: 'StartService',
            Service: name,
        });
        if (isLockdowndServiceResponse(resp)) {
            return { port: resp.Port, enableServiceSSL: !!resp.EnableServiceSSL };
        }
        else {
            throw new client_1.ResponseError(`Error starting service ${name}`, resp);
        }
    }
    async startSession(pairRecord) {
        debug(`startSession: ${pairRecord}`);
        const resp = await this.protocolClient.sendMessage({
            Request: 'StartSession',
            HostID: pairRecord.HostID,
            SystemBUID: pairRecord.SystemBUID,
        });
        if (isLockdowndSessionResponse(resp)) {
            if (resp.EnableSessionSSL) {
                this.protocolClient.socket = new tls.TLSSocket(this.protocolClient.socket, {
                    secureContext: tls.createSecureContext({
                        secureProtocol: 'TLSv1_method',
                        cert: pairRecord.RootCertificate,
                        key: pairRecord.RootPrivateKey,
                    }),
                });
                debug(`Socket upgraded to TLS connection`);
            }
            // TODO: save sessionID for StopSession?
        }
        else {
            throw new client_1.ResponseError('Error starting session', resp);
        }
    }
    async getAllValues() {
        debug(`getAllValues`);
        const resp = await this.protocolClient.sendMessage({ Request: 'GetValue' });
        if (isLockdowndAllValuesResponse(resp)) {
            return resp.Value;
        }
        else {
            throw new client_1.ResponseError('Error getting lockdown value', resp);
        }
    }
    async getValue(val) {
        debug(`getValue: ${val}`);
        const resp = await this.protocolClient.sendMessage({
            Request: 'GetValue',
            Key: val,
        });
        if (isLockdowndValueResponse(resp)) {
            return resp.Value;
        }
        else {
            throw new client_1.ResponseError('Error getting lockdown value', resp);
        }
    }
    async queryType() {
        debug('queryType');
        const resp = await this.protocolClient.sendMessage({
            Request: 'QueryType',
        });
        if (isLockdowndQueryTypeResponse(resp)) {
            return resp.Type;
        }
        else {
            throw new client_1.ResponseError('Error getting lockdown query type', resp);
        }
    }
    async doHandshake(pairRecord) {
        debug('doHandshake');
        // if (await this.lockdownQueryType() !== 'com.apple.mobile.lockdown') {
        //   throw new Error('Invalid type received from lockdown handshake');
        // }
        // await this.getLockdownValue('ProductVersion');
        // TODO: validate pair and pair
        await this.startSession(pairRecord);
    }
}
exports.LockdowndClient = LockdowndClient;
