"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ResponseError = exports.ServiceClient = void 0;
class ServiceClient {
    constructor(socket, protocolClient) {
        this.socket = socket;
        this.protocolClient = protocolClient;
    }
}
exports.ServiceClient = ServiceClient;
class ResponseError extends Error {
    constructor(msg, response) {
        super(msg);
        this.response = response;
    }
}
exports.ResponseError = ResponseError;
