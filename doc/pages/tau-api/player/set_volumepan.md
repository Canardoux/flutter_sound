---
title:  "Player API"
description: "setVolumePan()"
summary: "setVolumePan()"
permalink: tau_api_player_set_volumepan.html
tags: [api, player]
keywords: API Player
---
# The &tau; Player API
----------------------------------------------------------------------------------------------------------------------------------

## `setVolumePan()`

- Dart API: [setVolumePan()](pages/flutter-sound/api/player/FlutterSoundPlayer/setVolumePan.html).

parameter 1 is volume, a floating point number between 0 and 1.
parameter 2 is pan, a floating point number between -1 and 1. When -1, right is muted, when 1 left is muted.
Volume and Pan can be changed when player is running or before starting.
If used before `startPlayer()`, the required volume is kept/delayed and set during the following call to `startPlayer()`.

*Example:*
<ul id="profileTabs" class="nav nav-tabs">
    <li class="active"><a href="#dart" data-toggle="tab">Dart</a></li>
    <li><a href="#javascript" data-toggle="tab">Javascript</a></li>
</ul>
<div class="tab-content">

<div role="tabpanel" class="tab-pane active" id="dart">

<pre>
await myPlayer.setVolumePan(0.5,-0.5);
</pre>

</div>

<div role="tabpanel" class="tab-pane" id="javascript">
<pre>
        Lorem ipsum ...
</pre>
</div>

</div>

---------------------------------------------------------------------------------------------------------------------------------
