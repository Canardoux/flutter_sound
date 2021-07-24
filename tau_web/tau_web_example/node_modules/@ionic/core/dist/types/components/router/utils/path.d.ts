import { ParsedRoute, RouteChain, RouterDirection } from './interface';
export declare const generatePath: (segments: string[]) => string;
export declare const writePath: (history: History, root: string, useHash: boolean, path: string[], direction: RouterDirection, state: number, queryString?: string | undefined) => void;
export declare const chainToPath: (chain: RouteChain) => string[] | null;
export declare const readPath: (loc: Location, root: string, useHash: boolean) => string[] | null;
export declare const parsePath: (path: string | undefined | null) => ParsedRoute;
