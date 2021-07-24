"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.run = void 0;
const Debug = require("debug");
const path = require("path");
const errors_1 = require("./errors");
const debug = Debug('native-run');
async function run() {
    const args = process.argv.slice(2);
    if (args.includes('--version')) {
        const pkg = await Promise.resolve().then(() => require(path.resolve(__dirname, '../package.json')));
        process.stdout.write(pkg.version + '\n');
        return;
    }
    let cmd;
    const [platform, ...platformArgs] = args;
    try {
        if (platform === 'android') {
            cmd = await Promise.resolve().then(() => require('./android'));
            await cmd.run(platformArgs);
        }
        else if (platform === 'ios') {
            cmd = await Promise.resolve().then(() => require('./ios'));
            await cmd.run(platformArgs);
        }
        else if (platform === '--list') {
            cmd = await Promise.resolve().then(() => require('./list'));
            await cmd.run(args);
        }
        else {
            if (!platform ||
                platform === 'help' ||
                args.includes('--help') ||
                args.includes('-h') ||
                platform.startsWith('-')) {
                cmd = await Promise.resolve().then(() => require('./help'));
                return cmd.run(args);
            }
            throw new errors_1.CLIException(`Unsupported platform: "${platform}"`, errors_1.ERR_BAD_INPUT);
        }
    }
    catch (e) {
        debug('Caught fatal error: %O', e);
        process.exitCode = e instanceof errors_1.Exception ? e.exitCode : 1 /* GENERAL */;
        process.stdout.write(errors_1.serializeError(e));
    }
}
exports.run = run;
