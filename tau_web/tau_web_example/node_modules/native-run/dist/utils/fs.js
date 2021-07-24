"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.isDir = void 0;
const utils_fs_1 = require("@ionic/utils-fs");
async function isDir(p) {
    const stats = await utils_fs_1.statSafe(p);
    if (stats === null || stats === void 0 ? void 0 : stats.isDirectory()) {
        return true;
    }
    return false;
}
exports.isDir = isDir;
