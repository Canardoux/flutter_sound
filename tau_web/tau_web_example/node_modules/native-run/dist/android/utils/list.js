"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.avdToTarget = exports.deviceToTarget = exports.getVirtualTargets = exports.getDeviceTargets = void 0;
const adb_1 = require("./adb");
const avd_1 = require("./avd");
async function getDeviceTargets(sdk) {
    return (await adb_1.getDevices(sdk))
        .filter(device => device.type === 'hardware')
        .map(deviceToTarget);
}
exports.getDeviceTargets = getDeviceTargets;
async function getVirtualTargets(sdk) {
    const avds = await avd_1.getInstalledAVDs(sdk);
    const defaultAvd = await avd_1.getDefaultAVD(sdk, avds);
    if (!avds.includes(defaultAvd)) {
        avds.push(defaultAvd);
    }
    return avds.map(avdToTarget);
}
exports.getVirtualTargets = getVirtualTargets;
function deviceToTarget(device) {
    return {
        platform: 'android',
        model: `${device.manufacturer} ${device.model}`,
        sdkVersion: device.sdkVersion,
        id: device.serial,
    };
}
exports.deviceToTarget = deviceToTarget;
function avdToTarget(avd) {
    return {
        platform: 'android',
        name: avd.name,
        sdkVersion: avd.sdkVersion,
        id: avd.id,
    };
}
exports.avdToTarget = avdToTarget;
