# API Reference 3

&lt;!DOCTYPE html&gt;

player library - Dart API  

1. [flauto](index.md)
2. player library

player  

1. [flauto](index.md)
2. player library

#### flauto package

1. Topics
2. [Main](main-topic.md)
3. [UI Widgets](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/topics/UI%20Widgets-topic.html)
4. [Utilities](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/topics/Utilities-topic.html)
5. Libraries
6. Main
7. [player](player-library.md)
8. [recorder](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/recorder/recorder-library.html)
9. [tau](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/tau/tau-library.html)
10. UI Widgets
11. [ui\_controller](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/ui_controller/ui_controller-library.html)
12. [ui\_player](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/ui_player/ui_player-library.html)
13. [ui\_recorder](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/ui_recorder/ui_recorder-library.html)
14. Utilities
15. [enum\_helper](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/enum_helper/enum_helper-library.html)
16. [ffmpeg](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/ffmpeg/ffmpeg-library.html)
17. [helper](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/helper/helper-library.html)
18. [log](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/log/log-library.html)
19. [stack\_trace](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/stack_trace/stack_trace-library.html)
20. [temp\_file\_system](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/temp_file_system/temp_file_system-library.html)
21. [wave\_header](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/wave_header/wave_header-library.html)

## player library [Main](main-topic.md)

**THE** Flutter Sound Player

### Classes

 [FlutterSoundPlayer](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/player/FlutterSoundPlayer-class.html) A Player is an object that can playback from various sources. [\[...\]](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/player/FlutterSoundPlayer-class.html) [PlaybackDisposition](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/player/PlaybackDisposition-class.html) Used to stream data about the position of the playback as playback proceeds. [Track](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/player/Track-class.html) The track to play by [FlutterSoundPlayer.startPlayerFromTrack\(\)](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/player/FlutterSoundPlayer/startPlayerFromTrack.html).

### Enums

 [PlayerState](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/player/PlayerState-class.html) The possible states of the Player.

### Typedefs

 [TonPaused](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/player/TonPaused.html)\([bool](https://api.flutter.dev/flutter/dart-core/bool-class.html) paused\) → void Playback function type for [FlutterSoundPlayer.startPlayerFromTrack\(\)](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/player/FlutterSoundPlayer/startPlayerFromTrack.html). [\[...\]](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/player/TonPaused.html) [TonSkip](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/player/TonSkip.html)\(\) → void Playback function type for [FlutterSoundPlayer.startPlayerFromTrack\(\)](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/player/FlutterSoundPlayer/startPlayerFromTrack.html). [\[...\]](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/player/TonSkip.html) [TWhenFinished](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/player/TWhenFinished.html)\(\) → void Playback function type for [FlutterSoundPlayer.startPlayer\(\)](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/player/FlutterSoundPlayer/startPlayer.html). [\[...\]](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/player/TWhenFinished.html)

#### player library

1. [Classes](player-library.md#classes)
2. [FlutterSoundPlayer](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/player/FlutterSoundPlayer-class.html)
3. [PlaybackDisposition](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/player/PlaybackDisposition-class.html)
4. [Track](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/player/Track-class.html)
5. [Enums](player-library.md#enums)
6. [PlayerState](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/player/PlayerState-class.html)
7. [Typedefs](player-library.md#typedefs)
8. [TonPaused](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/player/TonPaused.html)
9. [TonSkip](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/player/TonSkip.html)
10. [TWhenFinished](https://github.com/Canardoux/tau/tree/8d2f505b3313518847fea9d2109635e0a071b6f5/doc/flutter-sound/api/player/TWhenFinished.html)

 flauto 6.4.5+1

