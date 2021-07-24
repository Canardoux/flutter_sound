"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AFCClient = void 0;
const Debug = require("debug");
const fs = require("fs");
const path = require("path");
const util_1 = require("util");
const afc_1 = require("../protocol/afc");
const client_1 = require("./client");
const debug = Debug('native-run:ios:lib:client:afc');
const MAX_OPEN_FILES = 240;
class AFCClient extends client_1.ServiceClient {
    constructor(socket) {
        super(socket, new afc_1.AFCProtocolClient(socket));
        this.socket = socket;
    }
    async getFileInfo(path) {
        debug(`getFileInfo: ${path}`);
        const resp = await this.protocolClient.sendMessage({
            operation: afc_1.AFC_OPS.GET_FILE_INFO,
            data: toCString(path),
        });
        const strings = [];
        let currentString = '';
        const tokens = resp.data;
        tokens.forEach(token => {
            if (token === 0) {
                strings.push(currentString);
                currentString = '';
            }
            else {
                currentString += String.fromCharCode(token);
            }
        });
        return strings;
    }
    async writeFile(fd, data) {
        debug(`writeFile: ${Array.prototype.toString.call(fd)}`);
        return this.protocolClient.sendMessage({
            operation: afc_1.AFC_OPS.FILE_WRITE,
            data: fd,
            payload: data,
        });
    }
    async openFile(path) {
        debug(`openFile: ${path}`);
        // mode + path + null terminator
        const data = Buffer.alloc(8 + path.length + 1);
        // write mode
        data.writeUInt32LE(afc_1.AFC_FILE_OPEN_FLAGS.WRONLY, 0);
        // then path to file
        toCString(path).copy(data, 8);
        const resp = await this.protocolClient.sendMessage({
            operation: afc_1.AFC_OPS.FILE_OPEN,
            data,
        });
        if (resp.operation === afc_1.AFC_OPS.FILE_OPEN_RES) {
            return resp.data;
        }
        throw new Error(`There was an unknown error opening file ${path}, response: ${Array.prototype.toString.call(resp.data)}`);
    }
    async closeFile(fd) {
        debug(`closeFile fd: ${Array.prototype.toString.call(fd)}`);
        return this.protocolClient.sendMessage({
            operation: afc_1.AFC_OPS.FILE_CLOSE,
            data: fd,
        });
    }
    async uploadFile(srcPath, destPath) {
        debug(`uploadFile: ${srcPath}`);
        // read local file and get fd of destination
        const [srcFile, destFile] = await Promise.all([
            await util_1.promisify(fs.readFile)(srcPath),
            await this.openFile(destPath),
        ]);
        try {
            await this.writeFile(destFile, srcFile);
            await this.closeFile(destFile);
        }
        catch (err) {
            await this.closeFile(destFile);
            throw err;
        }
    }
    async makeDirectory(path) {
        debug(`makeDirectory: ${path}`);
        return this.protocolClient.sendMessage({
            operation: afc_1.AFC_OPS.MAKE_DIR,
            data: toCString(path),
        });
    }
    async uploadDirectory(srcPath, destPath) {
        debug(`uploadDirectory: ${srcPath}`);
        await this.makeDirectory(destPath);
        // AFC doesn't seem to give out more than 240 file handles,
        // so we delay any requests that would push us over until more open up
        let numOpenFiles = 0;
        const pendingFileUploads = [];
        const _this = this;
        return uploadDir(srcPath);
        async function uploadDir(dirPath) {
            const promises = [];
            for (const file of fs.readdirSync(dirPath)) {
                const filePath = path.join(dirPath, file);
                const remotePath = path.join(destPath, path.relative(srcPath, filePath));
                if (fs.lstatSync(filePath).isDirectory()) {
                    promises.push(_this.makeDirectory(remotePath).then(() => uploadDir(filePath)));
                }
                else {
                    // Create promise to add to promises array
                    // this way it can be resolved once a pending upload has finished
                    let resolve;
                    let reject;
                    const promise = new Promise((res, rej) => {
                        resolve = res;
                        reject = rej;
                    });
                    promises.push(promise);
                    // wrap upload in a function in case we need to save it for later
                    const uploadFile = (tries = 0) => {
                        numOpenFiles++;
                        _this
                            .uploadFile(filePath, remotePath)
                            .then(() => {
                            resolve();
                            numOpenFiles--;
                            const fn = pendingFileUploads.pop();
                            if (fn) {
                                fn();
                            }
                        })
                            .catch((err) => {
                            // Couldn't get fd for whatever reason, try again
                            // # of retries is arbitrary and can be adjusted
                            if (err.status === afc_1.AFC_STATUS.NO_RESOURCES && tries < 10) {
                                debug(`Received NO_RESOURCES from AFC, retrying ${filePath} upload. ${tries}`);
                                uploadFile(tries++);
                            }
                            else {
                                numOpenFiles--;
                                reject(err);
                            }
                        });
                    };
                    if (numOpenFiles < MAX_OPEN_FILES) {
                        uploadFile();
                    }
                    else {
                        debug(`numOpenFiles >= ${MAX_OPEN_FILES}, adding to pending queue. Length: ${pendingFileUploads.length}`);
                        pendingFileUploads.push(uploadFile);
                    }
                }
            }
            await Promise.all(promises);
        }
    }
}
exports.AFCClient = AFCClient;
function toCString(s) {
    const buf = Buffer.alloc(s.length + 1);
    const len = buf.write(s);
    buf.writeUInt8(0, len);
    return buf;
}
