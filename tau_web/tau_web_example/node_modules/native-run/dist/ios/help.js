"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.run = void 0;
const help = `
  Usage: native-run ios [options]

    Run an .app or .ipa on a device or simulator target

    Targets are selected as follows:
      1) --target using device/simulator UUID
      2) A connected device, unless --virtual is used
      3) A running simulator

    If the above criteria are not met, the app is run on the default simulator
    (the last simulator in the list).

    Use --list to list available targets.

  Options:

    --list ............... Print available targets, then quit
    --json ............... Output JSON

    --app <path> ......... Deploy specified .app or .ipa file
    --device ............. Use a device if available
                           With --list prints connected devices
    --virtual ............ Prefer a simulator
                           With --list prints available simulators
    --target <id> ........ Use a specific target
    --connect ............ Tie process to app process
`;
async function run() {
    process.stdout.write(`${help}\n`);
}
exports.run = run;
