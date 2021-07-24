/// <reference types="node" />
import { Readable, ReadableOptions, Writable, WritableOptions } from 'stream';
export declare class NullStream extends Writable {
    _write(chunk: any, encoding: string, callback: () => void): void;
}
export interface ReadableStreamBufferOptions extends ReadableOptions {
    chunkSize?: number;
    allocSize?: number;
    growSize?: number;
}
export declare class ReadableStreamBuffer extends Readable {
    protected buffer: Buffer;
    protected _size: number;
    protected _stopped: boolean;
    protected chunkSize: number;
    protected growSize: number;
    constructor(opts?: ReadableStreamBufferOptions);
    get size(): number;
    get stopped(): boolean;
    _read(): void;
    feed(data: Buffer | string, encoding?: string): void;
    stop(): void;
    protected _send(): void;
}
export interface WritableStreamBufferOptions extends WritableOptions {
    allocSize?: number;
    growSize?: number;
}
export declare class WritableStreamBuffer extends Writable {
    protected buffer: Buffer;
    protected _size: number;
    protected growSize: number;
    constructor(opts?: WritableStreamBufferOptions);
    get size(): number;
    _write(chunk: any, encoding: string, callback: () => void): void;
    consume(bytes?: number): Buffer;
}
export declare function growBufferForAppendedData(buf: Buffer, actualsize: number, appendsize: number): Buffer;
