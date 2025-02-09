---
title:  "Player API"
description: "stopPlayer()"
summary: "stopPlayer()"
permalink: tau_api_player_stop_player.html
tags: [api, player]
keywords: API Player
---
# The &tau; Player API

---------------------------------------------------------------------------------------------------------------------------------

## `stopPlayer()`

- Dart API: [stopPlayer()](pages/flutter-sound/api/player/FlutterSoundPlayer/stopPlayer.html).

Use this verb to stop a playback. This verb never throw any exception. It is safe to call it everywhere,
for example when the App is not sure of the current Audio State and want to recover a clean reset state.

*Example:*
<ul id="profileTabs" class="nav nav-tabs">
    <li class="active"><a href="#dart" data-toggle="tab">Dart</a></li>
    <li><a href="#javascript" data-toggle="tab">Javascript</a></li>
</ul>
<div class="tab-content">

<div role="tabpanel" class="tab-pane active" id="dart">

<pre>
        await myPlayer.stopPlayer();
        if (_playerSubscription != null)
        {
                _playerSubscription.cancel();
                _playerSubscription = null;
        }
</pre>

</div>

<div role="tabpanel" class="tab-pane" id="javascript">
<pre>
        Lorem ipsum ...
</pre>
</div>

</div>

---------------------------------------------------------------------------------------------------------------------------------
