# Flutter Sound

<img src="https://raw.githubusercontent.com/dooboolab/flutter_sound/master/Logotype primary.png" width="70%" height="70%" />

<p align="left">
  <a href="https://pub.dartlang.org/packages/flutter_sound"><img alt="pub version" src="https://img.shields.io/pub/v/flutter_sound.svg?style=flat-square"></a>
</p>
This plugin provides simple recorder and player functionalities for both Android and iOS platforms.

<br/><br/>

![Demo](https://user-images.githubusercontent.com/27461460/77531555-77c9ec00-6ed6-11ea-9813-320f943b08cc.gif)

## Features

- Play and Record sounds or music with various codecs. (See [the supported codecs here](doc/codec.md#actually-the-following-codecs-are-supported-by-flutter_sound))
- Play local or remote files specified by their URL.
- The App playback can be controled from the device lock screen or from an Apple watch
- Handle playback stream from native (To sync exact time with bridging). [*Not sure to understand what it means!*]

## Flutter Sound branches

We actually maintain two branches for Flutter Sound :

- The V4 branch (the version ^4.0.0)
- The master branch (actually the version ^5.0.0)

We do not expect that everybody will switch today from 4.x.x to 5.x.x.

V4 is our stable branch, and will be maintained as long as everybody will not have switch to V5 :
in other words V4 is our LTS version (Long Term Support).

## Migration Guides

- To migrate [to 4.x.x from 3.x.x](doc/migration_4.x.x.md#migration-from-3xx-to-4xx) you must do some minor changes in your configurations files.
- To migrate [to 5.x.x from 4.x.x](doc/migration_5.x.x.md#migration-form-4xx-to-5xx) you must do a few changes in your App.

## Free Read

[Medium Blog](https://medium.com/@dooboolab/flutter-sound-plugin-audio-recorder-player-e5a455a8beaf). [*This link is probably obsolete!*]

## SDK requirements

- Flutter Sound requires an iOS 9.3 SDK (or later)
- Flutter Sound requires an Android 24 (or later)

## Installation

[Here is a guide](doc/install.md#install) for Flutter Sound installation

## Flutter Sound API

Flutter Sound is composed with 4 modules :

- [FlutterSoundPlayer](doc/player.md#flutter-sound-player-api), wich deal with everything about playbacks
- [FlutterSoudRecorder](doc/recorder.md#flutter-sound-recorder-api), which deal with everything about recording
- [FlutterSoundHelper](doc/helper.md), which offers some convenients tools
- [FlutterSoundUI](doc/ui_widget.md), which offer some Widget ready to be used out of the box

To use Flutter Sound you just do :
```
import 'package:flutter_sound/flutter_sound.dart';
```

This will export all the necessaries dart interfaces.

## Examples (Demo Apps)

Flutter Sound comes with two Demo/Examples :
- [Demo1 app](example/README.md#demo1) is a small demonstration of what we can do with Flutter Sound.
This Demo App is a kind of exerciser which try to implement the major Flutter Sound features. This Demo does not use the Flutter Sound UI Widgets
- [Demo2 app](example/README.md#demo2) is an example of what can be done using the Flutter Sound UI Widgets

## License

Flutter Sound is copyrighted by Dooboolab (2018, 2019, 2020)
Flutter Sound is released under a license with a *copyleft* clause: the LGPL-V3 license. This means that if you modify some of Flutter Sound code you must be publish your modifications under the LGPL license too.

## Contributions

Flutter Sound is a free and Open Source project. Several contributors have already contributed to Flutter Sound. Specially :
- @hyochan who is the Flutter Sound father
- @salvatore373 who wrote the Track Player
- @bsutton who wrote the UI Widgets
- @larpoux who add several codec supports

**We really need your contributions.**
Pull Requests are welcome and will be considered very carefully.


## Bugs, Features Requests, documentation inaccurate, help needed, ...

We use [Github](https://github.com/dooboolab/flutter_sound/issues) actively.

When you fill an issue, we try to answer something in less than 48h. Of course, this will not mean that your issue will be fixed in 48h. But you will know that we confirm (or not) your issue and what answer you can expect. Maintenance is our priority. We try to make it perfect.


## TODO

- [X] Record PCM on Android
- [X] Rewrite the documentation
- [ ] Small examples, smaller than the actual demox.app
- [ ] Record OPUS on Android
- [ ] Streaming records to Speech to Text
- [ ] More support for the Apple Watch
- [ ] Tests unit to avoid any regression
- [ ] Web App support (!!!actually just a dream!!!)


## Help Maintenance

My friend Hyo has been maintaining quite many repos these days and he is burning out slowly. If you could help him cheer up, buy him a cup of coffee will make his life really happy and get much energy out of it. As a side effect, we will know that Flutter Sound is important for you, that you appreciate our job and that you can show it with a little money.
<br/>
<a href="https://www.buymeacoffee.com/dooboolab" target="_blank"><img src="https://www.buymeacoffee.com/assets/img/custom_images/purple_img.png" alt="Buy Me A Coffee" style="height: auto !important;width: auto !important;" ></a>
[![Paypal](https://www.paypalobjects.com/webstatic/mktg/Logo/pp-logo-100px.png)](https://paypal.me/dooboolab)
