"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.formatTargets = void 0;
const utils_terminal_1 = require("@ionic/utils-terminal");
const errors_1 = require("../errors");
const json_1 = require("./json");
function formatTargets(args, targets) {
    const { devices, virtualDevices, errors } = targets;
    const virtualOnly = args.includes('--virtual');
    const devicesOnly = args.includes('--device');
    if (virtualOnly && devicesOnly) {
        throw new errors_1.CLIException('Only one of --device or --virtual may be specified', errors_1.ERR_BAD_INPUT);
    }
    if (args.includes('--json')) {
        let result;
        if (virtualOnly) {
            result = { virtualDevices, errors };
        }
        else if (devicesOnly) {
            result = { devices, errors };
        }
        else {
            result = { devices, virtualDevices, errors };
        }
        return json_1.stringify(result);
    }
    let output = '';
    if (errors.length > 0) {
        output += `Errors (!):\n\n${errors.map(e => `  ${errors_1.serializeError(e)}`)}\n`;
    }
    if (!virtualOnly) {
        output += printTargets('Connected Device', devices);
        if (devicesOnly) {
            return output;
        }
        output += '\n';
    }
    output += printTargets('Virtual Device', virtualDevices);
    return output;
}
exports.formatTargets = formatTargets;
function printTargets(name, targets) {
    let output = `${name}s:\n\n`;
    if (targets.length === 0) {
        output += `  No ${name.toLowerCase()}s found\n`;
    }
    else {
        output += formatTargetTable(targets) + '\n';
    }
    return output;
}
function formatTargetTable(targets) {
    const spacer = utils_terminal_1.indent(2);
    return (spacer +
        utils_terminal_1.columnar(targets.map(targetToRow), {
            headers: ['Name', 'API', 'Target ID'],
            vsep: ' ',
        })
            .split('\n')
            .join(`\n${spacer}`));
}
function targetToRow(target) {
    var _a, _b, _c, _d;
    return [
        (_c = (_b = (_a = target.name) !== null && _a !== void 0 ? _a : target.model) !== null && _b !== void 0 ? _b : target.id) !== null && _c !== void 0 ? _c : '?',
        `${target.platform === 'ios' ? 'iOS' : 'API'} ${target.sdkVersion}`,
        (_d = target.id) !== null && _d !== void 0 ? _d : '?',
    ];
}
