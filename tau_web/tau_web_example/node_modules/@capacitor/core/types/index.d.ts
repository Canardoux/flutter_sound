export type { CapacitorGlobal, PermissionState, Plugin, PluginCallback, PluginImplementations, PluginListenerHandle, PluginResultData, PluginResultError, } from './definitions';
export { CapacitorPlatforms, addPlatform, setPlatform } from './platforms';
export { Capacitor, registerPlugin } from './global';
export { WebPlugin, WebPluginConfig, ListenerCallback } from './web-plugin';
export { WebView } from './core-plugins';
export type { WebViewPath, WebViewPlugin } from './core-plugins';
export { CapacitorException, ExceptionCode } from './util';
export { Plugins, registerWebPlugin } from './global';
export type { CallbackID, CancellableCallback, ISODateString, PluginConfig, PluginRegistry, } from './legacy/legacy-definitions';
