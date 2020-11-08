[Back to the README](../README.md#flutter-sound-api)

-----------------------------------------------------------------------------------------------------------------------

# Flutter Sound UI Widgets API

The Widgets offered by the Flutter Sound UI Widgets module are :

- [Sound Player UI](#SoundPlayerUI)
- [Sound Recorder UI](#SoundRecorderUI)

-----------------------------------------------------------------------------------------------------------------------

## How to use
First import the module
``` import 'fluttersound/flutter_sound_ui.dart```

Then reference to one of the flutter sound UI widgets in your widget tree:

- [Sound Player UI](#SoundPlayerUI)
- [Sound Recorder UI](#SoundRecorderUI)

## `SoundPlayerUI`
To use add FOREGROUND_SERVICE permission.

### Android
Add this line to your AndroidManifest.xml
```
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
```

### Style of the `SoundPlayerUI` widget

The two constructors of the `SoundPlayerUI` widget have 6 optional parameters for allowing the App to tune the UI presentation:

- Color backgroundColor = Colors.grey,
- Color iconColor = Colors.black,
- Color disabledIconColor = Colors.blueGrey,
- TextStyle textStyle = null,
- TextStyle titleStyle = null,
- SliderThemeData sliderThemeData = null,

## `SoundRecorderUI`
...working on documentation.

-----------------------------------------------------------------------------------------------------------------------

[Back to the README](../README.md#flutter-sound-api)
