"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.run = void 0;
const help = `
  Usage: native-run [ios|android] [options]

  Options:

    -h, --help ........... Print help for the platform, then quit
    --version ............ Print version, then quit
    --verbose ............ Print verbose output to stderr
    --list ............... Print connected devices and virtual devices

`;
async function run(args) {
    process.stdout.write(help);
}
exports.run = run;
