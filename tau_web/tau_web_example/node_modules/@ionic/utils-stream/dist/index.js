"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.growBufferForAppendedData = exports.WritableStreamBuffer = exports.ReadableStreamBuffer = exports.NullStream = void 0;
const stream_1 = require("stream");
const DEFAULT_CHUNK_SIZE = 4;
const DEFAULT_ALLOC_SIZE = 32;
const DEFAULT_GROW_SIZE = 16;
class NullStream extends stream_1.Writable {
    _write(chunk, encoding, callback) {
        callback();
    }
}
exports.NullStream = NullStream;
class ReadableStreamBuffer extends stream_1.Readable {
    constructor(opts) {
        super(opts);
        this._size = 0;
        this._stopped = false;
        this.buffer = Buffer.alloc(opts && opts.allocSize ? opts.allocSize : DEFAULT_ALLOC_SIZE);
        this.chunkSize = opts && opts.chunkSize ? opts.chunkSize : DEFAULT_CHUNK_SIZE;
        this.growSize = opts && opts.growSize ? opts.growSize : DEFAULT_GROW_SIZE;
    }
    get size() {
        return this._size;
    }
    get stopped() {
        return this._stopped;
    }
    _read() {
        this._send();
    }
    feed(data, encoding = 'utf8') {
        if (this._stopped) {
            throw new Error('ReadableStreamBuffer is stopped. Can no longer feed.');
        }
        const datasize = typeof data === 'string' ? Buffer.byteLength(data) : data.length;
        this.buffer = growBufferForAppendedData(this.buffer, this._size, Math.ceil(datasize / this.growSize) * this.growSize);
        if (typeof data === 'string') {
            this.buffer.write(data, this._size, datasize, encoding);
        }
        else {
            this.buffer.copy(data, this._size, 0);
        }
        this._size += datasize;
    }
    stop() {
        if (this._stopped) {
            return;
        }
        this._stopped = true;
        if (this._size === 0) {
            this.push(null);
        }
    }
    _send() {
        const chunkSize = Math.min(this.chunkSize, this._size);
        let done = false;
        if (chunkSize > 0) {
            const chunk = Buffer.alloc(chunkSize);
            this.buffer.copy(chunk, 0, 0, chunkSize);
            done = !this.push(chunk);
            this.buffer.copy(this.buffer, 0, chunkSize, this._size);
            this._size -= chunkSize;
        }
        if (this._size === 0 && this._stopped) {
            this.push(null);
        }
        if (!done) {
            setTimeout(() => this._send(), 1);
        }
    }
}
exports.ReadableStreamBuffer = ReadableStreamBuffer;
class WritableStreamBuffer extends stream_1.Writable {
    constructor(opts) {
        super(opts);
        this._size = 0;
        this.buffer = Buffer.alloc(opts && opts.allocSize ? opts.allocSize : DEFAULT_ALLOC_SIZE);
        this.growSize = opts && opts.growSize ? opts.growSize : DEFAULT_GROW_SIZE;
    }
    get size() {
        return this._size;
    }
    _write(chunk, encoding, callback) {
        this.buffer = growBufferForAppendedData(this.buffer, this._size, Math.ceil(chunk.length / this.growSize) * this.growSize);
        chunk.copy(this.buffer, this._size, 0);
        this._size += chunk.length;
        callback();
    }
    consume(bytes) {
        bytes = typeof bytes === 'number' ? bytes : this._size;
        const data = Buffer.alloc(bytes);
        this.buffer.copy(data, 0, 0, data.length);
        this.buffer.copy(this.buffer, 0, data.length);
        this._size -= data.length;
        return data;
    }
}
exports.WritableStreamBuffer = WritableStreamBuffer;
function growBufferForAppendedData(buf, actualsize, appendsize) {
    if ((buf.length - actualsize) >= appendsize) {
        return buf;
    }
    const newbuffer = Buffer.alloc(buf.length + appendsize);
    buf.copy(newbuffer, 0, 0, actualsize);
    return newbuffer;
}
exports.growBufferForAppendedData = growBufferForAppendedData;
