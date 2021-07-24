/**
 * @deprecated
 */
export interface PluginRegistry {
    [pluginName: string]: {
        [prop: string]: any;
    };
}
/**
 * @deprecated
 */
export interface PluginConfig {
    id: string;
    name: string;
}
/**
 * @deprecated
 */
export declare type ISODateString = string;
/**
 * @deprecated
 */
export declare type CallbackID = string;
/**
 * CancellableCallback is a simple wrapper that a method will
 * return to make it easy to cancel any repeated callback the method
 * might have set up. For example: a geolocation watch.
 * @deprecated
 */
export interface CancellableCallback {
    /**
     * The cancel function for this method
     *
     * @deprecated
     */
    cancel: (...args: any[]) => any;
}
