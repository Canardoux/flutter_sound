"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.runProgram = exports.run = void 0;
const tslib_1 = require("tslib");
const commander_1 = tslib_1.__importDefault(require("commander"));
const colors_1 = tslib_1.__importDefault(require("./colors"));
const config_1 = require("./config");
const errors_1 = require("./errors");
const ipc_1 = require("./ipc");
const log_1 = require("./log");
const telemetry_1 = require("./telemetry");
const cli_1 = require("./util/cli");
const emoji_1 = require("./util/emoji");
process.on('unhandledRejection', error => {
    console.error(colors_1.default.failure('[fatal]'), error);
});
process.on('message', ipc_1.receive);
async function run() {
    try {
        const config = await config_1.loadConfig();
        runProgram(config);
    }
    catch (e) {
        process.exitCode = errors_1.isFatal(e) ? e.exitCode : 1;
        log_1.logger.error(e.message ? e.message : String(e));
    }
}
exports.run = run;
function runProgram(config) {
    commander_1.default.version(config.cli.package.version);
    commander_1.default
        .command('config', { hidden: true })
        .description(`print evaluated Capacitor config`)
        .option('--json', 'Print in JSON format')
        .action(cli_1.wrapAction(async ({ json }) => {
        const { configCommand } = await Promise.resolve().then(() => tslib_1.__importStar(require('./tasks/config')));
        await configCommand(config, json);
    }));
    commander_1.default
        .command('create [directory] [name] [id]', { hidden: true })
        .description('Creates a new Capacitor project')
        .action(cli_1.wrapAction(async () => {
        const { createCommand } = await Promise.resolve().then(() => tslib_1.__importStar(require('./tasks/create')));
        await createCommand();
    }));
    commander_1.default
        .command('init [appName] [appId]')
        .description(`Initialize Capacitor configuration`)
        .option('--web-dir <value>', 'Optional: Directory of your projects built web assets')
        .action(cli_1.wrapAction(telemetry_1.telemetryAction(config, async (appName, appId, { webDir }) => {
        const { initCommand } = await Promise.resolve().then(() => tslib_1.__importStar(require('./tasks/init')));
        await initCommand(config, appName, appId, webDir);
    })));
    commander_1.default
        .command('serve', { hidden: true })
        .description('Serves a Capacitor Progressive Web App in the browser')
        .action(cli_1.wrapAction(async () => {
        const { serveCommand } = await Promise.resolve().then(() => tslib_1.__importStar(require('./tasks/serve')));
        await serveCommand();
    }));
    commander_1.default
        .command('sync [platform]')
        .description(`${colors_1.default.input('copy')} + ${colors_1.default.input('update')}`)
        .option('--deployment', "Optional: if provided, Podfile.lock won't be deleted and pod install will use --deployment option")
        .action(cli_1.wrapAction(telemetry_1.telemetryAction(config, async (platform, { deployment }) => {
        const { syncCommand } = await Promise.resolve().then(() => tslib_1.__importStar(require('./tasks/sync')));
        await syncCommand(config, platform, deployment);
    })));
    commander_1.default
        .command('update [platform]')
        .description(`updates the native plugins and dependencies based on ${colors_1.default.strong('package.json')}`)
        .option('--deployment', "Optional: if provided, Podfile.lock won't be deleted and pod install will use --deployment option")
        .action(cli_1.wrapAction(telemetry_1.telemetryAction(config, async (platform, { deployment }) => {
        const { updateCommand } = await Promise.resolve().then(() => tslib_1.__importStar(require('./tasks/update')));
        await updateCommand(config, platform, deployment);
    })));
    commander_1.default
        .command('copy [platform]')
        .description('copies the web app build into the native app')
        .action(cli_1.wrapAction(telemetry_1.telemetryAction(config, async (platform) => {
        const { copyCommand } = await Promise.resolve().then(() => tslib_1.__importStar(require('./tasks/copy')));
        await copyCommand(config, platform);
    })));
    commander_1.default
        .command(`run [platform]`)
        .description(`runs ${colors_1.default.input('sync')}, then builds and deploys the native app`)
        .option('--list', 'list targets, then quit')
        // TODO: remove once --json is a hidden option (https://github.com/tj/commander.js/issues/1106)
        .allowUnknownOption(true)
        .option('--target <id>', 'use a specific target')
        .option('--no-sync', `do not run ${colors_1.default.input('sync')}`)
        .action(cli_1.wrapAction(telemetry_1.telemetryAction(config, async (platform, { list, target, sync }) => {
        const { runCommand } = await Promise.resolve().then(() => tslib_1.__importStar(require('./tasks/run')));
        await runCommand(config, platform, { list, target, sync });
    })));
    commander_1.default
        .command('open [platform]')
        .description('opens the native project workspace (Xcode for iOS)')
        .action(cli_1.wrapAction(telemetry_1.telemetryAction(config, async (platform) => {
        const { openCommand } = await Promise.resolve().then(() => tslib_1.__importStar(require('./tasks/open')));
        await openCommand(config, platform);
    })));
    commander_1.default
        .command('add [platform]')
        .description('add a native platform project')
        .action(cli_1.wrapAction(telemetry_1.telemetryAction(config, async (platform) => {
        const { addCommand } = await Promise.resolve().then(() => tslib_1.__importStar(require('./tasks/add')));
        await addCommand(config, platform);
    })));
    commander_1.default
        .command('ls [platform]')
        .description('list installed Cordova and Capacitor plugins')
        .action(cli_1.wrapAction(telemetry_1.telemetryAction(config, async (platform) => {
        const { listCommand } = await Promise.resolve().then(() => tslib_1.__importStar(require('./tasks/list')));
        await listCommand(config, platform);
    })));
    commander_1.default
        .command('doctor [platform]')
        .description('checks the current setup for common errors')
        .action(cli_1.wrapAction(telemetry_1.telemetryAction(config, async (platform) => {
        const { doctorCommand } = await Promise.resolve().then(() => tslib_1.__importStar(require('./tasks/doctor')));
        await doctorCommand(config, platform);
    })));
    commander_1.default
        .command('telemetry [on|off]', { hidden: true })
        .description('enable or disable telemetry')
        .action(cli_1.wrapAction(async (onOrOff) => {
        const { telemetryCommand } = await Promise.resolve().then(() => tslib_1.__importStar(require('./tasks/telemetry')));
        await telemetryCommand(onOrOff);
    }));
    commander_1.default
        .command('📡', { hidden: true })
        .description('IPC receiver command')
        .action(() => {
        // no-op: IPC messages are received via `process.on('message')`
    });
    commander_1.default
        .command('plugin:generate', { hidden: true })
        .description('start a new Capacitor plugin')
        .action(cli_1.wrapAction(async () => {
        const { newPluginCommand } = await Promise.resolve().then(() => tslib_1.__importStar(require('./tasks/new-plugin')));
        await newPluginCommand();
    }));
    commander_1.default.arguments('[command]').action(cli_1.wrapAction(async (cmd) => {
        if (typeof cmd === 'undefined') {
            log_1.output.write(`\n  ${emoji_1.emoji('⚡️', '--')}  ${colors_1.default.strong('Capacitor - Cross-Platform apps with JavaScript and the Web')}  ${emoji_1.emoji('⚡️', '--')}\n\n`);
            commander_1.default.outputHelp();
        }
        else {
            errors_1.fatal(`Unknown command: ${colors_1.default.input(cmd)}`);
        }
    }));
    commander_1.default.parse(process.argv);
}
exports.runProgram = runProgram;
