# API Reference 2

&lt;!DOCTYPE html&gt;

Main Topic - Dart API  

1. [flauto](https://github.com/Canardoux/tau/tree/3b217712243457a0be2401621f9a3d460c3b659e/doc/flutter_sound/api/index.html)
2. Main Topic

Main  

1. [flauto](https://github.com/Canardoux/tau/tree/3b217712243457a0be2401621f9a3d460c3b659e/doc/flutter_sound/api/index.html)
2. Main Topic

#### flauto package

1. Topics
2. [Main](main-topic.md)
3. [UI Widgets](https://github.com/Canardoux/tau/tree/3b217712243457a0be2401621f9a3d460c3b659e/doc/flutter_sound/api/topics/UI%20Widgets-topic.html)
4. [Utilities](https://github.com/Canardoux/tau/tree/3b217712243457a0be2401621f9a3d460c3b659e/doc/flutter_sound/api/topics/Utilities-topic.html)
5. Libraries
6. Main
7. [player](player-library.md)
8. [recorder](https://github.com/Canardoux/tau/tree/3b217712243457a0be2401621f9a3d460c3b659e/doc/flutter_sound/api/recorder/recorder-library.html)
9. [tau](https://github.com/Canardoux/tau/tree/3b217712243457a0be2401621f9a3d460c3b659e/doc/flutter_sound/api/tau/tau-library.html)
10. UI Widgets
11. [ui\_controller](https://github.com/Canardoux/tau/tree/3b217712243457a0be2401621f9a3d460c3b659e/doc/flutter_sound/api/ui_controller/ui_controller-library.html)
12. [ui\_player](https://github.com/Canardoux/tau/tree/3b217712243457a0be2401621f9a3d460c3b659e/doc/flutter_sound/api/ui_player/ui_player-library.html)
13. [ui\_recorder](https://github.com/Canardoux/tau/tree/3b217712243457a0be2401621f9a3d460c3b659e/doc/flutter_sound/api/ui_recorder/ui_recorder-library.html)
14. Utilities
15. [enum\_helper](https://github.com/Canardoux/tau/tree/3b217712243457a0be2401621f9a3d460c3b659e/doc/flutter_sound/api/enum_helper/enum_helper-library.html)
16. [ffmpeg](https://github.com/Canardoux/tau/tree/3b217712243457a0be2401621f9a3d460c3b659e/doc/flutter_sound/api/ffmpeg/ffmpeg-library.html)
17. [helper](https://github.com/Canardoux/tau/tree/3b217712243457a0be2401621f9a3d460c3b659e/doc/flutter_sound/api/helper/helper-library.html)
18. [log](https://github.com/Canardoux/tau/tree/3b217712243457a0be2401621f9a3d460c3b659e/doc/flutter_sound/api/log/log-library.html)
19. [stack\_trace](https://github.com/Canardoux/tau/tree/3b217712243457a0be2401621f9a3d460c3b659e/doc/flutter_sound/api/stack_trace/stack_trace-library.html)
20. [temp\_file\_system](https://github.com/Canardoux/tau/tree/3b217712243457a0be2401621f9a3d460c3b659e/doc/flutter_sound/api/temp_file_system/temp_file_system-library.html)
21. [wave\_header](https://github.com/Canardoux/tau/tree/3b217712243457a0be2401621f9a3d460c3b659e/doc/flutter_sound/api/wave_header/wave_header-library.html)

## Main Topic

## The Main modules <a id="the-main-modules"></a>

Flutter Sound is composed with 4 modules :

* [FlutterSoundPlayer](https://github.com/Canardoux/tau/tree/3b217712243457a0be2401621f9a3d460c3b659e/doc/flutter_sound/api/topics/player.md#flutter-sound-player-api), wich deal with everything about playbacks
* [FlutterSoundRecorder](https://github.com/Canardoux/tau/tree/3b217712243457a0be2401621f9a3d460c3b659e/doc/flutter_sound/api/topics/recorder.md#flutter-sound-recorder-api), which deal with everything about recording
* [FlutterSoundHelper](https://github.com/Canardoux/tau/tree/3b217712243457a0be2401621f9a3d460c3b659e/doc/flutter_sound/api/topics/utilities.md), which offers some convenients tools
* [FlutterSoundUI](https://github.com/Canardoux/tau/tree/3b217712243457a0be2401621f9a3d460c3b659e/doc/flutter_sound/api/topics/ui_widget.md), which offer some Widget ready to be used out of the box

To use Flutter Sound you just do :

```text
import 'package:flutter_sound/flutter_sound.dart';
```

This will import all the necessaries dart interfaces.

### Playback <a id="playback"></a>

1. **Instance one ore more players.** A good place to do that is in your `init()` function. It is also possible to instanciate the players "on the fly", when needed.

```text
FlutterSoundPlayer myPlayer = FlutterSoundPlayer();
```

1. **Open it.** You cannot do anything on a close Player. An audio-session is then created.

```text
myPlayer.openAudioSession().then( (){ ...} );
```

1. **Use the various verbs implemented by the players.**

* `startPlayer()`
* `startPlayerFromStream()`
* `startPlayerFromBuffer()`
* `setVolume()`
* `FlutterSoundPlayer.stopPlayer()`
* ...

1. **Close your players.** This is important to close every player open for freeing the resources taken by the audio session. A good place to do that is in the `dispose()` procedure.

```text
myPlayer.closeAudioSession();
```

### Recording <a id="recording"></a>

1. **Instance your recorder.** A good place to do that is in your `init()` function.

```text
FlutterSoundRecorder myRecorder = FlutterSoundRecorder();
```

1. **Open it.** You cannot do anything on a close Recorder. An audio-session is then created.

```text
myRecorder.openAudioSession().then( (){ ...} );
```

1. **Use the various verbs implemented by the players.**

* `startRecorder()`
* `pauseRecorder()`
* `resumeRecorder()`
* `stopRecorder()`
* ...

1. **Close your recorder.** This is important to close it for freeing the resources taken by the audio session. A good place to do that is in the `dispose()` procedure.

```text
myRecorder.closeAudioSession();
```

### Libraries

 [player](player-library.md) [Main](main-topic.md) **THE** Flutter Sound Player [recorder](https://github.com/Canardoux/tau/tree/3b217712243457a0be2401621f9a3d460c3b659e/doc/flutter_sound/api/recorder/recorder-library.html) [Main](main-topic.md) **THE** Flutter Sound Recorder [tau](https://github.com/Canardoux/tau/tree/3b217712243457a0be2401621f9a3d460c3b659e/doc/flutter_sound/api/tau/tau-library.html) [Main](main-topic.md) [\[...\]](https://github.com/Canardoux/tau/tree/3b217712243457a0be2401621f9a3d460c3b659e/doc/flutter_sound/api/tau/tau-library.html)

#### Main Topic

1. [Libraries](main-topic.md#libraries)
2. [player](player-library.md)
3. [recorder](https://github.com/Canardoux/tau/tree/3b217712243457a0be2401621f9a3d460c3b659e/doc/flutter_sound/api/recorder/recorder-library.html)
4. [tau](https://github.com/Canardoux/tau/tree/3b217712243457a0be2401621f9a3d460c3b659e/doc/flutter_sound/api/tau/tau-library.html)

 flauto 6.4.5+1

