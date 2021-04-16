---
title:  "Player API"
description: "startPlayerFromStream()."
summary: "startPlayerFromStream()."
permalink: tau_api_player_start_player_from_stream.html
tags: [api, player]
keywords: API Player
---
# The &tau; Player API

--------------------------------------------------------------------------------------------------------------------------------

## `startPlayerFromStream()`

- Dart API: [startPlayerFromStream()](pages/flutter-sound/api/player/FlutterSoundPlayer/startPlayerFromStream.html).

**This functionnality needs, at least, and Android SDK >= 21**

- The only codec supported is actually `Codec.pcm16`.
- The only value possible for `numChannels` is actually 1.
- SampleRate is the sample rate of the data you want to play.

Please look to [the following notice](guides_play_stream)

*Example*
You can look to the three provided examples :

- [This example](flutter_sound_examples_playback_from_stream_2) shows how to play Live data, with Back Pressure from Flutter Sound
- [This example](flutter_sound_examples_playback_from_stream_1) shows how to play Live data, without Back Pressure from Flutter Sound
- [This example](flutter_sound_examples_sound_effects) shows how to play some real time sound effects.

*Example 1:*
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
    );
</pre>

</div>

<div role="tabpanel" class="tab-pane" id="javascript">
<pre>
        Lorem ipsum ...
</pre>
</div>

</div>

*Example 2:*
<ul id="profileTabs" class="nav nav-tabs">
    <li class="active"><a href="#dart" data-toggle="tab">Dart</a></li>
    <li><a href="#javascript" data-toggle="tab">Javascript</a></li>
</ul>
<div class="tab-content">

<div role="tabpanel" class="tab-pane active" id="dart">

<pre>
await myPlayer.startPlayerFromStream(codec: Codec.pcm16, numChannels: 1, sampleRate: 48000);

myPlayer.foodSink.add(FoodData(aBuffer));
myPlayer.foodSink.add(FoodData(anotherBuffer));
myPlayer.foodSink.add(FoodData(myOtherBuffer));

myPlayer.foodSink.add(FoodEvent((){_mPlayer.stopPlayer();}));
</pre>

</div>

<div role="tabpanel" class="tab-pane" id="javascript">
<pre>
        Lorem ipsum ...
</pre>
</div>

</div>


---------------------------------------------------------------------------------------------------------------------------------------------
