# API Reference 1

&lt;!DOCTYPE html&gt;

flauto - Dart API docs  

1. [flauto package](https://canardoux.github.io/tau/book/flutter_sound/)

flauto  

1. [flauto package](https://canardoux.github.io/tau/book/flutter_sound/)

**flauto package**

1. Topics
2. [Main](main-topic.md)
3. [UI Widgets](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/topics/UI%20Widgets-topic.html)
4. [Utilities](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/topics/Utilities-topic.html)
5. Libraries
6. Main
7. [player](player-library.md)
8. [recorder](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/recorder/recorder-library.html)
9. [tau](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/tau/tau-library.html)
10. UI Widgets
11. [ui\_controller](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/ui_controller/ui_controller-library.html)
12. [ui\_player](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/ui_player/ui_player-library.html)
13. [ui\_recorder](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/ui_recorder/ui_recorder-library.html)
14. Utilities
15. [enum\_helper](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/enum_helper/enum_helper-library.html)
16. [ffmpeg](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/ffmpeg/ffmpeg-library.html)
17. [helper](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/helper/helper-library.html)
18. [log](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/log/log-library.html)
19. [stack\_trace](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/stack_trace/stack_trace-library.html)
20. [temp\_file\_system](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/temp_file_system/temp_file_system-library.html)
21. [wave\_header](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/wave_header/wave_header-library.html)

![](https://raw.githubusercontent.com/canardoux/tau/master/banner.png)

 [![pub version](https://img.shields.io/pub/v/flauto.svg?style=flat-square)](https://canardoux.github.io/tau/book/flutter_sound)

* **Flutter Sound user: your** [**documentation is there**](https://canardoux.github.io/tau/book)\*\*\*\*
* **The** [**CHANGELOG file is here**](https://canardoux.github.io/tau/book/CHANGELOG.html)\*\*\*\*
* **The** [**sources are here**](https://github.com/canardoux/tau)\*\*\*\*

## Flutter Sound V6.x is OUT <a id="flutter-sound-v6x-is-out"></a>

Please refer to the [CHANGELOG.md file](https://canardoux.github.io/tau/book/CHANGELOG.html) to learn about all the great new features. It has the following :

### Flutter Web support <a id="flutter-web-support"></a>

Flutter Sound is supported by Flutter Web. You can play with [this live demo on the web](https://canardoux.github.io/tau/doc/flutter_sound/web_example) \(still cannot record with Safari or any web browser on iOS\). You can [read this](https://canardoux.github.io/tau/book/tau/codec.html#flutter-sound-on-flutter-web).

### Record to Dart Stream <a id="record-to-dart-stream"></a>

This feature has been requested for many months from many, many, many Flutter Sound users. This opens doors to things like feeding a Speech-to-Text engine.

You can refer to the [Getting Started with Record-to-Stream](https://canardoux.github.io/tau/book/tau/codec.html#recording-pcm-16-to-a-dart-stream) notice.

### Playback from a live Dart Stream <a id="playback-from-a-live-dart-stream"></a>

This feature has also been requested for many months from many Flutter Sound users.

You can refer to the [Getting Started with Playback-from-Stream](https://canardoux.github.io/tau/book/tau/codec.html#playing-pcm-16-from-a-dart-stream) notice.

![Demo](https://user-images.githubusercontent.com/27461460/77531555-77c9ec00-6ed6-11ea-9813-320f943b08cc.gif)

### Overview <a id="overview"></a>

Flutter Sound is a Flutter package allowing you to play and record audio for :

* Android
* iOS
* Flutter Web

Maybe, one day, we will be supported by Linux, Macos, and even \(why not\) Windows. But this is not top of our priorities.

Flutter Sound provides both a high level API and widgets for:

* play audio
* record audio

Flutter Sound can be used to play a beep from an asset all the way up to implementing a complete media player.

The API is designed so you can use the supplied widgets or roll your own.

* Flutter Sound requires an iOS 9.3 SDK \(or later\)
* Flutter Sound requires an Android API level 21 \(or later\)

### Features <a id="features"></a>

The Flutter Sound package includes the following features

* Play and Record flutter sound or music with various codecs. \(See [the supported codecs here](https://canardoux.github.io/tau/book/tau/codec.html#flutter-sound-codecs)\)
* Play local or remote files specified by their URL.
* Play assets.
* Play audio using the built in SoundPlayerUI Widget.
* Roll your own UI utilising the Flutter Sound api.
* Record audio using the builtin SoundRecorderUI Widget.
* Roll your own Recording UI utilising the Flutter Sound api.
* Support for releasing/resuming resources when the app pauses/resumes.
* Record to a Dart Stream
* Playback from a Dart Stream
* The App playback can be controled from the device lock screen or from an Apple watch

### Changelog <a id="changelog"></a>

You can find the [changes here](https://canardoux.github.io/tau/book/CHANGELOG.html)

### Documentation <a id="documentation"></a>

The [documentation is here](https://canardoux.github.io/tau/book/)

### License <a id="license"></a>

Flutter Sound is copyrighted by Dooboolab \(2018, 2019, 2020\). Flutter Sound is released under a license with a _copyleft_ clause: the LGPL-V3 license. This means that if you modify some of Flutter Sound code you must publish your modifications under the LGPL license too.

### Help Maintenance <a id="help-maintenance"></a>

Flutter Sound is a fundamental building block needed by almost every flutter project.

I'm looking to make Flutter Sound the go to project for Flutter Audio with support for each of the Flutter supported platforms.

Flutter Sound is a large and complex project which requires me to maintain multiple hardware platforms and test environments.

I greatly appreciate any contributions to the project which can be as simple as providing feedback on the API or documentation.

My friend Hyo has been maintaining quite many repos these days and he is burning out slowly. If you could help him cheer up, buy him a cup of coffee will make his life really happy and get much energy out of it. As a side effect, we will know that Flutter Sound is important for you, that you appreciate our job and that you can show it with a little money.

[![Buy Me A Coffee](https://www.buymeacoffee.com/assets/img/custom_images/purple_img.png)](https://www.buymeacoffee.com/dooboolab) [![Paypal](https://www.paypalobjects.com/webstatic/mktg/Logo/pp-logo-100px.png)](https://paypal.me/dooboolab)

### Libraries

#### Main

 [player](player-library.md) [Main](main-topic.md) **THE** Flutter Sound Player [recorder](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/recorder/recorder-library.html) [Main](main-topic.md) **THE** Flutter Sound Recorder [tau](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/tau/tau-library.html) [Main](main-topic.md) [\[...\]](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/tau/tau-library.html)

#### UI Widgets

 [ui\_controller](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/ui_controller/ui_controller-library.html) [UI Widgets](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/topics/UI%20Widgets-topic.html) [\[...\]](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/ui_controller/ui_controller-library.html) [ui\_player](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/ui_player/ui_player-library.html) [UI Widgets](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/topics/UI%20Widgets-topic.html) [\[...\]](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/ui_player/ui_player-library.html) [ui\_recorder](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/ui_recorder/ui_recorder-library.html) [UI Widgets](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/topics/UI%20Widgets-topic.html) [\[...\]](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/ui_recorder/ui_recorder-library.html)

#### Utilities

 [enum\_helper](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/enum_helper/enum_helper-library.html) [Utilities](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/topics/Utilities-topic.html) [\[...\]](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/enum_helper/enum_helper-library.html) [ffmpeg](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/ffmpeg/ffmpeg-library.html) [Utilities](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/topics/Utilities-topic.html) [\[...\]](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/ffmpeg/ffmpeg-library.html) [helper](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/helper/helper-library.html) [Utilities](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/topics/Utilities-topic.html) [\[...\]](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/helper/helper-library.html) [log](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/log/log-library.html) [Utilities](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/topics/Utilities-topic.html) [\[...\]](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/log/log-library.html) [stack\_trace](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/stack_trace/stack_trace-library.html) [Utilities](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/topics/Utilities-topic.html) [\[...\]](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/stack_trace/stack_trace-library.html) [temp\_file\_system](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/temp_file_system/temp_file_system-library.html) [Utilities](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/topics/Utilities-topic.html) [\[...\]](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/temp_file_system/temp_file_system-library.html) [wave\_header](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/wave_header/wave_header-library.html) [Utilities](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/topics/Utilities-topic.html) [\[...\]](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/wave_header/wave_header-library.html) flauto 6.4.5+1

