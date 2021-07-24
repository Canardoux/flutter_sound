"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.sync = exports.syncCommand = void 0;
const common_1 = require("../common");
const errors_1 = require("../errors");
const log_1 = require("../log");
const promise_1 = require("../util/promise");
const copy_1 = require("./copy");
const update_1 = require("./update");
/**
 * Sync is a copy and an update in one.
 */
async function syncCommand(config, selectedPlatformName, deployment) {
    var _a, _b;
    if (selectedPlatformName && !(await common_1.isValidPlatform(selectedPlatformName))) {
        try {
            await copy_1.copyCommand(config, selectedPlatformName);
        }
        catch (e) {
            log_1.logger.error((_a = e.stack) !== null && _a !== void 0 ? _a : e);
        }
        await update_1.updateCommand(config, selectedPlatformName, deployment);
    }
    else {
        const then = +new Date();
        const platforms = await common_1.selectPlatforms(config, selectedPlatformName);
        try {
            await common_1.check([
                () => common_1.checkPackage(),
                () => common_1.checkWebDir(config),
                ...update_1.updateChecks(config, platforms),
            ]);
            await promise_1.allSerial(platforms.map(platformName => () => sync(config, platformName, deployment)));
            const now = +new Date();
            const diff = (now - then) / 1000;
            log_1.logger.info(`Sync finished in ${diff}s`);
        }
        catch (e) {
            if (!errors_1.isFatal(e)) {
                errors_1.fatal((_b = e.stack) !== null && _b !== void 0 ? _b : e);
            }
            throw e;
        }
    }
}
exports.syncCommand = syncCommand;
async function sync(config, platformName, deployment) {
    var _a;
    await common_1.runPlatformHook(config, platformName, config.app.rootDir, 'capacitor:sync:before');
    try {
        await copy_1.copy(config, platformName);
    }
    catch (e) {
        log_1.logger.error((_a = e.stack) !== null && _a !== void 0 ? _a : e);
    }
    await update_1.update(config, platformName, deployment);
    await common_1.runPlatformHook(config, platformName, config.app.rootDir, 'capacitor:sync:after');
}
exports.sync = sync;
