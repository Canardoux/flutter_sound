"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.supplementProcessEnv = exports.resolveAVDHome = exports.resolveEmulatorHome = exports.resolveSDKRoot = exports.getSDKPackage = exports.findAllSDKPackages = exports.getSDK = exports.SDK_DIRECTORIES = void 0;
const utils_fs_1 = require("@ionic/utils-fs");
const Debug = require("debug");
const os = require("os");
const pathlib = require("path");
const errors_1 = require("../../../errors");
const fs_1 = require("../../../utils/fs");
const xml_1 = require("./xml");
const modulePrefix = 'native-run:android:utils:sdk';
const homedir = os.homedir();
exports.SDK_DIRECTORIES = new Map([
    ['darwin', [pathlib.join(homedir, 'Library', 'Android', 'sdk')]],
    ['linux', [pathlib.join(homedir, 'Android', 'sdk')]],
    [
        'win32',
        [
            pathlib.join(process.env.LOCALAPPDATA || pathlib.join(homedir, 'AppData', 'Local'), 'Android', 'Sdk'),
        ],
    ],
]);
async function getSDK() {
    const root = await resolveSDKRoot();
    const emulatorHome = await resolveEmulatorHome();
    const avdHome = await resolveAVDHome();
    return { root, emulatorHome, avdHome };
}
exports.getSDK = getSDK;
const pkgcache = new Map();
async function findAllSDKPackages(sdk) {
    const debug = Debug(`${modulePrefix}:${findAllSDKPackages.name}`);
    if (sdk.packages) {
        return sdk.packages;
    }
    const sourcesRe = /^sources\/android-\d+\/.+\/.+/;
    debug('Walking %s to discover SDK packages', sdk.root);
    const contents = await utils_fs_1.readdirp(sdk.root, {
        filter: item => pathlib.basename(item.path) === 'package.xml',
        onError: err => debug('Error while walking SDK: %O', err),
        walkerOptions: {
            pathFilter: p => {
                if ([
                    'bin',
                    'bin64',
                    'lib',
                    'lib64',
                    'include',
                    'clang-include',
                    'skins',
                    'data',
                    'examples',
                    'resources',
                    'systrace',
                    'extras',
                ].includes(pathlib.basename(p))) {
                    return false;
                }
                if (p.match(sourcesRe)) {
                    return false;
                }
                return true;
            },
        },
    });
    sdk.packages = await Promise.all(contents.map(p => pathlib.dirname(p)).map(p => getSDKPackage(p)));
    sdk.packages.sort((a, b) => (a.name >= b.name ? 1 : -1));
    return sdk.packages;
}
exports.findAllSDKPackages = findAllSDKPackages;
async function getSDKPackage(location) {
    const debug = Debug(`${modulePrefix}:${getSDKPackage.name}`);
    let pkg = pkgcache.get(location);
    if (!pkg) {
        const packageXmlPath = pathlib.join(location, 'package.xml');
        debug('Parsing %s', packageXmlPath);
        try {
            const packageXml = await xml_1.readPackageXml(packageXmlPath);
            const name = xml_1.getNameFromPackageXml(packageXml);
            const version = xml_1.getVersionFromPackageXml(packageXml);
            const path = xml_1.getPathFromPackageXml(packageXml);
            const apiLevel = xml_1.getAPILevelFromPackageXml(packageXml);
            pkg = {
                path,
                location,
                version,
                name,
                apiLevel,
            };
        }
        catch (e) {
            debug('Encountered error with %s: %O', packageXmlPath, e);
            if (e.code === 'ENOENT') {
                throw new errors_1.SDKException(`SDK package not found by location: ${location}.`, errors_1.ERR_SDK_PACKAGE_NOT_FOUND);
            }
            throw e;
        }
        pkgcache.set(location, pkg);
    }
    return pkg;
}
exports.getSDKPackage = getSDKPackage;
async function resolveSDKRoot() {
    const debug = Debug(`${modulePrefix}:${resolveSDKRoot.name}`);
    debug('Looking for $ANDROID_HOME');
    // $ANDROID_HOME is deprecated, but still overrides $ANDROID_SDK_ROOT if
    // defined and valid.
    if (process.env.ANDROID_HOME && (await fs_1.isDir(process.env.ANDROID_HOME))) {
        debug('Using $ANDROID_HOME at %s', process.env.ANDROID_HOME);
        return process.env.ANDROID_HOME;
    }
    debug('Looking for $ANDROID_SDK_ROOT');
    // No valid $ANDROID_HOME, try $ANDROID_SDK_ROOT.
    if (process.env.ANDROID_SDK_ROOT &&
        (await fs_1.isDir(process.env.ANDROID_SDK_ROOT))) {
        debug('Using $ANDROID_SDK_ROOT at %s', process.env.ANDROID_SDK_ROOT);
        return process.env.ANDROID_SDK_ROOT;
    }
    const sdkDirs = exports.SDK_DIRECTORIES.get(process.platform);
    if (!sdkDirs) {
        throw new errors_1.SDKException(`Unsupported platform: ${process.platform}`);
    }
    debug('Looking at following directories: %O', sdkDirs);
    for (const sdkDir of sdkDirs) {
        if (await fs_1.isDir(sdkDir)) {
            debug('Using %s', sdkDir);
            return sdkDir;
        }
    }
    throw new errors_1.SDKException(`No valid Android SDK root found.`, errors_1.ERR_SDK_NOT_FOUND);
}
exports.resolveSDKRoot = resolveSDKRoot;
async function resolveEmulatorHome() {
    const debug = Debug(`${modulePrefix}:${resolveEmulatorHome.name}`);
    debug('Looking for $ANDROID_EMULATOR_HOME');
    if (process.env.ANDROID_EMULATOR_HOME &&
        (await fs_1.isDir(process.env.ANDROID_EMULATOR_HOME))) {
        debug('Using $ANDROID_EMULATOR_HOME at %s', process.env.$ANDROID_EMULATOR_HOME);
        return process.env.ANDROID_EMULATOR_HOME;
    }
    debug('Looking at $HOME/.android');
    const homeEmulatorHome = pathlib.join(homedir, '.android');
    if (await fs_1.isDir(homeEmulatorHome)) {
        debug('Using $HOME/.android/ at %s', homeEmulatorHome);
        return homeEmulatorHome;
    }
    throw new errors_1.SDKException(`No valid Android Emulator home found.`, errors_1.ERR_EMULATOR_HOME_NOT_FOUND);
}
exports.resolveEmulatorHome = resolveEmulatorHome;
async function resolveAVDHome() {
    const debug = Debug(`${modulePrefix}:${resolveAVDHome.name}`);
    debug('Looking for $ANDROID_AVD_HOME');
    if (process.env.ANDROID_AVD_HOME &&
        (await fs_1.isDir(process.env.ANDROID_AVD_HOME))) {
        debug('Using $ANDROID_AVD_HOME at %s', process.env.$ANDROID_AVD_HOME);
        return process.env.ANDROID_AVD_HOME;
    }
    debug('Looking at $HOME/.android/avd');
    const homeAvdHome = pathlib.join(homedir, '.android', 'avd');
    if (!(await fs_1.isDir(homeAvdHome))) {
        debug('Creating directory: %s', homeAvdHome);
        await utils_fs_1.mkdirp(homeAvdHome);
    }
    debug('Using $HOME/.android/avd/ at %s', homeAvdHome);
    return homeAvdHome;
}
exports.resolveAVDHome = resolveAVDHome;
function supplementProcessEnv(sdk) {
    return {
        ...process.env,
        ANDROID_SDK_ROOT: sdk.root,
        ANDROID_EMULATOR_HOME: sdk.emulatorHome,
        ANDROID_AVD_HOME: sdk.avdHome,
    };
}
exports.supplementProcessEnv = supplementProcessEnv;
