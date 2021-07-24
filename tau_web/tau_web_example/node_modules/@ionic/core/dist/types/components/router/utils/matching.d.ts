import { RouteChain, RouteID, RouteRedirect } from './interface';
export declare const matchesRedirect: (path: string[], redirect: RouteRedirect) => boolean;
export declare const findRouteRedirect: (path: string[], redirects: RouteRedirect[]) => RouteRedirect | undefined;
export declare const matchesIDs: (ids: string[], chain: RouteChain) => number;
export declare const matchesPath: (inputPath: string[], chain: RouteChain) => RouteChain | null;
export declare const mergeParams: (a: {
  [key: string]: any;
} | undefined, b: {
  [key: string]: any;
} | undefined) => {
  [key: string]: any;
} | undefined;
export declare const routerIDsToChain: (ids: RouteID[], chains: RouteChain[]) => RouteChain | null;
export declare const routerPathToChain: (path: string[], chains: RouteChain[]) => RouteChain | null;
export declare const computePriority: (chain: RouteChain) => number;
export declare class RouterSegments {
  private path;
  constructor(path: string[]);
  next(): string;
}
