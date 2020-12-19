---
title:  "Player API"
description: "setVolume()"
summary: "setVolume()"
permalink: tau_api_player_set_volume.html
tags: [API, player]
keywords: API Player
---
# The &tau; Player API
----------------------------------------------------------------------------------------------------------------------------------

## `setVolume()`

[Dart API](https://canardoux.github.io/tau/doc/flutter_sound/api/player/FlutterSoundPlayer/setVolume.html)

The parameter is a floating point number between 0 and 1.
Volume can be changed when player is running. Manage this after player starts.

*Example:*
```dart
await myPlayer.setVolume(0.1);
```

---------------------------------------------------------------------------------------------------------------------------------
