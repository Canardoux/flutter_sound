"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.runAndroid = void 0;
const tslib_1 = require("tslib");
const debug_1 = tslib_1.__importDefault(require("debug"));
const path_1 = require("path");
const colors_1 = tslib_1.__importDefault(require("../colors"));
const common_1 = require("../common");
const native_run_1 = require("../util/native-run");
const subprocess_1 = require("../util/subprocess");
const debug = debug_1.default('capacitor:android:run');
async function runAndroid(config, { target: selectedTarget }) {
    const target = await common_1.promptForPlatformTarget(await native_run_1.getPlatformTargets('android'), selectedTarget);
    const gradleArgs = ['assembleDebug'];
    debug('Invoking ./gradlew with args: %O', gradleArgs);
    await common_1.runTask('Running Gradle build', async () => subprocess_1.runCommand('./gradlew', gradleArgs, {
        cwd: config.android.platformDirAbs,
    }));
    const apkPath = path_1.resolve(config.android.buildOutputDirAbs, config.android.apkName);
    const nativeRunArgs = ['android', '--app', apkPath, '--target', target.id];
    debug('Invoking native-run with args: %O', nativeRunArgs);
    await common_1.runTask(`Deploying ${colors_1.default.strong(config.android.apkName)} to ${colors_1.default.input(target.id)}`, async () => native_run_1.runNativeRun(nativeRunArgs));
}
exports.runAndroid = runAndroid;
