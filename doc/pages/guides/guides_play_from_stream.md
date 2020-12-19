---
title:  "Guides"
description: "Playing PCM-16 from a Dart Stream."
summary: "Playing PCM-16 from a Dart Stream."
permalink: guides_play_stream.html
tags: [guides]
keywords: guides
---

---------------

## Playing PCM-16 from a Dart Stream

Please, remember that actually, Flutter Sound does not support Floating Point PCM data, nor records with more that one audio channel.

This works only with [openAudioSession](https://github.com/canardoux/tau/tree/d7b8befadb8626d34dd41290ee216ace42751e11/doc/guides/player.md#openaudiosession-and-closeaudiosession) and does not work with `openAudioSessionWithUI()`. To play live stream, you start playing with the verb [startPlayerFromStream](https://github.com/Canardoux/tau/tree/d7b8befadb8626d34dd41290ee216ace42751e11/doc/guides/player.md#startplayerfromstream) instead of the regular `startPlayer()` verb:

```text
await myPlayer.startPlayerFromStream
(
    codec: Codec.pcm16 // Actually this is the only codec possible
    numChannels: 1 // Actually this is the only value possible. You cannot have several channels.
    sampleRate: 48100 // This parameter is very important if you want to specify your own sample rate
);
```

The first thing you have to do if you want to play live audio is to answer this question: `Do I need back pressure from Flutter Sound, or not`?

#### Without back pressure,

The App does just [myPlayer.foodSink.add\( FoodData\(aBuffer\) \)](https://github.com/canardoux/tau/tree/d7b8befadb8626d34dd41290ee216ace42751e11/doc/guides/player.md#food) each time it wants to play some data. No need to await, no need to verify if the previous buffers have finished to be played. All the buffers added to `foodSink` are buffered, an are played sequentially. The App continues to work without knowing when the buffers are really played.

This means two things :

* If the App is very fast adding buffers to `foodSink` it can consume a lot of memory for the waiting buffers.
* When the App has finished feeding the sink, it cannot just do `myPlayer.stopPlayer()`, because there is perhaps many buffers not yet played.

  If it does a `stopPlayer()`, all the waiting buffers will be flushed which is probably not what it wants.

But there is a mechanism if the App wants to resynchronize with the output Stream. To resynchronize with the current playback, the App does [myPlayer.foodSink.add\( FoodEvent\(aCallback\) \);](https://github.com/canardoux/tau/tree/d7b8befadb8626d34dd41290ee216ace42751e11/doc/guides/player.md#food)

```text
myPlayer.foodSink.add
( FoodEvent
  (
     () async
     {
          await myPlayer.stopPlayer();
          setState((){});
     }
  )
);
```

_Example:_

You can look to this simple [example](https://github.com/canardoux/tau/tree/d7b8befadb8626d34dd41290ee216ace42751e11/doc/example/README.md#liveplaybackwithoutbackpressure) provided with Flutter Sound.

```dart
await myPlayer.startPlayerFromStream(codec: Codec.pcm16, numChannels: 1, sampleRate: 48000);

myPlayer.foodSink.add(FoodData(aBuffer));
myPlayer.foodSink.add(FoodData(anotherBuffer));
myPlayer.foodSink.add(FoodData(myOtherBuffer));

myPlayer.foodSink.add(FoodEvent((){_mPlayer.stopPlayer();}));
```

#### With back pressure

If the App wants to keep synchronization with what is played, it uses the verb [feedFromStream](https://github.com/canardoux/tau/tree/d7b8befadb8626d34dd41290ee216ace42751e11/doc/guides/player.md#feedfromstream) to play data. It is really very important not to call another `feedFromStream()` before the completion of the previous future. When each Future is completed, the App can be sure that the provided data are correctely either played, or at least put in low level internal buffers, and it knows that it is safe to do another one.

_Example:_

You can look to this [example](https://github.com/canardoux/tau/tree/d7b8befadb8626d34dd41290ee216ace42751e11/doc/flutter_sound/example/example.md#liveplaybackwithbackpressure) and [this example](https://github.com/Canardoux/tau/tree/d7b8befadb8626d34dd41290ee216ace42751e11/doc/flutter_sound/example/example.md#soundeffect)

```text
await myPlayer.startPlayerFromStream(codec: Codec.pcm16, numChannels: 1, sampleRate: 48000);

await myPlayer.feedFromStream(aBuffer);
await myPlayer.feedFromStream(anotherBuffer);
await myPlayer.feedFromStream(myOtherBuffer);

await myPlayer.stopPlayer();
```

You probably will `await` or use `then()` for each call to `feedFromStream()`.

#### Notes :

* This new functionnality needs, at least, an Android SDK &gt;= 21
* This new functionnality works better with Android minSdk &gt;= 23, because previous SDK was not able to do UNBLOCKING `write`.

_Examples_ You can look to the provided examples :

* [This example](https://github.com/canardoux/tau/tree/d7b8befadb8626d34dd41290ee216ace42751e11/doc/flutter_sound/example/example.md#liveplaybackwithbackpressure) shows how to play Live data, with Back Pressure from Flutter Sound
* [This example](https://github.com/canardoux/tau/tree/d7b8befadb8626d34dd41290ee216ace42751e11/doc/flutter_sound/example/example.md#liveplaybackwithoutbackpressure) shows how to play Live data, without Back Pressure from Flutter Sound
* [This example](https://github.com/canardoux/tau/tree/d7b8befadb8626d34dd41290ee216ace42751e11/doc/flutter_sound/example/example.md#soundeffect) shows how to play some real time sound effects.
* [This example](https://github.com/canardoux/tau/tree/d7b8befadb8626d34dd41290ee216ace42751e11/doc/flutter_sound/example/example.md#streamloop) play live stream what is recorded from the microphone.

