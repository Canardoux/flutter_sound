---
title:  "Player API"
description: "feedFromStream()."
summary: "feedFromStream()."
permalink: tau_api_player_feed_from_stream.html
tags: [api, player]
keywords: API Player
---
# The &tau; Player API


---------------------------------------------------------------------------------------------------------------------------------------------

## `feedFromStream()`

- Dart API: [feedFromStream()](/pages/flutter-sound/api/player/FlutterSoundPlayer/feedFromStream.html).

This is the verb that you use when you want to play live PCM data synchronously.
This procedure returns a Future. It is very important that you wait that this Future is completed before trying to play another buffer.

*Example:*

- [This example](flutter_sound_examples_playback_from_stream_1) shows how to play Live data, with Back Pressure from Flutter Sound
- [This example](flutter_sound_examples_playback_from_stream_2) shows how to play some real time sound effects synchronously.

<ul id="profileTabs" class="nav nav-tabs">
    <li class="active"><a href="#dart" data-toggle="tab">Dart</a></li>
    <li><a href="#javascript" data-toggle="tab">Javascript</a></li>
</ul>
<div class="tab-content">

<div role="tabpanel" class="tab-pane active" id="dart">

<pre>
await myPlayer.startPlayerFromStream(codec: Codec.pcm16, numChannels: 1, sampleRate: 48000);

await myPlayer.feedFromStream(aBuffer);
await myPlayer.feedFromStream(anotherBuffer);
await myPlayer.feedFromStream(myOtherBuffer);

await myPlayer.stopPlayer();
</pre>

</div>

<div role="tabpanel" class="tab-pane" id="javascript">
<pre>
        Lorem ipsum ...
</pre>
</div>

</div>

---------------------------------------------------------------------------------------------------------------------------------
