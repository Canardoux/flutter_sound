---
title:  "Player API"
description: "getPlayerState()"
summary: "`playerState`, `isPlaying`, `isPaused`, `isStopped`. `getPlayerState()`"
permalink: tau_api_player_get_player_state.html
tags: [api, player]
keywords: API Player
---
# The &tau; Player API

---------------------------------------------------------------------------------------------------------------------------------

## `playerState`, `isPlaying`, `isPaused`, `isStopped`. `getPlayerState()`

- Dart API: [getPlayerState()](pages/flutter-sound/api/player/FlutterSoundPlayer/getPlayerState.html).
- Dart API: [isPlaying](pages/flutter-sound/api/player/FlutterSoundPlayer/isPlaying.html).
- Dart API: [isPaused](pages/flutter-sound/api/player/FlutterSoundPlayer/isPaused.html).
- Dart API: [isStopped](pages/flutter-sound/api/player/FlutterSoundPlayer/isStopped.html).
- Dart API: [playerState](pages/flutter-sound/api/player/FlutterSoundPlayer/playerState.html).

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
<ul id="profileTabs" class="nav nav-tabs">
    <li class="active"><a href="#dart" data-toggle="tab">Dart</a></li>
    <li><a href="#javascript" data-toggle="tab">Javascript</a></li>
</ul>
<div class="tab-content">

<div role="tabpanel" class="tab-pane active" id="dart">

<pre>
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
</pre>

</div>

<div role="tabpanel" class="tab-pane" id="javascript">
<pre>
        Lorem ipsum ...
</pre>
</div>

</div>


---------------------------------------------------------------------------------------------------------------------------------
