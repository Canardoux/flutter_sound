---
title:  "Player API"
description: "getPlayerState()"
summary: "`playerState`, `isPlaying`, `isPaused`, `isStopped`. `getPlayerState()`"
permalink: tau_api_player_get_player_state.html
tags: [API, player]
keywords: API Player
---
# The &tau; Player API

---------------------------------------------------------------------------------------------------------------------------------

## `playerState`, `isPlaying`, `isPaused`, `isStopped`. `getPlayerState()`

[Dart API: playerState](https://canardoux.github.io/tau/doc/flutter_sound/api/player/FlutterSoundPlayer/playerState.html)
[Dart API: getPlayerState()](https://canardoux.github.io/tau/doc/flutter_sound/api/player/FlutterSoundPlayer/getPlayerState.html)
[Dart API: isPlaying()](https://canardoux.github.io/tau/doc/flutter_sound/api/player/FlutterSoundPlayer/isPlaying.html)
[Dart API: isPaused()](https://canardoux.github.io/tau/doc/flutter_sound/api/player/FlutterSoundPlayer/isPaused.html)
[Dart API: isStopped()](https://canardoux.github.io/tau/doc/flutter_sound/api/player/FlutterSoundPlayer/isStopped.html)

This four verbs is used when the app wants to get the current Audio State of the player.

`playerState` is an attribut which can have the following values :

  - isStopped   /// Player is stopped
  - isPlaying   /// Player is playing
  - isPaused    /// Player is paused

- isPlaying is a boolean attribut which is `true` when the player is in the "Playing" mode.
- isPaused is a boolean atrribut which  is `true` when the player is in the "Paused" mode.
- isStopped is a boolean atrribut which  is `true` when the player is in the "Stopped" mode.

Flutter Sound shows in the `playerState` attribut the last known state. When the Audio State of the background OS engine changes, the `playerState` parameter is not updated exactly at the same time.
If you want the exact background OS engine state you must use ```PlayerState theState = await myPlayer.getPlayerState()```.
Acutually `getPlayerState()` is only implemented on iOS.

*Example:*
```dart
        swtich(myPlayer.playerState)
        {
                case PlayerState.isPlaying: doSomething; break;
                case PlayerState.isStopped: doSomething; break;
                case PlayerState.isPaused: doSomething; break;
        }
        ...
        if (myPlayer.isStopped) doSomething;
        if (myPlayer.isPlaying) doSomething;
        if (myPlayer.isPaused) doSomething;
        ...
        PlayerState theState = await myPlayer.getPlayerState();
        ...

```

---------------------------------------------------------------------------------------------------------------------------------
