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

### SDK requirements

* Flutter Sound requires an iOS 10.0 SDK \(or later\)
* Flutter Sound requires an Android 21 \(or later\)

### Flutter Sound flavors

From version 9.x, Flutter Sound does not have anymore two flavors (LITE/FULL).
There is now just one plugin.
Flutter Sound comes in two flavors :

### Linking your App directly from `pub.dev`

Add `flutter_sound` or `flutter_sound_lite` as a dependency in pubspec.yaml.

The actual versions are :

* flutter\_sound\_lite: ^8.3.9  \(the LTS version without FFmpeg\)
* flutter\_sound: ^8.3.9 \(the LTS version with FFmpeg embedded\)

```text
dependencies:
  flutter:
    sdk: flutter
  flutter_sound: ^8.3.9
```

or

```text
dependencies:
  flutter:
    sdk: flutter
  flutter_sound_lite: ^8.3.9
```

**Additional iOS Setup for Recording**

If your app requires recording functionality on iOS, you will need to configure the audio session using the `audio_session` package. Add it to your dependencies in `pubspec.yaml`:
```text
dependencies:
  flutter:
    sdk: flutter
  audio_session: ^0.1.21
```

### Linking your App with Flutter Sound sources \(optional\)

The Flutter-Sound sources [are here](https://github.com/dooboolab/flutter_sound).

There is actually two branches :

* V7. This is the last release which is not compliant with Dart Null Safety
* master. This is the branch currently developed and is released under the version 8.x.x.

You probably want to look to [the Dev notice](tau_dev.html)
If you want to generate your App from the sources with a `FULL` flavor:

```bash
cd some/where
git clone https://github.com/dooboolab/flutter_sound
cd some/where/flutter_sound
bin/reldev.sh DEV
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
git clone https://github.com/dooboolab/flutter_sound
cd some/where/flutter_sound
bin/reldev.sh DEV
bin/flavor.sh LITE
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

From version 9.x, Flutter Sound does not depend anymore on Flutter FFmpeg.
If the App needs to do some audio conversions, it must depend itself on Flutter FFmpeg and include the apropriate interface.

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

If your App needs to play remote files you possibly must add :

```markup
       <key>NSAppTransportSecurity</key>
       <dict>
               <key>NSAllowsArbitraryLoads</key>
               <true/>
       </dict>
```

* On _Android_ you need to add a permission to `AndroidManifest.xml`:

  ```markup
  <uses-permission android:name="android.permission.RECORD_AUDIO" />
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
  ```

### Flutter Web

From version 9.x, the app does not need anymore to include the Flutter Sound library in its 'index.html'.

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

#### Problem with the linker during iOS link-edit

If you get this strange message from the Xcode linker : 
```
Undefined symbols for architecture arm64:
"___gxx_personality_v0",
```

Just add those 2 flags in XCode > Build Settings > Other Linker Flags :

```
-lc++
-lstd++
```
