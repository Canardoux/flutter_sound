---
title:  "Player API"
description: "Food."
summary: "Food."
permalink: tau_api_player_food.html
tags: [API, player]
keywords: API Player
---
# The &tau; Player API

----------------------------------------------------------------------------------------------------------------------------------

## `Food`

- [Dart API: Food](https://canardoux.github.io/tau/doc/flutter_sound/api/tau/Food/Food.html)
- [Dart API: FoodData](https://canardoux.github.io/tau/doc/flutter_sound/api/tau/FoodData/FoodData.html.html)
- [Dart API: FoodEvent](https://canardoux.github.io/tau/doc/flutter_sound/api/tau/FoodEvent/FoodEvent.html)


This are the objects that you can `add` to `foodSink`
The Food class has two others inherited classes :

- FoodData (the buffers that you want to play)
- FoodEvent (a call back to be called after a resynchronisation)

*Example:*

[This example](../example/README.md#liveplaybackwithoutbackpressure) shows how to play Live data, without Back Pressure from Flutter Sound
```dart
await myPlayer.startPlayerFromStream(codec: Codec.pcm16, numChannels: 1, sampleRate: 48000);

myPlayer.foodSink.add(FoodData(aBuffer));
myPlayer.foodSink.add(FoodData(anotherBuffer));
myPlayer.foodSink.add(FoodData(myOtherBuffer));
myPlayer.foodSink.add(FoodEvent(()async {await _mPlayer.stopPlayer(); setState((){});}));
```

---------------------------------------------------------------------------------------------------------------------------------
