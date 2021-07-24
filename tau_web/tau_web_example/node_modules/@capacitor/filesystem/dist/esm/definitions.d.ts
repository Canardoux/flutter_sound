import type { PermissionState } from '@capacitor/core';
export interface PermissionStatus {
    publicStorage: PermissionState;
}
export declare enum Directory {
    /**
     * The Documents directory
     * On iOS it's the app's documents directory.
     * Use this directory to store user-generated content.
     * On Android it's the Public Documents folder, so it's accessible from other apps.
     * It's not accesible on Android 10 unless the app enables legacy External Storage
     * by adding `android:requestLegacyExternalStorage="true"` in the `application` tag
     * in the `AndroidManifest.xml`.
     * It's not accesible on Android 11 or newer.
     *
     * @since 1.0.0
     */
    Documents = "DOCUMENTS",
    /**
     * The Data directory
     * On iOS it will use the Documents directory
     * On Android it's the directory holding application files.
     * Files will be deleted when the application is uninstalled.
     *
     * @since 1.0.0
     */
    Data = "DATA",
    /**
     * The Cache directory
     * Can be deleted in cases of low memory, so use this directory to write app-specific files
     * that your app can re-create easily.
     *
     * @since 1.0.0
     */
    Cache = "CACHE",
    /**
     * The external directory
     * On iOS it will use the Documents directory
     * On Android it's the directory on the primary shared/external
     * storage device where the application can place persistent files it owns.
     * These files are internal to the applications, and not typically visible
     * to the user as media.
     * Files will be deleted when the application is uninstalled.
     *
     * @since 1.0.0
     */
    External = "EXTERNAL",
    /**
     * The external storage directory
     * On iOS it will use the Documents directory
     * On Android it's the primary shared/external storage directory.
     * It's not accesible on Android 10 unless the app enables legacy External Storage
     * by adding `android:requestLegacyExternalStorage="true"` in the `application` tag
     * in the `AndroidManifest.xml`.
     * It's not accesible on Android 11 or newer.
     *
     * @since 1.0.0
     */
    ExternalStorage = "EXTERNAL_STORAGE"
}
export declare enum Encoding {
    /**
     * Eight-bit UCS Transformation Format
     *
     * @since 1.0.0
     */
    UTF8 = "utf8",
    /**
     * Seven-bit ASCII, a.k.a. ISO646-US, a.k.a. the Basic Latin block of the
     * Unicode character set
     * This encoding is only supported on Android.
     *
     * @since 1.0.0
     */
    ASCII = "ascii",
    /**
     * Sixteen-bit UCS Transformation Format, byte order identified by an
     * optional byte-order mark
     * This encoding is only supported on Android.
     *
     * @since 1.0.0
     */
    UTF16 = "utf16"
}
export interface WriteFileOptions {
    /**
     * The path of the file to write
     *
     * @since 1.0.0
     */
    path: string;
    /**
     * The data to write
     *
     * @since 1.0.0
     */
    data: string;
    /**
     * The `Directory` to store the file in
     *
     * @since 1.0.0
     */
    directory?: Directory;
    /**
     * The encoding to write the file in. If not provided, data
     * is written as base64 encoded.
     *
     * Pass Encoding.UTF8 to write data as string
     *
     * @since 1.0.0
     */
    encoding?: Encoding;
    /**
     * Whether to create any missing parent directories.
     *
     * @default false
     * @since 1.0.0
     */
    recursive?: boolean;
}
export interface AppendFileOptions {
    /**
     * The path of the file to append
     *
     * @since 1.0.0
     */
    path: string;
    /**
     * The data to write
     *
     * @since 1.0.0
     */
    data: string;
    /**
     * The `Directory` to store the file in
     *
     * @since 1.0.0
     */
    directory?: Directory;
    /**
     * The encoding to write the file in. If not provided, data
     * is written as base64 encoded.
     *
     * Pass Encoding.UTF8 to write data as string
     *
     * @since 1.0.0
     */
    encoding?: Encoding;
}
export interface ReadFileOptions {
    /**
     * The path of the file to read
     *
     * @since 1.0.0
     */
    path: string;
    /**
     * The `Directory` to read the file from
     *
     * @since 1.0.0
     */
    directory?: Directory;
    /**
     * The encoding to read the file in, if not provided, data
     * is read as binary and returned as base64 encoded.
     *
     * Pass Encoding.UTF8 to read data as string
     *
     * @since 1.0.0
     */
    encoding?: Encoding;
}
export interface DeleteFileOptions {
    /**
     * The path of the file to delete
     *
     * @since 1.0.0
     */
    path: string;
    /**
     * The `Directory` to delete the file from
     *
     * @since 1.0.0
     */
    directory?: Directory;
}
export interface MkdirOptions {
    /**
     * The path of the new directory
     *
     * @since 1.0.0
     */
    path: string;
    /**
     * The `Directory` to make the new directory in
     *
     * @since 1.0.0
     */
    directory?: Directory;
    /**
     * Whether to create any missing parent directories as well.
     *
     * @default false
     * @since 1.0.0
     */
    recursive?: boolean;
}
export interface RmdirOptions {
    /**
     * The path of the directory to remove
     *
     * @since 1.0.0
     */
    path: string;
    /**
     * The `Directory` to remove the directory from
     *
     * @since 1.0.0
     */
    directory?: Directory;
    /**
     * Whether to recursively remove the contents of the directory
     *
     * @default false
     * @since 1.0.0
     */
    recursive?: boolean;
}
export interface ReaddirOptions {
    /**
     * The path of the directory to read
     *
     * @since 1.0.0
     */
    path: string;
    /**
     * The `Directory` to list files from
     *
     * @since 1.0.0
     */
    directory?: Directory;
}
export interface GetUriOptions {
    /**
     * The path of the file to get the URI for
     *
     * @since 1.0.0
     */
    path: string;
    /**
     * The `Directory` to get the file under
     *
     * @since 1.0.0
     */
    directory: Directory;
}
export interface StatOptions {
    /**
     * The path of the file to get data about
     *
     * @since 1.0.0
     */
    path: string;
    /**
     * The `Directory` to get the file under
     *
     * @since 1.0.0
     */
    directory?: Directory;
}
export interface CopyOptions {
    /**
     * The existing file or directory
     *
     * @since 1.0.0
     */
    from: string;
    /**
     * The destination file or directory
     *
     * @since 1.0.0
     */
    to: string;
    /**
     * The `Directory` containing the existing file or directory
     *
     * @since 1.0.0
     */
    directory?: Directory;
    /**
     * The `Directory` containing the destination file or directory. If not supplied will use the 'directory'
     * parameter as the destination
     *
     * @since 1.0.0
     */
    toDirectory?: Directory;
}
export declare type RenameOptions = CopyOptions;
export interface ReadFileResult {
    /**
     * The string representation of the data contained in the file
     *
     * @since 1.0.0
     */
    data: string;
}
export interface WriteFileResult {
    /**
     * The uri where the file was written into
     *
     * @since 1.0.0
     */
    uri: string;
}
export interface ReaddirResult {
    /**
     * List of files and directories inside the directory
     *
     * @since 1.0.0
     */
    files: string[];
}
export interface GetUriResult {
    /**
     * The uri of the file
     *
     * @since 1.0.0
     */
    uri: string;
}
export interface StatResult {
    /**
     * Type of the file
     *
     * @since 1.0.0
     */
    type: string;
    /**
     * Size of the file
     *
     * @since 1.0.0
     */
    size: number;
    /**
     * Time of creation in milliseconds.
     *
     * It's not available on Android 7 and older devices.
     *
     * @since 1.0.0
     */
    ctime?: number;
    /**
     * Time of last modification in milliseconds.
     *
     * @since 1.0.0
     */
    mtime: number;
    /**
     * The uri of the file
     *
     * @since 1.0.0
     */
    uri: string;
}
export interface FilesystemPlugin {
    /**
     * Read a file from disk
     *
     * @since 1.0.0
     */
    readFile(options: ReadFileOptions): Promise<ReadFileResult>;
    /**
     * Write a file to disk in the specified location on device
     *
     * @since 1.0.0
     */
    writeFile(options: WriteFileOptions): Promise<WriteFileResult>;
    /**
     * Append to a file on disk in the specified location on device
     *
     * @since 1.0.0
     */
    appendFile(options: AppendFileOptions): Promise<void>;
    /**
     * Delete a file from disk
     *
     * @since 1.0.0
     */
    deleteFile(options: DeleteFileOptions): Promise<void>;
    /**
     * Create a directory.
     *
     * @since 1.0.0
     */
    mkdir(options: MkdirOptions): Promise<void>;
    /**
     * Remove a directory
     *
     * @since 1.0.0
     */
    rmdir(options: RmdirOptions): Promise<void>;
    /**
     * Return a list of files from the directory (not recursive)
     *
     * @since 1.0.0
     */
    readdir(options: ReaddirOptions): Promise<ReaddirResult>;
    /**
     * Return full File URI for a path and directory
     *
     * @since 1.0.0
     */
    getUri(options: GetUriOptions): Promise<GetUriResult>;
    /**
     * Return data about a file
     *
     * @since 1.0.0
     */
    stat(options: StatOptions): Promise<StatResult>;
    /**
     * Rename a file or directory
     *
     * @since 1.0.0
     */
    rename(options: RenameOptions): Promise<void>;
    /**
     * Copy a file or directory
     *
     * @since 1.0.0
     */
    copy(options: CopyOptions): Promise<void>;
    /**
     * Check read/write permissions.
     * Required on Android, only when using `Directory.Documents` or
     * `Directory.ExternalStorage`.
     *
     * @since 1.0.0
     */
    checkPermissions(): Promise<PermissionStatus>;
    /**
     * Request read/write permissions.
     * Required on Android, only when using `Directory.Documents` or
     * `Directory.ExternalStorage`.
     *
     * @since 1.0.0
     */
    requestPermissions(): Promise<PermissionStatus>;
}
/**
 * @deprecated Use `ReadFileOptions`.
 * @since 1.0.0
 */
export declare type FileReadOptions = ReadFileOptions;
/**
 * @deprecated Use `ReadFileResult`.
 * @since 1.0.0
 */
export declare type FileReadResult = ReadFileResult;
/**
 * @deprecated Use `WriteFileOptions`.
 * @since 1.0.0
 */
export declare type FileWriteOptions = WriteFileOptions;
/**
 * @deprecated Use `WriteFileResult`.
 * @since 1.0.0
 */
export declare type FileWriteResult = WriteFileResult;
/**
 * @deprecated Use `AppendFileOptions`.
 * @since 1.0.0
 */
export declare type FileAppendOptions = AppendFileOptions;
/**
 * @deprecated Use `DeleteFileOptions`.
 * @since 1.0.0
 */
export declare type FileDeleteOptions = DeleteFileOptions;
/**
 * @deprecated Use `Directory`.
 * @since 1.0.0
 */
export declare const FilesystemDirectory: typeof Directory;
/**
 * @deprecated Use `Encoding`.
 * @since 1.0.0
 */
export declare const FilesystemEncoding: typeof Encoding;
