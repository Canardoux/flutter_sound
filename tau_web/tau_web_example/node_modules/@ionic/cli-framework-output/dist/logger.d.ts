/// <reference types="node" />
import { WordWrapOptions } from '@ionic/utils-terminal';
import { ColorFunction, Colors } from './colors';
export interface LogRecord {
    msg: string;
    logger: Logger;
    level?: LoggerLevelWeight;
    format?: boolean;
}
export declare type LoggerLevel = 'DEBUG' | 'INFO' | 'WARN' | 'ERROR';
export declare type LoggerLevelWeight = number;
export declare type LoggerFormatter = (record: LogRecord) => string;
export declare const LOGGER_LEVELS: {
    readonly [L in LoggerLevel]: LoggerLevelWeight;
};
export declare const LOGGER_LEVEL_NAMES: ReadonlyMap<LoggerLevelWeight, LoggerLevel>;
export declare function getLoggerLevelName(level?: LoggerLevelWeight): LoggerLevel | undefined;
export declare function getLoggerLevelColor(colors: Colors, level?: LoggerLevelWeight): ColorFunction | undefined;
export interface LoggerHandler {
    formatter?: LoggerFormatter;
    clone(): LoggerHandler;
    handle(record: LogRecord): void;
}
export interface StreamHandlerOptions {
    readonly stream: NodeJS.WritableStream;
    readonly filter?: (record: LogRecord) => boolean;
    readonly formatter?: LoggerFormatter;
}
export declare class StreamHandler implements LoggerHandler {
    readonly stream: NodeJS.WritableStream;
    readonly filter?: (record: LogRecord) => boolean;
    formatter?: LoggerFormatter;
    constructor({ stream, filter, formatter }: StreamHandlerOptions);
    clone(opts?: Partial<StreamHandlerOptions>): StreamHandler;
    handle(record: LogRecord): void;
}
export declare const DEFAULT_LOGGER_HANDLERS: ReadonlySet<StreamHandler>;
export interface LoggerOptions {
    readonly handlers?: Set<LoggerHandler>;
    readonly level?: LoggerLevelWeight;
}
export declare class Logger {
    handlers: Set<LoggerHandler>;
    level: LoggerLevelWeight;
    constructor({ level, handlers }?: LoggerOptions);
    static cloneHandlers(handlers: ReadonlySet<LoggerHandler>): Set<LoggerHandler>;
    /**
     * Clone this logger, optionally overriding logger options.
     *
     * @param opts Logger options to override from this logger.
     */
    clone(opts?: Partial<LoggerOptions>): Logger;
    /**
     * Log a message as-is.
     *
     * @param msg The string to log.
     */
    msg(msg: string): void;
    /**
     * Log a message using the `debug` logger level.
     *
     * @param msg The string to log.
     */
    debug(msg: string): void;
    /**
     * Log a message using the `info` logger level.
     *
     * @param msg The string to log.
     */
    info(msg: string): void;
    /**
     * Log a message using the `warn` logger level.
     *
     * @param msg The string to log.
     */
    warn(msg: string): void;
    /**
     * Log a message using the `error` logger level.
     *
     * @param msg The string to log.
     */
    error(msg: string): void;
    createRecord(msg: string, level?: LoggerLevelWeight, format?: boolean): LogRecord;
    /**
     * Log newlines using a logger output found via `level`.
     *
     * @param num The number of newlines to log.
     * @param level The logger level. If omitted, the default output is used.
     */
    nl(num?: number, level?: LoggerLevelWeight): void;
    /**
     * Log a record using a logger output found via `level`.
     */
    log(record: LogRecord): void;
    createWriteStream(level?: LoggerLevelWeight, format?: boolean): NodeJS.WritableStream;
}
export interface CreateTaggedFormatterOptions {
    prefix?: string | (() => string);
    titleize?: boolean;
    wrap?: boolean | WordWrapOptions;
    colors?: Colors;
    tags?: ReadonlyMap<LoggerLevelWeight, string>;
}
export declare function createTaggedFormatter({ colors, prefix, tags, titleize, wrap }?: CreateTaggedFormatterOptions): LoggerFormatter;
export declare function createPrefixedFormatter(prefix: string | (() => string)): LoggerFormatter;
