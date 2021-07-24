import type * as d from '@stencil/core/internal';
export declare function runJest(config: d.Config, env: d.E2EProcessEnv): Promise<boolean>;
export declare function createTestRunner(): any;
export declare function includeTestFile(testPath: string, env: d.E2EProcessEnv): boolean;
export declare function getEmulateConfigs(testing: d.TestingConfig, flags: d.ConfigFlags): d.EmulateConfig[];
