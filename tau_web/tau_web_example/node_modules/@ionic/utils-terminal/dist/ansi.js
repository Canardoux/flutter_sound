"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.EscapeCode = void 0;
const ESC = '\u001B[';
/**
 * ANSI escape codes (WIP)
 *
 * @see https://en.wikipedia.org/wiki/ANSI_escape_code
 */
class EscapeCode {
}
exports.EscapeCode = EscapeCode;
EscapeCode.cursorLeft = () => `${ESC}G`;
EscapeCode.cursorUp = (count = 1) => `${ESC}${count}A`;
EscapeCode.cursorDown = (count = 1) => `${ESC}${count}B`;
EscapeCode.cursorForward = (count = 1) => `${ESC}${count}C`;
EscapeCode.cursorBackward = (count = 1) => `${ESC}${count}D`;
EscapeCode.cursorHide = () => `${ESC}?25l`;
EscapeCode.cursorShow = () => `${ESC}?25h`;
EscapeCode.eraseLine = () => `${ESC}2K`;
EscapeCode.eraseLines = (count) => {
    let seq = '';
    for (let i = 0; i < count; i++) {
        seq += EscapeCode.eraseLine();
        if (i < count - 1) {
            seq += EscapeCode.cursorUp();
        }
    }
    return `${seq}${EscapeCode.cursorLeft()}`;
};
EscapeCode.eraseUp = () => `${ESC}1J`;
EscapeCode.eraseDown = () => `${ESC}J`;
EscapeCode.eraseScreen = () => `${ESC}2J`;
