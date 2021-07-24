"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.MobileImageMounterClient = void 0;
const Debug = require("debug");
const fs = require("fs");
const lockdown_1 = require("../protocol/lockdown");
const client_1 = require("./client");
const debug = Debug('native-run:ios:lib:client:mobile_image_mounter');
function isMIMUploadCompleteResponse(resp) {
    return resp.Status === 'Complete';
}
function isMIMUploadReceiveBytesResponse(resp) {
    return resp.Status === 'ReceiveBytesAck';
}
class MobileImageMounterClient extends client_1.ServiceClient {
    constructor(socket) {
        super(socket, new lockdown_1.LockdownProtocolClient(socket));
    }
    async mountImage(imagePath, imageSig) {
        debug(`mountImage: ${imagePath}`);
        const resp = await this.protocolClient.sendMessage({
            Command: 'MountImage',
            ImagePath: imagePath,
            ImageSignature: imageSig,
            ImageType: 'Developer',
        });
        if (!lockdown_1.isLockdownResponse(resp) || resp.Status !== 'Complete') {
            throw new client_1.ResponseError(`There was an error mounting ${imagePath} on device`, resp);
        }
    }
    async uploadImage(imagePath, imageSig) {
        debug(`uploadImage: ${imagePath}`);
        const imageSize = fs.statSync(imagePath).size;
        return this.protocolClient.sendMessage({
            Command: 'ReceiveBytes',
            ImageSize: imageSize,
            ImageSignature: imageSig,
            ImageType: 'Developer',
        }, (resp, resolve, reject) => {
            if (isMIMUploadReceiveBytesResponse(resp)) {
                const imageStream = fs.createReadStream(imagePath);
                imageStream.pipe(this.protocolClient.socket, { end: false });
                imageStream.on('error', err => reject(err));
            }
            else if (isMIMUploadCompleteResponse(resp)) {
                resolve();
            }
            else {
                reject(new client_1.ResponseError(`There was an error uploading image ${imagePath} to the device`, resp));
            }
        });
    }
    async lookupImage() {
        debug('lookupImage');
        return this.protocolClient.sendMessage({
            Command: 'LookupImage',
            ImageType: 'Developer',
        });
    }
}
exports.MobileImageMounterClient = MobileImageMounterClient;
