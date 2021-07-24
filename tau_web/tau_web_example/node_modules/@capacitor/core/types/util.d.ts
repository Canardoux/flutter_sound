import type { WindowCapacitor } from './definitions-internal';
export declare enum ExceptionCode {
    /**
     * API is not implemented.
     *
     * This usually means the API can't be used because it is not implemented for
     * the current platform.
     */
    Unimplemented = "UNIMPLEMENTED",
    /**
     * API is not available.
     *
     * This means the API can't be used right now because:
     *   - it is currently missing a prerequisite, such as network connectivity
     *   - it requires a particular platform or browser version
     */
    Unavailable = "UNAVAILABLE"
}
export declare class CapacitorException extends Error {
    readonly message: string;
    readonly code?: ExceptionCode;
    constructor(message: string, code?: ExceptionCode);
}
export declare const getPlatformId: (win: WindowCapacitor) => 'android' | 'ios' | 'web';
