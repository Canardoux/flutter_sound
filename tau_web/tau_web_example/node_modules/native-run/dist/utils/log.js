"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.log = void 0;
const json_1 = require("./json");
function log(message) {
    if (process.argv.includes('--json')) {
        message = json_1.stringify({ message });
    }
    process.stdout.write(message);
}
exports.log = log;
