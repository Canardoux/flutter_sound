/**
 * These environment variables work for: GitHub Actions, Travis CI, CircleCI,
 * Gitlab CI, AppVeyor, CodeShip, Jenkins, TeamCity, Bitbucket Pipelines, AWS
 * CodeBuild
 */
export declare const CI_ENVIRONMENT_VARIABLES: readonly string[];
export declare const CI_ENVIRONMENT_VARIABLES_DETECTED: string[];
export interface TerminalInfo {
    /**
     * Whether this is in CI or not.
     */
    readonly ci: boolean;
    /**
     * Path to the user's shell program.
     */
    readonly shell: string;
    /**
     * Whether the terminal is an interactive TTY or not.
     */
    readonly tty: boolean;
    /**
     * Whether this is a Windows shell or not.
     */
    readonly windows: boolean;
}
export declare const TERMINAL_INFO: TerminalInfo;
