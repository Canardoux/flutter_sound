---
title:  "Player API"
description: "foodSink."
summary: "foodSink."
permalink: tau_api_player_food_sink.html
tags: [API, player]
keywords: API Player
---
# The &tau; Player API

---------------------------------------------------------------------------------------------------------------------------------

## `foodSink`

[Dart API](https://canardoux.github.io/tau/doc/flutter_sound/api/player/FlutterSoundPlayer/foodSink.html)

The sink side of the Food Controller that you use when you want to play asynchronously live data.
This StreamSink accept two kinds of objects :
- FoodData (the buffers that you want to play)
- FoodEvent (a call back to be called after a resynchronisation)

*Example:*

[This example](../example/README.md#liveplaybackwithoutbackpressure) shows how to play Live data, without Back Pressure from Flutter Sound
```dart
await myPlayer.startPlayerFromStream(codec: Codec.pcm16, numChannels: 1, sampleRate: 48000);

myPlayer.foodSink.add(FoodData(aBuffer));
myPlayer.foodSink.add(FoodData(anotherBuffer));
myPlayer.foodSink.add(FoodData(myOtherBuffer));
myPlayer.foodSink.add(FoodEvent((){_mPlayer.stopPlayer();}));
```

---------------------------------------------------------------------------------------------------------------------------------
