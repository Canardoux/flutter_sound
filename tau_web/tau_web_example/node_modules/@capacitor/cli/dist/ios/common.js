"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.shouldPodInstall = exports.editProjectSettingsIOS = exports.resolvePlugin = exports.getIOSPlugins = exports.checkCocoaPods = exports.checkIOSPackage = void 0;
const tslib_1 = require("tslib");
const utils_fs_1 = require("@ionic/utils-fs");
const path_1 = require("path");
const colors_1 = tslib_1.__importDefault(require("../colors"));
const common_1 = require("../common");
const cordova_1 = require("../cordova");
const plugin_1 = require("../plugin");
const subprocess_1 = require("../util/subprocess");
async function checkIOSPackage(config) {
    return common_1.checkCapacitorPlatform(config, 'ios');
}
exports.checkIOSPackage = checkIOSPackage;
async function checkCocoaPods(config) {
    if (!(await subprocess_1.isInstalled(config.ios.podPath)) && config.cli.os === "mac" /* Mac */) {
        return (`CocoaPods is not installed.\n` +
            `See this install guide: ${colors_1.default.strong('https://guides.cocoapods.org/using/getting-started.html#installation')}`);
    }
    return null;
}
exports.checkCocoaPods = checkCocoaPods;
async function getIOSPlugins(allPlugins) {
    const resolved = await Promise.all(allPlugins.map(async (plugin) => await resolvePlugin(plugin)));
    return resolved.filter((plugin) => !!plugin);
}
exports.getIOSPlugins = getIOSPlugins;
async function resolvePlugin(plugin) {
    var _a, _b;
    const platform = 'ios';
    if ((_a = plugin.manifest) === null || _a === void 0 ? void 0 : _a.ios) {
        plugin.ios = {
            name: plugin.name,
            type: 0 /* Core */,
            path: (_b = plugin.manifest.ios.src) !== null && _b !== void 0 ? _b : platform,
        };
    }
    else if (plugin.xml) {
        plugin.ios = {
            name: plugin.name,
            type: 1 /* Cordova */,
            path: 'src/' + platform,
        };
        if (cordova_1.getIncompatibleCordovaPlugins(platform).includes(plugin.id) ||
            !plugin_1.getPluginPlatform(plugin, platform)) {
            plugin.ios.type = 2 /* Incompatible */;
        }
    }
    else {
        return null;
    }
    return plugin;
}
exports.resolvePlugin = resolvePlugin;
/**
 * Update the native project files with the desired app id and app name
 */
async function editProjectSettingsIOS(config) {
    const appId = config.app.appId;
    const appName = config.app.appName;
    const pbxPath = `${config.ios.nativeXcodeProjDirAbs}/project.pbxproj`;
    const plistPath = path_1.resolve(config.ios.nativeTargetDirAbs, 'Info.plist');
    let plistContent = await utils_fs_1.readFile(plistPath, { encoding: 'utf-8' });
    plistContent = plistContent.replace(/<key>CFBundleDisplayName<\/key>[\s\S]?\s+<string>([^<]*)<\/string>/, `<key>CFBundleDisplayName</key>\n        <string>${appName}</string>`);
    let pbxContent = await utils_fs_1.readFile(pbxPath, { encoding: 'utf-8' });
    pbxContent = pbxContent.replace(/PRODUCT_BUNDLE_IDENTIFIER = ([^;]+)/g, `PRODUCT_BUNDLE_IDENTIFIER = ${appId}`);
    await utils_fs_1.writeFile(plistPath, plistContent, { encoding: 'utf-8' });
    await utils_fs_1.writeFile(pbxPath, pbxContent, { encoding: 'utf-8' });
}
exports.editProjectSettingsIOS = editProjectSettingsIOS;
function shouldPodInstall(config, platformName) {
    // Don't run pod install or xcodebuild if not on macOS
    if (config.cli.os !== "mac" /* Mac */ && platformName === 'ios') {
        return false;
    }
    return true;
}
exports.shouldPodInstall = shouldPodInstall;
