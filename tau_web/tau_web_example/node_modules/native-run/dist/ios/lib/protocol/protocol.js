"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ProtocolClient = exports.PlistProtocolReader = exports.ProtocolReader = exports.ProtocolReaderFactory = void 0;
const bplistParser = require("bplist-parser");
const plist = require("plist");
const BPLIST_MAGIC = Buffer.from('bplist00');
class ProtocolReaderFactory {
    constructor(ProtocolReader) {
        this.ProtocolReader = ProtocolReader;
    }
    create(callback) {
        return new this.ProtocolReader(callback);
    }
}
exports.ProtocolReaderFactory = ProtocolReaderFactory;
class ProtocolReader {
    constructor(headerSize, callback) {
        this.headerSize = headerSize;
        this.callback = callback;
        this.buffer = Buffer.alloc(0);
        this.onData = this.onData.bind(this);
    }
    onData(data) {
        try {
            // if there's data, add it on to existing buffer
            this.buffer = data ? Buffer.concat([this.buffer, data]) : this.buffer;
            // we haven't gotten the body length from the header yet
            if (!this.bodyLength) {
                if (this.buffer.length < this.headerSize) {
                    // partial header, wait for rest
                    return;
                }
                this.bodyLength = this.parseHeader(this.buffer);
                // move on to body
                this.buffer = this.buffer.slice(this.headerSize);
                if (!this.buffer.length) {
                    // only got header, wait for body
                    return;
                }
            }
            if (this.buffer.length < this.bodyLength) {
                // wait for rest of body
                return;
            }
            if (this.bodyLength === -1) {
                this.callback(this.parseBody(this.buffer));
                this.buffer = Buffer.alloc(0);
            }
            else {
                this.body = this.buffer.slice(0, this.bodyLength);
                this.bodyLength -= this.body.length;
                if (!this.bodyLength) {
                    this.callback(this.parseBody(this.body));
                }
                this.buffer = this.buffer.slice(this.body.length);
                // There are multiple messages here, call parse again
                if (this.buffer.length) {
                    this.onData();
                }
            }
        }
        catch (err) {
            this.callback(null, err);
        }
    }
}
exports.ProtocolReader = ProtocolReader;
class PlistProtocolReader extends ProtocolReader {
    parseBody(body) {
        if (BPLIST_MAGIC.compare(body, 0, 8) === 0) {
            return bplistParser.parseBuffer(body);
        }
        else {
            return plist.parse(body.toString('utf8'));
        }
    }
}
exports.PlistProtocolReader = PlistProtocolReader;
class ProtocolClient {
    constructor(socket, readerFactory, writer) {
        this.socket = socket;
        this.readerFactory = readerFactory;
        this.writer = writer;
    }
    sendMessage(msg, callback) {
        return new Promise((resolve, reject) => {
            const reader = this.readerFactory.create(async (resp, err) => {
                if (err) {
                    reject(err);
                    return;
                }
                if (callback) {
                    callback(resp, (value) => {
                        this.socket.removeListener('data', reader.onData);
                        resolve(value);
                    }, reject);
                }
                else {
                    this.socket.removeListener('data', reader.onData);
                    resolve(resp);
                }
            });
            this.socket.on('data', reader.onData);
            this.writer.write(this.socket, msg);
        });
    }
}
exports.ProtocolClient = ProtocolClient;
