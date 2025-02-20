---
title:  "Getting Started"
description: "Getting Started.."
summary: "Introduction for Flutter Sound beginners."
permalink: guides_getting_started.html
tags: [getting_started,guide]
keywords: gettingStarted
---

# Getting Started

## Playback

The complete running example [is there](flutter_sound_examples_simple_playback.html)

### 1. FlutterSoundPlayer instanciation

To play back something you must instanciate a player. Most of the time, you will need just one player, and you can place this instanciation in the variables initialisation of your class :

```dart
  import 'package:flauto/flutter_sound.dart';
  import 'package:audio_session/audio_session.dart';
...
  FlutterSoundPlayer _myPlayer = FlutterSoundPlayer();
```

### 2. Open and close the audio session

Before calling `startPlayer()` you must open the Session.

When you have finished with it, **you must** close the session. A good places to put those verbs are in the procedures `initState()` and `dispose()`.

```dart
@override
  void initState() {
    super.initState();
    // Be careful : openAudioSession return a Future.
    // Do not access your FlutterSoundPlayer or FlutterSoundRecorder before the completion of the Future
    _myPlayer.openAudioSession().then((value) {
      setState(() {
        _mPlayerIsInited = true;
      });
    });
  }



  @override
  void dispose() {
    // Be careful : you must `close` the audio session when you have finished with it.
    _myPlayer.closeAudioSession();
    _myPlayer = null;
    super.dispose();
  }
```

### 3. Play your sound

To play a sound you call `startPlayer()`. To stop a sound you call `stopPlayer()`

```dart
void play() async {
    await _myPlayer.startPlayer(
      fromURI: _exampleAudioFilePathMP3,
      codec: Codec.mp3,
      whenFinished: (){setState((){});}
    );
    setState(() {});
  }

  Future<void> stopPlayer() async {
    if (_myPlayer != null) {
      await _myPlayer.stopPlayer();
    }
  }
```

## Recording

The complete running example [is there](flutter_sound_examples_simple_recorder.html)

### 1. FlutterSoundRecorder instanciation

To play back something you must instanciate a recorder. Most of the time, you will need just one recorder, and you can place this instanciation in the variables initialisation of your class :

```dart
  FlutterSoundRecorder _myRecorder = FlutterSoundRecorder();
```

### 2. Open and close the audio session

Before calling `startRecorder()` you must open the Session.

When you have finished with it, **you must** close the session. A god place to pute those verbs is in the procedures `initState()` and `dispose()`.

```dart
@override
  void initState() {
    super.initState();
    // Be careful : openRecorder return a Future.
    // Do not access your FlutterSoundPlayer or FlutterSoundRecorder before the completion of the Future
    _myRecorder.openRecorder().then((value) {
      setState(() {
        _mRecorderIsInited = true;
      });
    });
  }



  @override
  void dispose() {
    // Be careful : you must `close` the audio session when you have finished with it.
    _myRecorder.closeRecorder();
    _myRecorder = null;
    super.dispose();
  }
```

### 3. Additional Setup for iOS Audio Recording

When recording audio on iOS devices, extra configuration is required to properly set up the audio session.

After calling `openRecorder()`, configure the audio session as shown below:

```dart
@override
void initState() {
  super.initState();
  // Be careful : openRecorder return a Future.
  // Do not access your FlutterSoundPlayer or FlutterSoundRecorder before the completion of the Future
  _myRecorder.openRecorder().then((value) async {
    await initializeAudioSession();
    setState(() {
      _mRecorderIsInited = true;
    });
  });
}

Future<void> initializeAudioSession() async {
  final session = await AudioSession.instance;
  await session.configure(
    AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth |
          AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.voiceCommunication,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ),
  );
}
```

This configuration will enable Bluetooth support, route audio to the device speaker, and ensure that your app is properly set up for voice recording on iOS.


### 4. Record something

To record something you call `startRecorder()`. To stop the recorder you call `stopRecorder()`

```dart
  Future<void> record() async {
    await _myRecorder.startRecorder(
      toFile: _mPath,
      codec: Codec.aacADTS,
    );
  }


  Future<void> stopRecorder() async {
    await _myRecorder.stopRecorder();
  }
```
