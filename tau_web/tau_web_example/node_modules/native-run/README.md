[![github-actions](https://img.shields.io/github/workflow/status/ionic-team/native-run/CI/develop?style=flat-square)](https://github.com/ionic-team/native-run/actions?query=workflow%3ACI)
[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg?style=flat-square)](https://github.com/semantic-release/semantic-release)
[![npm](https://img.shields.io/npm/v/native-run.svg?style=flat-square)](https://www.npmjs.com/package/native-run)

# native-run

`native-run` is a cross-platform command-line utility for running native app binaries (`.ipa` and `.apk` files) on iOS and Android devices. It can be used for both hardware and virtual devices.

This tool is used by the Ionic CLI, but it can be used standalone as part of a development or testing pipeline for launching apps. It doesn't matter whether the `.apk` or `.ipa` is created with Cordova or native IDEs, `native-run` will be able to deploy it.

## Install

`native-run` is written entirely in TypeScript/NodeJS, so there are no native dependencies.

To install, run:

```
npm install -g native-run
```

:memo: Requires NodeJS 10+

## Usage

```
native-run <platform> [options]
```

See the help documentation with the `--help` flag.

```
native-run --help
native-run ios --help
native-run android --help
```

### Troubleshooting

Much more information can be printed to the screen with the `--verbose` flag.
