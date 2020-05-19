[Back to the README](../README.md#Installation)

--------------------------------------------------------------------------------------------------------------

# Install

For help on adding as a dependency, view the [documentation](https://flutter.io/using-packages/).

## Flutter Sound flavors

Flutter Sound comes in two flavors :
- the **FULL** flavor : flutter_sound
- the **LITE** flavor : flutter_sound_lite

The big difference between the two flavors is that the **LITE** flavor does not have `mobile_ffmpeg` embedded inside.
There is a huge impact on the memory used, but the **LITE** flavor will not be able to do :
- Support some codecs like Playback OGG/OPUS on iOS or Record OGG_OPUS on iOS
- Will not be able to offer some helping functions, like `FlutterSoundHelper.FFmpegGetMediaInformation()` or `FlutterSoundHelper.duration()`

## Linking your App directly from `pub.dev`

Add `flutter_sound` or `flutter_sound_lite` as a dependency in pubspec.yaml.

The actual versions are :
- flutter_sound_lite: ^4.0.0  (the LTS version without FFmpeg)
- flutter_sound: ^4.0.0       (the LTS version with FFmpeg embedded)

- flutter_sound_lite: ^5.0.0  (the current version without FFmpeg)
- flutter_sound: ^5.0.0       (the current version with FFmpeg)

```
dependencies:
  flutter:
    sdk: flutter
  flutter_sound: ^5.0.0
```
or
```
dependencies:
  flutter:
    sdk: flutter
  flutter_sound_lite: ^5.0.0
```

## Linking your App with Flutter Sound sources

The Flutter-Sound sources [are here](https://github.com/dooboolab/flutter_sound).

There is actually two branches :
- V4. This is the Long Term Support (LTS) branch which is maintained under the version 4.x.x
- master. This is the branch currently developed and is released under the version 5.x.x.

If you want to generate your App from the sources with a `FULL` flavor:

```sh
cd some/where
git clone https://github.com/dooboolab/flutter_sound
cd some/where/flutter_sound
bin/flavor FULL
```

and add your dependency in your pubspec.yaml :

```
dependencies:
  flutter:
    sdk: flutter
  flutter_sound:
    path: some/where/flutter_sound
```

If you prefer to link your App with the `LITE` flavor :

```sh
cd some/where
git clone https://github.com/dooboolab/flutter_sound
cd some/where/flutter_sound
bin/flavor LITE
```

and add your dependency in your pubspec.yaml :

```
dependencies:
  flutter:
    sdk: flutter
  flutter_sound_lite:
    path: some/where/flutter_sound
```


## FFmpeg

flutter_sound FULL flavor makes use of flutter_ffmpeg. In contrary to Flutter Sound Version 3.x.x, in Version 4.0.x your App can be built without any Flutter-FFmpeg dependency.
```flutter_ffmpeg audio-lts``` is now embedding inside the `FULL` flutter_sound.

If your App needs to use FFmpeg audio package, you must use the embedded version inside flutter_sound instead of adding a new dependency in your pubspec.yaml.

If your App needs an other FFmpeg package (for example the "video" package), use the LITE flavor of Flutter Sound and add yourself the App dependency that you need.


## Post Installation

- On _iOS_ you need to add usage descriptions to `info.plist`:

  ```xml
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

- On _Android_ you need to add a permission to `AndroidManifest.xml`:

  ```xml
  <uses-permission android:name="android.permission.RECORD_AUDIO" />
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
  ```

-----------------------------------------------------------------------------------------------------------------------------------------------------------------

[Back to the README](../README.md#Installation)