"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.onBeforeExit = exports.wait = exports.execFile = exports.exec = void 0;
const cp = require("child_process");
const Debug = require("debug");
const util = require("util");
const fn_1 = require("./fn");
const debug = Debug('native-run:utils:process');
exports.exec = util.promisify(cp.exec);
exports.execFile = util.promisify(cp.execFile);
exports.wait = util.promisify(setTimeout);
const exitQueue = [];
function onBeforeExit(fn) {
    exitQueue.push(fn);
}
exports.onBeforeExit = onBeforeExit;
const BEFORE_EXIT_SIGNALS = [
    'SIGINT',
    'SIGTERM',
    'SIGHUP',
    'SIGBREAK',
];
const beforeExitHandlerWrapper = (signal) => fn_1.once(async () => {
    debug('onBeforeExit handler: %s received', signal);
    debug('onBeforeExit handler: running %s queued functions', exitQueue.length);
    for (const [i, fn] of exitQueue.entries()) {
        try {
            await fn();
        }
        catch (e) {
            debug('Error from function %d in exit queue: %O', i, e);
        }
    }
    debug('onBeforeExit handler: exiting (exit code %s)', process.exitCode ? process.exitCode : 0);
    process.exit();
});
for (const signal of BEFORE_EXIT_SIGNALS) {
    process.on(signal, beforeExitHandlerWrapper(signal));
}
