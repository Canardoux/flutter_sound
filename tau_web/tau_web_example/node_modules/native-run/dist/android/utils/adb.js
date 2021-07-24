"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.execAdb = exports.unforwardPorts = exports.forwardPorts = exports.parseAdbDevices = exports.startActivity = exports.parseAdbInstallOutput = exports.ADBEvent = exports.uninstallApp = exports.closeApp = exports.installApk = exports.waitForClose = exports.waitForBoot = exports.waitForDevice = exports.getDeviceProperties = exports.getDeviceProperty = exports.getDevices = void 0;
const child_process_1 = require("child_process");
const Debug = require("debug");
const os = require("os");
const path = require("path");
const split2 = require("split2");
const through2 = require("through2");
const errors_1 = require("../../errors");
const process_1 = require("../../utils/process");
const sdk_1 = require("./sdk");
const modulePrefix = 'native-run:android:utils:adb';
const ADB_GETPROP_MAP = new Map([
    ['ro.product.manufacturer', 'manufacturer'],
    ['ro.product.model', 'model'],
    ['ro.product.name', 'product'],
    ['ro.build.version.sdk', 'sdkVersion'],
]);
async function getDevices(sdk) {
    const debug = Debug(`${modulePrefix}:${getDevices.name}`);
    const args = ['devices', '-l'];
    debug('Invoking adb with args: %O', args);
    const stdout = await execAdb(sdk, args, { timeout: 5000 });
    const devices = parseAdbDevices(stdout);
    await Promise.all(devices.map(async (device) => {
        const properties = await getDeviceProperties(sdk, device);
        for (const [prop, deviceProp] of ADB_GETPROP_MAP.entries()) {
            const value = properties[prop];
            if (value) {
                device[deviceProp] = value;
            }
        }
    }));
    debug('Found adb devices: %O', devices);
    return devices;
}
exports.getDevices = getDevices;
async function getDeviceProperty(sdk, device, property) {
    const debug = Debug(`${modulePrefix}:${getDeviceProperty.name}`);
    const args = ['-s', device.serial, 'shell', 'getprop', property];
    debug('Invoking adb with args: %O', args);
    const stdout = await execAdb(sdk, args, { timeout: 5000 });
    return stdout.trim();
}
exports.getDeviceProperty = getDeviceProperty;
async function getDeviceProperties(sdk, device) {
    const debug = Debug(`${modulePrefix}:${getDeviceProperties.name}`);
    const args = ['-s', device.serial, 'shell', 'getprop'];
    debug('Invoking adb with args: %O', args);
    const stdout = await execAdb(sdk, args, { timeout: 5000 });
    const re = /^\[([a-z0-9.]+)\]: \[(.*)\]$/;
    const propAllowList = [...ADB_GETPROP_MAP.keys()];
    const properties = {};
    for (const line of stdout.split(os.EOL)) {
        const m = line.match(re);
        if (m) {
            const [, key, value] = m;
            if (propAllowList.includes(key)) {
                properties[key] = value;
            }
        }
    }
    return properties;
}
exports.getDeviceProperties = getDeviceProperties;
async function waitForDevice(sdk, serial) {
    const debug = Debug(`${modulePrefix}:${waitForDevice.name}`);
    const args = ['-s', serial, 'wait-for-any-device'];
    debug('Invoking adb with args: %O', args);
    await execAdb(sdk, args);
    debug('Device %s is connected to ADB!', serial);
}
exports.waitForDevice = waitForDevice;
async function waitForBoot(sdk, device) {
    const debug = Debug(`${modulePrefix}:${waitForBoot.name}`);
    return new Promise(resolve => {
        const interval = setInterval(async () => {
            const booted = await getDeviceProperty(sdk, device, 'dev.bootcomplete');
            if (booted) {
                debug('Device %s is booted!', device.serial);
                clearInterval(interval);
                resolve();
            }
        }, 100);
    });
}
exports.waitForBoot = waitForBoot;
async function waitForClose(sdk, device, app) {
    const debug = Debug(`${modulePrefix}:${waitForClose.name}`);
    const args = ['-s', device.serial, 'shell', `ps | grep ${app}`];
    return new Promise(resolve => {
        const interval = setInterval(async () => {
            try {
                debug('Invoking adb with args: %O', args);
                await execAdb(sdk, args);
            }
            catch (e) {
                debug('Error received from adb: %O', e);
                debug('App %s no longer found in process list for %s', app, device.serial);
                clearInterval(interval);
                resolve();
            }
        }, 500);
    });
}
exports.waitForClose = waitForClose;
async function installApk(sdk, device, apk) {
    const debug = Debug(`${modulePrefix}:${installApk.name}`);
    const platformTools = await sdk_1.getSDKPackage(path.join(sdk.root, 'platform-tools'));
    const adbBin = path.join(platformTools.location, 'adb');
    const args = ['-s', device.serial, 'install', '-r', '-t', apk];
    debug('Invoking adb with args: %O', args);
    const p = child_process_1.spawn(adbBin, args, {
        stdio: 'pipe',
        env: sdk_1.supplementProcessEnv(sdk),
    });
    return new Promise((resolve, reject) => {
        p.on('close', code => {
            if (code === 0) {
                resolve();
            }
            else {
                reject(new errors_1.ADBException(`Non-zero exit code from adb: ${code}`));
            }
        });
        p.on('error', err => {
            debug('adb install error: %O', err);
            reject(err);
        });
        p.stderr.pipe(split2()).pipe(through2((chunk, enc, cb) => {
            const line = chunk.toString();
            debug('adb install: %O', line);
            const event = parseAdbInstallOutput(line);
            if (event === ADBEvent.IncompatibleUpdateFailure) {
                reject(new errors_1.ADBException(`Encountered adb error: ${ADBEvent[event]}.`, errors_1.ERR_INCOMPATIBLE_UPDATE));
            }
            else if (event === ADBEvent.NewerVersionOnDeviceFailure) {
                reject(new errors_1.ADBException(`Encountered adb error: ${ADBEvent[event]}.`, errors_1.ERR_VERSION_DOWNGRADE));
            }
            else if (event === ADBEvent.NewerSdkRequiredOnDeviceFailure) {
                reject(new errors_1.ADBException(`Encountered adb error: ${ADBEvent[event]}.`, errors_1.ERR_MIN_SDK_VERSION));
            }
            else if (event === ADBEvent.NoCertificates) {
                reject(new errors_1.ADBException(`Encountered adb error: ${ADBEvent[event]}.`, errors_1.ERR_NO_CERTIFICATES));
            }
            else if (event === ADBEvent.NotEnoughSpace) {
                reject(new errors_1.ADBException(`Encountered adb error: ${ADBEvent[event]}.`, errors_1.ERR_NOT_ENOUGH_SPACE));
            }
            else if (event === ADBEvent.DeviceOffline) {
                reject(new errors_1.ADBException(`Encountered adb error: ${ADBEvent[event]}.`, errors_1.ERR_DEVICE_OFFLINE));
            }
            cb();
        }));
    });
}
exports.installApk = installApk;
async function closeApp(sdk, device, app) {
    const debug = Debug(`${modulePrefix}:${closeApp.name}`);
    const args = ['-s', device.serial, 'shell', 'am', 'force-stop', app];
    debug('Invoking adb with args: %O', args);
    await execAdb(sdk, args);
}
exports.closeApp = closeApp;
async function uninstallApp(sdk, device, app) {
    const debug = Debug(`${modulePrefix}:${uninstallApp.name}`);
    const args = ['-s', device.serial, 'uninstall', app];
    debug('Invoking adb with args: %O', args);
    await execAdb(sdk, args);
}
exports.uninstallApp = uninstallApp;
var ADBEvent;
(function (ADBEvent) {
    ADBEvent[ADBEvent["IncompatibleUpdateFailure"] = 0] = "IncompatibleUpdateFailure";
    ADBEvent[ADBEvent["NewerVersionOnDeviceFailure"] = 1] = "NewerVersionOnDeviceFailure";
    ADBEvent[ADBEvent["NewerSdkRequiredOnDeviceFailure"] = 2] = "NewerSdkRequiredOnDeviceFailure";
    ADBEvent[ADBEvent["NoCertificates"] = 3] = "NoCertificates";
    ADBEvent[ADBEvent["NotEnoughSpace"] = 4] = "NotEnoughSpace";
    ADBEvent[ADBEvent["DeviceOffline"] = 5] = "DeviceOffline";
})(ADBEvent = exports.ADBEvent || (exports.ADBEvent = {}));
function parseAdbInstallOutput(line) {
    const debug = Debug(`${modulePrefix}:${parseAdbInstallOutput.name}`);
    let event;
    if (line.includes('INSTALL_FAILED_UPDATE_INCOMPATIBLE')) {
        event = ADBEvent.IncompatibleUpdateFailure;
    }
    else if (line.includes('INSTALL_FAILED_VERSION_DOWNGRADE')) {
        event = ADBEvent.NewerVersionOnDeviceFailure;
    }
    else if (line.includes('INSTALL_FAILED_OLDER_SDK')) {
        event = ADBEvent.NewerSdkRequiredOnDeviceFailure;
    }
    else if (line.includes('INSTALL_PARSE_FAILED_NO_CERTIFICATES')) {
        event = ADBEvent.NoCertificates;
    }
    else if (line.includes('INSTALL_FAILED_INSUFFICIENT_STORAGE') ||
        line.includes('not enough space')) {
        event = ADBEvent.NotEnoughSpace;
    }
    else if (line.includes('device offline')) {
        event = ADBEvent.DeviceOffline;
    }
    if (typeof event !== 'undefined') {
        debug('Parsed event from adb install output: %s', ADBEvent[event]);
    }
    return event;
}
exports.parseAdbInstallOutput = parseAdbInstallOutput;
async function startActivity(sdk, device, packageName, activityName) {
    const debug = Debug(`${modulePrefix}:${startActivity.name}`);
    const args = [
        '-s',
        device.serial,
        'shell',
        'am',
        'start',
        '-W',
        '-n',
        `${packageName}/${activityName}`,
    ];
    debug('Invoking adb with args: %O', args);
    await execAdb(sdk, args, { timeout: 5000 });
}
exports.startActivity = startActivity;
function parseAdbDevices(output) {
    const debug = Debug(`${modulePrefix}:${parseAdbDevices.name}`);
    const re = /^([\S]+)\s+([a-z\s]+)\s+(.*)$/;
    const ipRe = /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}:\d+$/;
    const lines = output.split(os.EOL);
    debug('Parsing adb devices from output lines: %O', lines);
    const devices = [];
    for (const line of lines) {
        if (line && !line.startsWith('List')) {
            const m = line.match(re);
            if (m) {
                const [, serial, state, description] = m;
                const properties = description
                    .split(/\s+/)
                    .map(prop => (prop.includes(':') ? prop.split(':') : undefined))
                    .filter((kv) => typeof kv !== 'undefined' && kv.length >= 2)
                    .reduce((acc, [k, v]) => {
                    if (k && v) {
                        acc[k.trim()] = v.trim();
                    }
                    return acc;
                }, {});
                const isIP = !!serial.match(ipRe);
                const isGenericDevice = (properties['device'] || '').startsWith('generic');
                const type = 'usb' in properties ||
                    isIP ||
                    !serial.startsWith('emulator') ||
                    !isGenericDevice
                    ? 'hardware'
                    : 'emulator';
                const connection = 'usb' in properties ? 'usb' : isIP ? 'tcpip' : null;
                devices.push({
                    serial,
                    state,
                    type,
                    connection,
                    properties,
                    // We might not know these yet
                    manufacturer: '',
                    model: properties['model'] || '',
                    product: properties['product'] || '',
                    sdkVersion: '',
                });
            }
            else {
                debug('adb devices output line does not match expected regex: %O', line);
            }
        }
    }
    return devices;
}
exports.parseAdbDevices = parseAdbDevices;
async function forwardPorts(sdk, device, ports) {
    const debug = Debug(`${modulePrefix}:${forwardPorts.name}`);
    const args = [
        '-s',
        device.serial,
        'reverse',
        `tcp:${ports.device}`,
        `tcp:${ports.host}`,
    ];
    debug('Invoking adb with args: %O', args);
    await execAdb(sdk, args, { timeout: 5000 });
}
exports.forwardPorts = forwardPorts;
async function unforwardPorts(sdk, device, ports) {
    const debug = Debug(`${modulePrefix}:${unforwardPorts.name}`);
    const args = [
        '-s',
        device.serial,
        'reverse',
        '--remove',
        `tcp:${ports.device}`,
    ];
    debug('Invoking adb with args: %O', args);
    await execAdb(sdk, args, { timeout: 5000 });
}
exports.unforwardPorts = unforwardPorts;
async function execAdb(sdk, args, options = {}) {
    const debug = Debug(`${modulePrefix}:${execAdb.name}`);
    let timer;
    const retry = async () => {
        const msg = `ADBs is unresponsive after ${options.timeout}ms, killing server and retrying...\n`;
        if (process.argv.includes('--json')) {
            debug(msg);
        }
        else {
            process.stderr.write(msg);
        }
        debug('ADB timeout of %O reached, killing server and retrying...', options.timeout);
        debug('Invoking adb with args: %O', ['kill-server']);
        await execAdb(sdk, ['kill-server']);
        debug('Invoking adb with args: %O', ['start-server']);
        await execAdb(sdk, ['start-server']);
        debug('Retrying...');
        return run();
    };
    const run = async () => {
        const platformTools = await sdk_1.getSDKPackage(path.join(sdk.root, 'platform-tools'));
        const adbBin = path.join(platformTools.location, 'adb');
        const { stdout } = await process_1.execFile(adbBin, args, {
            env: sdk_1.supplementProcessEnv(sdk),
        });
        if (timer) {
            clearTimeout(timer);
            timer = undefined;
        }
        return stdout;
    };
    return new Promise((resolve, reject) => {
        if (options.timeout) {
            timer = setTimeout(() => retry().then(resolve, reject), options.timeout);
        }
        run().then(resolve, err => {
            if (!timer) {
                reject(err);
            }
        });
    });
}
exports.execAdb = execAdb;
