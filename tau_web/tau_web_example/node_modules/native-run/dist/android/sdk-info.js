"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.run = void 0;
const json_1 = require("../utils/json");
const sdk_1 = require("./utils/sdk");
const api_1 = require("./utils/sdk/api");
async function run(args) {
    const sdk = await sdk_1.getSDK();
    const packages = await sdk_1.findAllSDKPackages(sdk);
    const apis = await api_1.getAPILevels(packages);
    const platforms = apis.map(api => {
        const schema = api_1.API_LEVEL_SCHEMAS.find(s => s.apiLevel === api.apiLevel);
        return { ...api, missingPackages: schema ? schema.validate(packages) : [] };
    });
    const sdkinfo = {
        root: sdk.root,
        avdHome: sdk.avdHome,
        platforms,
        tools: packages.filter(pkg => typeof pkg.apiLevel === 'undefined'),
    };
    if (args.includes('--json')) {
        process.stdout.write(json_1.stringify(sdkinfo));
        return;
    }
    process.stdout.write(`${formatSDKInfo(sdkinfo)}\n\n`);
}
exports.run = run;
function formatSDKInfo(sdk) {
    return `
SDK Location:         ${sdk.root}
AVD Home${sdk.avdHome ? `:             ${sdk.avdHome}` : ` (!):         not found`}

${sdk.platforms.map(platform => `${formatPlatform(platform)}\n\n`).join('\n')}
Tools:

${sdk.tools.map(tool => formatPackage(tool)).join('\n')}
  `.trim();
}
function formatPlatform(platform) {
    return `
API Level:            ${platform.apiLevel}
Packages:             ${platform.packages
        .map(p => formatPackage(p))
        .join('\n' + ' '.repeat(22))}
${platform.missingPackages.length > 0
        ? `(!) Missing Packages: ${platform.missingPackages
            .map(p => formatPackage(p))
            .join('\n' + ' '.repeat(22))}`
        : ''}
  `.trim();
}
function formatPackage(p) {
    return `${p.name}  ${p.path}  ${typeof p.version === 'string' ? p.version : ''}`;
}
