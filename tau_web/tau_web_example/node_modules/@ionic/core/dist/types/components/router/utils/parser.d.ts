import { RouteChain, RouteRedirect, RouteTree } from './interface';
export declare const readRedirects: (root: Element) => RouteRedirect[];
export declare const readRoutes: (root: Element) => RouteChain[];
export declare const readRouteNodes: (node: Element) => RouteTree;
export declare const flattenRouterTree: (nodes: RouteTree) => RouteChain[];
