"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.runIOS = void 0;
const tslib_1 = require("tslib");
const debug_1 = tslib_1.__importDefault(require("debug"));
const path_1 = require("path");
const colors_1 = tslib_1.__importDefault(require("../colors"));
const common_1 = require("../common");
const native_run_1 = require("../util/native-run");
const subprocess_1 = require("../util/subprocess");
const debug = debug_1.default('capacitor:ios:run');
async function runIOS(config, { target: selectedTarget }) {
    const target = await common_1.promptForPlatformTarget(await native_run_1.getPlatformTargets('ios'), selectedTarget);
    const derivedDataPath = path_1.resolve(config.ios.platformDirAbs, 'DerivedData', target.id);
    const xcodebuildArgs = [
        '-workspace',
        path_1.basename(await config.ios.nativeXcodeWorkspaceDirAbs),
        '-scheme',
        config.ios.scheme,
        '-configuration',
        'Debug',
        '-destination',
        `id=${target.id}`,
        '-derivedDataPath',
        derivedDataPath,
    ];
    debug('Invoking xcodebuild with args: %O', xcodebuildArgs);
    await common_1.runTask('Running xcodebuild', async () => subprocess_1.runCommand('xcrun', ['xcodebuild', ...xcodebuildArgs], {
        cwd: config.ios.nativeProjectDirAbs,
    }));
    const appName = `${config.ios.scheme}.app`;
    const appPath = path_1.resolve(derivedDataPath, 'Build/Products', target.virtual ? 'Debug-iphonesimulator' : 'Debug-iphoneos', appName);
    const nativeRunArgs = ['ios', '--app', appPath, '--target', target.id];
    debug('Invoking native-run with args: %O', nativeRunArgs);
    await common_1.runTask(`Deploying ${colors_1.default.strong(appName)} to ${colors_1.default.input(target.id)}`, async () => native_run_1.runNativeRun(nativeRunArgs));
}
exports.runIOS = runIOS;
