---
title:  "PCM Dart Streams"
description: "Recording PCM-16 to a Dart Stream."
summary: "Recording PCM-16 to a Dart Stream."
permalink: guides_streams.html
tags: [guide]
keywords: guides
---

Record to Stream and Play from Stream are two very important Flutter Sound features

---------------

# Record to Stream

To record to live PCM data, when calling the verb `startRecorder()`, you specify the parameter `toStream:`, `toStreamFloat32` or `toStreamInt16` with your Stream sink, instead of the parameter `toFile:`. This parameter is a Dart StreamSink that you can listen to, for processing the audio data. 

- The parameter `toStream:` is used when you want to record interleaved data to a `<Uint8List>` Stream Sink
- The parameter `toStreamFloat32:` is used when you want to record non interleaved data to a `<List<Float32List>>` Stream Sink
- The parameter `toStreamInt16:` is used when you want to record non interleaved data to a `<List<Int16List>>` Stream Sink

{% include note.html content="`toStreamInt16:` are only supported on iOS. It will be supported later on Web and Android." %}
{% include note.html content="`toStreamFloat32:` is only supported on iOS and web. It will be supported later on Android." %}

## Interleaved

Interleaved data are given as `<Uint8List>`. This are the Raw Data where each sample are coded with 2 or 4 unsigned bytes for each sample. This is convenient when you want to handle globally the data as a raw buffer. For example when you want send the raw data to a remote server.

## Non interleaved

Non interleaved data are coded as `<List<Float32List>>` or `<List<Int16List>>` depending of the codec selected. The number of the element of the List is equal to the number of channels (1 for monophony, 2 for stereophony). This is convenient when you want to access the real audio data as Float32 or Int16. 

{% include tip.html content="You can specify `toStreamFloat32` or `toStreamInt16:` even when you have just one channel. In this case the length of the list is 1." %}

## startRecorder()

The main parameters for the verb `startRecorder()` are : 

- `codec:` : The codec (Codec.pcm16 or Codec.pcmFloat32)
- The Stream sink :
   - `toStream:` : When you want to record data interleaved
   - `toStreamFloat32:` : When you want to record Float32 data not interleaved
   - `toStreamInt16:` : When you eant to record record Int16 data  not interleaved
- `sampleRate:` : The sample rate
- `numChannels:` The number of channels (1 for monophony, 2 for stereophony, or more ...)

---------------------


## _Interleaved Example_

You can look to the [simple example](https://github.com/canardoux/flutter_sound/blob/master/flutter_sound/example/lib/recordToStream/record_to_stream_example.dart) provided with Flutter Sound.

```dart
  StreamController<Uint8List> recordingDataController = StreamController<Uint8List>();
  _mRecordingDataSubscription =
          recordingDataController.stream.listen
            ((Uint8List buffer)
              {
                ... // Process the audio frame
              }
            );
  await _mRecorder.startRecorder(
        toStream: recordingDataController.sink,
        codec: Codec.pcm16,
        numChannels: 2,
        sampleRate: 48000,
  );
```


## _Non Interleaved Example_

You can look to the [simple example](https://github.com/canardoux/flutter_sound/blob/master/flutter_sound/example/lib/streams/streams.dart) provided with Flutter Sound.

```dart
  StreamController<Food> recordingDataController = StreamController<List<Float32List>>();
  _mRecordingDataSubscription =
          recordingDataController.stream.listen
            ( (List<Float32List> buffer)
              {
                for (int channel = 0; channel < cstChannelCount; ++channel)
                {
                    Float32List channelData = buffer[channel];
                    for (int n = 0; n < channelData.length; ++n)
                    {
                      double sample = buffer[channel][n];
                      ... // Process the sample
                    }
                }
              }
            );
  await _mRecorder.startRecorder(
        toStreamFloat32: recordingDataController.sink,
        codec: Codec.pcmFloat32,
        numChannels: 2,
        sampleRate: 48000,
  );
```

## Notes :

{% include note.html content="Floating Point PCM data is not yet supported on Android. It is actually only implemented on iOS and Web." %}

{% include note.html content="interleaved Int16 PCM data is not yet supported on Web. It is actually only implemented on iOS." %}

{% include note.html content="Non interleaved Int16 PCM data is not yet supported on iOS and web." %}

{% include note.html content="Note: This functionnality needs, at least, an Android SDK &gt;= 21. This new functionnality works better with Android minSdk &gt;= 23, because previous SDK was not able to do UNBLOCKING `write`." %}

---------------

# Play from Stream

To play live stream, you start playing with the verb `startPlayerFromStream()` instead of the regular `startPlayer()` verb.

-----------------------

## startPlayerFromStream()

The main parameters for the verb `startPlayerFromStream()` are : 

- `codec:` : The codec (Codec.pcm16 or Codec.pcmFloat32)
- `sampleRate:` : The sample rate
- `numChannels:` : The number of channels (1 for monophony, 2 for stereophony, or more ...)
- `interleaved:` : A boolean for specifying if the data played are interleaved

```text
await myPlayer.startPlayerFromStream
(
    codec: Codec.pcmFloat32 
    numChannels: 2
    sampleRate: 48100
    interleaved: true,
    whenFinished: (){}, // to desactivate the stopPlayer() when the driver is short on waiting audio data to be played.
);
```

## interleaved:

This parameter specifies if the data to be played are interleaved or not. When the data are interleaved, you will use the `_mPlayer.foodSink` to play data. When the data are not interleaved, you will use `_mPlayer.float32Sink` or `_mPlayer.int16Sink` depending on the codec used. When the data are interleaved, the data provided by the app are coded as UINt8List. This is convenient when you have raw data to be played from a remote server. When the data are not interleaved, they are provided as `List<List>`, with an array of length equal to the number of channels. 

{% include tip.html content="It is possible to use non interleaved data, even with `numChannels` equal 1 when you have int16 Integers or float32 data to be played and not a raw buffer." %}

{% include note.html content="Non interleaved PCM data is not yet supported on Android. It is actually only implemented on iOS and Web." %}

-----

## whenFinished:

This parameter cannot be used. After `startPlayerFromStream()` the player is always on until `stopPlayer()`. The app can send audio data when it wants. Even after an elapsed time without any audio data.

--------------------

## Interleaved playback without back pressure (without flow control),

- `_mPlayer.uint8ListSink` is a Stream Sink used when the data are interleaved and when you have UInt8List buffers to be played
- `_mPlayer.float32Sink` is a Stream Sink used when the data are not interleaved and when you have Float32 data to be played
- `_mPlayer.int16Sink` is a Stream Sink used when the data are not interleaved and when you have Int16 data to be played

```dart
Uint8List d;
...
_mPlayer.uint8ListSink!.add(d);
```

```dart
List<Float32List> d; // A List of `numChannels` Float32List
...
_mPlayer.float32Sink(d);

```

```dart
List<Int16List>; // A List of `numChannels` Int16List
...
_mPlayer.int16Sink(d);
```


{% include note.html content="`int16Sink` is not yet supported on Android and Web. It is actually only implemented on iOS." %}
{% include note.html content="`float32Sink` is not yet supported on Android. It is actually only implemented on iOS and Web." %}

The App does `myPlayer.uint8ListSink.add(d)` or `_mPlayer.float32Sink(d)` or `mPlayer.int16Sink(d);` each time it wants to play some data. No need to await, no need to verify if the previous buffers have finished to be played. All the data added to the Stream Sink are buffered, and are played sequentially. The App continues to work without knowing when the buffers are really played.

This means two things :

* If the App is very fast adding buffers to `foodSink` it can consume a lot of memory for the waiting buffers.
* When the App has finished feeding the sink, it cannot just do `myPlayer.stopPlayer()`, because there are perhaps many buffers not yet played.

  If it does a `stopPlayer()`, all the waiting buffers will be flushed which is probably not what it wants.

## feedUint8FromStream(), feedInt16FromStream() and feedF32FromStream()

Instead of using the three getters uint8ListSink, float32Sink and int16Sink, you can also call directely the functions : 
- feedUint8FromStream()
- feedInt16FromStream()
- feedF32FromStream()

--------------

## _Examples_ 

You can look to the provided examples :

* [This example](https://github.com/canardoux/flutter_sound/blob/master/flutter_sound/example/lib/streams/streams.dart)
* [This example](hhttps://github.com/Canardoux/flutter_sound/blob/master/flutter_sound/example/lib/livePlaybackWithoutBackPressure/live_playback_without_back_pressure.dart) shows how to play Live data, without Back Pressure from Flutter Sound

--------------------

## Notes :

{% include note.html content="Note: Floating Point PCM data is not yet supported on Android. It is actually only implemented on iOS and Web." %}

{% include note.html content="Note: Non interleaved PCM data is not yet supported on Android. It is actually only implemented on iOS and Web." %}

{% include note.html content="Note: Non interleaved Int16 PCM data is not yet supported on iOS and Web. It is only implemented with codec.pcmFloat32." %}

{% include note.html content="Note: This functionnality needs, at least, an Android SDK &gt;= 21. This new functionnality works better with Android minSdk &gt;= 23, because previous SDK was not able to do UNBLOCKING `write`." %}

