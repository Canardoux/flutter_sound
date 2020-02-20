# flutter_sound_example
This is not a playlist audio module and this library provides simple recorder and player functionalities for both `android` and `ios` platforms. This only supports default file extension for each platform. This module can also handle file from url.

## Getting Started

For help getting started with Flutter, view our online
[documentation](https://flutter.io/).

## Install
Add ```flutter_sound``` as a dependency in pubspec.yaml
For help on adding as a dependency, view the [documentation](https://flutter.io/using-packages/).

## Post Installation
On *iOS* you need to add a usage description to `info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>This sample uses the microphone to record your speech and convert it to text.</string>
<key>UIBackgroundModes</key>
<array>
	<string>audio</string>
</array>
```

On *Android* you need to add a permission to `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
```
