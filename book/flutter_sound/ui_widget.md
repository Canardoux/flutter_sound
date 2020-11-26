# Flutter Sound UI Widgets API

The modules offered for the Flutter Sound UI Widgets are :

- [UI Player](../ui_player/ui_player-library.html)
- [UI Recorder](../ui_recorder/ui_recorder-library.html)
- [UI Controller](../ui_controller/ui_controller-library.html)

*(This documentation is just a start. It must be completely rewriten)*

-----------------------------------------------------------------------------------------------------------------------

## How to use
First import the modules
``` import 'flutter_sound.dart```

Then reference to one of the flutter sound UI widgets in your widget tree:

- [UI Player](../ui_player/ui_player-library.html)
- [UI Recorder](../ui_recorder/ui_recorder-library.html)
- [UI Controller](../ui_controller/ui_controller-library.html)

--------------------------------------------------------------------------------

## `UI Player`

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

*...working on documentation.*

--------------------------------------------------------------------------

## `UI Recorder`

*...working on documentation.*

--------------------------------------------------------------------------

## `UI Controller`

*...working on documentation.*

