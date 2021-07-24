"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.once = void 0;
function once(fn) {
    let called = false;
    let r;
    const wrapper = (...args) => {
        if (!called) {
            called = true;
            r = fn(...args);
        }
        return r;
    };
    return wrapper;
}
exports.once = once;
