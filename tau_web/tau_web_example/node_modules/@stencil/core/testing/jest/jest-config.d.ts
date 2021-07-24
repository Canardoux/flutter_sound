import type * as d from '@stencil/core/internal';
import type { Config } from '@jest/types';
export declare function buildJestArgv(config: d.Config): Config.Argv;
export declare function buildJestConfig(config: d.Config): string;
export declare function getProjectListFromCLIArgs(config: d.Config, argv: Config.Argv): Config.Path[];
