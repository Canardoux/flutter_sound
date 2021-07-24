"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.processExit = exports.offBeforeExit = exports.onBeforeExit = exports.onExit = exports.sleepForever = exports.sleepUntil = exports.sleep = exports.getPathParts = exports.createProcessEnv = exports.killProcessTree = exports.ERROR_TIMEOUT_REACHED = void 0;
const utils_object_1 = require("@ionic/utils-object");
const utils_terminal_1 = require("@ionic/utils-terminal");
const Debug = require("debug");
const pathlib = require("path");
const onSignalExit = require("signal-exit");
const kill = require("tree-kill");
const debug = Debug('ionic:utils-process');
exports.ERROR_TIMEOUT_REACHED = new Error('TIMEOUT_REACHED');
function killProcessTree(pid, signal = 'SIGTERM') {
    return new Promise((resolve, reject) => {
        kill(pid, signal, err => {
            if (err) {
                debug('error while killing process tree for %d: %O', pid, err);
                return reject(err);
            }
            resolve();
        });
    });
}
exports.killProcessTree = killProcessTree;
/**
 * Creates an alternative implementation of `process.env` object.
 *
 * On a Windows shell, `process.env` is a magic object that offers
 * case-insensitive environment variable access. On other platforms, case
 * sensitivity matters. This method creates an empty "`process.env`" object
 * type that works for all platforms.
 */
function createProcessEnv(...sources) {
    return Object.assign(utils_terminal_1.TERMINAL_INFO.windows ? utils_object_1.createCaseInsensitiveObject() : {}, ...sources);
}
exports.createProcessEnv = createProcessEnv;
/**
 * Split a PATH string into path parts.
 */
function getPathParts(envpath = process.env.PATH || '') {
    return envpath.split(pathlib.delimiter);
}
exports.getPathParts = getPathParts;
/**
 * Resolves when the given amount of milliseconds has passed.
 */
async function sleep(ms) {
    return new Promise(resolve => {
        setTimeout(resolve, ms);
    });
}
exports.sleep = sleep;
/**
 * Resolves when a given predicate is true or a timeout is reached.
 *
 * Configure `interval` to set how often the `predicate` is called.
 *
 * By default, `timeout` is Infinity. If given a value (in ms), and that
 * timeout value is reached, this function will reject with
 * the `ERROR_TIMEOUT_REACHED` error.
 */
async function sleepUntil(predicate, { interval = 30, timeout = Infinity }) {
    let ms = 0;
    while (!predicate()) {
        await sleep(interval);
        ms += interval;
        if (ms > timeout) {
            throw exports.ERROR_TIMEOUT_REACHED;
        }
    }
}
exports.sleepUntil = sleepUntil;
/**
 * Never resolves and keeps Node running.
 */
async function sleepForever() {
    return new Promise(() => {
        setInterval(() => { }, 1000);
    });
}
exports.sleepForever = sleepForever;
/**
 * Register a synchronous function to be called once the process exits.
 */
function onExit(fn) {
    onSignalExit(() => {
        debug('onExit: process.exit/normal shutdown');
        fn();
    });
}
exports.onExit = onExit;
const exitFns = new Set();
/**
 * Register an asynchronous function to be called when the process wants to
 * exit.
 *
 * A handler will be registered for the 'SIGINT', 'SIGTERM', 'SIGHUP',
 * 'SIGBREAK' signals. If any of the signal events is emitted, `fn` will be
 * called exactly once, awaited upon, and then the process will exit once all
 * registered functions are resolved.
 */
function onBeforeExit(fn) {
    exitFns.add(fn);
}
exports.onBeforeExit = onBeforeExit;
/**
 * Remove a function that was registered with `onBeforeExit`.
 */
function offBeforeExit(fn) {
    exitFns.delete(fn);
}
exports.offBeforeExit = offBeforeExit;
const once = (fn) => {
    let called = false;
    return async () => {
        if (!called) {
            await fn();
            called = true;
        }
    };
};
const beforeExitHandlerWrapper = (signal) => once(async () => {
    debug('onBeforeExit handler: %O received', signal);
    debug('onBeforeExit handler: running %O functions', exitFns.size);
    await Promise.all([...exitFns.values()].map(async (fn) => {
        try {
            await fn();
        }
        catch (e) {
            debug('onBeforeExit handler: error from function: %O', e);
        }
    }));
    if (signal !== 'process.exit') {
        debug('onBeforeExit handler: killing self (exit code %O, signal %O)', process.exitCode ? process.exitCode : 0, signal);
        process.removeListener(signal, BEFORE_EXIT_SIGNAL_LISTENERS[signal]);
        process.kill(process.pid, signal);
    }
});
const BEFORE_EXIT_SIGNAL_LISTENERS = {
    SIGINT: beforeExitHandlerWrapper('SIGINT'),
    SIGTERM: beforeExitHandlerWrapper('SIGTERM'),
    SIGHUP: beforeExitHandlerWrapper('SIGHUP'),
    SIGBREAK: beforeExitHandlerWrapper('SIGBREAK'),
};
for (const [signal, fn] of Object.entries(BEFORE_EXIT_SIGNAL_LISTENERS)) {
    process.on(signal, fn);
}
const processExitHandler = beforeExitHandlerWrapper('process.exit');
/**
 * Asynchronous `process.exit()`, for running functions registered with
 * `onBeforeExit`.
 */
async function processExit(exitCode = 0) {
    process.exitCode = exitCode;
    await processExitHandler();
    debug('processExit: exiting (exit code: %O)', process.exitCode);
    process.exit();
}
exports.processExit = processExit;
