"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.parseAndroidConsoleResponse = exports.getAVDFromEmulator = exports.parseEmulatorOutput = exports.EmulatorEvent = exports.spawnEmulator = exports.runEmulator = void 0;
const utils_fs_1 = require("@ionic/utils-fs");
const child_process_1 = require("child_process");
const Debug = require("debug");
const net = require("net");
const os = require("os");
const path = require("path");
const split2 = require("split2");
const through2 = require("through2");
const errors_1 = require("../../errors");
const fn_1 = require("../../utils/fn");
const adb_1 = require("./adb");
const sdk_1 = require("./sdk");
const modulePrefix = 'native-run:android:utils:emulator';
/**
 * Resolves when emulator is ready and running with the specified AVD.
 */
async function runEmulator(sdk, avd, port) {
    try {
        await spawnEmulator(sdk, avd, port);
    }
    catch (e) {
        if (!(e instanceof errors_1.EmulatorException) || e.code !== errors_1.ERR_ALREADY_RUNNING) {
            throw e;
        }
    }
    const serial = `emulator-${port}`;
    const devices = await adb_1.getDevices(sdk);
    const emulator = devices.find(device => device.serial === serial);
    if (!emulator) {
        throw new errors_1.EmulatorException(`Emulator not found: ${serial}`);
    }
    return emulator;
}
exports.runEmulator = runEmulator;
async function spawnEmulator(sdk, avd, port) {
    const debug = Debug(`${modulePrefix}:${spawnEmulator.name}`);
    const emulator = await sdk_1.getSDKPackage(path.join(sdk.root, 'emulator'));
    const emulatorBin = path.join(emulator.location, 'emulator');
    const args = ['-avd', avd.id, '-port', port.toString(), '-verbose'];
    debug('Invoking emulator: %O %O', emulatorBin, args);
    const p = child_process_1.spawn(emulatorBin, args, {
        detached: true,
        stdio: ['ignore', 'pipe', 'pipe'],
        env: sdk_1.supplementProcessEnv(sdk),
    });
    p.unref();
    return new Promise((_resolve, _reject) => {
        const resolve = fn_1.once(() => {
            _resolve();
            cleanup();
        });
        const reject = fn_1.once(err => {
            _reject(err);
            cleanup();
        });
        adb_1.waitForDevice(sdk, `emulator-${port}`).then(() => resolve(), err => reject(err));
        const eventParser = through2((chunk, enc, cb) => {
            const line = chunk.toString();
            debug('Android Emulator: %O', line);
            const event = parseEmulatorOutput(line);
            if (event === EmulatorEvent.AlreadyRunning) {
                reject(new errors_1.EmulatorException(`Emulator already running with AVD [${avd.id}]`, errors_1.ERR_ALREADY_RUNNING));
            }
            else if (event === EmulatorEvent.UnknownAVD) {
                reject(new errors_1.EmulatorException(`Unknown AVD name [${avd.id}]`, errors_1.ERR_UNKNOWN_AVD));
            }
            else if (event === EmulatorEvent.AVDHomeNotFound) {
                reject(new errors_1.EmulatorException(`Emulator cannot find AVD home`, errors_1.ERR_AVD_HOME_NOT_FOUND));
            }
            cb();
        });
        const stdoutStream = p.stdout.pipe(split2());
        const stderrStream = p.stderr.pipe(split2());
        stdoutStream.pipe(eventParser);
        stderrStream.pipe(eventParser);
        const cleanup = () => {
            debug('Unhooking stdout/stderr streams from emulator process');
            p.stdout.push(null);
            p.stderr.push(null);
        };
        p.on('close', code => {
            debug('Emulator closed, exit code %d', code);
            if (code > 0) {
                reject(new errors_1.EmulatorException(`Non-zero exit code from Emulator: ${code}`, errors_1.ERR_NON_ZERO_EXIT));
            }
        });
        p.on('error', err => {
            debug('Emulator error: %O', err);
            reject(err);
        });
    });
}
exports.spawnEmulator = spawnEmulator;
var EmulatorEvent;
(function (EmulatorEvent) {
    EmulatorEvent[EmulatorEvent["UnknownAVD"] = 0] = "UnknownAVD";
    EmulatorEvent[EmulatorEvent["AlreadyRunning"] = 1] = "AlreadyRunning";
    EmulatorEvent[EmulatorEvent["AVDHomeNotFound"] = 2] = "AVDHomeNotFound";
})(EmulatorEvent = exports.EmulatorEvent || (exports.EmulatorEvent = {}));
function parseEmulatorOutput(line) {
    const debug = Debug(`${modulePrefix}:${parseEmulatorOutput.name}`);
    let event;
    if (line.includes('Unknown AVD name')) {
        event = EmulatorEvent.UnknownAVD;
    }
    else if (line.includes('another emulator instance running with the current AVD')) {
        event = EmulatorEvent.AlreadyRunning;
    }
    else if (line.includes('Cannot find AVD system path')) {
        event = EmulatorEvent.AVDHomeNotFound;
    }
    if (typeof event !== 'undefined') {
        debug('Parsed event from emulator output: %s', EmulatorEvent[event]);
    }
    return event;
}
exports.parseEmulatorOutput = parseEmulatorOutput;
async function getAVDFromEmulator(emulator, avds) {
    const debug = Debug(`${modulePrefix}:${getAVDFromEmulator.name}`);
    const emulatorPortRegex = /^emulator-(\d+)$/;
    const m = emulator.serial.match(emulatorPortRegex);
    if (!m) {
        throw new errors_1.EmulatorException(`Emulator ${emulator.serial} does not match expected emulator serial format`);
    }
    const port = Number.parseInt(m[1], 10);
    const host = 'localhost';
    const sock = net.createConnection({ host, port });
    sock.setEncoding('utf8');
    sock.setTimeout(5000);
    const readAuthFile = new Promise((resolve, reject) => {
        sock.on('connect', () => {
            debug('Connected to %s:%d', host, port);
            utils_fs_1.readFile(path.resolve(os.homedir(), '.emulator_console_auth_token'), {
                encoding: 'utf8',
            }).then(contents => resolve(contents.trim()), err => reject(err));
        });
    });
    let Stage;
    (function (Stage) {
        Stage[Stage["Initial"] = 0] = "Initial";
        Stage[Stage["Auth"] = 1] = "Auth";
        Stage[Stage["AuthSuccess"] = 2] = "AuthSuccess";
        Stage[Stage["Response"] = 3] = "Response";
        Stage[Stage["Complete"] = 4] = "Complete";
    })(Stage || (Stage = {}));
    return new Promise((resolve, reject) => {
        let stage = Stage.Initial;
        const timer = setTimeout(() => {
            if (stage !== Stage.Complete) {
                reject(new errors_1.EmulatorException(`Took too long to get AVD name from Android Emulator Console, something went wrong.`));
            }
        }, 3000);
        const cleanup = fn_1.once(() => {
            clearTimeout(timer);
            sock.end();
        });
        sock.on('timeout', () => {
            reject(new errors_1.EmulatorException(`Socket timeout on ${host}:${port}`));
            cleanup();
        });
        sock.pipe(split2()).pipe(through2((chunk, enc, cb) => {
            const line = chunk.toString();
            debug('Android Console: %O', line);
            if (stage === Stage.Initial &&
                line.includes('Authentication required')) {
                stage = Stage.Auth;
            }
            else if (stage === Stage.Auth && line.trim() === 'OK') {
                readAuthFile.then(token => sock.write(`auth ${token}\n`, 'utf8'), err => reject(err));
                stage = Stage.AuthSuccess;
            }
            else if (stage === Stage.AuthSuccess && line.trim() === 'OK') {
                sock.write('avd name\n', 'utf8');
                stage = Stage.Response;
            }
            else if (stage === Stage.Response) {
                const avdId = line.trim();
                const avd = avds.find(avd => avd.id === avdId);
                if (avd) {
                    resolve(avd);
                }
                else {
                    reject(new errors_1.EmulatorException(`Unknown AVD name [${avdId}]`, errors_1.ERR_UNKNOWN_AVD));
                }
                stage = Stage.Complete;
                cleanup();
            }
            cb();
        }));
    });
}
exports.getAVDFromEmulator = getAVDFromEmulator;
function parseAndroidConsoleResponse(output) {
    const debug = Debug(`${modulePrefix}:${parseAndroidConsoleResponse.name}`);
    const m = /([\s\S]+)OK\r?\n/g.exec(output);
    if (m) {
        const [, response] = m;
        debug('Parsed response data from Android Console output: %O', response);
        return response;
    }
}
exports.parseAndroidConsoleResponse = parseAndroidConsoleResponse;
