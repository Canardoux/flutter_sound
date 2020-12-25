---
title:  "Player API"
description: "nowPlaying()"
summary: "nowPlaying()"
permalink: tau_api_player_now_playing.html
tags: [api, player]
keywords: API Player
---
# The &tau; Player API

---------------------------------------------------------------------------------------------------------------------------------

## `nowPlaying()`

- Dart API: [nowPlaying()](pages/flutter-sound/api/player/FlutterSoundPlayer/nowPlaying.html).

This verb is used to set the Lock screen fields without starting a new playback.
The fields 'dataBuffer' and 'trackPath' of the Track parameter are not used.
Please refer to 'startPlayerFromTrack' for the meaning of the others parameters.
Remark `setUIProgressBar()` is implemented only on iOS.

*Example:*
<ul id="profileTabs" class="nav nav-tabs">
    <li class="active"><a href="#dart" data-toggle="tab">Dart</a></li>
    <li><a href="#javascript" data-toggle="tab">Javascript</a></li>
</ul>
<div class="tab-content">

<div role="tabpanel" class="tab-pane active" id="dart">

<pre>
    Track track = Track( codec: Codec.opusOGG, trackPath: fileUri, trackAuthor: '3 Inches of Blood', trackTitle: 'Axes of Evil', albumArtAsset: albumArt );
    await nowPlaying(Track);
</pre>

</div>

<div role="tabpanel" class="tab-pane" id="javascript">
<pre>
        Lorem ipsum ...
</pre>
</div>

</div>
