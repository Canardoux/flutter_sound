/// <reference types="node" />
import * as fs from 'fs-extra';
import * as stream from 'stream';
export * from 'fs-extra';
export { stat as statSafe, readdir as readdirSafe } from './safe';
export interface ReaddirPOptions {
    /**
     * Filter out items from the walk process from the final result.
     *
     * @return `true` to keep, otherwise the item is filtered out
     */
    readonly filter?: (item: WalkerItem) => boolean;
    /**
     * Called whenever an error occurs during the walk process.
     *
     * If excluded, the function will throw an error when first encountered.
     */
    readonly onError?: (err: Error) => void;
    readonly walkerOptions?: WalkerOptions;
}
export declare function readdirp(dir: string, { filter, onError, walkerOptions }?: ReaddirPOptions): Promise<string[]>;
export declare const enum FileType {
    FILE = "file",
    DIRECTORY = "directory"
}
export interface RegularFileNode {
    path: string;
    type: FileType.FILE;
    parent: FileNode;
}
export interface DirectoryNode {
    path: string;
    type: FileType.DIRECTORY;
    parent?: FileNode;
    children: FileNode[];
}
export declare type FileNode = RegularFileNode | DirectoryNode;
export interface GetFileTreeOptions<RE = {}, DE = {}> {
    /**
     * Called whenever an error occurs during the walk process.
     *
     * If excluded, the function will throw an error when first encountered.
     */
    readonly onError?: (err: Error) => void;
    /**
     * Called whenever a file node is added to the tree.
     *
     * File nodes can be supplemented by returning a new object from this
     * function.
     */
    readonly onFileNode?: (node: RegularFileNode) => RegularFileNode & RE;
    /**
     * Called whenever a directory node is added to the tree.
     *
     * Directory nodes can be supplemented by returning a new object from this
     * function.
     */
    readonly onDirectoryNode?: (node: DirectoryNode) => DirectoryNode & DE;
    readonly walkerOptions?: WalkerOptions;
}
/**
 * Compile and return a file tree structure.
 *
 * This function walks a directory structure recursively, building a nested
 * object structure in memory that represents it. When finished, the root
 * directory node is returned.
 *
 * @param dir The root directory from which to compile the file tree
 */
export declare function getFileTree<RE = {}, DE = {}>(dir: string, { onError, onFileNode, onDirectoryNode, walkerOptions }?: GetFileTreeOptions<RE, DE>): Promise<RegularFileNode & RE | DirectoryNode & DE>;
export declare function fileToString(filePath: string): Promise<string>;
export declare function getFileChecksum(filePath: string): Promise<string>;
/**
 * Return true and cached checksums for a file by its path.
 *
 * Cached checksums are stored as `.md5` files next to the original file. If
 * the cache file is missing, the cached checksum is undefined.
 *
 * @param p The file path
 * @return Promise<[true checksum, cached checksum or undefined if cache file missing]>
 */
export declare function getFileChecksums(p: string): Promise<[string, string | undefined]>;
/**
 * Store a cache file containing the source file's md5 checksum hash.
 *
 * @param p The file path
 * @param checksum The checksum. If excluded, the checksum is computed
 */
export declare function cacheFileChecksum(p: string, checksum?: string): Promise<void>;
export declare function writeStreamToFile(stream: NodeJS.ReadableStream, destination: string): Promise<any>;
export declare function pathAccessible(filePath: string, mode: number): Promise<boolean>;
export declare function pathExists(filePath: string): Promise<boolean>;
export declare function pathReadable(filePath: string): Promise<boolean>;
export declare function pathWritable(filePath: string): Promise<boolean>;
export declare function pathExecutable(filePath: string): Promise<boolean>;
export declare function isExecutableFile(filePath: string): Promise<boolean>;
/**
 * Find the base directory based on the path given and a marker file to look for.
 */
export declare function findBaseDirectory(dir: string, file: string): Promise<string | undefined>;
/**
 * Generate a random file path within the computer's temporary directory.
 *
 * @param prefix Optionally provide a filename prefix.
 */
export declare function tmpfilepath(prefix?: string): string;
/**
 * Given an absolute system path, compile an array of paths working backwards
 * one directory at a time, always ending in the root directory.
 *
 * For example, `'/some/dir'` => `['/some/dir', '/some', '/']`
 *
 * @param filePath Absolute system base path.
 */
export declare function compilePaths(filePath: string): string[];
export interface WalkerItem {
    path: string;
    stats: fs.Stats;
}
export interface WalkerOptions {
    /**
     * Filter out file paths during walk.
     *
     * As the file tree is walked, this function can be used to exclude files and
     * directories from the final result.
     *
     * It can also be used to tune performance. If a subdirectory is excluded, it
     * is not walked.
     *
     * @param p The file path.
     * @return `true` to include file path, otherwise it is excluded
     */
    readonly pathFilter?: (p: string) => boolean;
}
export interface Walker extends stream.Readable {
    on(event: 'data', callback: (item: WalkerItem) => void): this;
    on(event: string, callback: (...args: any[]) => any): this;
}
export declare class Walker extends stream.Readable {
    readonly p: string;
    readonly options: WalkerOptions;
    readonly paths: string[];
    constructor(p: string, options?: WalkerOptions);
    _read(): void;
}
export declare function walk(p: string, options?: WalkerOptions): Walker;
