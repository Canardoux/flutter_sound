import { TTY_WIDTH, indent, sliceAnsi, stringWidth, stripAnsi, wordWrap } from '@ionic/utils-terminal';
import { Logger, CreateTaggedFormatterOptions } from './logger';
import { OutputStrategy } from './output';
export { TTY_WIDTH, indent, sliceAnsi, stringWidth, stripAnsi, wordWrap };
export * from './colors';
export * from './logger';
export * from './output';
export * from './tasks';
export interface CreateDefaultLoggerOptions {
    /**
     * Specify a custom output strategy to use for the logger.
     *
     * By default, the logger uses a output strategy with process.stdout and no colors.
     */
    output?: OutputStrategy;
    /**
     * Specify custom logger formatter options.
     */
    formatterOptions?: CreateTaggedFormatterOptions;
}
/**
 * Creates a logger instance with good defaults.
 */
export declare function createDefaultLogger({ output, formatterOptions }?: CreateDefaultLoggerOptions): Logger;
