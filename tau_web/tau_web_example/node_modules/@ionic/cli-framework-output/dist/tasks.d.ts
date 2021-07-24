/// <reference types="node" />
import { EventEmitter } from 'events';
export declare const ICON_SUCCESS: string;
export declare const ICON_FAILURE: string;
export declare class Spinner {
    frames: string[];
    i: number;
    constructor(frames?: string[]);
    frame(): string;
}
export interface TaskOptions {
    readonly msg?: string;
    readonly tickInterval?: number;
}
export interface TaskResult {
    /**
     * Elapsed time from process.hrtime()
     */
    elapsedTime: [number, number];
    /**
     * Whether the task succeeded or not
     */
    success: boolean;
}
export interface Task extends EventEmitter {
    on(name: 'success', handler: () => void): this;
    on(name: 'failure', handler: () => void): this;
    on(name: 'clear', handler: () => void): this;
    on(name: 'tick', handler: () => void): this;
    on(name: 'end', handler: (result: TaskResult) => void): this;
    emit(name: 'success'): boolean;
    emit(name: 'failure'): boolean;
    emit(name: 'clear'): boolean;
    emit(name: 'tick'): boolean;
    emit(name: 'end', result: TaskResult): boolean;
}
export declare class Task extends EventEmitter {
    tickInterval?: number;
    intervalId?: NodeJS.Timer;
    running: boolean;
    progressRatio?: number;
    protected _msg: string;
    protected _startTime?: [number, number];
    protected _success: boolean;
    constructor({ msg, tickInterval }?: TaskOptions);
    get msg(): string;
    set msg(msg: string);
    start(): this;
    tick(): this;
    progress(prog: number, total: number): this;
    clear(): this;
    end(): this;
    succeed(): this;
    fail(): this;
}
export interface TaskChain extends EventEmitter {
    on(name: 'end', handler: (lastTask?: Task) => void): this;
    on(name: 'failure', handler: (failedTask?: Task) => void): this;
    on(name: 'next', handler: (task: Task) => void): this;
    emit(name: 'end', lastTask?: Task): boolean;
    emit(name: 'failure', failedTask?: Task): boolean;
    emit(name: 'next', task: Task): boolean;
}
export interface TaskChainOptions {
    readonly taskOptions?: Partial<TaskOptions>;
}
export declare class TaskChain extends EventEmitter {
    protected current?: Task;
    protected readonly tasks: Task[];
    protected readonly taskOptions: Partial<TaskOptions>;
    constructor({ taskOptions }?: TaskChainOptions);
    next(msg: string): Task;
    createTask(options: TaskOptions): Task;
    nextTask(task: Task): Task;
    end(): this;
    fail(): this;
    cleanup(): this;
}
