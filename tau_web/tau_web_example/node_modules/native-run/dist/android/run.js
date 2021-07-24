"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.selectDevice = exports.run = void 0;
const Debug = require("debug");
const errors_1 = require("../errors");
const cli_1 = require("../utils/cli");
const log_1 = require("../utils/log");
const process_1 = require("../utils/process");
const adb_1 = require("./utils/adb");
const apk_1 = require("./utils/apk");
const avd_1 = require("./utils/avd");
const run_1 = require("./utils/run");
const sdk_1 = require("./utils/sdk");
const modulePrefix = 'native-run:android:run';
async function run(args) {
    const sdk = await sdk_1.getSDK();
    const apkPath = cli_1.getOptionValue(args, '--app');
    const forwardedPorts = cli_1.getOptionValues(args, '--forward');
    const ports = [];
    if (forwardedPorts && forwardedPorts.length > 0) {
        forwardedPorts.forEach((port) => {
            const [device, host] = port.split(':');
            if (!device || !host) {
                throw new errors_1.CLIException(`Invalid --forward value "${port}": expecting <device port:host port>, e.g. 8080:8080`);
            }
            ports.push({ device, host });
        });
    }
    if (!apkPath) {
        throw new errors_1.CLIException('--app is required', errors_1.ERR_BAD_INPUT);
    }
    const device = await selectDevice(sdk, args);
    log_1.log(`Selected ${device.type === 'hardware' ? 'hardware device' : 'emulator'} ${device.serial}\n`);
    const { appId, activityName } = await apk_1.getApkInfo(apkPath);
    await adb_1.waitForBoot(sdk, device);
    if (ports) {
        await Promise.all(ports.map(async (port) => {
            await adb_1.forwardPorts(sdk, device, port);
            log_1.log(`Forwarded device port ${port.device} to host port ${port.host}\n`);
        }));
    }
    await run_1.installApkToDevice(sdk, device, apkPath, appId);
    log_1.log(`Starting application activity ${appId}/${activityName}...\n`);
    await adb_1.startActivity(sdk, device, appId, activityName);
    log_1.log(`Run Successful\n`);
    process_1.onBeforeExit(async () => {
        if (ports) {
            await Promise.all(ports.map(async (port) => {
                await adb_1.unforwardPorts(sdk, device, port);
            }));
        }
    });
    if (args.includes('--connect')) {
        process_1.onBeforeExit(async () => {
            await adb_1.closeApp(sdk, device, appId);
        });
        log_1.log(`Waiting for app to close...\n`);
        await adb_1.waitForClose(sdk, device, appId);
    }
}
exports.run = run;
async function selectDevice(sdk, args) {
    const debug = Debug(`${modulePrefix}:${selectDevice.name}`);
    const devices = await adb_1.getDevices(sdk);
    const avds = await avd_1.getInstalledAVDs(sdk);
    const target = cli_1.getOptionValue(args, '--target');
    const preferEmulator = args.includes('--virtual');
    if (target) {
        const targetDevice = await run_1.selectDeviceByTarget(sdk, devices, avds, target);
        if (targetDevice) {
            return targetDevice;
        }
        else {
            throw new errors_1.AndroidRunException(`Target not found: ${target}`, errors_1.ERR_TARGET_NOT_FOUND);
        }
    }
    if (!preferEmulator) {
        const selectedDevice = await run_1.selectHardwareDevice(devices);
        if (selectedDevice) {
            return selectedDevice;
        }
        else if (args.includes('--device')) {
            throw new errors_1.AndroidRunException(`No hardware devices found. Not attempting emulator because --device was specified.`, errors_1.ERR_NO_DEVICE);
        }
        else {
            log_1.log('No hardware devices found, attempting emulator...\n');
        }
    }
    try {
        return await run_1.selectVirtualDevice(sdk, devices, avds);
    }
    catch (e) {
        if (!(e instanceof errors_1.AVDException)) {
            throw e;
        }
        debug('Issue with AVDs: %s', e.message);
        if (e.code === errors_1.ERR_UNSUITABLE_API_INSTALLATION) {
            throw new errors_1.AndroidRunException('No targets devices/emulators available. Cannot create AVD because there is no suitable API installation. Use --sdk-info to reveal missing packages and other issues.', errors_1.ERR_NO_TARGET);
        }
    }
    throw new errors_1.AndroidRunException('No target devices/emulators available.', errors_1.ERR_NO_TARGET);
}
exports.selectDevice = selectDevice;
