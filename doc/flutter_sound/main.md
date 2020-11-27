# The Main modules

The three main modules of Flutter Sound are :

- [FlutterSoundPlayer](../player/player-library.html)  (Everything for Playback)
- [FlutterSoundRecorder](../recorder/recorder-library.html)  (Everything for recording)
- [tau](../tau/tau-library.html) (Contains very important Type Declarations like `Codec`).

## How to use

First import the Flutter Sound plugin
```dart
import 'flutter_sound.dart';
```

## Playback

1. **Instance one ore more players.**
A good place to do that is in your `init()` function.
It is also possible to instanciate the players "on the fly", when needed.
```dart
FlutterSoundPlayer myPlayer = FlutterSoundPlayer();
```

2. **Open it.**
You cannot do anything on a close Player.
An audio-session is then created.
```dart
myPlayer.openAudioSession().then( (){ ...} );
```


3. **Use the various verbs implemented by the players.**
- `startPlayer()`
- `startPlayerFromStream()`
- `startPlayerFromBuffer()`
- `setVolume()`
- `FlutterSoundPlayer.stopPlayer()`
- ...


4. **Close your players.**
This is important to close every player open for freeing the resources taken by the audio session.
```dart
myPlayer.closeAudioSession();
```


## Recording


1. **Instance your recorder.**
A good place to do that is in your `init()` function.
```dart
FlutterSoundRecorder myRecorder = FlutterSoundRecorder();
```

2. **Open it.**
You cannot do anything on a close Recorder.
An audio-session is then created.
```dart
myRecorder.openAudioSession().then( (){ ...} );
```


3. **Use the various verbs implemented by the players.**
- `startRecorder()`
- `pauseRecorder()`
- `resumeRecorder()`
- `stopRecorder()`
- ...


4. **Close your recorder.**
This is important to close it for freeing the resources taken by the audio session.
```dart
myRecorder.closeAudioSession();
```

