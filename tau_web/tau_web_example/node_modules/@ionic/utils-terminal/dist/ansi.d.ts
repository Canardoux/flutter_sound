/**
 * ANSI escape codes (WIP)
 *
 * @see https://en.wikipedia.org/wiki/ANSI_escape_code
 */
export declare class EscapeCode {
    static readonly cursorLeft: () => string;
    static readonly cursorUp: (count?: number) => string;
    static readonly cursorDown: (count?: number) => string;
    static readonly cursorForward: (count?: number) => string;
    static readonly cursorBackward: (count?: number) => string;
    static readonly cursorHide: () => string;
    static readonly cursorShow: () => string;
    static readonly eraseLine: () => string;
    static readonly eraseLines: (count: number) => string;
    static readonly eraseUp: () => string;
    static readonly eraseDown: () => string;
    static readonly eraseScreen: () => string;
}
