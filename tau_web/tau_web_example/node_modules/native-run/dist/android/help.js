"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.run = void 0;
const help = `
  Usage: native-run android [options]

    Run an .apk on a device or emulator target

    Targets are selected as follows:
      1) --target using device/emulator serial number or AVD ID
      2) A connected device, unless --virtual is used
      3) A running emulator

    If the above criteria are not met, an emulator is started from a default
    AVD, which is created if it does not exist.

    Use --list to list available targets.

  Options:

    --list .................. Print available targets, then quit
    --sdk-info .............. Print SDK information, then quit
    --json .................. Output JSON


    --app <path> ............ Deploy specified .apk file
    --device ................ Use a device if available
                              With --list prints connected devices
    --virtual ............... Prefer an emulator
                              With --list prints available emulators
    --target <id> ........... Use a specific target
    --connect ............... Tie process to app process
    --forward <port:port> ... Forward a port from device to host
`;
async function run(args) {
    process.stdout.write(`${help}\n`);
}
exports.run = run;
