/// <reference types="node" />
import { Colors } from './colors';
import { TaskChain } from './tasks';
export interface OutputStrategy {
    readonly stream: NodeJS.WritableStream;
    readonly colors: Colors;
    write(msg: string): boolean;
    createTaskChain(): TaskChain;
}
export interface StreamOutputStrategyOptions {
    readonly stream?: NodeJS.WritableStream;
    readonly colors?: Colors;
}
export declare class StreamOutputStrategy implements OutputStrategy {
    readonly stream: NodeJS.WritableStream;
    readonly colors: Colors;
    constructor({ stream, colors }: StreamOutputStrategyOptions);
    write(msg: string): boolean;
    createTaskChain(): TaskChain;
}
export interface TTYOutputStrategyOptions extends StreamOutputStrategyOptions {
    readonly stream?: NodeJS.WriteStream;
}
export declare class TTYOutputStrategy extends StreamOutputStrategy implements OutputStrategy {
    readonly stream: NodeJS.WriteStream;
    protected readonly redrawer: TTYOutputRedrawer;
    constructor({ stream, colors }?: TTYOutputStrategyOptions);
    createTaskChain(): TaskChain;
}
export interface TTYOutputRedrawerOptions {
    readonly stream?: NodeJS.WriteStream;
}
export declare class TTYOutputRedrawer {
    readonly stream: NodeJS.WriteStream;
    constructor({ stream }: TTYOutputRedrawerOptions);
    get width(): number;
    redraw(msg: string): void;
    clear(): void;
    end(): void;
}
