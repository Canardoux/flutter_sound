"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.TTYOutputRedrawer = exports.TTYOutputStrategy = exports.StreamOutputStrategy = void 0;
const utils_terminal_1 = require("@ionic/utils-terminal");
const colors_1 = require("./colors");
const tasks_1 = require("./tasks");
const utils_1 = require("./utils");
class StreamOutputStrategy {
    constructor({ stream = process.stdout, colors = colors_1.NO_COLORS }) {
        this.stream = stream;
        this.colors = colors;
    }
    write(msg) {
        return this.stream.write(msg);
    }
    createTaskChain() {
        const { failure, success, weak } = this.colors;
        const chain = new tasks_1.TaskChain();
        chain.on('next', task => {
            task.on('end', result => {
                if (result.success) {
                    this.write(`${success(tasks_1.ICON_SUCCESS)} ${task.msg} ${weak(`in ${utils_1.formatHrTime(result.elapsedTime)}`)}\n`);
                }
                else {
                    this.write(`${failure(tasks_1.ICON_FAILURE)} ${task.msg} ${failure(weak('- failed!'))}\n`);
                }
            });
        });
        return chain;
    }
}
exports.StreamOutputStrategy = StreamOutputStrategy;
class TTYOutputStrategy extends StreamOutputStrategy {
    constructor({ stream = process.stdout, colors = colors_1.NO_COLORS } = {}) {
        super({ stream, colors });
        this.stream = stream;
        this.redrawer = new TTYOutputRedrawer({ stream });
    }
    createTaskChain() {
        const { failure, strong, success, weak } = this.colors;
        const chain = new tasks_1.TaskChain({ taskOptions: { tickInterval: 50 } });
        chain.on('next', task => {
            task.on('end', result => {
                if (result.success) {
                    this.write(`${success(tasks_1.ICON_SUCCESS)} ${task.msg} ${weak(`in ${utils_1.formatHrTime(result.elapsedTime)}`)}\n`);
                }
                else {
                    this.write(`${failure(tasks_1.ICON_FAILURE)} ${task.msg} ${failure(weak('- failed!'))}\n`);
                }
            });
            const spinner = new tasks_1.Spinner();
            task.on('tick', () => {
                const progress = task.progressRatio ? (task.progressRatio * 100).toFixed(2) : '';
                const frame = spinner.frame();
                this.redrawer.redraw(`${strong(frame)} ${task.msg}${progress ? ' (' + strong(String(progress) + '%') + ')' : ''} `);
            });
            task.on('clear', () => {
                this.redrawer.clear();
            });
        });
        chain.on('end', () => {
            this.redrawer.end();
        });
        return chain;
    }
}
exports.TTYOutputStrategy = TTYOutputStrategy;
class TTYOutputRedrawer {
    constructor({ stream = process.stdout }) {
        this.stream = stream;
    }
    get width() {
        return this.stream.columns || 80;
    }
    redraw(msg) {
        utils_terminal_1.Cursor.hide();
        this.stream.write(utils_terminal_1.EscapeCode.eraseLines(1) + msg.replace(/[\r\n]+$/, ''));
    }
    clear() {
        this.stream.write(utils_terminal_1.EscapeCode.eraseLines(1));
    }
    end() {
        utils_terminal_1.Cursor.show();
    }
}
exports.TTYOutputRedrawer = TTYOutputRedrawer;
