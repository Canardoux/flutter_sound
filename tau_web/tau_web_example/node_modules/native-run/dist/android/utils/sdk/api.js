"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.API_LEVEL_SCHEMAS = exports.API_LEVEL_24 = exports.API_LEVEL_25 = exports.API_LEVEL_26 = exports.API_LEVEL_27 = exports.API_LEVEL_28 = exports.API_LEVEL_29 = exports.API_LEVEL_30 = exports.findPackageBySchemaPath = exports.findPackageBySchema = exports.findUnsatisfiedPackages = exports.getAPILevels = void 0;
const Debug = require("debug");
const modulePrefix = 'native-run:android:utils:sdk:api';
async function getAPILevels(packages) {
    const debug = Debug(`${modulePrefix}:${getAPILevels.name}`);
    const levels = [
        ...new Set(packages
            .map(pkg => pkg.apiLevel)
            .filter((apiLevel) => typeof apiLevel !== 'undefined')),
    ].sort((a, b) => (a <= b ? 1 : -1));
    const apis = levels.map(apiLevel => ({
        apiLevel,
        packages: packages.filter(pkg => pkg.apiLevel === apiLevel),
    }));
    debug('Discovered installed API Levels: %O', apis.map(api => ({ ...api, packages: api.packages.map(pkg => pkg.path) })));
    return apis;
}
exports.getAPILevels = getAPILevels;
function findUnsatisfiedPackages(packages, schemas) {
    return schemas.filter(pkg => !findPackageBySchema(packages, pkg));
}
exports.findUnsatisfiedPackages = findUnsatisfiedPackages;
function findPackageBySchema(packages, pkg) {
    const apiPkg = findPackageBySchemaPath(packages, pkg.path);
    if (apiPkg) {
        if (typeof pkg.version === 'string') {
            if (pkg.version === apiPkg.version) {
                return apiPkg;
            }
        }
        else {
            if (apiPkg.version.match(pkg.version)) {
                return apiPkg;
            }
        }
    }
}
exports.findPackageBySchema = findPackageBySchema;
function findPackageBySchemaPath(packages, path) {
    return packages.find(pkg => {
        if (typeof path !== 'string') {
            return !!pkg.path.match(path);
        }
        return path === pkg.path;
    });
}
exports.findPackageBySchemaPath = findPackageBySchemaPath;
exports.API_LEVEL_30 = Object.freeze({
    apiLevel: '30',
    validate: (packages) => {
        const schemas = [
            { name: 'Android Emulator', path: 'emulator', version: /.+/ },
            {
                name: 'Android SDK Platform 30',
                path: 'platforms;android-30',
                version: /.+/,
            },
        ];
        const missingPackages = findUnsatisfiedPackages(packages, schemas);
        if (!findPackageBySchemaPath(packages, /^system-images;android-30;/)) {
            missingPackages.push({
                name: 'Google Play Intel x86 Atom System Image',
                path: 'system-images;android-30;google_apis_playstore;x86',
                version: '/.+/',
            });
        }
        return missingPackages;
    },
    loadPartialAVDSchematic: async () => Promise.resolve().then(() => require('../../data/avds/Pixel_3_API_30.json')),
});
exports.API_LEVEL_29 = Object.freeze({
    apiLevel: '29',
    validate: (packages) => {
        const schemas = [
            { name: 'Android Emulator', path: 'emulator', version: /.+/ },
            {
                name: 'Android SDK Platform 29',
                path: 'platforms;android-29',
                version: /.+/,
            },
        ];
        const missingPackages = findUnsatisfiedPackages(packages, schemas);
        if (!findPackageBySchemaPath(packages, /^system-images;android-29;/)) {
            missingPackages.push({
                name: 'Google Play Intel x86 Atom System Image',
                path: 'system-images;android-29;google_apis_playstore;x86',
                version: '/.+/',
            });
        }
        return missingPackages;
    },
    loadPartialAVDSchematic: async () => Promise.resolve().then(() => require('../../data/avds/Pixel_3_API_29.json')),
});
exports.API_LEVEL_28 = Object.freeze({
    apiLevel: '28',
    validate: (packages) => {
        const schemas = [
            { name: 'Android Emulator', path: 'emulator', version: /.+/ },
            {
                name: 'Android SDK Platform 28',
                path: 'platforms;android-28',
                version: /.+/,
            },
        ];
        const missingPackages = findUnsatisfiedPackages(packages, schemas);
        if (!findPackageBySchemaPath(packages, /^system-images;android-28;/)) {
            missingPackages.push({
                name: 'Google Play Intel x86 Atom System Image',
                path: 'system-images;android-28;google_apis_playstore;x86',
                version: '/.+/',
            });
        }
        return missingPackages;
    },
    loadPartialAVDSchematic: async () => Promise.resolve().then(() => require('../../data/avds/Pixel_2_API_28.json')),
});
exports.API_LEVEL_27 = Object.freeze({
    apiLevel: '27',
    validate: (packages) => {
        const schemas = [
            { name: 'Android Emulator', path: 'emulator', version: /.+/ },
            {
                name: 'Android SDK Platform 27',
                path: 'platforms;android-27',
                version: /.+/,
            },
        ];
        const missingPackages = findUnsatisfiedPackages(packages, schemas);
        if (!findPackageBySchemaPath(packages, /^system-images;android-27;/)) {
            missingPackages.push({
                name: 'Google Play Intel x86 Atom System Image',
                path: 'system-images;android-27;google_apis_playstore;x86',
                version: '/.+/',
            });
        }
        return missingPackages;
    },
    loadPartialAVDSchematic: async () => Promise.resolve().then(() => require('../../data/avds/Pixel_2_API_27.json')),
});
exports.API_LEVEL_26 = Object.freeze({
    apiLevel: '26',
    validate: (packages) => {
        const schemas = [
            { name: 'Android Emulator', path: 'emulator', version: /.+/ },
            {
                name: 'Android SDK Platform 26',
                path: 'platforms;android-26',
                version: /.+/,
            },
        ];
        const missingPackages = findUnsatisfiedPackages(packages, schemas);
        if (!findPackageBySchemaPath(packages, /^system-images;android-26;/)) {
            missingPackages.push({
                name: 'Google Play Intel x86 Atom System Image',
                path: 'system-images;android-26;google_apis_playstore;x86',
                version: '/.+/',
            });
        }
        return missingPackages;
    },
    loadPartialAVDSchematic: async () => Promise.resolve().then(() => require('../../data/avds/Pixel_2_API_26.json')),
});
exports.API_LEVEL_25 = Object.freeze({
    apiLevel: '25',
    validate: (packages) => {
        const schemas = [
            { name: 'Android Emulator', path: 'emulator', version: /.+/ },
            {
                name: 'Android SDK Platform 25',
                path: 'platforms;android-25',
                version: /.+/,
            },
        ];
        const missingPackages = findUnsatisfiedPackages(packages, schemas);
        if (!findPackageBySchemaPath(packages, /^system-images;android-25;/)) {
            missingPackages.push({
                name: 'Google Play Intel x86 Atom System Image',
                path: 'system-images;android-25;google_apis_playstore;x86',
                version: '/.+/',
            });
        }
        return missingPackages;
    },
    loadPartialAVDSchematic: async () => Promise.resolve().then(() => require('../../data/avds/Pixel_API_25.json')),
});
exports.API_LEVEL_24 = Object.freeze({
    apiLevel: '24',
    validate: (packages) => {
        const schemas = [
            { name: 'Android Emulator', path: 'emulator', version: /.+/ },
            {
                name: 'Android SDK Platform 24',
                path: 'platforms;android-24',
                version: /.+/,
            },
        ];
        const missingPackages = findUnsatisfiedPackages(packages, schemas);
        if (!findPackageBySchemaPath(packages, /^system-images;android-24;/)) {
            missingPackages.push({
                name: 'Google Play Intel x86 Atom System Image',
                path: 'system-images;android-24;google_apis_playstore;x86',
                version: '/.+/',
            });
        }
        return missingPackages;
    },
    loadPartialAVDSchematic: async () => Promise.resolve().then(() => require('../../data/avds/Nexus_5X_API_24.json')),
});
exports.API_LEVEL_SCHEMAS = [
    exports.API_LEVEL_30,
    exports.API_LEVEL_29,
    exports.API_LEVEL_28,
    exports.API_LEVEL_27,
    exports.API_LEVEL_26,
    exports.API_LEVEL_25,
    exports.API_LEVEL_24,
];
