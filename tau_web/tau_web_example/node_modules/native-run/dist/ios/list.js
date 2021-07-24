"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.list = exports.run = void 0;
const list_1 = require("../utils/list");
const device_1 = require("./utils/device");
const simulator_1 = require("./utils/simulator");
async function run(args) {
    const targets = await list(args);
    process.stdout.write(`\n${list_1.formatTargets(args, targets)}\n`);
}
exports.run = run;
async function list(args) {
    const errors = [];
    const [devices, virtualDevices] = await Promise.all([
        (async () => {
            try {
                const devices = await device_1.getConnectedDevices();
                return devices.map(deviceToTarget);
            }
            catch (e) {
                errors.push(e);
                return [];
            }
        })(),
        (async () => {
            try {
                const simulators = await simulator_1.getSimulators();
                return simulators.map(simulatorToTarget);
            }
            catch (e) {
                errors.push(e);
                return [];
            }
        })(),
    ]);
    return { devices, virtualDevices, errors };
}
exports.list = list;
function deviceToTarget(device) {
    return {
        platform: 'ios',
        name: device.DeviceName,
        model: device.ProductType,
        sdkVersion: device.ProductVersion,
        id: device.UniqueDeviceID,
    };
}
function simulatorToTarget(simulator) {
    return {
        platform: 'ios',
        name: simulator.name,
        sdkVersion: simulator.runtime.version,
        id: simulator.udid,
    };
}
