"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getOptionValues = exports.getOptionValue = void 0;
function getOptionValue(args, arg, defaultValue) {
    const i = args.indexOf(arg);
    if (i >= 0) {
        return args[i + 1];
    }
    return defaultValue;
}
exports.getOptionValue = getOptionValue;
function getOptionValues(args, arg) {
    const returnVal = [];
    args.map((entry, idx) => {
        if (entry === arg) {
            returnVal.push(args[idx + 1]);
        }
    });
    return returnVal;
}
exports.getOptionValues = getOptionValues;
