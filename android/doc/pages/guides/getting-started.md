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

The complete running example [is there](https://github.com/dooboolab/flutter_sound/blob/master/flutter_sound/example/lib/simple_playback/simple_playback.dart)

### 1. FlutterSoundPlayer instanciation

To play back something you must instanciate a player. Most of the time, you will need just one player, and you can place this instanciation in the variables initialisation of your class :

```dart
  import 'package:flauto/flutter_sound.dart';
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
    // openAudioSession() return a Future but it is not necessary to wait its completion.
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

The complete running example [is there](https://github.com/dooboolab/flutter_sound/blob/master/flutter_sound/example/lib/simple_recorder/simple_recorder.dart)

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
    // Be careful : openAudioSession return a Future.
    // Do not access your FlutterSoundPlayer or FlutterSoundRecorder before the completion of the Future
    _myRecorder.openAudioSession().then((value) {
      setState(() {
        _mRecorderIsInited = true;
      });
    });
  }



  @override
  void dispose() {
    // Be careful : you must `close` the audio session when you have finished with it.
    _myRecorder.closeAudioSession();
    _myRecorder = null;
    super.dispose();
  }
```

### 3. Record something

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

