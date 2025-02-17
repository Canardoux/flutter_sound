---
title:  "Installation"
summary: "Flutter Sound installation."
permalink: fs-guides_install.html
---
# Installation

## Install

Flutter Sound is a regular Flutter plugin. For help on adding a Flutter plugin as a dependency, view the Flutter [documentation](https://flutter.io/using-packages/).

## SDK requirements

* Flutter Sound requires an iOS 10.0 SDK \(or later\)
* Flutter Sound requires an Android 21 \(or later\)

## Linking your App directly from `pub.dev`

Add `flutter_sound` as a dependency in pubspec.yaml.

The actual version is : 9.x. A version 10.0 is currentely being developped. See `Taudio`, downside.

```text
dependencies:
  flutter:
    sdk: flutter
  flutter_sound: ^9.23
```

## Linking your App with Flutter Sound sources \(optional\)

The Flutter-Sound sources [are here](https://github.com/canardoux/flutter_sound).
It is a subproject of [tau](https://github.com/canardoux/tau)

You probably want to look to [the Dev notice](fs-guides_dev.html)

```bash
cd /some/where
git clone --recursive https://github.com/canardoux/tau
cd /some/where/tau
bin/reldev.sh DEV
```

and add your dependency in your pubspec.yaml :

```text
dependencies:
  flutter:
    sdk: flutter
  flutter_sound:
    path: /some/where/tau/flutter_sound
```

## FFmpeg

From version 9.x, Flutter Sound does not depend anymore on Flutter FFmpeg.
If the App needs to do some audio conversions, it must depend itself on Flutter FFmpeg and include the apropriate interface.

Flutter FFmpeg is really great. Huge but great. It can help you to handle sound files.
Flutter Sound is for playing or recording. Not to manipulate sound files.

## Post Installation

* On _iOS_ you may need to add usage descriptions to `info.plist`:

  ```markup
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

## Flutter Web

From version 9.x, the app does not need anymore to include the Flutter Sound library in its 'index.html'.

## Troubles shooting

### Problem with Cocoapods

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

### Problem with the linker during iOS link-edit

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