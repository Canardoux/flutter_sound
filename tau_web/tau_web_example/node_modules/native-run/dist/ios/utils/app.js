"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.unzipIPA = exports.getBundleId = void 0;
const utils_fs_1 = require("@ionic/utils-fs");
const Debug = require("debug");
const fs_1 = require("fs");
const path = require("path");
const errors_1 = require("../../errors");
const process_1 = require("../../utils/process");
const unzip_1 = require("../../utils/unzip");
const debug = Debug('native-run:ios:utils:app');
// TODO: cross platform? Use plist/bplist
async function getBundleId(appPath) {
    const plistPath = path.resolve(appPath, 'Info.plist');
    try {
        const { stdout } = await process_1.execFile('/usr/libexec/PlistBuddy', ['-c', 'Print :CFBundleIdentifier', plistPath], { encoding: 'utf8' });
        if (stdout) {
            return stdout.trim();
        }
    }
    catch {
        // ignore
    }
    throw new errors_1.Exception('Unable to get app bundle identifier');
}
exports.getBundleId = getBundleId;
async function unzipIPA(ipaPath, destPath) {
    let error;
    let appPath = '';
    await unzip_1.unzip(ipaPath, async (entry, zipfile, openReadStream) => {
        debug(`Unzip: ${entry.fileName}`);
        const dest = path.join(destPath, entry.fileName);
        if (entry.fileName.endsWith('/')) {
            await utils_fs_1.mkdirp(dest);
            if (entry.fileName.endsWith('.app/')) {
                appPath = entry.fileName;
            }
            zipfile.readEntry();
        }
        else {
            await utils_fs_1.mkdirp(path.dirname(dest));
            const readStream = await openReadStream(entry);
            readStream.on('error', (err) => (error = err));
            readStream.on('end', () => {
                zipfile.readEntry();
            });
            readStream.pipe(fs_1.createWriteStream(dest));
        }
    });
    if (error) {
        throw error;
    }
    if (!appPath) {
        throw new errors_1.Exception('Unable to determine .app directory from .ipa');
    }
    return appPath;
}
exports.unzipIPA = unzipIPA;
