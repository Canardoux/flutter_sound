"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AFCProtocolWriter = exports.AFCProtocolReader = exports.AFCProtocolClient = exports.AFCError = exports.AFC_FILE_OPEN_FLAGS = exports.AFC_STATUS = exports.AFC_OPS = exports.AFC_HEADER_SIZE = exports.AFC_MAGIC = void 0;
const Debug = require("debug");
const protocol_1 = require("./protocol");
const debug = Debug('native-run:ios:lib:protocol:afc');
exports.AFC_MAGIC = 'CFA6LPAA';
exports.AFC_HEADER_SIZE = 40;
/**
 * AFC Operations
 */
var AFC_OPS;
(function (AFC_OPS) {
    /**
     * Invalid
     */
    AFC_OPS[AFC_OPS["INVALID"] = 0] = "INVALID";
    /**
     * Status
     */
    AFC_OPS[AFC_OPS["STATUS"] = 1] = "STATUS";
    /**
     * Data
     */
    AFC_OPS[AFC_OPS["DATA"] = 2] = "DATA";
    /**
     * ReadDir
     */
    AFC_OPS[AFC_OPS["READ_DIR"] = 3] = "READ_DIR";
    /**
     * ReadFile
     */
    AFC_OPS[AFC_OPS["READ_FILE"] = 4] = "READ_FILE";
    /**
     * WriteFile
     */
    AFC_OPS[AFC_OPS["WRITE_FILE"] = 5] = "WRITE_FILE";
    /**
     * WritePart
     */
    AFC_OPS[AFC_OPS["WRITE_PART"] = 6] = "WRITE_PART";
    /**
     * TruncateFile
     */
    AFC_OPS[AFC_OPS["TRUNCATE"] = 7] = "TRUNCATE";
    /**
     * RemovePath
     */
    AFC_OPS[AFC_OPS["REMOVE_PATH"] = 8] = "REMOVE_PATH";
    /**
     * MakeDir
     */
    AFC_OPS[AFC_OPS["MAKE_DIR"] = 9] = "MAKE_DIR";
    /**
     * GetFileInfo
     */
    AFC_OPS[AFC_OPS["GET_FILE_INFO"] = 10] = "GET_FILE_INFO";
    /**
     * GetDeviceInfo
     */
    AFC_OPS[AFC_OPS["GET_DEVINFO"] = 11] = "GET_DEVINFO";
    /**
     * WriteFileAtomic (tmp file+rename)
     */
    AFC_OPS[AFC_OPS["WRITE_FILE_ATOM"] = 12] = "WRITE_FILE_ATOM";
    /**
     * FileRefOpen
     */
    AFC_OPS[AFC_OPS["FILE_OPEN"] = 13] = "FILE_OPEN";
    /**
     * FileRefOpenResult
     */
    AFC_OPS[AFC_OPS["FILE_OPEN_RES"] = 14] = "FILE_OPEN_RES";
    /**
     * FileRefRead
     */
    AFC_OPS[AFC_OPS["FILE_READ"] = 15] = "FILE_READ";
    /**
     * FileRefWrite
     */
    AFC_OPS[AFC_OPS["FILE_WRITE"] = 16] = "FILE_WRITE";
    /**
     * FileRefSeek
     */
    AFC_OPS[AFC_OPS["FILE_SEEK"] = 17] = "FILE_SEEK";
    /**
     * FileRefTell
     */
    AFC_OPS[AFC_OPS["FILE_TELL"] = 18] = "FILE_TELL";
    /**
     * FileRefTellResult
     */
    AFC_OPS[AFC_OPS["FILE_TELL_RES"] = 19] = "FILE_TELL_RES";
    /**
     * FileRefClose
     */
    AFC_OPS[AFC_OPS["FILE_CLOSE"] = 20] = "FILE_CLOSE";
    /**
     * FileRefSetFileSize (ftruncate)
     */
    AFC_OPS[AFC_OPS["FILE_SET_SIZE"] = 21] = "FILE_SET_SIZE";
    /**
     * GetConnectionInfo
     */
    AFC_OPS[AFC_OPS["GET_CON_INFO"] = 22] = "GET_CON_INFO";
    /**
     * SetConnectionOptions
     */
    AFC_OPS[AFC_OPS["SET_CON_OPTIONS"] = 23] = "SET_CON_OPTIONS";
    /**
     * RenamePath
     */
    AFC_OPS[AFC_OPS["RENAME_PATH"] = 24] = "RENAME_PATH";
    /**
     * SetFSBlockSize (0x800000)
     */
    AFC_OPS[AFC_OPS["SET_FS_BS"] = 25] = "SET_FS_BS";
    /**
     * SetSocketBlockSize (0x800000)
     */
    AFC_OPS[AFC_OPS["SET_SOCKET_BS"] = 26] = "SET_SOCKET_BS";
    /**
     * FileRefLock
     */
    AFC_OPS[AFC_OPS["FILE_LOCK"] = 27] = "FILE_LOCK";
    /**
     * MakeLink
     */
    AFC_OPS[AFC_OPS["MAKE_LINK"] = 28] = "MAKE_LINK";
    /**
     * GetFileHash
     */
    AFC_OPS[AFC_OPS["GET_FILE_HASH"] = 29] = "GET_FILE_HASH";
    /**
     * SetModTime
     */
    AFC_OPS[AFC_OPS["SET_FILE_MOD_TIME"] = 30] = "SET_FILE_MOD_TIME";
    /**
     * GetFileHashWithRange
     */
    AFC_OPS[AFC_OPS["GET_FILE_HASH_RANGE"] = 31] = "GET_FILE_HASH_RANGE";
    // iOS 6+
    /**
     * FileRefSetImmutableHint
     */
    AFC_OPS[AFC_OPS["FILE_SET_IMMUTABLE_HINT"] = 32] = "FILE_SET_IMMUTABLE_HINT";
    /**
     * GetSizeOfPathContents
     */
    AFC_OPS[AFC_OPS["GET_SIZE_OF_PATH_CONTENTS"] = 33] = "GET_SIZE_OF_PATH_CONTENTS";
    /**
     * RemovePathAndContents
     */
    AFC_OPS[AFC_OPS["REMOVE_PATH_AND_CONTENTS"] = 34] = "REMOVE_PATH_AND_CONTENTS";
    /**
     * DirectoryEnumeratorRefOpen
     */
    AFC_OPS[AFC_OPS["DIR_OPEN"] = 35] = "DIR_OPEN";
    /**
     * DirectoryEnumeratorRefOpenResult
     */
    AFC_OPS[AFC_OPS["DIR_OPEN_RESULT"] = 36] = "DIR_OPEN_RESULT";
    /**
     * DirectoryEnumeratorRefRead
     */
    AFC_OPS[AFC_OPS["DIR_READ"] = 37] = "DIR_READ";
    /**
     * DirectoryEnumeratorRefClose
     */
    AFC_OPS[AFC_OPS["DIR_CLOSE"] = 38] = "DIR_CLOSE";
    // iOS 7+
    /**
     * FileRefReadWithOffset
     */
    AFC_OPS[AFC_OPS["FILE_READ_OFFSET"] = 39] = "FILE_READ_OFFSET";
    /**
     * FileRefWriteWithOffset
     */
    AFC_OPS[AFC_OPS["FILE_WRITE_OFFSET"] = 40] = "FILE_WRITE_OFFSET";
})(AFC_OPS = exports.AFC_OPS || (exports.AFC_OPS = {}));
/**
 * Error Codes
 */
var AFC_STATUS;
(function (AFC_STATUS) {
    AFC_STATUS[AFC_STATUS["SUCCESS"] = 0] = "SUCCESS";
    AFC_STATUS[AFC_STATUS["UNKNOWN_ERROR"] = 1] = "UNKNOWN_ERROR";
    AFC_STATUS[AFC_STATUS["OP_HEADER_INVALID"] = 2] = "OP_HEADER_INVALID";
    AFC_STATUS[AFC_STATUS["NO_RESOURCES"] = 3] = "NO_RESOURCES";
    AFC_STATUS[AFC_STATUS["READ_ERROR"] = 4] = "READ_ERROR";
    AFC_STATUS[AFC_STATUS["WRITE_ERROR"] = 5] = "WRITE_ERROR";
    AFC_STATUS[AFC_STATUS["UNKNOWN_PACKET_TYPE"] = 6] = "UNKNOWN_PACKET_TYPE";
    AFC_STATUS[AFC_STATUS["INVALID_ARG"] = 7] = "INVALID_ARG";
    AFC_STATUS[AFC_STATUS["OBJECT_NOT_FOUND"] = 8] = "OBJECT_NOT_FOUND";
    AFC_STATUS[AFC_STATUS["OBJECT_IS_DIR"] = 9] = "OBJECT_IS_DIR";
    AFC_STATUS[AFC_STATUS["PERM_DENIED"] = 10] = "PERM_DENIED";
    AFC_STATUS[AFC_STATUS["SERVICE_NOT_CONNECTED"] = 11] = "SERVICE_NOT_CONNECTED";
    AFC_STATUS[AFC_STATUS["OP_TIMEOUT"] = 12] = "OP_TIMEOUT";
    AFC_STATUS[AFC_STATUS["TOO_MUCH_DATA"] = 13] = "TOO_MUCH_DATA";
    AFC_STATUS[AFC_STATUS["END_OF_DATA"] = 14] = "END_OF_DATA";
    AFC_STATUS[AFC_STATUS["OP_NOT_SUPPORTED"] = 15] = "OP_NOT_SUPPORTED";
    AFC_STATUS[AFC_STATUS["OBJECT_EXISTS"] = 16] = "OBJECT_EXISTS";
    AFC_STATUS[AFC_STATUS["OBJECT_BUSY"] = 17] = "OBJECT_BUSY";
    AFC_STATUS[AFC_STATUS["NO_SPACE_LEFT"] = 18] = "NO_SPACE_LEFT";
    AFC_STATUS[AFC_STATUS["OP_WOULD_BLOCK"] = 19] = "OP_WOULD_BLOCK";
    AFC_STATUS[AFC_STATUS["IO_ERROR"] = 20] = "IO_ERROR";
    AFC_STATUS[AFC_STATUS["OP_INTERRUPTED"] = 21] = "OP_INTERRUPTED";
    AFC_STATUS[AFC_STATUS["OP_IN_PROGRESS"] = 22] = "OP_IN_PROGRESS";
    AFC_STATUS[AFC_STATUS["INTERNAL_ERROR"] = 23] = "INTERNAL_ERROR";
    AFC_STATUS[AFC_STATUS["MUX_ERROR"] = 30] = "MUX_ERROR";
    AFC_STATUS[AFC_STATUS["NO_MEM"] = 31] = "NO_MEM";
    AFC_STATUS[AFC_STATUS["NOT_ENOUGH_DATA"] = 32] = "NOT_ENOUGH_DATA";
    AFC_STATUS[AFC_STATUS["DIR_NOT_EMPTY"] = 33] = "DIR_NOT_EMPTY";
    AFC_STATUS[AFC_STATUS["FORCE_SIGNED_TYPE"] = -1] = "FORCE_SIGNED_TYPE";
})(AFC_STATUS = exports.AFC_STATUS || (exports.AFC_STATUS = {}));
var AFC_FILE_OPEN_FLAGS;
(function (AFC_FILE_OPEN_FLAGS) {
    /**
     * r (O_RDONLY)
     */
    AFC_FILE_OPEN_FLAGS[AFC_FILE_OPEN_FLAGS["RDONLY"] = 1] = "RDONLY";
    /**
     * r+ (O_RDWR | O_CREAT)
     */
    AFC_FILE_OPEN_FLAGS[AFC_FILE_OPEN_FLAGS["RW"] = 2] = "RW";
    /**
     * w (O_WRONLY | O_CREAT | O_TRUNC)
     */
    AFC_FILE_OPEN_FLAGS[AFC_FILE_OPEN_FLAGS["WRONLY"] = 3] = "WRONLY";
    /**
     * w+ (O_RDWR | O_CREAT  | O_TRUNC)
     */
    AFC_FILE_OPEN_FLAGS[AFC_FILE_OPEN_FLAGS["WR"] = 4] = "WR";
    /**
     * a (O_WRONLY | O_APPEND | O_CREAT)
     */
    AFC_FILE_OPEN_FLAGS[AFC_FILE_OPEN_FLAGS["APPEND"] = 5] = "APPEND";
    /**
     * a+ (O_RDWR | O_APPEND | O_CREAT)
     */
    AFC_FILE_OPEN_FLAGS[AFC_FILE_OPEN_FLAGS["RDAPPEND"] = 6] = "RDAPPEND";
})(AFC_FILE_OPEN_FLAGS = exports.AFC_FILE_OPEN_FLAGS || (exports.AFC_FILE_OPEN_FLAGS = {}));
function isAFCResponse(resp) {
    return (AFC_OPS[resp.operation] !== undefined &&
        resp.id !== undefined &&
        resp.data !== undefined);
}
function isStatusResponse(resp) {
    return isAFCResponse(resp) && resp.operation === AFC_OPS.STATUS;
}
function isErrorStatusResponse(resp) {
    return isStatusResponse(resp) && resp.data !== AFC_STATUS.SUCCESS;
}
class AFCInternalError extends Error {
    constructor(msg, requestId) {
        super(msg);
        this.requestId = requestId;
    }
}
class AFCError extends Error {
    constructor(msg, status) {
        super(msg);
        this.status = status;
    }
}
exports.AFCError = AFCError;
class AFCProtocolClient extends protocol_1.ProtocolClient {
    constructor(socket) {
        super(socket, new protocol_1.ProtocolReaderFactory(AFCProtocolReader), new AFCProtocolWriter());
        this.requestId = 0;
        this.requestCallbacks = {};
        const reader = this.readerFactory.create((resp, err) => {
            if (err && err instanceof AFCInternalError) {
                this.requestCallbacks[err.requestId](resp, err);
            }
            else if (isErrorStatusResponse(resp)) {
                this.requestCallbacks[resp.id](resp, new AFCError(AFC_STATUS[resp.data], resp.data));
            }
            else {
                this.requestCallbacks[resp.id](resp);
            }
        });
        socket.on('data', reader.onData);
    }
    sendMessage(msg) {
        return new Promise((resolve, reject) => {
            const requestId = this.requestId++;
            this.requestCallbacks[requestId] = async (resp, err) => {
                if (err) {
                    reject(err);
                    return;
                }
                if (isAFCResponse(resp)) {
                    resolve(resp);
                }
                else {
                    reject(new Error('Malformed AFC response'));
                }
            };
            this.writer.write(this.socket, { ...msg, requestId });
        });
    }
}
exports.AFCProtocolClient = AFCProtocolClient;
class AFCProtocolReader extends protocol_1.ProtocolReader {
    constructor(callback) {
        super(exports.AFC_HEADER_SIZE, callback);
    }
    parseHeader(data) {
        const magic = data.slice(0, 8).toString('ascii');
        if (magic !== exports.AFC_MAGIC) {
            throw new AFCInternalError(`Invalid AFC packet received (magic != ${exports.AFC_MAGIC})`, data.readUInt32LE(24));
        }
        // technically these are uint64
        this.header = {
            magic,
            totalLength: data.readUInt32LE(8),
            headerLength: data.readUInt32LE(16),
            requestId: data.readUInt32LE(24),
            operation: data.readUInt32LE(32),
        };
        debug(`parse header: ${JSON.stringify(this.header)}`);
        if (this.header.headerLength < exports.AFC_HEADER_SIZE) {
            throw new AFCInternalError('Invalid AFC header', this.header.requestId);
        }
        return this.header.totalLength - exports.AFC_HEADER_SIZE;
    }
    parseBody(data) {
        const body = {
            operation: this.header.operation,
            id: this.header.requestId,
            data,
        };
        if (isStatusResponse(body)) {
            const status = data.readUInt32LE(0);
            debug(`${AFC_OPS[this.header.operation]} response: ${AFC_STATUS[status]}`);
            body.data = status;
        }
        else if (data.length <= 8) {
            debug(`${AFC_OPS[this.header.operation]} response: ${Array.prototype.toString.call(body)}`);
        }
        else {
            debug(`${AFC_OPS[this.header.operation]} response length: ${data.length} bytes`);
        }
        return body;
    }
}
exports.AFCProtocolReader = AFCProtocolReader;
class AFCProtocolWriter {
    write(socket, msg) {
        const { data, payload, operation, requestId } = msg;
        const dataLength = data ? data.length : 0;
        const payloadLength = payload ? payload.length : 0;
        const header = Buffer.alloc(exports.AFC_HEADER_SIZE);
        const magic = Buffer.from(exports.AFC_MAGIC);
        magic.copy(header);
        header.writeUInt32LE(exports.AFC_HEADER_SIZE + dataLength + payloadLength, 8);
        header.writeUInt32LE(exports.AFC_HEADER_SIZE + dataLength, 16);
        header.writeUInt32LE(requestId, 24);
        header.writeUInt32LE(operation, 32);
        socket.write(header);
        socket.write(data);
        if (data.length <= 8) {
            debug(`socket write, header: { requestId: ${requestId}, operation: ${AFC_OPS[operation]}}, body: ${Array.prototype.toString.call(data)}`);
        }
        else {
            debug(`socket write, header: { requestId: ${requestId}, operation: ${AFC_OPS[operation]}}, body: ${data.length} bytes`);
        }
        debug(`socket write, bytes written ${header.length} (header), ${data.length} (body)`);
        if (payload) {
            socket.write(payload);
        }
    }
}
exports.AFCProtocolWriter = AFCProtocolWriter;
