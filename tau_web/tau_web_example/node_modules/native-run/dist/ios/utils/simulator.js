"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.runOnSimulator = exports.getSimulators = void 0;
const child_process_1 = require("child_process"); // TODO: need cross-spawn for windows?
const Debug = require("debug");
const errors_1 = require("../../errors");
const log_1 = require("../../utils/log");
const process_1 = require("../../utils/process");
const xcode_1 = require("./xcode");
const debug = Debug('native-run:ios:utils:simulator');
async function getSimulators() {
    const simctl = child_process_1.spawnSync('xcrun', ['simctl', 'list', '--json'], {
        encoding: 'utf8',
    });
    if (simctl.status) {
        throw new errors_1.Exception(`Unable to retrieve simulator list: ${simctl.stderr}`);
    }
    const [xcodeVersion] = xcode_1.getXcodeVersionInfo();
    if (Number(xcodeVersion) < 10) {
        throw new errors_1.Exception('native-run only supports Xcode 10 and later');
    }
    try {
        const output = JSON.parse(simctl.stdout);
        return output.runtimes
            .filter(runtime => runtime.name.indexOf('watch') === -1 &&
            runtime.name.indexOf('tv') === -1)
            .map(runtime => (output.devices[runtime.identifier] || output.devices[runtime.name])
            .filter(device => device.isAvailable)
            .map(device => ({ ...device, runtime })))
            .reduce((prev, next) => prev.concat(next)) // flatten
            .sort((a, b) => (a.name < b.name ? -1 : 1));
    }
    catch (err) {
        throw new errors_1.Exception(`Unable to retrieve simulator list: ${err.message}`);
    }
}
exports.getSimulators = getSimulators;
async function runOnSimulator(udid, appPath, bundleId, waitForApp) {
    debug(`Booting simulator ${udid}`);
    const bootResult = child_process_1.spawnSync('xcrun', ['simctl', 'boot', udid], {
        encoding: 'utf8',
    });
    // TODO: is there a better way to check this?
    if (bootResult.status &&
        !bootResult.stderr.includes('Unable to boot device in current state: Booted')) {
        throw new errors_1.Exception(`There was an error booting simulator: ${bootResult.stderr}`);
    }
    debug(`Installing ${appPath} on ${udid}`);
    const installResult = child_process_1.spawnSync('xcrun', ['simctl', 'install', udid, appPath], { encoding: 'utf8' });
    if (installResult.status) {
        throw new errors_1.Exception(`There was an error installing app on simulator: ${installResult.stderr}`);
    }
    const xCodePath = await xcode_1.getXCodePath();
    debug(`Running simulator ${udid}`);
    const openResult = child_process_1.spawnSync('open', [
        `${xCodePath}/Applications/Simulator.app`,
        '--args',
        '-CurrentDeviceUDID',
        udid,
    ], { encoding: 'utf8' });
    if (openResult.status) {
        throw new errors_1.Exception(`There was an error opening simulator: ${openResult.stderr}`);
    }
    debug(`Launching ${appPath} on ${udid}`);
    const launchResult = child_process_1.spawnSync('xcrun', ['simctl', 'launch', udid, bundleId], { encoding: 'utf8' });
    if (launchResult.status) {
        throw new errors_1.Exception(`There was an error launching app on simulator: ${launchResult.stderr}`);
    }
    if (waitForApp) {
        process_1.onBeforeExit(async () => {
            const terminateResult = child_process_1.spawnSync('xcrun', ['simctl', 'terminate', udid, bundleId], { encoding: 'utf8' });
            if (terminateResult.status) {
                debug('Unable to terminate app on simulator');
            }
        });
        log_1.log(`Waiting for app to close...\n`);
        await waitForSimulatorClose(udid, bundleId);
    }
}
exports.runOnSimulator = runOnSimulator;
async function waitForSimulatorClose(udid, bundleId) {
    return new Promise(resolve => {
        // poll service list for bundle id
        const interval = setInterval(async () => {
            try {
                const data = child_process_1.spawnSync('xcrun', ['simctl', 'spawn', udid, 'launchctl', 'list'], { encoding: 'utf8' });
                // if bundle id isn't in list, app isn't running
                if (data.stdout.indexOf(bundleId) === -1) {
                    clearInterval(interval);
                    resolve();
                }
            }
            catch (e) {
                debug('Error received from launchctl: %O', e);
                debug('App %s no longer found in process list for %s', bundleId, udid);
                clearInterval(interval);
                resolve();
            }
        }, 500);
    });
}
