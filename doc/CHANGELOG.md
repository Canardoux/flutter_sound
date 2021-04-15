---
title: "The &tau; CHANGELOG"
keywords: changelog
tags: [changelog]
sidebar: mydoc_sidebar
permalink: changelog.html
summary: The Changelog of The &tau; Project.
toc: false
---
## 8.0.2

- SetAudioFocus must return an int. Not a boolean. [#631](https://github.com/Canardoux/tau/issues/631)

## 8.0.1

- Flutter Sound on Web : Stop mediaStream tracks after recording ends. [#656](https://github.com/Canardoux/tau/pull/656), [#655](https://github.com/Canardoux/tau/issues/655). Contribution from @osaxma. Thanks to him.

## 8.0.0

- Null Safety

## 7.7.0

- Flutter Sound on web : now we can record AAC-MP4 on webkit (iOS web browsers and Safari). [#559](https://github.com/Canardoux/tau/issues/559)
- Flutter Sound LITE did not compile on iOS : [#613](https://github.com/Canardoux/tau/issues/613)

## 7.6.7

- The procedure "resetPlugin" was missing on Flutter Sound on Web

## 7.6.6

- We must get the lock semaphore when calling stop() during "audioPlaybackFinished"

## 7.6.5

- Local variable _restarted_ is static.

## 7.6.4

- Fixes a problem with `FlutterSoundHelper.duration()`. (Still does not work with temporary files). [#613](https://github.com/Canardoux/tau/issues/613)

## 7.6.3

- No dependency to `synchronized: ^3.0.0-nullsafety`. [#624](https://github.com/Canardoux/tau/issues/624)
- Compatibility with `flutter_ffmpeg`. [#613](https://github.com/Canardoux/tau/issues/613) and [#585](https://github.com/Canardoux/tau/issues/585)
- No crash after a Hot Restart. [#543](https://github.com/Canardoux/tau/issues/543), [#387](https://github.com/Canardoux/tau/issues/387) and [#304](https://github.com/Canardoux/tau/issues/304)

## 7.6.2

- On iOS : fixes a bug with pause/resume at the end of the playback [#469](https://github.com/dooboolab/flutter_sound/issues/469)

## 7.6.1

- On iOS : the audio flags was not transmitted correctely to tau_core

## 7.6.0

- Enhancement : Record to a temporary file. No need any more to use flutter_path_provider. `myRecorder.startRecorder('foo');` . Works on Android, iOS, and Flutter Web. [#607](https://github.com/dooboolab/flutter_sound/issues/607). [temporary files](temporary_files.html)
- `stopRecorder()` returns a Future of an URL to the recorded file : `URL url = await stopRecorder();` . Useful to get the URL of a temporary record object. [#616](https://github.com/dooboolab/flutter_sound/issues/616), [#592](https://github.com/dooboolab/flutter_sound/issues/592)
- New verb `deleteTemporaryFile('foo');`
- All temporary files are automaticaly deleted when the session is closed
- No await necessary on `openAudioSession()`. [#606](https://github.com/dooboolab/flutter_sound/issues/606)
- Exception when a verb can be processed instead of having an await stuck for ever. [#605](https://github.com/dooboolab/flutter_sound/issues/605)

## 7.5.3

- Fix a major bug during Feed(). A major regression introduced in 7.5.1. [#590](https://github.com/dooboolab/flutter_sound/issues/590)

## 7.5.2

- Android : Fixes a bug when the plugin is attached several time to the engine. Thanks to @ed-vx for the Pull Request :-) . [#595](https://github.com/dooboolab/flutter_sound/pull/595) and [#594](https://github.com/dooboolab/flutter_sound/issues/594)
- iOS : Initialization of `flutterSoundPlayerManager` and `flutterSoundRecorderManager` to NIL. [#411](https://github.com/dooboolab/flutter_sound/issues/411), [#587](https://github.com/dooboolab/flutter_sound/issues/587)

## 7.5.1

- The &tau; documentation is moved to https://tau.canardoux.xyz . Yes, HTTPS, and not anymore HTTP. [#553](https://github.com/dooboolab/flutter_sound/issues/553)
- Jekyll : patched to allow the dartdoc support without being based on symbolic links (that produced many 404). [#553](https://github.com/dooboolab/flutter_sound/issues/553)

## 7.5.0

- New procedure [FlutterSoundPlayer.startPlayerFromMic()](http://www.canardoux.xyz/tau_sound/doc/pages/flutter-sound/api/topics/tau_api_player_start_player_from_mic.html). [#580](https://github.com/dooboolab/flutter_sound/issues/580)

## 7.4.16

- Now, the demo-example can play remote files for **all** the codec **directely** supported (without using FFmpeg). And not only MP3.

## 7.4.15

- Remove the `intl` dependency. [#584](https://github.com/dooboolab/flutter_sound/issues/584)

## 7.4.14

- Now, &tau; throws a correct exception during `startRecorder()` on Android when the recording permission is not granted. [#558](https://github.com/dooboolab/flutter_sound/issues/558)

## 7.4.13

- Fixes problems on iOS with play/record from/to stream. SampleRate=44000 is a good choice. [#484](https://github.com/dooboolab/flutter_sound/issues/484).

## 7.4.12

- Add an example doing several playbacks at the same time [#546](https://github.com/dooboolab/flutter_sound/issues/546)

## 7.4.11

- Fighting with [#569](https://github.com/dooboolab/flutter_sound/issues/569) : remove two naughty warnings during pod install of the example.

## 7.4.10

- Fixes a bug in the live web example [#574](https://github.com/dooboolab/flutter_sound/issues/574)

## 7.4.9

- Documention is switched to Jekyll
- I did a terrible mistake : the version is named 7.4.9 instead of 6.4.9 Impossible to correct that on pub.dev: a commit is for ever. I am confused :-( .

## 6.4.8

iOS : Rename `AudioPlayer` as `AudioPlayerFlauto` to avoid duplicate symbol with "just_audio: ^0.5.7". [#542](https://github.com/dooboolab/flutter_sound/issues/542)

## 6.4.7

The two simple examples doing recording did not ask for recording permission. [#539](https://github.com/dooboolab/flutter_sound/issues/539)

## 6.4.6

- Fixes a bug in `setAudioFocus()` when  the focus parameter is `t_AUDIO_FOCUS.requestFocus` [#537](https://github.com/dooboolab/flutter_sound/issues/537)

## 6.4.5

- Fixes an other problem in `setAudioFocus()` on Android and iOS [#535](https://github.com/dooboolab/flutter_sound/issues/535)

## 6.4.4

- Fixes a crash in `setAudioFocus()` on Android [#535](https://github.com/dooboolab/flutter_sound/issues/535)

## 6.4.3

- The documentation of the API is now generated by `dartdoc`. [Here it is](https://dooboolab.github.io/flutter_sound/doc/flutter_sound/api/index.html)
- The various traces done by Flutter Sound with the Dart code are now handled by 'util/log.dart'. (The traces done by iOS and Android are still hard coded).;
- Fix a bug in Pause/Resume on the lock screen
- The Flutter Sound documentation is now handled by gitbook.
- Fix bug in `setUIProgressBar()`
- The output of `dartanalyzer` is now clean. The pub.dev score is 110/110 !
- Two new very simple examples for Flutter Sound beginners

## 6.4.2

- Syntaxe error in flutter_sound_web.podspec [#509](https://github.com/dooboolab/flutter_sound/issues/509)

## 6.4.1

- Little mistake in the Podspec file name for flutter_sound_web [#509](https://github.com/dooboolab/flutter_sound/issues/509)

## 6.4.0

- Flutter Sound is supported by Flutter Web. You can play with [this live demo on the web](https://www.canardoux.space/tau/flutter_sound_example) (still cannot record with Safari or any web browser on iOS : thank you Apple). You can [read this](flutter_sound/doc/codec.md#flutter-sound-on-flutter-web). Issues : [#494](https://github.com/dooboolab/flutter_sound/issues/494), [#468](https://github.com/dooboolab/flutter_sound/issues/468) and [#297](https://github.com/dooboolab/flutter_sound/issues/297)

## 6.3.1

- Fix a syntax error in the TauEngine build.gradle [499](https://github.com/dooboolab/flutter_sound/issues/499)
- English in the UI widget is now configurable [498](https://github.com/dooboolab/flutter_sound/pull/498)

## 6.3.0

- On Android : Flutter Sound is now a wrapper around `TauEngine`
- Add a new example doing Speech-To-Text. Thanks to @jtkeyva :-) . [#210](https://github.com/dooboolab/flutter_sound/issues/210)

## 6.2.0

- Publication on JCenter

## 6.2.0

- On iOS, Flutter Sound use now a Pod library : `TauEngine`
- On iOS : `startPlayer()` from a remote URL returned too early (before downloading the file)
- The loop example, (from the recorder to the player) has now a delay < 1 sec. [#479](https://github.com/dooboolab/flutter_sound/issues/479) and [#90](https://github.com/dooboolab/flutter_sound/issues/90)
- Fix compilation errors of the examples in LITE flavor [#483](https://github.com/dooboolab/flutter_sound/issues/483)


## 6.1.2

- Playback from a remote URL [#470](https://github.com/dooboolab/flutter_sound/issues/470)

## 6.1.1

- Volume control with the volume buttons, on Android. [#457](https://github.com/dooboolab/flutter_sound/issues/457)

## 6.1.0

- Re-design the modules architecture to be Google recommandations compliant. (We use a new dependency : `flutter_sound_platform_interface`)
- `openAudioSessionWithUI` is now deprecated. Use the parameter `withUI` in `openAudioSession()` instead.
- Upgrade "recase" version dependency (thanks to @CRJFisher) [#471](https://github.com/dooboolab/flutter_sound/pull/471)

## 6.0.1

- Little bug in the Demo App : 48000 is not a valid Sample rate for AAC/ADTS [#460](https://github.com/dooboolab/flutter_sound/issues/460)

## 6.0.0

- Modification to the Widget Recorder UI, to be homogeneous with the Widget Player UI
- Fix two severe bugs on Android in openAudioSessionWithUI and startPlayerFromTrack : those two functions returned too early instead of a future. [#425](https://github.com/dooboolab/flutter_sound/issues/425)
- On iOS, the device did not go to sleep when idle, with the Flutter Sound default parameters. [#439](https://github.com/dooboolab/flutter_sound/issues/439)
- startPlayer() and startPlayerFromTrack() return a Future to the record duration instead of a void.
- Flutter Sound **FULL** is now linked (again) with mobile-ffmpeg-audio 4.3.1.LTS. Please, look to [the migration guide](doc/migration_6.x.x.md#migration-from-5xx-to-6xx)
- Fix a concurrency bug between `whenFinished()` and `updateProgress()` [#441](https://github.com/dooboolab/flutter_sound/issues/441)
- Android : minAndroidSdk is 18. (Tested on a SDK 18 emulator). SDK 18 is fine for the FlutterSoundPlayer, but the FlutterSoundRecorder needs at least 23. [#400](https://github.com/dooboolab/flutter_sound/issues/400)
- New helper API verb : [pcmToWave()](doc/helper.md#pcmtowave)  to add a WAVE header in front of a Raw PCM record
- New helper API verb : [pcmToWaveBuffer()](doc/helper.md#pcmtowavebuffer)  to add a WAVE header in front of a Raw PCM buffer
- New helper API verb : [waveToPCM()](doc/helper.md#waveToPCM)  to remove a WAVE header in front of a Wave record
- New helper API verb : [waveToPCMBuffer()](doc/helper.md#waveToPCMBuffer)  to remove a WAVE header in front of a Wave buffer
- [startRecorder()](doc/recorder.md#startrecorder) can now record **Raw PCM Integers/Linear 16** files, both on iOS and Android (Look to a [PCM discussion, here](doc/codec.md#note-on-raw-pcm-and-wave-files))
- [startplayer()](doc/recorder.md#startplayer) can now play **Raw PCM Integers/Linear 16** files, both on iOS and Android (Look to a [PCM discussion, here](doc/codec.md#note-on-raw-pcm-and-wave-files))
- Fix concurrency bug, when the App does a `stopRecorder()` or `pauseRecorder()` during `recorderTicker()` processing, [#443](https://github.com/dooboolab/flutter_sound/issues/443)
- Fix a bug when we keep the device in pause mode on the iOS lock screen more than 30 seconds [#451](https://github.com/dooboolab/flutter_sound/issues/451)
- Recording PCM-Linear 16 to a live Stream (many, many, many requesters). [Here a GettingStarted notice](doc/codec.md#recording-pcm-16-to-a-dart-stream)
- Playback PCM-Linear 16 from a live Stream (many, many, many requesters). [Here a GettingStarted notice](doc/codec.md#playing-pcm-16-from-a-dart-stream)

## 5.1.1

- Fix various bugs in UI Widget [#407](https://github.com/dooboolab/flutter_sound/issues/407)
- Add a button Pause/Resume in UI Widget Recorder
- Add a button Pause/Resume in UI Widget Player

## 5.1.0

- Add a semaphore so that the App cannot do several call to Flutter Sound at the same time [#374](https://github.com/dooboolab/flutter_sound/issues/374)
- On iOS : the "NowPlaying" info on the lockscreen is removed when the sound is finished or when the App does a ```stopPlayer()```. Add parameter ```removeUIWhenStopped``` to ```startPlayerFromTrack()```. (iOS only).
- On iOS : the "NowPlaying" progress bar on the lockscreen is uptodated when the App does a ```seekToPlayer()``` [#364](https://github.com/dooboolab/flutter_sound/issues/364)
- On iOS : Add parameter ```defaultPauseResume``` to ```startPlayerFromTrack()```. (iOS only).
- On iOS : Add API verb ```getProgress()```. (iOS only).
- On iOS : Add API verb ```getPlayerState()```. (iOS only).
- On iOS : Add API verb ```nowPlaying()```. (iOS only).
- On iOS : Add API verb ```setUIProgressBar()```. (iOS only). [#376](https://github.com/dooboolab/flutter_sound/issues/376)
- Fixes bug [#380](https://github.com/dooboolab/flutter_sound/issues/380), [#385](https://github.com/dooboolab/flutter_sound/pull/385)
- Fixes bug "AudioFlags and AudioSource not work as expect " [#366](https://github.com/dooboolab/flutter_sound/issues/366), [#372](https://github.com/dooboolab/flutter_sound/pull/372), [#381](https://github.com/dooboolab/flutter_sound/pull/381)
- New parameters in the `SoundPlayerUI` constructors for specifying colors, text style and slider style. [#397](https://github.com/dooboolab/flutter_sound/issues/397)

## 5.0.2

Error returns from iOS in FlutterSoundPlayer.m was wrong : [#350](https://github.com/dooboolab/flutter_sound/pull/350)

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

## 4.0.7

- Patch to avoid problems when the App does a `stopPlayer()` during a `startPlayer()` [#374](https://github.com/dooboolab/flutter_sound/issues/374)

## 4.0.6

- Error returns from iOS in FlutterSoundPlayer.m was wrong : [#350](https://github.com/dooboolab/flutter_sound/pull/350)

## 4.0.5

- Fix as bug in the Focus gain, on iOS [#324](https://github.com/dooboolab/flutter_sound/issues/324#issuecomment-630970336)

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
- Native code is directely linked with FFmpeg. Flutter Sound App does not need any more to depends on flutter_ffmpeg [#265](https://github.com/dooboolab/flutter_sound/issues/265) and [#273](https://github.com/dooboolab/flutter_sound/issues/273)
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
- The call to ```initialize()``` is now optional [#271](https://github.com/dooboolab/flutter_sound/issues/271)
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
