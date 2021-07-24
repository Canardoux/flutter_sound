"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.serializeError = exports.IOSRunException = exports.SDKException = exports.AndroidRunException = exports.EmulatorException = exports.AVDException = exports.ADBException = exports.CLIException = exports.ERR_UNSUPPORTED_API_LEVEL = exports.ERR_UNKNOWN_AVD = exports.ERR_DEVICE_LOCKED = exports.ERR_NO_TARGET = exports.ERR_NO_DEVICE = exports.ERR_TARGET_NOT_FOUND = exports.ERR_SDK_UNSATISFIED_PACKAGES = exports.ERR_SDK_PACKAGE_NOT_FOUND = exports.ERR_SDK_NOT_FOUND = exports.ERR_UNSUITABLE_API_INSTALLATION = exports.ERR_MISSING_SYSTEM_IMAGE = exports.ERR_NO_AVDS_FOUND = exports.ERR_NON_ZERO_EXIT = exports.ERR_INVALID_SYSTEM_IMAGE = exports.ERR_INVALID_SKIN = exports.ERR_INVALID_SERIAL = exports.ERR_INVALID_SDK_PACKAGE = exports.ERR_DEVICE_OFFLINE = exports.ERR_NOT_ENOUGH_SPACE = exports.ERR_NO_CERTIFICATES = exports.ERR_MIN_SDK_VERSION = exports.ERR_VERSION_DOWNGRADE = exports.ERR_INCOMPATIBLE_UPDATE = exports.ERR_EMULATOR_HOME_NOT_FOUND = exports.ERR_AVD_HOME_NOT_FOUND = exports.ERR_ALREADY_RUNNING = exports.ERR_BAD_INPUT = exports.AndroidException = exports.Exception = void 0;
const json_1 = require("./utils/json");
class Exception extends Error {
    constructor(message, code, exitCode = 1 /* GENERAL */, data) {
        super(message);
        this.message = message;
        this.code = code;
        this.exitCode = exitCode;
        this.data = data;
    }
    serialize() {
        return `${this.code ? this.code : 'ERR_UNKNOWN'}: ${this.message}`;
    }
    toJSON() {
        return {
            error: this.message,
            code: this.code,
            ...this.data,
        };
    }
}
exports.Exception = Exception;
class AndroidException extends Exception {
    serialize() {
        return (`${super.serialize()}\n\n` +
            `\tMore details for this error may be available online:\n\n` +
            `\thttps://github.com/ionic-team/native-run/wiki/Android-Errors`);
    }
}
exports.AndroidException = AndroidException;
exports.ERR_BAD_INPUT = 'ERR_BAD_INPUT';
exports.ERR_ALREADY_RUNNING = 'ERR_ALREADY_RUNNING ';
exports.ERR_AVD_HOME_NOT_FOUND = 'ERR_AVD_HOME_NOT_FOUND';
exports.ERR_EMULATOR_HOME_NOT_FOUND = 'ERR_EMULATOR_HOME_NOT_FOUND';
exports.ERR_INCOMPATIBLE_UPDATE = 'ERR_INCOMPATIBLE_UPDATE';
exports.ERR_VERSION_DOWNGRADE = 'ERR_VERSION_DOWNGRADE';
exports.ERR_MIN_SDK_VERSION = 'ERR_MIN_SDK_VERSION';
exports.ERR_NO_CERTIFICATES = 'ERR_NO_CERTIFICATES';
exports.ERR_NOT_ENOUGH_SPACE = 'ERR_NOT_ENOUGH_SPACE';
exports.ERR_DEVICE_OFFLINE = 'ERR_DEVICE_OFFLINE';
exports.ERR_INVALID_SDK_PACKAGE = 'ERR_INVALID_SDK_PACKAGE';
exports.ERR_INVALID_SERIAL = 'ERR_INVALID_SERIAL';
exports.ERR_INVALID_SKIN = 'ERR_INVALID_SKIN';
exports.ERR_INVALID_SYSTEM_IMAGE = 'ERR_INVALID_SYSTEM_IMAGE';
exports.ERR_NON_ZERO_EXIT = 'ERR_NON_ZERO_EXIT';
exports.ERR_NO_AVDS_FOUND = 'ERR_NO_AVDS_FOUND';
exports.ERR_MISSING_SYSTEM_IMAGE = 'ERR_MISSING_SYSTEM_IMAGE';
exports.ERR_UNSUITABLE_API_INSTALLATION = 'ERR_UNSUITABLE_API_INSTALLATION';
exports.ERR_SDK_NOT_FOUND = 'ERR_SDK_NOT_FOUND';
exports.ERR_SDK_PACKAGE_NOT_FOUND = 'ERR_SDK_PACKAGE_NOT_FOUND';
exports.ERR_SDK_UNSATISFIED_PACKAGES = 'ERR_SDK_UNSATISFIED_PACKAGES';
exports.ERR_TARGET_NOT_FOUND = 'ERR_TARGET_NOT_FOUND';
exports.ERR_NO_DEVICE = 'ERR_NO_DEVICE';
exports.ERR_NO_TARGET = 'ERR_NO_TARGET';
exports.ERR_DEVICE_LOCKED = 'ERR_DEVICE_LOCKED';
exports.ERR_UNKNOWN_AVD = 'ERR_UNKNOWN_AVD';
exports.ERR_UNSUPPORTED_API_LEVEL = 'ERR_UNSUPPORTED_API_LEVEL';
class CLIException extends Exception {
}
exports.CLIException = CLIException;
class ADBException extends AndroidException {
}
exports.ADBException = ADBException;
class AVDException extends AndroidException {
}
exports.AVDException = AVDException;
class EmulatorException extends AndroidException {
}
exports.EmulatorException = EmulatorException;
class AndroidRunException extends AndroidException {
}
exports.AndroidRunException = AndroidRunException;
class SDKException extends AndroidException {
}
exports.SDKException = SDKException;
class IOSRunException extends Exception {
}
exports.IOSRunException = IOSRunException;
function serializeError(e = new Error()) {
    const stack = String(e.stack ? e.stack : e);
    if (process.argv.includes('--json')) {
        return json_1.stringify(e instanceof Exception ? e : { error: stack });
    }
    return (e instanceof Exception ? e.serialize() : stack) + '\n';
}
exports.serializeError = serializeError;
