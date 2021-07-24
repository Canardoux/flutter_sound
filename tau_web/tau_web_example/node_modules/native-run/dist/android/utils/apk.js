"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getApkInfo = exports.readAndroidManifest = void 0;
const unzip_1 = require("../../utils/unzip");
const binary_xml_parser_1 = require("./binary-xml-parser");
async function readAndroidManifest(apkPath) {
    let error;
    const chunks = [];
    await unzip_1.unzip(apkPath, async (entry, zipfile, openReadStream) => {
        if (entry.fileName === 'AndroidManifest.xml') {
            const readStream = await openReadStream(entry);
            readStream.on('error', (err) => (error = err));
            readStream.on('data', (chunk) => chunks.push(chunk));
            readStream.on('end', () => zipfile.close());
        }
        else {
            zipfile.readEntry();
        }
    });
    if (error) {
        throw error;
    }
    const buf = Buffer.concat(chunks);
    const manifestBuffer = Buffer.from(buf);
    return new binary_xml_parser_1.BinaryXmlParser(manifestBuffer).parse();
}
exports.readAndroidManifest = readAndroidManifest;
async function getApkInfo(apkPath) {
    const doc = await readAndroidManifest(apkPath);
    const appId = doc.attributes.find((a) => a.name === 'package').value;
    const application = doc.childNodes.find((n) => n.nodeName === 'application');
    const activity = application.childNodes.find((n) => n.nodeName === 'activity');
    const activityName = activity.attributes.find((a) => a.name === 'name').value;
    return { appId, activityName };
}
exports.getApkInfo = getApkInfo;
