## 1.4.1
+ Fixed 'mediaplayer went away with unhandled events' bug [#83](https://github.com/dooboolab/flutter_sound/pull/83)
## 1.4.0
+ AndroidX compatibility improved [#68](https://github.com/dooboolab/flutter_sound/pull/68)
+ iOS: Fixes for seekToPlayer [#72](https://github.com/dooboolab/flutter_sound/pull/72)
+ iOS: Setup configuration for using bluetooth microphone recording input [#73](https://github.com/dooboolab/flutter_sound/pull/73)

## 1.3.6
+ Android: Adds a single threaded command scheduler for all recording related
  commands.
+ Switch source & target compability to Java 8
+ Bump gradle plugin version dependencies

## 1.3.+
+ Support db/meter [#41](https://github.com/dooboolab/flutter_sound/pull/41)
+ Show wrong recorder timer text [#47](https://github.com/dooboolab/flutter_sound/pull/47)
+ Add ability to specify Android & iOS encoder [#49](https://github.com/dooboolab/flutter_sound/pull/49)
+ Adjust db range and fix nullable check in ios [#59](https://github.com/dooboolab/flutter_sound/pull/59)
+ Android: Recording operations on a separate command queue [#66](https://github.com/dooboolab/flutter_sound/pull/66)
+ Android: Remove reference to non-AndroidX classes which improves compatibility

## 1.2.+
* Fixed sound distorting when playing recorded audio again. Issue [#14](https://github.com/dooboolab/flutter_sound/issues/14).
* Fixed `seekToPlayer` for android. Issue [#10](https://github.com/dooboolab/flutter_sound/issues/10).
+ Expose recorder `sampleRate` and `numChannel`.
+ Do not append `tmp` when filePath provided in `ios`.
+ Resolve `regression` issue in `1.2.3` which caused in `1.2.2`.
+ Reduce the size of audio file in `1.2.4`. Related [#26](https://github.com/dooboolab/flutter_sound/issues/26).
+ Fixed `recording` issue in android in `1.2.5`.
+ Changed `seekToPlayer` to place exact `secs` instead adding it.
+ Fix file URI for recording and playing in iOS.
## 1.1.+
* Released 1.1.0 with beautiful logo from mansa.
* Improved readme.
* Resolve #7.
* Fixed missing break in switch statement.
## 1.0.9
* Reimport `intl` which is needed to format date in Dart.
## 1.0.8
* Implemented `setVolume` method.
* Specific error messages given in android.
* Manage ios player thread when audio is not loaded.
## 1.0.7
* Safer handling of progressUpdate in ios when audio is invalid.
## 1.0.6
* Fixed bug in platform specific code.
## 1.0.5
* Fixed pug in `seekToPlayer` in `ios`.
## 1.0.3
* Added license.
## 1.0.0
* Released preview version for audio `recorder` and `player`.
