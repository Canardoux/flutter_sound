import type { PluginListenerHandle, Plugin } from './definitions';
import type { CapacitorException } from './util';
/**
 * Base class web plugins should extend.
 */
export declare class WebPlugin implements Plugin {
    /**
     * @deprecated WebPluginConfig deprecated in v3 and will be removed in v4.
     */
    config?: WebPluginConfig;
    protected listeners: {
        [eventName: string]: ListenerCallback[];
    };
    protected windowListeners: {
        [eventName: string]: WindowListenerHandle;
    };
    constructor(config?: WebPluginConfig);
    addListener(eventName: string, listenerFunc: ListenerCallback): Promise<PluginListenerHandle> & PluginListenerHandle;
    removeAllListeners(): Promise<void>;
    protected notifyListeners(eventName: string, data: any): void;
    protected hasListeners(eventName: string): boolean;
    protected registerWindowListener(windowEventName: string, pluginEventName: string): void;
    protected unimplemented(msg?: string): CapacitorException;
    protected unavailable(msg?: string): CapacitorException;
    private removeListener;
    private addWindowListener;
    private removeWindowListener;
}
export declare type ListenerCallback = (err: any, ...args: any[]) => void;
export interface WindowListenerHandle {
    registered: boolean;
    windowEventName: string;
    pluginEventName: string;
    handler: (event: any) => void;
}
/**
 * @deprecated Deprecated in v3, removing in v4.
 */
export interface WebPluginConfig {
    /**
     * @deprecated Deprecated in v3, removing in v4.
     */
    readonly name: string;
    /**
     * @deprecated Deprecated in v3, removing in v4.
     */
    platforms?: string[];
}
