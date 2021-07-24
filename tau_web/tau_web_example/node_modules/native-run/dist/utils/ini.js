"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.writeINI = exports.readINI = void 0;
const utils_fs_1 = require("@ionic/utils-fs");
const Debug = require("debug");
const util = require("util");
const debug = Debug('native-run:android:utils:ini');
async function readINI(p, guard = (o) => true) {
    const ini = await Promise.resolve().then(() => require('ini'));
    try {
        const contents = await utils_fs_1.readFile(p, { encoding: 'utf8' });
        const config = ini.decode(contents);
        if (!guard(config)) {
            throw new Error(`Invalid ini configuration file: ${p}\n` +
                `The following guard was used: ${guard.toString()}\n` +
                `INI config parsed as: ${util.inspect(config)}`);
        }
        return { __filename: p, ...config };
    }
    catch (e) {
        debug(e);
    }
}
exports.readINI = readINI;
async function writeINI(p, o) {
    const ini = await Promise.resolve().then(() => require('ini'));
    const contents = ini.encode(o);
    await utils_fs_1.writeFile(p, contents, { encoding: 'utf8' });
}
exports.writeINI = writeINI;
