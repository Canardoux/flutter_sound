# The Main modules

The three main modules of Flutter Sound are :

- [FlutterSoundPlayer](../player/player-library.html)  (Everything for Playback)
- [FlutterSoundRecorder](../recorder/recorder-library.html)  (Everything for recording)
- [tau](../tau/tau-library.html)

## How to use

First import the Flutter Sound plugin
```dart
import 'flutter_sound.dart
```

## Playback

1. Instance one ore more players
A good place to do that is in your `init()` function.
It is possible also to instanciate players "On the Flight", when needed.

2. Open it
[FlutterSoundPlayer.openAudioSession()]
You cannot do anything on a close Player.
An audio-session is then created.

3. Use the various verbs implemented by the players
- `startPlayer()` [FlutterSoundPlayer.startPlayer()]
- `startPlayerFromStream()`
- `startPlayerFromBuffer()`
- `setVolume()`
- [FlutterSoundPlayer.stopPlayer()]
- ...

4. Close your players
[FlutterSoundPlayer.closeAudioSession()]


## Recording

1. Instance your recorder

2. Open it

3. Use the various verbs implemented by the recorders

4. Close your recorder

