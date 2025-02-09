---
title:  "Player API"
description: "setSpeed()"
summary: "setSpeed()"
permalink: tau_api_player_set_speed.html
tags: [api, player]
keywords: API Player
---
# The &tau; Player API
----------------------------------------------------------------------------------------------------------------------------------

## `setSpeed()`

- Dart API: [setSpeed()](pages/flutter-sound/api/player/FlutterSoundPlayer/setSpeed.html).

The parameter is a floating point number greater than 0. It must be 0 to 1.0 to play slower, and greater than 1.0 to play faster.
The speed can be changed when player is running or before starting.
If used before `startPlayer()`, the required speed is kept/delayed and set during the following call to `startPlayer()`.

This verb is actually only for `startRecorder()`,  `startPlayerFromBuffer()` or `startPlayerFromStream()`.
It does not work with `startPlayerFromMic()`.

This verb works fine on
- iOS
- Android
- Web

On iOS and Android, the speed is changed without any impact on the pitch. On web, the pitch is affected : this must be fixed in a future version.

Note : on iOS it is mandatory to call at least one time this verb after opening the player and before the `startPlayer()`.
This call can be dummy. For example `myPlayer.setSpeed(1.0)`.
Then, after starting the player, the app will be able to change the speed as it wants.

Note : on Android, it works only with Android API >= 23 (Android M).

*Example:*
<ul id="profileTabs" class="nav nav-tabs">
    <li class="active"><a href="#dart" data-toggle="tab">Dart</a></li>
    <li><a href="#javascript" data-toggle="tab">Javascript</a></li>
</ul>
<div class="tab-content">

<div role="tabpanel" class="tab-pane active" id="dart">

<pre>
await myPlayer.setSpeed(0.8);
</pre>

</div>

<div role="tabpanel" class="tab-pane" id="javascript">
<pre>
        Lorem ipsum ...
</pre>
</div>

</div>

---------------------------------------------------------------------------------------------------------------------------------
