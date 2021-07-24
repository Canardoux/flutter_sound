import sliceAnsi = require('slice-ansi');
import stringWidth = require('string-width');
import stripAnsi = require('strip-ansi');
export { sliceAnsi, stringWidth, stripAnsi };
export declare const TTY_WIDTH: number;
export declare function indent(n?: number): string;
export interface WordWrapOptions {
    width?: number;
    indentation?: number;
    append?: string;
}
export declare function wordWrap(msg: string, { width, indentation, append }: WordWrapOptions): string;
export declare function prettyPath(p: string): string;
export declare function expandPath(p: string): string;
export declare function generateFillSpaceStringList(list: string[], optimalLength?: number, fillCharacter?: string): string[];
export interface ColumnarOptions {
    hsep?: string;
    vsep?: string;
    headers?: string[];
}
/**
 * Basic CLI table generator with support for ANSI colors.
 *
 * @param rows 2-dimensional matrix containing cells. An array of columns,
 *             which are arrays of cells.
 * @param options.vsep The vertical separator character, default is
 *                     `chalk.dim('|')`. Supply an empty string to hide
 *                     the separator altogether.
 * @param options.hsep The horizontal separator character, default is
 *                     `chalk.dim('-')`. This is used under the headers,
 *                     if supplied. Supply an empty string to hide the
 *                     separator altogether.
 * @param options.headers An array of header cells.
 */
export declare function columnar(rows: string[][], { hsep, vsep, headers }: ColumnarOptions): string;
