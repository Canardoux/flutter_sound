---
title:  "Player API"
description: "startPlayerFromStream()."
summary: "startPlayerFromStream()."
permalink: tau_api_player_start_player_from_stream.html
tags: [API, player]
keywords: API Player
---
# The &tau; Player API

--------------------------------------------------------------------------------------------------------------------------------

## `startPlayerFromStream()`

[Dart API](https://canardoux.github.io/tau/doc/flutter_sound/api/player/FlutterSoundPlayer/startPlayerFromStream.html)

**This functionnality needs, at least, and Android SDK >= 21**

- The only codec supported is actually `Codec.pcm16`.
- The only value possible for `numChannels` is actually 1.
- SampleRate is the sample rate of the data you want to play.

Please look to [the following notice](codec.md#playing-pcm-16-from-a-dart-stream)

*Example*
You can look to the three provided examples :

- [This example](../flutter_sound/example/example.md#liveplaybackwithbackpressure) shows how to play Live data, with Back Pressure from Flutter Sound
- [This example](../flutter_sound/example/example.md#liveplaybackwithoutbackpressure) shows how to play Live data, without Back Pressure from Flutter Sound
- [This example](../flutter_sound/example/example.md#soundeffect) shows how to play some real time sound effects.

*Example 1:*
```dart
await myPlayer.startPlayerFromStream(codec: Codec.pcm16, numChannels: 1, sampleRate: 48000);

await myPlayer.feedFromStream(aBuffer);
await myPlayer.feedFromStream(anotherBuffer);
await myPlayer.feedFromStream(myOtherBuffer);

await myPlayer.stopPlayer();
```
*Example 2:*
```dart
await myPlayer.startPlayerFromStream(codec: Codec.pcm16, numChannels: 1, sampleRate: 48000);

myPlayer.foodSink.add(FoodData(aBuffer));
myPlayer.foodSink.add(FoodData(anotherBuffer));
myPlayer.foodSink.add(FoodData(myOtherBuffer));

myPlayer.foodSink.add(FoodEvent((){_mPlayer.stopPlayer();}));
```

---------------------------------------------------------------------------------------------------------------------------------------------
