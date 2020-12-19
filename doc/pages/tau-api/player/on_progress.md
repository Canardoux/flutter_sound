---
title:  "Player API"
description: "onProgress."
summary: "onProgress."
permalink: tau_api_player_on_progress.html
tags: [API, player]
keywords: API Player
---
# The &tau; Player API

---------------------------------------------------------------------------------------------------------------------------------

## `onProgress`

[Dart API](https://canardoux.github.io/tau/doc/flutter_sound/api/player/FlutterSoundPlayer/onProgress.html)

The stream side of the Food Controller : this is a stream on which FlutterSound will post the player progression.
You may listen to this Stream to have feedback on the current playback.

PlaybackDisposition has two fields :
- Duration duration  (the total playback duration)
- Duration position  (the current playback position)

*Example:*
```dart
        _playerSubscription = myPlayer.onProgress.listen((e)
        {
                Duration maxDuration = e.duration;
                Duration position = e.position;
                ...
        }
```

----------------------------------------------------------------------------------------------------------------------------------
