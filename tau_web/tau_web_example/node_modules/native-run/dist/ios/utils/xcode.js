"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getDeveloperDiskImagePath = exports.getXCodePath = exports.getXcodeVersionInfo = void 0;
const utils_fs_1 = require("@ionic/utils-fs");
const child_process_1 = require("child_process");
const errors_1 = require("../../errors");
const process_1 = require("../../utils/process");
function getXcodeVersionInfo() {
    const xcodeVersionInfo = child_process_1.spawnSync('xcodebuild', ['-version'], {
        encoding: 'utf8',
    });
    if (xcodeVersionInfo.error) {
        throw xcodeVersionInfo.error;
    }
    try {
        const trimmed = xcodeVersionInfo.stdout.trim().split('\n');
        return ['Xcode ', 'Build version'].map((s, i) => trimmed[i].replace(s, ''));
    }
    catch (error) {
        throw new errors_1.Exception(`There was an error trying to retrieve the Xcode version: ${xcodeVersionInfo.stderr}`);
    }
}
exports.getXcodeVersionInfo = getXcodeVersionInfo;
async function getXCodePath() {
    try {
        const { stdout } = await process_1.execFile('xcode-select', ['-p'], {
            encoding: 'utf8',
        });
        if (stdout) {
            return stdout.trim();
        }
    }
    catch {
        // ignore
    }
    throw new errors_1.Exception('Unable to get Xcode location. Is Xcode installed?');
}
exports.getXCodePath = getXCodePath;
async function getDeveloperDiskImagePath(version) {
    const xCodePath = await getXCodePath();
    const versionDirs = await utils_fs_1.readdir(`${xCodePath}/Platforms/iPhoneOS.platform/DeviceSupport/`);
    const versionPrefix = version.match(/\d+\.\d+/);
    if (versionPrefix === null) {
        throw new errors_1.Exception(`Invalid iOS version: ${version}`);
    }
    // Can look like "11.2 (15C107)"
    for (const dir of versionDirs) {
        if (dir.includes(versionPrefix[0])) {
            return `${xCodePath}/Platforms/iPhoneOS.platform/DeviceSupport/${dir}/DeveloperDiskImage.dmg`;
        }
    }
    throw new errors_1.Exception(`Unable to find Developer Disk Image path for SDK ${version}. Do you have the right version of Xcode?`);
}
exports.getDeveloperDiskImagePath = getDeveloperDiskImagePath;
