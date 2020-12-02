<img src="https://raw.githubusercontent.com/canardoux/tau/master/banner.png" width="100%" height="100%" />

<p align="left">
  <a href="https://dooboolab.github.io/flutter_sound/book/flutter_sound"><img alt="pub version" src="https://img.shields.io/pub/v/flutter_sound.svg?style=flat-square"></a>
</p>


-------------------------------------------------------------------------------------

- # Flutter Sound user: your [documentation is there](https://dooboolab.github.io/flutter_sound/book)
- # The [CHANGELOG file is here](https://dooboolab.github.io/flutter_sound/book/CHANGELOG.html)
- # The [sources are here](https://github.com/dooboolab/flutter_sound)

---------

# Flutter Sound V6.x is OUT

Please refer to the [CHANGELOG.md file](https://dooboolab.github.io/flutter_sound/book/CHANGELOG.html) to learn about all the great new features. It has the following :

## Flutter Web support

Flutter Sound is supported by Flutter Web. You can play with [this live demo on the web](https://dooboolab.github.io/flutter_sound/doc/flutter_sound/web_example) (still cannot record with Safari or any web browser on iOS). You can [read this](https://dooboolab.github.io/flutter_sound/book/tau/codec.html#flutter-sound-on-flutter-web).

## Record to Dart Stream

This feature has been requested for many months from many, many, many Flutter Sound users. This opens doors to things like feeding a Speech-to-Text engine.

You can refer to the [Getting Started with Record-to-Stream](https://dooboolab.github.io/flutter_sound/book/tau/codec.html#recording-pcm-16-to-a-dart-stream) notice.

## Playback from a live Dart Stream

This feature has also been requested for many months from many Flutter Sound users.

You can refer to the [Getting Started with Playback-from-Stream](https://dooboolab.github.io/flutter_sound/book/tau/codec.html#playing-pcm-16-from-a-dart-stream) notice.

-----------------------------------------------------------------------------------------------------------------------------------

![Demo](https://user-images.githubusercontent.com/27461460/77531555-77c9ec00-6ed6-11ea-9813-320f943b08cc.gif)

## Overview

Flutter Sound is a Flutter package allowing you to play and record audio for :
- Android
- iOS
- Flutter Web

Maybe, one day, we will be supported by Linux, Macos, and even (why not) Windows. But this is not top of our priorities.

Flutter Sound provides both a high level API and widgets for:

* play audio
* record audio

Flutter Sound can be used to play a beep from an asset all the way up to implementing a complete media player.

The API is designed so you can use the supplied widgets or roll your own.

- Flutter Sound requires an iOS 9.3 SDK (or later)
- Flutter Sound requires an Android API level 21 (or later)

## Features

The Flutter Sound package includes the following features

- Play and Record flutter sound or music with various codecs. (See [the supported codecs here](https://dooboolab.github.io/flutter_sound/book/tau/codec.html#flutter-sound-codecs))
- Play local or remote files specified by their URL.
- Play assets.
- Play audio using the built in SoundPlayerUI Widget.
- Roll your own UI utilising the Flutter Sound api.
- Record audio using the builtin SoundRecorderUI Widget.
- Roll your own Recording UI utilising the Flutter Sound api.
- Support for releasing/resuming resources when the app pauses/resumes.
- Record to a Dart Stream
- Playback from a Dart Stream
- The App playback can be controled from the device lock screen or from an Apple watch

## Changelog

You can find the [changes here](https://dooboolab.github.io/flutter_sound/book/CHANGELOG.html)

## Documentation

The [documentation is here](https://dooboolab.github.io/flutter_sound/book/)

## License

Flutter Sound is copyrighted by Dooboolab (2018, 2019, 2020).
Flutter Sound is released under a license with a *copyleft* clause: the LGPL-V3 license. This means that if you modify some of Flutter Sound code you must publish your modifications under the LGPL license too.


## Help Maintenance

Flutter Sound is a fundamental building block needed by almost every flutter project.

I'm looking to make Flutter Sound the go to project for Flutter Audio with support for each of the Flutter supported platforms.

Flutter Sound is a large and complex project which requires me to maintain multiple hardware platforms and test environments.

I greatly appreciate any contributions to the project which can be as simple as providing feedback on the API or documentation.


My friend Hyo has been maintaining quite many repos these days and he is burning out slowly. If you could help him cheer up, buy him a cup of coffee will make his life really happy and get much energy out of it. As a side effect, we will know that Flutter Sound is important for you, that you appreciate our job and that you can show it with a little money.

<a href="https://www.buymeacoffee.com/dooboolab" target="_blank"><img src="https://www.buymeacoffee.com/assets/img/custom_images/purple_img.png" alt="Buy Me A Coffee" style="height: auto !important;width: auto !important;" ></a>
[![Paypal](https://www.paypalobjects.com/webstatic/mktg/Logo/pp-logo-100px.png)](https://paypal.me/dooboolab)
