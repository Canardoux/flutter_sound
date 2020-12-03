# The τ API

Flutter Sound is composed with 4 modules :

* [FlutterSoundPlayer](player.md#flutter-sound-player-api), wich deal with everything about playbacks
* [FlutterSoundRecorder](recorder.md#flutter-sound-recorder-api), which deal with everything about recording
* [FlutterSoundHelper](utilities.md), which offers some convenients tools
* [FlutterSoundUI](ui_widget.md), which offer some Widget ready to be used out of the box

To use Flutter Sound you just do :

```text
import 'package:flutter_sound/flutter_sound.dart';
```

This will import all the necessaries dart interfaces.

## Playback

1. **Instance one ore more players.** A good place to do that is in your `init()` function. It is also possible to instanciate the players "on the fly", when needed.

   ```dart
   FlutterSoundPlayer myPlayer = FlutterSoundPlayer();
   ```

2. **Open it.** You cannot do anything on a close Player. An audio-session is then created.

   ```dart
   myPlayer.openAudioSession().then( (){ ...} );
   ```

3. **Use the various verbs implemented by the players.**
4. `startPlayer()`
5. `startPlayerFromStream()`
6. `startPlayerFromBuffer()`
7. `setVolume()`
8. `FlutterSoundPlayer.stopPlayer()`
9. ...
10. **Close your players.**

    This is important to close every player open for freeing the resources taken by the audio session.

    A good place to do that is in the `dispose()` procedure.

    ```dart
    myPlayer.closeAudioSession();
    ```

## Recording

1. **Instance your recorder.** A good place to do that is in your `init()` function.

   ```dart
   FlutterSoundRecorder myRecorder = FlutterSoundRecorder();
   ```

2. **Open it.** You cannot do anything on a close Recorder. An audio-session is then created.

   ```dart
   myRecorder.openAudioSession().then( (){ ...} );
   ```

3. **Use the various verbs implemented by the players.**
4. `startRecorder()`
5. `pauseRecorder()`
6. `resumeRecorder()`
7. `stopRecorder()`
8. ...
9. **Close your recorder.**

   This is important to close it for freeing the resources taken by the audio session.

   A good place to do that is in the `dispose()` procedure.

   ```dart
   myRecorder.closeAudioSession();
   ```

