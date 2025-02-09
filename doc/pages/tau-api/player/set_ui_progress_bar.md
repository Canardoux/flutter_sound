---
title:  "Player API"
description: "setUIProgressBar()"
summary: "setUIProgressBar()"
permalink: tau_api_player_set_ui_progress_bar.html
tags: [api, player]
keywords: API Player
---
# The &tau; Player API

---------------------------------------------------------------------------------------------------------------------------------

## `setUIProgressBar()`

- Dart API: [setUIProgressBar()](pages/flutter-sound/api/player/FlutterSoundPlayer/setUIProgressBar.html).

This verb is used if the App wants to control itself the Progress Bar on the lock screen. By default, this progress bar is handled automaticaly by Flutter Sound.
Remark `setUIProgressBar()` is implemented only on iOS.

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
        setUIProgressBar(progress: Duration(milliseconds: progress.milliseconds - 500), duration: duration)
</pre>

</div>

<div role="tabpanel" class="tab-pane" id="javascript">
<pre>
        Lorem ipsum ...
</pre>
</div>

</div>

---------------------------------------------------------------------------------------------------------------------------------
