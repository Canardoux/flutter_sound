"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getVersionFromPackageXml = exports.getNameFromPackageXml = exports.getPathFromPackageXml = exports.readPackageXml = exports.getAPILevelFromPackageXml = void 0;
const utils_fs_1 = require("@ionic/utils-fs");
const errors_1 = require("../../../errors");
function getAPILevelFromPackageXml(packageXml) {
    var _a;
    const apiLevel = packageXml.find('./localPackage/type-details/api-level');
    return (_a = apiLevel === null || apiLevel === void 0 ? void 0 : apiLevel.text) === null || _a === void 0 ? void 0 : _a.toString();
}
exports.getAPILevelFromPackageXml = getAPILevelFromPackageXml;
async function readPackageXml(path) {
    const et = await Promise.resolve().then(() => require('elementtree'));
    const contents = await utils_fs_1.readFile(path, { encoding: 'utf8' });
    const etree = et.parse(contents);
    return etree;
}
exports.readPackageXml = readPackageXml;
function getPathFromPackageXml(packageXml) {
    const localPackage = packageXml.find('./localPackage');
    if (!localPackage) {
        throw new errors_1.SDKException(`Invalid SDK package.`, errors_1.ERR_INVALID_SDK_PACKAGE);
    }
    const path = localPackage.get('path');
    if (!path) {
        throw new errors_1.SDKException(`Invalid SDK package path.`, errors_1.ERR_INVALID_SDK_PACKAGE);
    }
    return path.toString();
}
exports.getPathFromPackageXml = getPathFromPackageXml;
function getNameFromPackageXml(packageXml) {
    const name = packageXml.find('./localPackage/display-name');
    if (!name || !name.text) {
        throw new errors_1.SDKException(`Invalid SDK package name.`, errors_1.ERR_INVALID_SDK_PACKAGE);
    }
    return name.text.toString();
}
exports.getNameFromPackageXml = getNameFromPackageXml;
function getVersionFromPackageXml(packageXml) {
    const versionElements = [
        packageXml.find('./localPackage/revision/major'),
        packageXml.find('./localPackage/revision/minor'),
        packageXml.find('./localPackage/revision/micro'),
    ];
    const textFromElement = (e) => (e === null || e === void 0 ? void 0 : e.text) ? e.text.toString() : '';
    const versions = [];
    for (const version of versionElements.map(textFromElement)) {
        if (!version) {
            break;
        }
        versions.push(version);
    }
    if (versions.length === 0) {
        throw new errors_1.SDKException(`Invalid SDK package version.`, errors_1.ERR_INVALID_SDK_PACKAGE);
    }
    return versions.join('.');
}
exports.getVersionFromPackageXml = getVersionFromPackageXml;
