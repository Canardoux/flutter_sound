/// <reference types="node" />
import * as fs from 'fs-extra';
export declare function stat(p: string): Promise<fs.Stats | undefined>;
export declare function readdir(dir: string): Promise<string[]>;
