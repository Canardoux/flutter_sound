"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.run = exports.runCommand = void 0;
const tslib_1 = require("tslib");
const utils_terminal_1 = require("@ionic/utils-terminal");
const run_1 = require("../android/run");
const colors_1 = tslib_1.__importDefault(require("../colors"));
const common_1 = require("../common");
const errors_1 = require("../errors");
const run_2 = require("../ios/run");
const log_1 = require("../log");
const native_run_1 = require("../util/native-run");
const sync_1 = require("./sync");
async function runCommand(config, selectedPlatformName, options) {
    var _a;
    if (selectedPlatformName && !(await common_1.isValidPlatform(selectedPlatformName))) {
        const platformDir = common_1.resolvePlatform(config, selectedPlatformName);
        if (platformDir) {
            await common_1.runPlatformHook(config, selectedPlatformName, platformDir, 'capacitor:run');
        }
        else {
            log_1.logger.error(`Platform ${colors_1.default.input(selectedPlatformName)} not found.`);
        }
    }
    else {
        const platforms = await common_1.selectPlatforms(config, selectedPlatformName);
        let platformName;
        if (platforms.length === 1) {
            platformName = platforms[0];
        }
        else {
            platformName = await common_1.promptForPlatform(platforms.filter(createRunnablePlatformFilter(config)), `Please choose a platform to run:`);
        }
        if (options.list) {
            const targets = await native_run_1.getPlatformTargets(platformName);
            const outputTargets = targets.map(t => {
                var _a;
                return ({
                    name: common_1.getPlatformTargetName(t),
                    api: `${t.platform === 'ios' ? 'iOS' : 'API'} ${t.sdkVersion}`,
                    id: (_a = t.id) !== null && _a !== void 0 ? _a : '?',
                });
            });
            // TODO: make hidden commander option (https://github.com/tj/commander.js/issues/1106)
            if (process.argv.includes('--json')) {
                process.stdout.write(`${JSON.stringify(outputTargets)}\n`);
            }
            else {
                const rows = outputTargets.map(t => [t.name, t.api, t.id]);
                log_1.output.write(`${utils_terminal_1.columnar(rows, {
                    headers: ['Name', 'API', 'Target ID'],
                    vsep: ' ',
                })}\n`);
            }
            return;
        }
        try {
            if (options.sync) {
                await sync_1.sync(config, platformName, false);
            }
            await run(config, platformName, options);
        }
        catch (e) {
            if (!errors_1.isFatal(e)) {
                errors_1.fatal((_a = e.stack) !== null && _a !== void 0 ? _a : e);
            }
            throw e;
        }
    }
}
exports.runCommand = runCommand;
async function run(config, platformName, options) {
    if (platformName == config.ios.name) {
        await run_2.runIOS(config, options);
    }
    else if (platformName === config.android.name) {
        await run_1.runAndroid(config, options);
    }
    else if (platformName === config.web.name) {
        return;
    }
    else {
        throw `Platform ${platformName} is not valid.`;
    }
}
exports.run = run;
function createRunnablePlatformFilter(config) {
    return platform => platform === config.ios.name || platform === config.android.name;
}
