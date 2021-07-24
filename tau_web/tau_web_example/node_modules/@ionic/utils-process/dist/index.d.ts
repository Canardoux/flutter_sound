/// <reference types="node" />
export declare const ERROR_TIMEOUT_REACHED: Error;
export declare function killProcessTree(pid: number, signal?: string | number): Promise<void>;
/**
 * Creates an alternative implementation of `process.env` object.
 *
 * On a Windows shell, `process.env` is a magic object that offers
 * case-insensitive environment variable access. On other platforms, case
 * sensitivity matters. This method creates an empty "`process.env`" object
 * type that works for all platforms.
 */
export declare function createProcessEnv(...sources: {
    [key: string]: string | undefined;
}[]): NodeJS.ProcessEnv;
/**
 * Split a PATH string into path parts.
 */
export declare function getPathParts(envpath?: string): string[];
/**
 * Resolves when the given amount of milliseconds has passed.
 */
export declare function sleep(ms: number): Promise<void>;
/**
 * Resolves when a given predicate is true or a timeout is reached.
 *
 * Configure `interval` to set how often the `predicate` is called.
 *
 * By default, `timeout` is Infinity. If given a value (in ms), and that
 * timeout value is reached, this function will reject with
 * the `ERROR_TIMEOUT_REACHED` error.
 */
export declare function sleepUntil(predicate: () => boolean, { interval, timeout }: {
    interval?: number;
    timeout?: number;
}): Promise<void>;
/**
 * Never resolves and keeps Node running.
 */
export declare function sleepForever(): Promise<never>;
/**
 * Register a synchronous function to be called once the process exits.
 */
export declare function onExit(fn: () => void): void;
export declare type ExitFn = () => Promise<void>;
/**
 * Register an asynchronous function to be called when the process wants to
 * exit.
 *
 * A handler will be registered for the 'SIGINT', 'SIGTERM', 'SIGHUP',
 * 'SIGBREAK' signals. If any of the signal events is emitted, `fn` will be
 * called exactly once, awaited upon, and then the process will exit once all
 * registered functions are resolved.
 */
export declare function onBeforeExit(fn: ExitFn): void;
/**
 * Remove a function that was registered with `onBeforeExit`.
 */
export declare function offBeforeExit(fn: ExitFn): void;
/**
 * Asynchronous `process.exit()`, for running functions registered with
 * `onBeforeExit`.
 */
export declare function processExit(exitCode?: number): Promise<void>;
