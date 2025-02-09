---
title:  "Player API"
description: "foodSink."
summary: "foodSink."
permalink: tau_api_player_food_sink.html
tags: [api, player]
keywords: API Player
---
# The &tau; Player API

---------------------------------------------------------------------------------------------------------------------------------

## `foodSink`

- Dart API: [foodSink](pages/flutter-sound/api/player/FlutterSoundPlayer/foodSink.html).

The sink side of the Food Controller that you use when you want to play asynchronously live data.
This StreamSink accept two kinds of objects :
- FoodData (the buffers that you want to play)
- FoodEvent (a call back to be called after a resynchronisation)

*Example:*

[This example](flutter_sound_examples_playback_from_stream_1) shows how to play Live data, without Back Pressure from Flutter Sound

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

---------------------------------------------------------------------------------------------------------------------------------
