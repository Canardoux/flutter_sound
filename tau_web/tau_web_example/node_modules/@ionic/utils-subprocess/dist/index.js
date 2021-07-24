"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.findExecutables = exports.which = exports.fork = exports.spawn = exports.Subprocess = exports.SubprocessError = exports.convertPATH = exports.expandTildePath = exports.TILDE_PATH_REGEX = exports.ERROR_SIGNAL_EXIT = exports.ERROR_NON_ZERO_EXIT = exports.ERROR_COMMAND_NOT_FOUND = void 0;
const utils_array_1 = require("@ionic/utils-array");
const utils_fs_1 = require("@ionic/utils-fs");
const utils_process_1 = require("@ionic/utils-process");
const utils_stream_1 = require("@ionic/utils-stream");
const utils_terminal_1 = require("@ionic/utils-terminal");
const child_process_1 = require("child_process");
const crossSpawn = require("cross-spawn");
const os = require("os");
const pathlib = require("path");
exports.ERROR_COMMAND_NOT_FOUND = 'ERR_SUBPROCESS_COMMAND_NOT_FOUND';
exports.ERROR_NON_ZERO_EXIT = 'ERR_SUBPROCESS_NON_ZERO_EXIT';
exports.ERROR_SIGNAL_EXIT = 'ERR_SUBPROCESS_SIGNAL_EXIT';
exports.TILDE_PATH_REGEX = /^~($|\/|\\)/;
function expandTildePath(p) {
    const h = os.homedir();
    return p.replace(exports.TILDE_PATH_REGEX, `${h}$1`);
}
exports.expandTildePath = expandTildePath;
/**
 * Prepare the PATH environment variable for use with subprocesses.
 *
 * If a raw tilde is found in PATH, e.g. `~/.bin`, it is expanded. The raw
 * tilde works in Bash, but not in Node's `child_process` outside of a shell.
 *
 * This is a utility method. You do not need to use it with `Subprocess`.
 *
 * @param path Defaults to `process.env.PATH`
 */
function convertPATH(path = process.env.PATH || '') {
    return path.split(pathlib.delimiter).map(expandTildePath).join(pathlib.delimiter);
}
exports.convertPATH = convertPATH;
class SubprocessError extends Error {
    constructor(message) {
        super(message);
        this.name = 'SubprocessError';
        this.message = message;
        this.stack = (new Error()).stack || '';
    }
}
exports.SubprocessError = SubprocessError;
class Subprocess {
    constructor(name, args, options = {}) {
        this.name = name;
        this.args = args;
        const masked = this.maskArg(name);
        if (masked !== name) {
            this.name = masked;
            this.path = name;
        }
        this._options = options;
    }
    get options() {
        const opts = this._options;
        if (!opts.env) {
            opts.env = process.env;
        }
        const env = utils_process_1.createProcessEnv(opts.env || {}, {
            PATH: convertPATH(typeof opts.env.PATH === 'string' ? opts.env.PATH : process.env.PATH),
        });
        return { ...opts, env };
    }
    async output() {
        this._options.stdio = 'pipe';
        const promise = this.run();
        const stdoutBuf = new utils_stream_1.WritableStreamBuffer();
        const stderrBuf = new utils_stream_1.WritableStreamBuffer();
        const combinedBuf = new utils_stream_1.WritableStreamBuffer();
        promise.p.stdout.pipe(stdoutBuf);
        promise.p.stdout.pipe(combinedBuf);
        promise.p.stderr.pipe(stderrBuf);
        promise.p.stderr.pipe(combinedBuf);
        try {
            await promise;
        }
        catch (e) {
            stdoutBuf.end();
            stderrBuf.end();
            e.output = combinedBuf.consume().toString();
            throw e;
        }
        stderrBuf.end();
        combinedBuf.end();
        return stdoutBuf.consume().toString();
    }
    async combinedOutput() {
        this._options.stdio = 'pipe';
        const promise = this.run();
        const buf = new utils_stream_1.WritableStreamBuffer();
        promise.p.stdout.pipe(buf);
        promise.p.stderr.pipe(buf);
        try {
            await promise;
        }
        catch (e) {
            e.output = buf.consume().toString();
            throw e;
        }
        return buf.consume().toString();
    }
    run() {
        const p = this.spawn();
        const promise = new Promise((resolve, reject) => {
            p.on('error', (error) => {
                let err;
                if (error.code === 'ENOENT') {
                    err = new SubprocessError('Command not found.');
                    err.code = exports.ERROR_COMMAND_NOT_FOUND;
                }
                else {
                    err = new SubprocessError('Command error.');
                }
                err.error = error;
                reject(err);
            });
            p.on('close', (code, signal) => {
                let err;
                if (code === 0) {
                    return resolve();
                }
                if (signal) {
                    err = new SubprocessError('Signal exit from subprocess.');
                    err.code = exports.ERROR_SIGNAL_EXIT;
                    err.signal = signal;
                }
                else {
                    err = new SubprocessError('Non-zero exit from subprocess.');
                    err.code = exports.ERROR_NON_ZERO_EXIT;
                    err.exitCode = code;
                }
                reject(err);
            });
        });
        Object.defineProperties(promise, {
            p: { value: p },
        });
        return promise;
    }
    spawn() {
        return spawn(this.path ? this.path : this.name, this.args, this.options);
    }
    bashify({ maskArgv0 = true, maskArgv1 = false, shiftArgv0 = false } = {}) {
        const args = [this.path ? this.path : this.name, ...this.args];
        if (shiftArgv0) {
            args.shift();
        }
        if (args[0] && maskArgv0) {
            args[0] = this.maskArg(args[0]);
        }
        if (args[1] && maskArgv1) {
            args[1] = this.maskArg(args[1]);
        }
        return args.length > 0
            ? args.map(arg => this.bashifyArg(arg)).join(' ')
            : '';
    }
    bashifyArg(arg) {
        return arg.includes(' ') ? `"${arg.replace(/\"/g, '\\"')}"` : arg;
    }
    maskArg(arg) {
        const i = arg.lastIndexOf(pathlib.sep);
        return i >= 0 ? arg.substring(i + 1) : arg;
    }
}
exports.Subprocess = Subprocess;
function spawn(command, args = [], options) {
    return crossSpawn(command, [...args], options);
}
exports.spawn = spawn;
function fork(modulePath, args = [], options = {}) {
    return child_process_1.fork(modulePath, [...args], options);
}
exports.fork = fork;
const DEFAULT_PATHEXT = utils_terminal_1.TERMINAL_INFO.windows ? '.COM;.EXE;.BAT;.CMD' : undefined;
/**
 * Find the first instance of a program in PATH.
 *
 * If `program` contains a path separator, this function will merely return it.
 *
 * @param program A command name, such as `ionic`
 */
async function which(program, { PATH = process.env.PATH, PATHEXT = process.env.PATHEXT || DEFAULT_PATHEXT } = {}) {
    if (program.includes(pathlib.sep)) {
        return program;
    }
    const results = await _findExecutables(program, { PATH });
    if (!results.length) {
        const err = new Error(`${program} cannot be found within PATH`);
        err.code = 'ENOENT';
        throw err;
    }
    return results[0];
}
exports.which = which;
/**
 * Find all instances of a program in PATH.
 *
 * If `program` contains a path separator, this function will merely return it
 * inside an array.
 *
 * @param program A command name, such as `ionic`
 */
async function findExecutables(program, { PATH = process.env.PATH, PATHEXT = process.env.PATHEXT || DEFAULT_PATHEXT } = {}) {
    if (program.includes(pathlib.sep)) {
        return [program];
    }
    return _findExecutables(program, { PATH });
}
exports.findExecutables = findExecutables;
async function _findExecutables(program, { PATH = process.env.PATH, PATHEXT = process.env.PATHEXT || DEFAULT_PATHEXT } = {}) {
    const pathParts = utils_process_1.getPathParts(PATH);
    let programNames;
    // if windows, cycle through all possible executable extensions
    // ex: node.exe, npm.cmd, etc.
    if (utils_terminal_1.TERMINAL_INFO.windows) {
        const exts = utils_process_1.getPathParts(PATHEXT).map(ext => ext.toLowerCase());
        // don't append extensions if one has already been provided
        programNames = exts.includes(pathlib.extname(program).toLowerCase()) ? [program] : exts.map(ext => program + ext);
    }
    else {
        programNames = [program];
    }
    return [].concat(...await utils_array_1.map(programNames, async (programName) => utils_array_1.concurrentFilter(pathParts.map(p => pathlib.join(p, programName)), async (p) => utils_fs_1.isExecutableFile(p))));
}
