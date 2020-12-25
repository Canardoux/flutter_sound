---
title:  "Player API"
description: "onProgress."
summary: "onProgress."
permalink: tau_api_player_on_progress.html
tags: [api, player]
keywords: API Player
---
# The &tau; Player API

---------------------------------------------------------------------------------------------------------------------------------

## `onProgress`

- Dart API: [onProgress](pages/flutter-sound/api/player/FlutterSoundPlayer/onProgress.html).

The stream side of the Food Controller : this is a stream on which FlutterSound will post the player progression.
You may listen to this Stream to have feedback on the current playback.

PlaybackDisposition has two fields :
- Duration duration  (the total playback duration)
- Duration position  (the current playback position)

*Example:*
<ul id="profileTabs" class="nav nav-tabs">
    <li class="active"><a href="#dart" data-toggle="tab">Dart</a></li>
    <li><a href="#javascript" data-toggle="tab">Javascript</a></li>
</ul>
<div class="tab-content">

<div role="tabpanel" class="tab-pane active" id="dart">

<pre>
        _playerSubscription = myPlayer.onProgress.listen((e)
        {
                Duration maxDuration = e.duration;
                Duration position = e.position;
                ...
        }
</pre>

</div>

<div role="tabpanel" class="tab-pane" id="javascript">
<pre>
        Lorem ipsum ...
</pre>
</div>

</div>

----------------------------------------------------------------------------------------------------------------------------------
