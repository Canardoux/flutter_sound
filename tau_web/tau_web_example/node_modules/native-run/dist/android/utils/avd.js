"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getSkinPathByName = exports.validateSystemImagePath = exports.copySkin = exports.validateSkin = exports.validateAVDSchematic = exports.createAVDSchematic = exports.createAVD = exports.getDefaultAVD = exports.getAVDSchematicFromAPILevel = exports.getDefaultAVDSchematic = exports.getInstalledAVDs = exports.getAVDFromINI = exports.getSDKVersionFromTarget = exports.getAVDFromConfigINI = exports.getAVDINIs = exports.isAVDConfigINI = exports.isAVDINI = void 0;
const utils_fs_1 = require("@ionic/utils-fs");
const Debug = require("debug");
const pathlib = require("path");
const constants_1 = require("../../constants");
const errors_1 = require("../../errors");
const ini_1 = require("../../utils/ini");
const object_1 = require("../../utils/object");
const sdk_1 = require("./sdk");
const api_1 = require("./sdk/api");
const modulePrefix = 'native-run:android:utils:avd';
const isAVDINI = (o) => o &&
    typeof o['avd.ini.encoding'] === 'string' &&
    typeof o['path'] === 'string' &&
    typeof o['path.rel'] === 'string' &&
    typeof o['target'] === 'string';
exports.isAVDINI = isAVDINI;
const isAVDConfigINI = (o) => o &&
    (typeof o['avd.ini.displayname'] === 'undefined' ||
        typeof o['avd.ini.displayname'] === 'string') &&
    (typeof o['hw.lcd.density'] === 'undefined' ||
        typeof o['hw.lcd.density'] === 'string') &&
    (typeof o['hw.lcd.height'] === 'undefined' ||
        typeof o['hw.lcd.height'] === 'string') &&
    (typeof o['hw.lcd.width'] === 'undefined' ||
        typeof o['hw.lcd.width'] === 'string') &&
    (typeof o['image.sysdir.1'] === 'undefined' ||
        typeof o['image.sysdir.1'] === 'string');
exports.isAVDConfigINI = isAVDConfigINI;
async function getAVDINIs(sdk) {
    const debug = Debug(`${modulePrefix}:${getAVDINIs.name}`);
    const contents = await utils_fs_1.readdir(sdk.avdHome);
    const iniFilePaths = contents
        .filter(f => pathlib.extname(f) === '.ini')
        .map(f => pathlib.resolve(sdk.avdHome, f));
    debug('Discovered AVD ini files: %O', iniFilePaths);
    const iniFiles = await Promise.all(iniFilePaths.map(async (f) => [
        f,
        await ini_1.readINI(f, exports.isAVDINI),
    ]));
    const avdInis = iniFiles.filter((c) => typeof c[1] !== 'undefined');
    return avdInis;
}
exports.getAVDINIs = getAVDINIs;
function getAVDFromConfigINI(inipath, ini, configini) {
    const inibasename = pathlib.basename(inipath);
    const id = inibasename.substring(0, inibasename.length - pathlib.extname(inibasename).length);
    const name = configini['avd.ini.displayname']
        ? String(configini['avd.ini.displayname'])
        : id.replace(/_/g, ' ');
    const screenDPI = configini['hw.lcd.density']
        ? Number(configini['hw.lcd.density'])
        : null;
    const screenWidth = configini['hw.lcd.width']
        ? Number(configini['hw.lcd.width'])
        : null;
    const screenHeight = configini['hw.lcd.height']
        ? Number(configini['hw.lcd.height'])
        : null;
    return {
        id,
        path: ini.path,
        name,
        sdkVersion: getSDKVersionFromTarget(ini.target),
        screenDPI,
        screenWidth,
        screenHeight,
    };
}
exports.getAVDFromConfigINI = getAVDFromConfigINI;
function getSDKVersionFromTarget(target) {
    return target.replace(/^android-(\d+)/, '$1');
}
exports.getSDKVersionFromTarget = getSDKVersionFromTarget;
async function getAVDFromINI(inipath, ini) {
    const configini = await ini_1.readINI(pathlib.resolve(ini.path, 'config.ini'), exports.isAVDConfigINI);
    if (configini) {
        return getAVDFromConfigINI(inipath, ini, configini);
    }
}
exports.getAVDFromINI = getAVDFromINI;
async function getInstalledAVDs(sdk) {
    const avdInis = await getAVDINIs(sdk);
    const possibleAvds = await Promise.all(avdInis.map(([inipath, ini]) => getAVDFromINI(inipath, ini)));
    const avds = possibleAvds.filter((avd) => typeof avd !== 'undefined');
    return avds;
}
exports.getInstalledAVDs = getInstalledAVDs;
async function getDefaultAVDSchematic(sdk) {
    const debug = Debug(`${modulePrefix}:${getDefaultAVDSchematic.name}`);
    const packages = await sdk_1.findAllSDKPackages(sdk);
    const apis = await api_1.getAPILevels(packages);
    for (const api of apis) {
        try {
            const schematic = await getAVDSchematicFromAPILevel(sdk, packages, api);
            debug('Using schematic %s for default AVD', schematic.id);
            return schematic;
        }
        catch (e) {
            if (!(e instanceof errors_1.AVDException)) {
                throw e;
            }
            debug('Issue with API %s: %s', api.apiLevel, e.message);
        }
    }
    throw new errors_1.AVDException('No suitable API installation found.', errors_1.ERR_UNSUITABLE_API_INSTALLATION, 1);
}
exports.getDefaultAVDSchematic = getDefaultAVDSchematic;
async function getAVDSchematicFromAPILevel(sdk, packages, api) {
    const schema = api_1.API_LEVEL_SCHEMAS.find(s => s.apiLevel === api.apiLevel);
    if (!schema) {
        throw new errors_1.AVDException(`Unsupported API level: ${api.apiLevel}`, errors_1.ERR_UNSUPPORTED_API_LEVEL);
    }
    const missingPackages = schema.validate(packages);
    if (missingPackages.length > 0) {
        throw new errors_1.AVDException(`Unsatisfied packages within API ${api.apiLevel}: ${missingPackages
            .map(pkg => pkg.path)
            .join(', ')}`, errors_1.ERR_SDK_UNSATISFIED_PACKAGES, 1);
    }
    return createAVDSchematic(sdk, await schema.loadPartialAVDSchematic());
}
exports.getAVDSchematicFromAPILevel = getAVDSchematicFromAPILevel;
async function getDefaultAVD(sdk, avds) {
    const defaultAvdSchematic = await getDefaultAVDSchematic(sdk);
    const defaultAvd = avds.find(avd => avd.id === defaultAvdSchematic.id);
    if (defaultAvd) {
        return defaultAvd;
    }
    return createAVD(sdk, defaultAvdSchematic);
}
exports.getDefaultAVD = getDefaultAVD;
async function createAVD(sdk, schematic) {
    const { id, ini, configini } = schematic;
    await utils_fs_1.mkdirp(pathlib.join(sdk.avdHome, `${id}.avd`));
    await Promise.all([
        ini_1.writeINI(pathlib.join(sdk.avdHome, `${id}.ini`), ini),
        ini_1.writeINI(pathlib.join(sdk.avdHome, `${id}.avd`, 'config.ini'), configini),
    ]);
    return getAVDFromConfigINI(pathlib.join(sdk.avdHome, `${id}.ini`), ini, configini);
}
exports.createAVD = createAVD;
async function createAVDSchematic(sdk, partialSchematic) {
    const sysimage = api_1.findPackageBySchemaPath(sdk.packages || [], new RegExp(`^system-images;${partialSchematic.ini.target}`));
    if (!sysimage) {
        throw new errors_1.AVDException(`Cannot create AVD schematic for ${partialSchematic.id}: missing system image.`, errors_1.ERR_MISSING_SYSTEM_IMAGE);
    }
    const avdpath = pathlib.join(sdk.avdHome, `${partialSchematic.id}.avd`);
    const skinpath = getSkinPathByName(sdk, partialSchematic.configini['skin.name']);
    const sysdir = pathlib.relative(sdk.root, sysimage.location);
    const [, , tagid] = sysimage.path.split(';');
    const schematic = {
        id: partialSchematic.id,
        ini: object_1.sort({
            ...partialSchematic.ini,
            'path': avdpath,
            'path.rel': `avd/${partialSchematic.id}.avd`,
        }),
        configini: object_1.sort({
            ...partialSchematic.configini,
            'skin.path': skinpath,
            'image.sysdir.1': sysdir,
            'tag.id': tagid,
        }),
    };
    await validateAVDSchematic(sdk, schematic);
    return schematic;
}
exports.createAVDSchematic = createAVDSchematic;
async function validateAVDSchematic(sdk, schematic) {
    const { configini } = schematic;
    const skin = configini['skin.name'];
    const skinpath = configini['skin.path'];
    const sysdir = configini['image.sysdir.1'];
    if (!skinpath) {
        throw new errors_1.AVDException(`${schematic.id} does not have a skin defined.`, errors_1.ERR_INVALID_SKIN);
    }
    if (!sysdir) {
        throw new errors_1.AVDException(`${schematic.id} does not have a system image defined.`, errors_1.ERR_INVALID_SYSTEM_IMAGE);
    }
    await validateSkin(sdk, skin, skinpath);
    await validateSystemImagePath(sdk, sysdir);
}
exports.validateAVDSchematic = validateAVDSchematic;
async function validateSkin(sdk, skin, skinpath) {
    const debug = Debug(`${modulePrefix}:${validateSkin.name}`);
    const p = pathlib.join(skinpath, 'layout');
    debug('Checking skin layout file: %s', p);
    const stat = await utils_fs_1.statSafe(p);
    if (stat === null || stat === void 0 ? void 0 : stat.isFile()) {
        return;
    }
    await copySkin(sdk, skin, skinpath);
}
exports.validateSkin = validateSkin;
async function copySkin(sdk, skin, skinpath) {
    const debug = Debug(`${modulePrefix}:${copySkin.name}`);
    const skinsrc = pathlib.resolve(constants_1.ASSETS_PATH, 'android', 'skins', skin);
    const stat = await utils_fs_1.statSafe(skinsrc);
    if (stat === null || stat === void 0 ? void 0 : stat.isDirectory()) {
        debug('Copying skin from %s to %s', skinsrc, skinpath);
        try {
            return await utils_fs_1.copy(skinsrc, skinpath);
        }
        catch (e) {
            debug('Error while copying skin: %O', e);
        }
    }
    throw new errors_1.AVDException(`${skinpath} is an invalid skin.`, errors_1.ERR_INVALID_SKIN);
}
exports.copySkin = copySkin;
async function validateSystemImagePath(sdk, sysdir) {
    const debug = Debug(`${modulePrefix}:${validateSystemImagePath.name}`);
    const p = pathlib.join(sdk.root, sysdir, 'package.xml');
    debug('Checking package.xml file: %s', p);
    const stat = await utils_fs_1.statSafe(p);
    if (!stat || !stat.isFile()) {
        throw new errors_1.AVDException(`${p} is an invalid system image package.`, errors_1.ERR_INVALID_SYSTEM_IMAGE);
    }
}
exports.validateSystemImagePath = validateSystemImagePath;
function getSkinPathByName(sdk, name) {
    const path = pathlib.join(sdk.root, 'skins', name);
    return path;
}
exports.getSkinPathByName = getSkinPathByName;
