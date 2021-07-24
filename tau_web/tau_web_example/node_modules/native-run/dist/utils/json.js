"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.stringify = void 0;
function stringify(obj) {
    return JSON.stringify(obj, (k, v) => (v instanceof RegExp ? v.toString() : v), '\t');
}
exports.stringify = stringify;
