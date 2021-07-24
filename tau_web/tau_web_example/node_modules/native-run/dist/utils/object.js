"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.sort = void 0;
function sort(obj) {
    const entries = [...Object.entries(obj)];
    entries.sort(([k1], [k2]) => k1.localeCompare(k2));
    for (const [key] of entries) {
        delete obj[key];
    }
    for (const [key, value] of entries) {
        obj[key] = value;
    }
    return obj;
}
exports.sort = sort;
