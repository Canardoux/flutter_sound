---
title:  "Player API"
description: "stopPlayer()"
summary: "stopPlayer()"
permalink: tau_api_player_stop_player.html
tags: [API, player]
keywords: API Player
---
# The &tau; Player API

---------------------------------------------------------------------------------------------------------------------------------

## `stopPlayer()`

[Dart API](https://canardoux.github.io/tau/doc/flutter_sound/api/player/FlutterSoundPlayer/stopPlayer.html)

Use this verb to stop a playback. This verb never throw any exception. It is safe to call it everywhere,
for example when the App is not sure of the current Audio State and want to recover a clean reset state.

*Example:*
```dart
        await myPlayer.stopPlayer();
        if (_playerSubscription != null)
        {
                _playerSubscription.cancel();
                _playerSubscription = null;
        }
```

---------------------------------------------------------------------------------------------------------------------------------
