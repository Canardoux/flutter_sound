"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Cursor = void 0;
const onExit = require("signal-exit");
const ansi_1 = require("./ansi");
class Cursor {
    static show() {
        if (Cursor.stream.isTTY) {
            Cursor._isVisible = true;
            Cursor.stream.write(ansi_1.EscapeCode.cursorShow());
        }
    }
    static hide() {
        if (Cursor.stream.isTTY) {
            if (!Cursor._listenerAttached) {
                onExit(() => {
                    Cursor.show();
                });
                Cursor._listenerAttached = true;
            }
            Cursor._isVisible = false;
            Cursor.stream.write(ansi_1.EscapeCode.cursorHide());
        }
    }
    static toggle() {
        if (Cursor._isVisible) {
            Cursor.hide();
        }
        else {
            Cursor.show();
        }
    }
}
exports.Cursor = Cursor;
Cursor.stream = process.stderr;
Cursor._isVisible = true;
Cursor._listenerAttached = false;
