"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.run = void 0;
async function run(args) {
    let cmd;
    if (args.includes('--help') || args.includes('-h')) {
        cmd = await Promise.resolve().then(() => require('./help'));
        return cmd.run(args);
    }
    if (args.includes('--list') || args.includes('-l')) {
        cmd = await Promise.resolve().then(() => require('./list'));
        return cmd.run(args);
    }
    cmd = await Promise.resolve().then(() => require('./run'));
    await cmd.run(args);
}
exports.run = run;
