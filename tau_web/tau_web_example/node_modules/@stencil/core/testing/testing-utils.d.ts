import type * as d from '@stencil/core/internal';
export declare function shuffleArray(array: any[]): any[];
export declare function expectFiles(fs: d.InMemoryFileSystem, filePaths: string[]): void;
export declare function doNotExpectFiles(fs: d.InMemoryFileSystem, filePaths: string[]): void;
export declare function getAppScriptUrl(config: d.Config, browserUrl: string): string;
export declare function getAppStyleUrl(config: d.Config, browserUrl: string): string;
