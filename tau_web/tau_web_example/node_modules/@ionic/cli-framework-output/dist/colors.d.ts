import { LoggerLevel } from './logger';
export declare type ColorFunction = (...text: string[]) => string;
export declare type LoggerColors = {
    [L in LoggerLevel]: ColorFunction;
};
export interface Colors {
    /**
     * Used to mark text as important. Comparable to HTML's <strong>.
     */
    strong: ColorFunction;
    /**
     * Used to mark text as less important.
     */
    weak: ColorFunction;
    /**
     * Used to mark text as input such as commands, inputs, options, etc.
     */
    input: ColorFunction;
    /**
     * Used to mark text as successful.
     */
    success: ColorFunction;
    /**
     * Used to mark text as failed.
     */
    failure: ColorFunction;
    /**
     * Used to mark text as ancillary or supportive.
     */
    ancillary: ColorFunction;
    log: LoggerColors;
}
export declare const NO_COLORS: Colors;
