"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.formatHrTime = exports.dropWhile = exports.enforceLF = exports.identity = void 0;
function identity(v) {
    return v;
}
exports.identity = identity;
function enforceLF(str) {
    return str.match(/[\r\n]$/) ? str : str + '\n';
}
exports.enforceLF = enforceLF;
function dropWhile(array, predicate = v => !!v) {
    let done = false;
    return array.filter(item => {
        if (done) {
            return true;
        }
        if (predicate(item)) {
            return false;
        }
        else {
            done = true;
            return true;
        }
    });
}
exports.dropWhile = dropWhile;
const TIME_UNITS = ['s', 'ms', 'μp'];
function formatHrTime(hrtime) {
    let time = hrtime[0] + hrtime[1] / 1e9;
    let index = 0;
    for (; index < TIME_UNITS.length - 1; index++, time *= 1000) {
        if (time >= 1) {
            break;
        }
    }
    return time.toFixed(2) + TIME_UNITS[index];
}
exports.formatHrTime = formatHrTime;
