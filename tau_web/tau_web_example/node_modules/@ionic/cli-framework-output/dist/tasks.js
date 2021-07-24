"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.TaskChain = exports.Task = exports.Spinner = exports.ICON_FAILURE = exports.ICON_SUCCESS = void 0;
const events_1 = require("events");
const isWindows = process.platform === 'win32';
exports.ICON_SUCCESS = isWindows ? '√' : '✔';
exports.ICON_FAILURE = isWindows ? '×' : '✖';
const SPINNER_FRAMES = isWindows ?
    ['-', '\\', '|', '/'] :
    ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];
class Spinner {
    constructor(frames = SPINNER_FRAMES) {
        this.frames = frames;
        this.i = 0;
    }
    frame() {
        return this.frames[this.i = ++this.i % this.frames.length];
    }
}
exports.Spinner = Spinner;
class Task extends events_1.EventEmitter {
    constructor({ msg = '', tickInterval } = {}) {
        super();
        this.running = false;
        this._msg = '';
        this._success = false;
        this.msg = msg;
        this.tickInterval = tickInterval;
    }
    get msg() {
        return this._msg;
    }
    set msg(msg) {
        this._msg = msg;
        this.tick();
    }
    start() {
        if (!this.running && this.tickInterval) {
            this.intervalId = setInterval(() => { this.tick(); }, this.tickInterval);
        }
        this.running = true;
        this._startTime = process.hrtime();
        return this;
    }
    tick() {
        this.emit('tick');
        return this;
    }
    progress(prog, total) {
        this.progressRatio = prog / total;
        this.tick();
        return this;
    }
    clear() {
        if (this.intervalId) {
            clearInterval(this.intervalId);
            this.intervalId = undefined;
        }
        this.emit('clear');
        return this;
    }
    end() {
        this.running = false;
        this.tick();
        this.clear();
        this.emit('end', {
            elapsedTime: process.hrtime(this._startTime),
            success: this._success,
        });
        return this;
    }
    succeed() {
        if (this.running) {
            this._success = true;
            this.end();
            this.emit('success');
        }
        return this;
    }
    fail() {
        if (this.running) {
            this._success = false;
            this.end();
            this.emit('failure');
        }
        return this;
    }
}
exports.Task = Task;
class TaskChain extends events_1.EventEmitter {
    constructor({ taskOptions = {} } = {}) {
        super();
        this.tasks = [];
        this.taskOptions = taskOptions;
    }
    next(msg) {
        return this.nextTask(this.createTask({ msg, ...this.taskOptions }));
    }
    createTask(options) {
        return new Task(options);
    }
    nextTask(task) {
        if (this.current) {
            this.current.succeed();
        }
        this.tasks.push(task);
        this.current = task;
        task.start();
        this.emit('next', task);
        return task;
    }
    end() {
        const task = this.current;
        if (task) {
            task.succeed();
        }
        this.current = undefined;
        this.emit('end', task);
        return this;
    }
    fail() {
        const task = this.current;
        if (task) {
            task.fail();
        }
        this.emit('failure', task);
        return this;
    }
    cleanup() {
        for (const task of this.tasks) {
            if (task.running) {
                task.fail();
            }
            else {
                task.clear();
            }
        }
        return this;
    }
}
exports.TaskChain = TaskChain;
