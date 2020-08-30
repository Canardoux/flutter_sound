[Back to the README](../README.md#flutter-sound-api)

-----------------------------------------------------------------------------------------------------------------------

# Flutter Sound UI Widgets API

The Widgets offered by the Flutter Sound UI Widgets module are :

- [Sound Recorder](#SoundRecorderUi)
- [Grayed Out](#GrayedOut)
- ...WIP

-----------------------------------------------------------------------------------------------------------------------

## How to use
First import the module
``` import 'fluttersound/flutter_sound_ui.dart```

Then reference to one of the flutter sound UI widgets in your widget tree.

## `SoundRecorderUI`
.. working on describing it.

## `GrayedOut`
/// GreyedOut optionally grays out the given child widget.
/// [child] the child widget to display
/// If [greyedOut] is true then the child will be grayed out and
/// any touch activity over the child will be discarded.
/// If [greyedOut] is false then the child will displayed as normal.
/// The [opacity] setting controls the visiblity of the child
/// when it is greyed out. A value of 1.0 makes the child fully visible,
/// a value of 0.0 makes the child fully opaque.
/// The default value of [opacity] is 0.3.


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

-----------------------------------------------------------------------------------------------------------------------

[Back to the README](../README.md#flutter-sound-api)
