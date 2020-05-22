## 5.0.1

- Flutter Sound V5 is published under the LGPL license.

## 5.0.0

- New API documentation
- Changed the global enums names to CamelCase, to be conform with Google recommandations
- Remove the OS dependant parameters from startRecorder()
- Add a new parameter to `startPlayer()` : the Audio Focus requested
- Support of [new codecs](doc/codec.md#actually-the-following-codecs-are-supported-by-flutter_sound), both for Android and iOS.
- Remove the authorization request from `startRecorder()`
- Remove the NULL posted when the player or the recorder is closed.
- The Audio Focus is **NOT** automaticaly abandoned between two `startPlayer()` or two `startRecorder()`

## 4.0.4+1

- Fix a bug in `resumeRecorder()` on Android : the dbPeak Stream was not restored after a resume()
- Fix a bug in `resumeRecorder()` : the returned value was sometimes a boolean instead of a String.

## 4.0.3+1

- Check the Initialization Status, before accessing Flutter Sound Modules [#307](https://github.com/dooboolab/flutter_sound/issues/307)
- Fixes : Pausing a recording doesn't 'pause' the duration. [#278](https://github.com/dooboolab/flutter_sound/issues/278)
- Fix a crash that we had when accessing the global variable AndroidActivity from `BackGroundAudioSerice.java` [#317](https://github.com/dooboolab/flutter_sound/issues/317)

## 4.0.1+1

- "s.static_framework = true" in flutter_sound.podspec

## 4.0.0

- Adds pedantic lints and major refactoring of example with bug fixes. [#279](https://github.com/dooboolab/flutter_sound/pull/279)
- Native code is directely linked with FFmpeg. Flutter Sound App does not need any more to depends on flutter_ffmpeg [#265](https://github.com/dooboolab/flutter_sound/issues/265) and [273](https://github.com/dooboolab/flutter_sound/issues/273)
- Add a new parameter in the Track structure : albumArtFile
- A new flutter plugin is born : `flutter_sound_lite` [#291](https://github.com/dooboolab/flutter_sound/issues/291)
- Adds a new parameter `whenPaused:` to the `startPlayerFromTrack()` function. [#314](https://github.com/dooboolab/flutter_sound/issues/314)
- Fix bug for displaying a remote albumArt on Android. [#290](https://github.com/dooboolab/flutter_sound/issues/290)


## 3.1.10

- Trying to catch Android crash during a dirty Timer. [#289](https://github.com/dooboolab/flutter_sound/issues/289)

## 3.1.9

- Trying to fix the Android crash when AndroidActivity is null [#296](https://github.com/dooboolab/flutter_sound/issues/296)

## 3.1.8

- Fix a bug ('async') when the app forget to initalize its Flutter Sound module. [#287](https://github.com/dooboolab/flutter_sound/issues/287)

## 3.1.7

- Codec PCM for recorder on iOS
- Optional argument ```requestPermission``` before ```startRecorder()``` so that the App can control itself the recording permissions. [#283](https://github.com/dooboolab/flutter_sound/pull/283)


## 3.1.6+1

- Fix a bug when initializing for Flutter Embedded V1 on Android [#267](https://github.com/dooboolab/flutter_sound/issues/267)
- Add _removePlayerCallback, _removeRecorderCallback() and _removeDbPeakCallback() inside release() [#248](https://github.com/dooboolab/flutter_sound/pull/248)
- Fix conflict with permission_handler 5.x.x [#274](https://github.com/dooboolab/flutter_sound/pull/274)
- On iOS, ```setMeteringEnabled:YES``` is called during ```setDbLevelEnabled()``` [#252](https://github.com/dooboolab/flutter_sound/pull/252), [#251](https://github.com/dooboolab/flutter_sound/issues/251)
- The call to ```initialize()``` is now optional [271](https://github.com/dooboolab/flutter_sound/issues/271)
- README : [#265](https://github.com/dooboolab/flutter_sound/issues/265)

## 3.1.5

- Fix README : [#268](https://github.com/dooboolab/flutter_sound/pull/268)

## 3.1.4

- Change dependecies in range
  ```
  permission_handler: ">=4.0.0 <5.0.0"
  flutter_ffmpeg: ">=0.2.0 <1.0.0"
  ```

## 3.1.3

- The `isRecording` variable is false when the recorder is paused [#266](https://github.com/dooboolab/flutter_sound/issues/266)

## 3.1.2

- Flutter Sound depends on permission_handler: ^4.4.0 [#263](https://github.com/dooboolab/flutter_sound/issues/263)

## 3.1.0

- flutter_sound modules are re-entrant [#250](https://github.com/dooboolab/flutter_sound/issues/250) and [#232](https://github.com/dooboolab/flutter_sound/issues/232)
  - We can open several `FlutterSoundPlayer` at the same time
  - We can open several `FlutterSoundRecorder` at the same time
- Add new API verbs : [#244](https://github.com/dooboolab/flutter_sound/issues/244)
  - flutterSoundHelper.getLastFFmpegReturnCode()
  - flutterSoundHelper.getLastFFmpegCommandOutput()
  - flutterSoundHelper.FFmpegGetMediaInformation() which return info on the given record
  - flutterSoundHelper.duration() which return the number of milli-seconds for the given record
- Add new API verbs : [##242](https://github.com/dooboolab/flutter_sound/issues/242)
  - FlutterSoundRecorder.pauseRecorder()
  - FlutterSoundRecorder.resumeRecorder()
- flutter_sound is now compatible with permission_handler 5.x.x [#259](https://github.com/dooboolab/flutter_sound/issues/259)
- API to control the `audiofocus` [#219](https://github.com/dooboolab/flutter_sound/issues/219)
- API to set the `audio-category` (i.e. duck-others) [#219](https://github.com/dooboolab/flutter_sound/issues/219)
- AndroidX and Android embbeded-V2 support [#203](https://github.com/dooboolab/flutter_sound/issues/203)
- Add a parameter to `startPlayer` to specify a callback when the song is finished [#215](https://github.com/dooboolab/flutter_sound/issues/215)
- License is now LGPL 3.0 instead of MIT

## 3.0.0+1

- bugfix [#254](https://github.com/dooboolab/flutter_sound/issues/254)

## 3.0.0

- Module `flauto` for controlling flutter_sound from the lock-screen [219](https://github.com/dooboolab/flutter_sound/issues/219) and [#243](https://github.com/dooboolab/flutter_sound/pull/243)
  > Highly honor [Larpoux](https://github.com/Larpoux), [bsutton](https://github.com/bsutton), [salvatore373](https://github.com/salvatore373) :tada:!

## 2.1.1

- Handle custom audio path from [path_provider](https://pub.dev/packages/path_provider).

## 2.0.5

- Hotfix [#221](https://github.com/dooboolab/flutter_sound/issues/221)
- Use AAC-LC format instead of MPEG-4 [#209](https://github.com/dooboolab/flutter_sound/pull/209)

## 2.0.4

- OGG/OPUS support on iOS [#199](https://github.com/dooboolab/flutter_sound/pull/199)

## 2.0.3

- Resolve [#194](https://github.com/dooboolab/flutter_sound/issues/194)
  - `stopReocorder` resolve path.
- Resolve [#198](https://github.com/dooboolab/flutter_sound/issues/198)
  - Improve static handler in android.

## 2.0.1

- Add compatibility for android sdk 19.
- Add `androidx` compatibility.
- Resolve [#193](https://github.com/dooboolab/flutter_sound/issues/193)
  - Restore default `startRecorder`

## 1.9.0

- Fix issue [#175](https://github.com/dooboolab/flutter_sound/issues/175)
  - add functions
    . isEncoderSupported(t_CODEC codec);
    . isDecoderSupported(t_CODEC codec);
  - add property 'audioState'
  - check if codec is really supported before doing 'startRecorder'
  - modify the example app : disable buttons when the button is not compatible with the current state
  - in the example, add sound assets encoded with the various encoder
  - modify the example to play from assets
  - modify the example to allow selection of various codec

## 1.7.0

- startPlayerFromBuffer, to play from a buffer [#170](https://github.com/dooboolab/flutter_sound/pull/170)

## 1.6.0

- Set android default encoding option to `AAC`.
- Fix android default poor sound.
  - Resolve [#155](https://github.com/dooboolab/flutter_sound/issues/155)
  - Resolve [#95](https://github.com/dooboolab/flutter_sound/issues/95)
  - Resolve [#75](https://github.com/dooboolab/flutter_sound/issues/79)

## 1.5.2

- Postfix `GetDirectoryType` to avoid conflicts [#147](https://github.com/dooboolab/flutter_sound/pull/147)

## 1.5.1

- Set android recorder encoder default value to `AndroidEncoder.DEFAULT`.

## 1.5.0

- Use `NSCachesDirectory` instead of `NSTemporaryDirectory` [#141](https://github.com/dooboolab/flutter_sound/pull/141)

## 1.4.8

- Resolve [#129](https://github.com/dooboolab/flutter_sound/issues/129)

## 1.4.7

- Resolve few issues on `ios` record path.
- Resolve issue `playing` status so player can resume.
- Resolve [#134](https://github.com/dooboolab/flutter_sound/issues/134)
- Resolve [#135](https://github.com/dooboolab/flutter_sound/issues/135)

## 1.4.4

- Stopped recording generating infinite db values [#131](https://github.com/dooboolab/flutter_sound/pull/131)

## 1.4.3

- Improved db calcs [#123](https://github.com/dooboolab/flutter_sound/pull/123)

## 1.4.2

- Fixed 'mediaplayer went away with unhandled events' bug [#104](https://github.com/dooboolab/flutter_sound/pull/104)

## 1.4.1

- Fixed 'mediaplayer went away with unhandled events' bug [#83](https://github.com/dooboolab/flutter_sound/pull/83)

## 1.4.0

- AndroidX compatibility improved [#68](https://github.com/dooboolab/flutter_sound/pull/68)
- iOS: Fixes for seekToPlayer [#72](https://github.com/dooboolab/flutter_sound/pull/72)
- iOS: Setup configuration for using bluetooth microphone recording input [#73](https://github.com/dooboolab/flutter_sound/pull/73)

## 1.3.6

- Android: Adds a single threaded command scheduler for all recording related
  commands.
- Switch source & target compability to Java 8
- Bump gradle plugin version dependencies

## 1.3.+

- Support db/meter [#41](https://github.com/dooboolab/flutter_sound/pull/41)
- Show wrong recorder timer text [#47](https://github.com/dooboolab/flutter_sound/pull/47)
- Add ability to specify Android & iOS encoder [#49](https://github.com/dooboolab/flutter_sound/pull/49)
- Adjust db range and fix nullable check in ios [#59](https://github.com/dooboolab/flutter_sound/pull/59)
- Android: Recording operations on a separate command queue [#66](https://github.com/dooboolab/flutter_sound/pull/66)
- Android: Remove reference to non-AndroidX classes which improves compatibility

## 1.2.+

- Fixed sound distorting when playing recorded audio again. Issue [#14](https://github.com/dooboolab/flutter_sound/issues/14).
- Fixed `seekToPlayer` for android. Issue [#10](https://github.com/dooboolab/flutter_sound/issues/10).

* Expose recorder `sampleRate` and `numChannel`.
* Do not append `tmp` when filePath provided in `ios`.
* Resolve `regression` issue in `1.2.3` which caused in `1.2.2`.
* Reduce the size of audio file in `1.2.4`. Related [#26](https://github.com/dooboolab/flutter_sound/issues/26).
* Fixed `recording` issue in android in `1.2.5`.
* Changed `seekToPlayer` to place exact `secs` instead adding it.
* Fix file URI for recording and playing in iOS.

## 1.1.+

- Released 1.1.0 with beautiful logo from mansa.
- Improved readme.
- Resolve #7.
- Fixed missing break in switch statement.

## 1.0.9

- Reimport `intl` which is needed to format date in Dart.

## 1.0.8

- Implemented `setVolume` method.
- Specific error messages given in android.
- Manage ios player thread when audio is not loaded.

## 1.0.7

- Safer handling of progressUpdate in ios when audio is invalid.

## 1.0.6

- Fixed bug in platform specific code.

## 1.0.5

- Fixed pug in `seekToPlayer` in `ios`.

## 1.0.3

- Added license.

## 1.0.0

- Released preview version for audio `recorder` and `player`.
