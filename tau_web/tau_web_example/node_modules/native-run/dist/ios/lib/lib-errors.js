"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.IOSLibError = void 0;
class IOSLibError extends Error {
    constructor(message, code) {
        super(message);
        this.code = code;
    }
}
exports.IOSLibError = IOSLibError;
