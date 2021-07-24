"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.createDefaultLogger = exports.wordWrap = exports.stripAnsi = exports.stringWidth = exports.sliceAnsi = exports.indent = exports.TTY_WIDTH = void 0;
const tslib_1 = require("tslib");
const utils_terminal_1 = require("@ionic/utils-terminal");
Object.defineProperty(exports, "TTY_WIDTH", { enumerable: true, get: function () { return utils_terminal_1.TTY_WIDTH; } });
Object.defineProperty(exports, "indent", { enumerable: true, get: function () { return utils_terminal_1.indent; } });
Object.defineProperty(exports, "sliceAnsi", { enumerable: true, get: function () { return utils_terminal_1.sliceAnsi; } });
Object.defineProperty(exports, "stringWidth", { enumerable: true, get: function () { return utils_terminal_1.stringWidth; } });
Object.defineProperty(exports, "stripAnsi", { enumerable: true, get: function () { return utils_terminal_1.stripAnsi; } });
Object.defineProperty(exports, "wordWrap", { enumerable: true, get: function () { return utils_terminal_1.wordWrap; } });
const colors_1 = require("./colors");
const logger_1 = require("./logger");
const output_1 = require("./output");
tslib_1.__exportStar(require("./colors"), exports);
tslib_1.__exportStar(require("./logger"), exports);
tslib_1.__exportStar(require("./output"), exports);
tslib_1.__exportStar(require("./tasks"), exports);
/**
 * Creates a logger instance with good defaults.
 */
function createDefaultLogger({ output = new output_1.StreamOutputStrategy({ colors: colors_1.NO_COLORS, stream: process.stdout }), formatterOptions } = {}) {
    const { weak } = output.colors;
    const prefix = process.argv.includes('--log-timestamps') ? () => `${weak('[' + new Date().toISOString() + ']')}` : '';
    const formatter = logger_1.createTaggedFormatter({ colors: output.colors, prefix, titleize: true, wrap: true, ...formatterOptions });
    const handlers = new Set([new logger_1.StreamHandler({ stream: output.stream, formatter })]);
    return new logger_1.Logger({ handlers });
}
exports.createDefaultLogger = createDefaultLogger;
