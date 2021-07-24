/// <reference types="node" />
import { ChildProcess, ForkOptions, SpawnOptions } from 'child_process';
export declare const ERROR_COMMAND_NOT_FOUND = "ERR_SUBPROCESS_COMMAND_NOT_FOUND";
export declare const ERROR_NON_ZERO_EXIT = "ERR_SUBPROCESS_NON_ZERO_EXIT";
export declare const ERROR_SIGNAL_EXIT = "ERR_SUBPROCESS_SIGNAL_EXIT";
export declare const TILDE_PATH_REGEX: RegExp;
export declare function expandTildePath(p: string): string;
/**
 * Prepare the PATH environment variable for use with subprocesses.
 *
 * If a raw tilde is found in PATH, e.g. `~/.bin`, it is expanded. The raw
 * tilde works in Bash, but not in Node's `child_process` outside of a shell.
 *
 * This is a utility method. You do not need to use it with `Subprocess`.
 *
 * @param path Defaults to `process.env.PATH`
 */
export declare function convertPATH(path?: string): string;
export declare class SubprocessError extends Error {
    readonly name = "SubprocessError";
    message: string;
    stack: string;
    code?: typeof ERROR_COMMAND_NOT_FOUND | typeof ERROR_NON_ZERO_EXIT | typeof ERROR_SIGNAL_EXIT;
    error?: Error;
    output?: string;
    signal?: string;
    exitCode?: number;
    constructor(message: string);
}
export interface SubprocessOptions extends SpawnOptions {
}
export interface SubprocessBashifyOptions {
    /**
     * Mask file path to first argument.
     *
     * The first argument to subprocesses is the program name or path, e.g.
     * `/path/to/bin/my-program`. If `true`, `bashify()` will return the program
     * name without a file path, e.g. `my-program`.
     *
     * The default is `true`.
     */
    maskArgv0?: boolean;
    /**
     * Mask file path to second argument.
     *
     * In some subprocesses, the second argument is a script file to run, e.g.
     * `node ./scripts/post-install`. If `true`, `bashify()` will return the
     * script name without a file path, e.g. `node post-install`.
     *
     * The default is `false`.
     */
    maskArgv1?: boolean;
    /**
     * Remove the first argument from output.
     *
     * Useful to make a command such as `node ./scripts/post-install` appear as
     * simply `post-install`.
     *
     * The default is `false`.
     */
    shiftArgv0?: boolean;
}
export declare class Subprocess {
    name: string;
    args: readonly string[];
    protected readonly path?: string;
    protected _options: SpawnOptions;
    constructor(name: string, args: readonly string[], options?: SubprocessOptions);
    get options(): Readonly<SpawnOptions>;
    output(): Promise<string>;
    combinedOutput(): Promise<string>;
    run(): Promise<void> & {
        p: ChildProcess;
    };
    spawn(): ChildProcess;
    bashify({ maskArgv0, maskArgv1, shiftArgv0 }?: SubprocessBashifyOptions): string;
    bashifyArg(arg: string): string;
    maskArg(arg: string): string;
}
export declare function spawn(command: string, args?: readonly string[], options?: SpawnOptions): ChildProcess;
export declare function fork(modulePath: string, args?: readonly string[], options?: ForkOptions & Pick<SpawnOptions, 'stdio'>): ChildProcess;
export interface WhichOptions {
    PATH?: string;
    PATHEXT?: string;
}
/**
 * Find the first instance of a program in PATH.
 *
 * If `program` contains a path separator, this function will merely return it.
 *
 * @param program A command name, such as `ionic`
 */
export declare function which(program: string, { PATH, PATHEXT }?: WhichOptions): Promise<string>;
/**
 * Find all instances of a program in PATH.
 *
 * If `program` contains a path separator, this function will merely return it
 * inside an array.
 *
 * @param program A command name, such as `ionic`
 */
export declare function findExecutables(program: string, { PATH, PATHEXT }?: WhichOptions): Promise<string[]>;
