"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.list = exports.run = void 0;
const list_1 = require("../utils/list");
const list_2 = require("./utils/list");
const sdk_1 = require("./utils/sdk");
async function run(args) {
    const targets = await list(args);
    process.stdout.write(`\n${list_1.formatTargets(args, targets)}\n`);
}
exports.run = run;
async function list(args) {
    const sdk = await sdk_1.getSDK();
    const errors = [];
    const [devices, virtualDevices] = await Promise.all([
        (async () => {
            try {
                return await list_2.getDeviceTargets(sdk);
            }
            catch (e) {
                errors.push(e);
                return [];
            }
        })(),
        (async () => {
            try {
                return await list_2.getVirtualTargets(sdk);
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
