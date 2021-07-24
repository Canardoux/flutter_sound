"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.convertToUnixPath = void 0;
const convertToUnixPath = (path) => {
    return path.replace(/\\/g, '/');
};
exports.convertToUnixPath = convertToUnixPath;
