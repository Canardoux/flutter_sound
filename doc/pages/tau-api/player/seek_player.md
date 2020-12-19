---
title:  "Player API"
description: "seekPlayer()"
summary: "seekPlayer()"
permalink: tau_api_player_seek_player.html
tags: [API, player]
keywords: API Player
---
# The &tau; Player API

-------------------------------------------------------------------------------------------------------------------------------
## `seekPlayer()`

[Dart API](https://canardoux.github.io/tau/doc/flutter_sound/api/player/FlutterSoundPlayer/seekPlayer.html)

To seek to a new location. The player must already be playing or paused. If not, an exception is thrown.

*Example:*
```dart
await myPlayer.seekToPlayer(Duration(milliseconds: milliSecs));
```

----------------------------------------------------------------------------------------------------------------------------------
