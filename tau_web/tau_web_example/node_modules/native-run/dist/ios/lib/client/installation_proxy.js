"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.InstallationProxyClient = void 0;
const Debug = require("debug");
const lockdown_1 = require("../protocol/lockdown");
const client_1 = require("./client");
const debug = Debug('native-run:ios:lib:client:installation_proxy');
function isIPLookupResponse(resp) {
    return resp.length && resp[0].LookupResult !== undefined;
}
function isIPInstallPercentCompleteResponse(resp) {
    return resp.length && resp[0].PercentComplete !== undefined;
}
function isIPInstallCFBundleIdentifierResponse(resp) {
    return resp.length && resp[0].CFBundleIdentifier !== undefined;
}
function isIPInstallCompleteResponse(resp) {
    return resp.length && resp[0].Status === 'Complete';
}
class InstallationProxyClient extends client_1.ServiceClient {
    constructor(socket) {
        super(socket, new lockdown_1.LockdownProtocolClient(socket));
        this.socket = socket;
    }
    async lookupApp(bundleIds, options = {
        ReturnAttributes: [
            'Path',
            'Container',
            'CFBundleExecutable',
            'CFBundleIdentifier',
        ],
        ApplicationsType: 'Any',
    }) {
        debug(`lookupApp, options: ${JSON.stringify(options)}`);
        const resp = await this.protocolClient.sendMessage({
            Command: 'Lookup',
            ClientOptions: {
                BundleIDs: bundleIds,
                ...options,
            },
        });
        if (isIPLookupResponse(resp)) {
            return resp[0].LookupResult;
        }
        else {
            throw new client_1.ResponseError(`There was an error looking up app`, resp);
        }
    }
    async installApp(packagePath, bundleId, options = {
        ApplicationsType: 'Any',
        PackageType: 'Developer',
    }) {
        debug(`installApp, packagePath: ${packagePath}, bundleId: ${bundleId}`);
        return this.protocolClient.sendMessage({
            Command: 'Install',
            PackagePath: packagePath,
            ClientOptions: {
                CFBundleIdentifier: bundleId,
                ...options,
            },
        }, (resp, resolve, reject) => {
            if (isIPInstallCompleteResponse(resp)) {
                resolve();
            }
            else if (isIPInstallPercentCompleteResponse(resp)) {
                debug(`Installation status: ${resp[0].Status}, %${resp[0].PercentComplete}`);
            }
            else if (isIPInstallCFBundleIdentifierResponse(resp)) {
                debug(`Installed app: ${resp[0].CFBundleIdentifier}`);
            }
            else {
                reject(new client_1.ResponseError('There was an error installing app', resp));
            }
        });
    }
}
exports.InstallationProxyClient = InstallationProxyClient;
