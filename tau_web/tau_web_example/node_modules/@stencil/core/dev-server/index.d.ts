import type { CompilerWatcher, Logger, StencilDevServerConfig, DevServer } from '../internal/index';
export declare function start(stencilDevServerConfig: StencilDevServerConfig, logger: Logger, watcher?: CompilerWatcher): Promise<DevServer>;
export { DevServer, StencilDevServerConfig as DevServerConfig, Logger };
