---
title:  "Player API"
description: "Food."
summary: "Food."
permalink: tau_api_player_food.html
tags: [api, player]
keywords: API Player
---
# The &tau; Player API

----------------------------------------------------------------------------------------------------------------------------------

## `Food`

- Dart API: [food](pages/flutter-sound/api/tau/Food-class.html).
- Dart API: [foodData](pages/flutter-sound/api/tau/FoodData-class.html).
- Dart API: [food](pages/flutter-sound/api/tau/FoodEvent-class.html).


This are the objects that you can `add` to `foodSink`
The Food class has two others inherited classes :

- FoodData (the buffers that you want to play)
- FoodEvent (a call back to be called after a resynchronisation)

*Example:*

[This example](flutter_sound_examples_playback_from_stream_2) shows how to play Live data, without Back Pressure from Flutter Sound
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
myPlayer.foodSink.add(FoodEvent(()async {await _mPlayer.stopPlayer(); setState((){});}));
</pre>

</div>

<div role="tabpanel" class="tab-pane" id="javascript">
<pre>
        Lorem ipsum ...
</pre>
</div>

</div>


---------------------------------------------------------------------------------------------------------------------------------
