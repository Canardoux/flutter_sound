/// <reference types="node" />
export declare class Cursor {
    static stream: NodeJS.WriteStream;
    private static _isVisible;
    private static _listenerAttached;
    static show(): void;
    static hide(): void;
    static toggle(): void;
}
