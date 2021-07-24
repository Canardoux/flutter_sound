"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.installApkToDevice = exports.selectVirtualDevice = exports.selectHardwareDevice = exports.selectDeviceByTarget = void 0;
const Debug = require("debug");
const errors_1 = require("../../errors");
const log_1 = require("../../utils/log");
const adb_1 = require("./adb");
const avd_1 = require("./avd");
const emulator_1 = require("./emulator");
const modulePrefix = 'native-run:android:utils:run';
async function selectDeviceByTarget(sdk, devices, avds, target) {
    const debug = Debug(`${modulePrefix}:${selectDeviceByTarget.name}`);
    debug('--target %s detected', target);
    debug('Checking if device can be found by serial: %s', target);
    const device = devices.find(d => d.serial === target);
    if (device) {
        debug('Device found by serial: %s', device.serial);
        return device;
    }
    const emulatorDevices = devices.filter(d => d.type === 'emulator');
    const pairAVD = async (emulator) => {
        let avd;
        try {
            avd = await emulator_1.getAVDFromEmulator(emulator, avds);
            debug('Emulator %s is using AVD: %s', emulator.serial, avd.id);
        }
        catch (e) {
            debug('Error with emulator %s: %O', emulator.serial, e);
        }
        return [emulator, avd];
    };
    debug('Checking if any of %d running emulators are using AVD by ID: %s', emulatorDevices.length, target);
    const emulatorsAndAVDs = await Promise.all(emulatorDevices.map(emulator => pairAVD(emulator)));
    const emulators = emulatorsAndAVDs.filter((t) => typeof t[1] !== 'undefined');
    const emulator = emulators.find(([, avd]) => avd.id === target);
    if (emulator) {
        const [device, avd] = emulator;
        debug('Emulator %s found by AVD: %s', device.serial, avd.id);
        return device;
    }
    debug('Checking if AVD can be found by ID: %s', target);
    const avd = avds.find(avd => avd.id === target);
    if (avd) {
        debug('AVD found by ID: %s', avd.id);
        const device = await emulator_1.runEmulator(sdk, avd, 5554); // TODO: 5554 will not always be available at this point
        debug('Emulator ready, running avd: %s on %s', avd.id, device.serial);
        return device;
    }
}
exports.selectDeviceByTarget = selectDeviceByTarget;
async function selectHardwareDevice(devices) {
    const hardwareDevices = devices.filter(d => d.type === 'hardware');
    // If a hardware device is found, we prefer launching to it instead of in an emulator.
    if (hardwareDevices.length > 0) {
        return hardwareDevices[0]; // TODO: can probably do better analysis on which to use?
    }
}
exports.selectHardwareDevice = selectHardwareDevice;
async function selectVirtualDevice(sdk, devices, avds) {
    const debug = Debug(`${modulePrefix}:${selectVirtualDevice.name}`);
    const emulators = devices.filter(d => d.type === 'emulator');
    // If an emulator is running, use it.
    if (emulators.length > 0) {
        const [emulator] = emulators;
        debug('Found running emulator: %s', emulator.serial);
        return emulator;
    }
    // Spin up an emulator using the AVD we ship with.
    const defaultAvd = await avd_1.getDefaultAVD(sdk, avds);
    const device = await emulator_1.runEmulator(sdk, defaultAvd, 5554); // TODO: will 5554 always be available at this point?
    debug('Emulator ready, running avd: %s on %s', defaultAvd.id, device.serial);
    return device;
}
exports.selectVirtualDevice = selectVirtualDevice;
async function installApkToDevice(sdk, device, apk, appId) {
    log_1.log(`Installing ${apk}...\n`);
    try {
        await adb_1.installApk(sdk, device, apk);
    }
    catch (e) {
        if (e instanceof errors_1.ADBException) {
            if (e.code === errors_1.ERR_INCOMPATIBLE_UPDATE ||
                e.code === errors_1.ERR_VERSION_DOWNGRADE) {
                log_1.log(`${e.message} Uninstalling and trying again...\n`);
                await adb_1.uninstallApp(sdk, device, appId);
                await adb_1.installApk(sdk, device, apk);
                return;
            }
        }
        throw e;
    }
}
exports.installApkToDevice = installApkToDevice;
