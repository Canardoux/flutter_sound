---
title:  "Getting Started"
summary: "Introduction for Flutter Sound beginners."
permalink: fs-guides_getting_started.html
---

## Playback

The complete source of a runnable example [is there](https://github.com/Canardoux/flutter_sound/blob/master/example/lib/simple_playback/simple_playback.dart)

### 1. FlutterSoundPlayer instanciation

To play back something you must instanciate a player. Most of the time, you will need just one player, and you can place this instanciation in the variables initialisation of your class :

```dart
  import 'package:flutter_sound/flutter_sound.dart';
...
  FlutterSoundPlayer _mPlayer = FlutterSoundPlayer();
```

### 2. Open and close your player

Before calling `startPlayer()` you must [open the Player](/tau/fs/api/player/FlutterSoundPlayer/openPlayer.html).

When you have finished with it, **you must** [close it](/tau/fs/api/player/FlutterSoundPlayer/closePlayer.html). A good places to put those verbs are in the procedures `initState()` and `dispose()`.

```dart
  FlutterSoundPlayer? _mPlayer = FlutterSoundPlayer();
  bool _mPlayerIsInited = false;

  @override
  void initState() {
    // Be careful : openPlayer returns a Future.
    // Do not access your FlutterSoundPlayer before the completion of the Future
    super.initState();
    _mPlayer!.openPlayer().then((value) {
      setState(() {
        _mPlayerIsInited = true;
      });
    });
  }
```

```dart
  @override
  void dispose() {
    stopPlayer();
    // Be careful : you must `close` the audio session when you have finished with it.
    _mPlayer!.closePlayer();
    _mPlayer = null;

    super.dispose();
  }
```

### 3. Play your sound

To play a sound you call [startPlayer()](/tau/fs/api/player/FlutterSoundPlayer/startPlayer.html). To stop a sound you call [stopPlayer()](/tau/fs/api/player/FlutterSoundPlayer/stopPlayer.html)

```dart
const _exampleAudioFilePathMP3 = 'https://tau.canardoux.xyz/live/extract/05.mp3';

  void play() async {
    await _mPlayer!.startPlayer(
        fromURI: _exampleAudioFilePathMP3,
        codec: Codec.mp3,
        whenFinished: () {
          setState(() {});
        });
    setState(() {});
  }
```
```dart
  Future<void> stopPlayer() async {
    if (_mPlayer != null) {
      await _mPlayer!.stopPlayer();
    }
  }
```

## Recording

The complete source of a runnable example [is there](https://github.com/Canardoux/flutter_sound/blob/master/example/lib/simple_recorder/simple_recorder.dart)

### 1. FlutterSoundRecorder instanciation

To record something you must instanciate a recorder. Most of the time, you will need just one recorder, and you can place this instanciation in the variables initialisation of your class :

```dart
  FlutterSoundRecorder _myRecorder = FlutterSoundRecorder();
```

### 2. Open and close the audio session

Before calling `startRecorder()` you must [open](/tau/fs/api/recorder/FlutterSoundRecorder/openRecorder.html) your recorder.

When you have finished with it, **you must** [close](/tau/fs/api/recorder/FlutterSoundRecorder/closeRecorder.html) it. A god place to pute those verbs is in the procedures `initState()` and `dispose()`.

```dart
  @override
  void initState() {
    super.initState();
    _mPlayer!.openPlayer().then((value) {
      setState(() {
        _mPlayerIsInited = true;
      });
    });
  }
```

```dart
  @override
  void dispose() {
    stopPlayer();
    // Be careful : you must `close` the recorder when you have finished with it.
    _mPlayer!.closePlayer();
    _mPlayer = null;

    super.dispose();
  }
```

### 3. Record something

To record something you call [startRecorder()](/tau/fs/api/recorder/FlutterSoundRecorder/startRecorder.html). To stop the recorder you call [stopRecorder()](/tau/fs/api/recorder/FlutterSoundRecorder/stopRecorder.html)

```dart
  Future<void> record() async {
    await _myRecorder.startRecorder(
      toFile: _mPath,
      codec: Codec.aacADTS,
    );
  }
```

```dart
  Future<void> stopRecorder() async {
    await _myRecorder.stopRecorder();
  }
```