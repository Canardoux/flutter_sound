---
title:  "Installation"
description: "Flutter Sound installation."
summary: "Flutter Sound installation."
permalink: flutter_sound_install.html
tags: [flutter_sound,installation]
keywords: Flutter, Flutter Sound, installation
---
# Installation

## Install

For help on adding as a dependency, view the [documentation](https://flutter.io/using-packages/).

### Flutter Sound flavors

Flutter Sound comes in two flavors :

* the **FULL** flavor : flutter\_sound
* the **LITE** flavor : flutter\_sound\_lite

The big difference between the two flavors is that the **LITE** flavor does not have `mobile_ffmpeg` embedded inside. There is a huge impact on the memory used, but the **LITE** flavor will not be able to do :

* Support some codecs like Playback OGG/OPUS on iOS or Record OGG\_OPUS on iOS
* Will not be able to offer some helping functions, like `FlutterSoundHelper.FFmpegGetMediaInformation()` or `FlutterSoundHelper.duration()`

Here are the size of example/demo1 iOS .ipa in Released Mode. Those numbers include everything \(flutter library, application, ...\) and not only Flutter Sound.

| Flavor | V4.x | V5.1 |
| :--- | :---: | :--- |
| LITE | 16.2 MB | 17.8 MB |
| FULL | 30.7 MB | 32.1 MB |

### Linking your App directly from `pub.dev`

Add `flutter_sound` or `flutter_sound_lite` as a dependency in pubspec.yaml.

The actual versions are :

* flutter\_sound\_lite: ^5.0.0  \(the LTS version without FFmpeg\)
* flutter\_sound: ^5.0.0 \(the LTS version with FFmpeg embedded\)
* flutter\_sound\_lite: ^6.0.0 \(the current version without FFmpeg\)
* flutter\_sound: ^6.0.0       \(the current version with FFmpeg\)

```text
dependencies:
  flutter:
    sdk: flutter
  flutter_sound: ^6.0.0
```

or

```text
dependencies:
  flutter:
    sdk: flutter
  flutter_sound_lite: ^6.0.0
```

### Linking your App with Flutter Sound sources \(optional\)

The Flutter-Sound sources [are here](https://github.com/canardoux/tau).

There is actually two branches :

* V5. This is the Long Term Support \(LTS\) branch which is maintained under the version 5.x.x
* master. This is the branch currently developed and is released under the version 6.x.x.

If you want to generate your App from the sources with a `FULL` flavor:

```bash
cd some/where
git clone https://github.com/canardoux/tau
cd some/where/flutter_sound
bin/flavor FULL
```

and add your dependency in your pubspec.yaml :

```text
dependencies:
  flutter:
    sdk: flutter
  flutter_sound:
    path: some/where/flutter_sound
```

If you prefer to link your App with the `LITE` flavor :

```bash
cd some/where
git clone https://github.com/canardoux/tau
cd some/where/flutter_sound
bin/flavor LITE
```

and add your dependency in your pubspec.yaml :

```text
dependencies:
  flutter:
    sdk: flutter
  flutter_sound_lite:
    path: some/where/flutter_sound
```

### FFmpeg

flutter\_sound FULL flavor makes use of flutter\_ffmpeg. In contrary to Flutter Sound Version 3.x.x, in Version 4.0.x your App can be built without any Flutter-FFmpeg dependency. `flutter_ffmpeg audio-lts` is now embedding inside the `FULL` flutter\_sound.

If your App needs to use FFmpeg audio package, you must use the embedded version inside flutter\_sound instead of adding a new dependency in your pubspec.yaml.

If your App needs an other FFmpeg package \(for example the "video" package\), use the LITE flavor of Flutter Sound and add yourself the App dependency that you need.

### Post Installation

* On _iOS_ you need to add usage descriptions to `info.plist`:

  ```markup
        <key>NSAppleMusicUsageDescription</key>
        <string>MyApp does not need this permission</string>
        <key>NSCalendarsUsageDescription</key>
        <string>MyApp does not need this permission</string>
        <key>NSCameraUsageDescription</key>
        <string>MyApp does not need this permission</string>
        <key>NSContactsUsageDescription</key>
        <string>MyApp does not need this permission</string>
        <key>NSLocationWhenInUseUsageDescription</key>
        <string>MyApp does not need this permission</string>
        <key>NSMotionUsageDescription</key>
        <string>MyApp does not need this permission</string>
        <key>NSSpeechRecognitionUsageDescription</key>
        <string>MyApp does not need this permission</string>
        <key>UIBackgroundModes</key>
        <array>
                <string>audio</string>
        </array>
        <key>NSMicrophoneUsageDescription</key>
        <string>MyApp uses the microphone to record your speech and convert it to text.</string>
  ```

* On _Android_ you need to add a permission to `AndroidManifest.xml`:

  ```markup
  <uses-permission android:name="android.permission.RECORD_AUDIO" />
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
  ```

### Flutter Web

To use Flutter Sound in a web application, you can either :

#### Static reference

Add those 4 lines at the end of the `<head>` section of your `index.html` file :

```text
  <script src="assets/packages/flutter_sound_web/js/flutter_sound/flutter_sound.js"></script>
  <script src="assets/packages/flutter_sound_web/js/flutter_sound/flutter_sound_player.js"></script>
  <script src="assets/packages/flutter_sound_web/js/flutter_sound/flutter_sound_recorder.js"></script>
  <script src="assets/packages/flutter_sound_web/js/howler/howler.js"></script>
```

#### or Dynamic reference

Add those 4 lines at the end of the `<head>` section of your `index.html` file :

```text
  <script src="https://cdn.jsdelivr.net/npm/tau_engine@6/js/flutter_sound/flutter_sound.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/tau_engine@6/js/flutter_sound/flutter_sound_player.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/tau_engine@6/js/flutter_sound/flutter_sound_recorder.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/howler@2/dist/howler.min.js"></script>
```

Please [read this](https://www.jsdelivr.com/features) to understand how you can specify the interval of the versions you are interested by.

### Troubles shooting

#### Problem with Cocoapods

If you get this message \(specially after the release of a new Flutter Version\) :

```text
Cocoapods could not find compatible versions for pod ...
```

you can try the following instructions sequence \(and ignore if some commands gives errors\) :

```bash
cd ios
pod cache clean --all
rm Podfile.lock
rm -rf .symlinks/
cd ..
flutter clean
flutter pub get
cd ios
pod update
pod repo update
pod install --repo-update
pod update
pod install
cd ..
```

If everything good, the last `pod install` must not give any error.

