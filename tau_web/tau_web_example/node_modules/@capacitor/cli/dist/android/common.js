"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.editProjectSettingsAndroid = exports.resolvePlugin = exports.getAndroidPlugins = exports.checkAndroidPackage = void 0;
const utils_fs_1 = require("@ionic/utils-fs");
const path_1 = require("path");
const common_1 = require("../common");
const cordova_1 = require("../cordova");
const plugin_1 = require("../plugin");
const fs_1 = require("../util/fs");
async function checkAndroidPackage(config) {
    return common_1.checkCapacitorPlatform(config, 'android');
}
exports.checkAndroidPackage = checkAndroidPackage;
async function getAndroidPlugins(allPlugins) {
    const resolved = await Promise.all(allPlugins.map(async (plugin) => await resolvePlugin(plugin)));
    return resolved.filter((plugin) => !!plugin);
}
exports.getAndroidPlugins = getAndroidPlugins;
async function resolvePlugin(plugin) {
    var _a;
    const platform = 'android';
    if ((_a = plugin.manifest) === null || _a === void 0 ? void 0 : _a.android) {
        let pluginFilesPath = plugin.manifest.android.src
            ? plugin.manifest.android.src
            : platform;
        const absolutePath = path_1.join(plugin.rootPath, pluginFilesPath, plugin.id);
        // Android folder shouldn't have subfolders, but they used to, so search for them for compatibility reasons
        if (await utils_fs_1.pathExists(absolutePath)) {
            pluginFilesPath = path_1.join(platform, plugin.id);
        }
        plugin.android = {
            type: 0 /* Core */,
            path: fs_1.convertToUnixPath(pluginFilesPath),
        };
    }
    else if (plugin.xml) {
        plugin.android = {
            type: 1 /* Cordova */,
            path: 'src/' + platform,
        };
        if (cordova_1.getIncompatibleCordovaPlugins(platform).includes(plugin.id) ||
            !plugin_1.getPluginPlatform(plugin, platform)) {
            plugin.android.type = 2 /* Incompatible */;
        }
    }
    else {
        return null;
    }
    return plugin;
}
exports.resolvePlugin = resolvePlugin;
/**
 * Update an Android project with the desired app name and appId.
 * This is a little trickier for Android because the appId becomes
 * the package name.
 */
async function editProjectSettingsAndroid(config) {
    const appId = config.app.appId;
    const appName = config.app.appName;
    const manifestPath = path_1.resolve(config.android.srcMainDirAbs, 'AndroidManifest.xml');
    const buildGradlePath = path_1.resolve(config.android.appDirAbs, 'build.gradle');
    let manifestContent = await utils_fs_1.readFile(manifestPath, { encoding: 'utf-8' });
    manifestContent = manifestContent.replace(/com.getcapacitor.myapp/g, `${appId}`);
    await utils_fs_1.writeFile(manifestPath, manifestContent, { encoding: 'utf-8' });
    const domainPath = appId.split('.').join('/');
    // Make the package source path to the new plugin Java file
    const newJavaPath = path_1.resolve(config.android.srcMainDirAbs, `java/${domainPath}`);
    if (!(await utils_fs_1.pathExists(newJavaPath))) {
        await utils_fs_1.mkdirp(newJavaPath);
    }
    await utils_fs_1.copy(path_1.resolve(config.android.srcMainDirAbs, 'java/com/getcapacitor/myapp/MainActivity.java'), path_1.resolve(newJavaPath, 'MainActivity.java'));
    if (appId.split('.')[1] !== 'getcapacitor') {
        await utils_fs_1.remove(path_1.resolve(config.android.srcMainDirAbs, 'java/com/getcapacitor'));
    }
    // Remove our template 'com' folder if their ID doesn't have it
    if (appId.split('.')[0] !== 'com') {
        await utils_fs_1.remove(path_1.resolve(config.android.srcMainDirAbs, 'java/com/'));
    }
    // Update the package in the MainActivity java file
    const activityPath = path_1.resolve(newJavaPath, 'MainActivity.java');
    let activityContent = await utils_fs_1.readFile(activityPath, { encoding: 'utf-8' });
    activityContent = activityContent.replace(/package ([^;]*)/, `package ${appId}`);
    await utils_fs_1.writeFile(activityPath, activityContent, { encoding: 'utf-8' });
    // Update the applicationId in build.gradle
    let gradleContent = await utils_fs_1.readFile(buildGradlePath, { encoding: 'utf-8' });
    gradleContent = gradleContent.replace(/applicationId "[^"]+"/, `applicationId "${appId}"`);
    await utils_fs_1.writeFile(buildGradlePath, gradleContent, { encoding: 'utf-8' });
    // Update the settings in res/values/strings.xml
    const stringsPath = path_1.resolve(config.android.resDirAbs, 'values/strings.xml');
    let stringsContent = await utils_fs_1.readFile(stringsPath, { encoding: 'utf-8' });
    stringsContent = stringsContent.replace(/com.getcapacitor.myapp/g, appId);
    stringsContent = stringsContent.replace(/My App/g, appName.replace(/'/g, `\\'`));
    await utils_fs_1.writeFile(stringsPath, stringsContent);
}
exports.editProjectSettingsAndroid = editProjectSettingsAndroid;
