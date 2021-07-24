import type { BuildCtx, Cache, CompilerCtx, CompilerSystem, Config } from '@stencil/core/internal';
import { TestingLogger } from './testing-logger';
export declare function mockConfig(sys?: CompilerSystem): Config;
export declare function mockCompilerCtx(config?: Config): CompilerCtx;
export declare function mockBuildCtx(config?: Config, compilerCtx?: CompilerCtx): BuildCtx;
export declare function mockCache(config?: Config, compilerCtx?: CompilerCtx): Cache;
export declare function mockLogger(): TestingLogger;
export interface TestingSystem extends CompilerSystem {
    diskReads: number;
    diskWrites: number;
}
export declare function mockStencilSystem(): TestingSystem;
export declare function mockDocument(html?: string): Document;
export declare function mockWindow(html?: string): Window;
