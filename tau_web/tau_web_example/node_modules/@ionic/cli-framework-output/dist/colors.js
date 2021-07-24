"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.NO_COLORS = void 0;
const utils_1 = require("./utils");
exports.NO_COLORS = Object.freeze({
    strong: utils_1.identity,
    weak: utils_1.identity,
    input: utils_1.identity,
    success: utils_1.identity,
    failure: utils_1.identity,
    ancillary: utils_1.identity,
    log: Object.freeze({
        DEBUG: utils_1.identity,
        INFO: utils_1.identity,
        WARN: utils_1.identity,
        ERROR: utils_1.identity,
    }),
});
