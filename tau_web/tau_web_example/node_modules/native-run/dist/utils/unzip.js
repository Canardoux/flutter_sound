"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.unzip = void 0;
const util_1 = require("util");
async function unzip(srcPath, onEntry) {
    const yauzl = await Promise.resolve().then(() => require('yauzl'));
    return new Promise((resolve, reject) => {
        yauzl.open(srcPath, { lazyEntries: true }, (err, zipfile) => {
            if (!zipfile || err) {
                return reject(err);
            }
            const openReadStream = util_1.promisify(zipfile.openReadStream.bind(zipfile));
            zipfile.once('error', reject);
            // resolve when either one happens
            zipfile.once('close', resolve); // fd of zip closed
            zipfile.once('end', resolve); // last entry read
            zipfile.on('entry', entry => onEntry(entry, zipfile, openReadStream));
            zipfile.readEntry();
        });
    });
}
exports.unzip = unzip;
