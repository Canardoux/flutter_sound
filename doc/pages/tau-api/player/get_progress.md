---
title:  "Player API"
description: "getProgress()"
summary: "getProgress()"
permalink: tau_api_player_get_progress.html
tags: [api, player]
keywords: API Player
---
# The &tau; Player API

---------------------------------------------------------------------------------------------------------------------------------

## `getProgress()`

- Dart API: [getProgress()](pages/flutter-sound/api/player/FlutterSoundPlayer/getProgress.html).

This verb is used to get the current progress of a playback.
It returns a `Map` with two Duration entries : `'progress'` and `'duration'`.
Remark : actually only implemented on iOS.

*Example:*
<ul id="profileTabs" class="nav nav-tabs">
    <li class="active"><a href="#dart" data-toggle="tab">Dart</a></li>
    <li><a href="#javascript" data-toggle="tab">Javascript</a></li>
</ul>
<div class="tab-content">

<div role="tabpanel" class="tab-pane active" id="dart">

<pre>
        Duration progress = (await getProgress())['progress'];
        Duration duration = (await getProgress())['duration'];
</pre>

</div>

<div role="tabpanel" class="tab-pane" id="javascript">
<pre>
        Lorem ipsum ...
</pre>
</div>

</div>

---------------------------------------------------------------------------------------------------------------------------------

