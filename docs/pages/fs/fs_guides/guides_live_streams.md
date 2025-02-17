---
title:  "PCM Dart Streams"
summary: "Recording PCM-16 to a Dart Stream and Playback from a Dart Stream are two **VERY**, **VERY** important Flutter Sound features that must not be overlooked."
permalink: fs-guides_live_streams.html
---
## Record to Stream

To record to a live PCM data, when calling the verb [startRecorder()](/tau/fs/api/recorder/FlutterSoundRecorder/startRecorder.html), you specify the parameter `toStream:`, `toStreamFloat32:` or `toStreamInt16:` with your Stream sink, instead of the parameter `toFile:`. This parameter is a Dart StreamSink that you can listen to, for processing the audio data. 

- The parameter `toStream:` is used when you want to record interleaved data to a `<Uint8List>` Stream Sink
- The parameter `toStreamFloat32:` is used when you want to record non interleaved data (Planar mode) to a `<List<Float32List>>` Stream Sink
- The parameter `toStreamInt16:` is used when you want to record non interleaved data (Planar mode) to a `<List<Int16List>>` Stream Sink

{% include note.html content="
`toStreamInt16:` are only supported on iOS. It will be supported later on Web and Android.
"%}
{% include note.html content="
`toStreamFloat32:` is only supported on iOS and web. It will be supported later on Android.
"%}

### Interleaved

Interleaved data are given as `<Uint8List>`. This are the Raw Data where each sample are coded with 2 or 4 unsigned bytes for each sample. This is convenient when you want to handle globally the data as a raw buffer. For example when you want send the raw data to a remote server.

### Non interleaved (or Planar)

Non interleaved data are coded as `<List<Float32List>>` or `<List<Int16List>>` depending of the codec selected. The number of the element of the List is equal to the number of channels (1 for monophony, 2 for stereophony). This is convenient when you want to access the real audio data as Float32 or Int16. 

{% include tip.html content="
You can specify `toStreamFloat32` or `toStreamInt16:` even when you have just one channel. In this case the length of the list is 1.
"%}

### startRecorder()

The main parameters for the verb [startRecorder()](/tau/fs/api/recorder/FlutterSoundRecorder/startRecorder.html) are : 

- `codec:` : The codec (Codec.pcm16 or Codec.pcmFloat32)
- The Stream sink :
   - `toStream:` : When you want to record data interleaved
   - `toStreamFloat32:` : When you want to record Float32 data not interleaved
   - `toStreamInt16:` : When you eant to record record Int16 data  not interleaved
- `sampleRate:` : The sample rate
- `numChannels:` The number of channels (1 for monophony, 2 for stereophony, or more ...)

---------------------


### _Interleaved Example_

You can look to 
* The [simple example](fs-ex_record_to_stream.html) provided with Flutter Sound.
* The [simple example](fs-ex_streams.html)


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


### _Non Interleaved Example_

You can look to the same [simple example](fs-ex_streams.html) provided with Flutter Sound.

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

### Notes :

{% include note.html content="
Floating Point PCM data is not yet supported on Android. It is actually only implemented on iOS and Web.
"%}

{% include note.html content="
interleaved Int16 PCM data is not yet supported on Web. It is actually only implemented on iOS.
"%}

{% include note.html content="
Non interleaved Int16 PCM data is not yet supported on iOS and web.
"%}

{% include note.html content="
Note: This functionnality needs, at least, an Android SDK &gt;= 21. This new functionnality works better with Android minSdk &gt;= 23, because previous SDK was not able to do UNBLOCKING `write`.
"%}

---------------

## Play from Stream

To play live stream, you start playing with the verb [startPlayerFromStream()](/tau/fs/api/player/FlutterSoundPlayer/startPlayerFromStream.html) instead of the regular `startPlayer()` verb.

The main parameters for the verb [startPlayerFromStream()](/tau/fs/api/player/FlutterSoundPlayer/startPlayerFromStream.html) are : 

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
);
```

### interleaved:

This parameter specifies if the data to be played are interleaved or not. When the data are interleaved, you will use the [_mPlayer.uint8ListSink](/tau/fs/api/player/FlutterSoundPlayer/uint8ListSink.html) to play data. When the data are not interleaved, you will use [_mPlayer.float32Sink](/tau/fs/api/player/FlutterSoundPlayer/float32Sink.html) or [_mPlayer.int16Sink](/tau/fs/api/player/FlutterSoundPlayer/int16Sink.html) depending on the codec used. When the data are interleaved, the data provided by the app must be coded as UInt8List. This is convenient when you have raw data to be played from a remote server. When the data are not interleaved, they are provided as `List<List>`, with an array of length equal to the number of channels. 

{% include tip.html content="
It is possible to use non interleaved data, even with `numChannels` equal 1 when you have int16 Integers or float32 data to be played and not a raw buffer.
"%}

{% include note.html content="
Non interleaved PCM data is not yet supported on Android. It is actually only implemented on iOS and Web.
"%}

-----

### whenFinished:

This parameter cannot be used. After [startPlayerFromStream()](/tau/fs/api/player/FlutterSoundPlayer/startPlayerFromStream.html) the player is always `on` until [stopPlayer()](/tau/fs/api/player/FlutterSoundPlayer/stopPlayer.html). The app can provide audio data when it wants. Even after an elapsed time without any audio data.

--------------------

### Playback without back pressure (without flow control),

- [_mPlayer.float32Sink](/tau/fs/api/player/FlutterSoundPlayer/float32Sink.html) is a Stream Sink used when the data are interleaved and when you have UInt8List buffers to be played
- [_mPlayer.int16Sink](/tau/fs/api/player/FlutterSoundPlayer/int16Sink.html) is a Stream Sink used when the data are not interleaved and when you have Float32 data to be played
- [_mPlayer.int16Sink](/tau/fs/api/player/FlutterSoundPlayer/int16Sink.html) is a Stream Sink used when the data are not interleaved and when you have Int16 data to be played

```dart
Uint8List d;
...
_mPlayer.uint8ListSink.add(d);
```

```dart
List<Float32List> d; // A List of `numChannels` Float32List
...
_mPlayer.float32Sink.add(d);

```

```dart
List<Int16List>; // A List of `numChannels` Int16List
...
_mPlayer.int16Sink.add(d);
```


{% include note.html content="
`int16Sink` is not yet supported on Android and Web. It is actually only implemented on iOS.
"%}
{% include note.html content="
`float32Sink` is not yet supported on Android. It is actually only implemented on iOS and Web.
"%}

The App does `myPlayer.uint8ListSink.add(d)` or `_mPlayer.float32Sink(d)` or `mPlayer.int16Sink(d);` each time it wants to play some data. No need to await, no need to verify if the previous buffers have finished to be played. All the data added to the Stream Sink are buffered, and are played sequentially. The App continues to work without knowing when the buffers are really played.

This means three things :

* If the App is very fast adding buffers to the `foodSink` it can consume a lot of memory for the waiting buffers.
* When the App has finished feeding the sink, it cannot just do `myPlayer.stopPlayer()`, because there are perhaps many buffers not yet played.
If it does a `stopPlayer()`, all the waiting buffers will be flushed which is probably not what it wants.
* The App cannot know when the audio data are really played.


--------------

### _Examples_ 

You can look to the provided examples :

* The [simple example](fs-ex_streams.html)
* [This example](fs-ex_playback_from_stream_1.html) shows how to play live data, without Back Pressure from Flutter Sound

--------------------

### Playback with back pressure (with flow control).

Playing live data without flow control is very simple, because you don't have to wait//handle Futures. But sometimes it can be interesting to manage a flow control :
- When you have huge data generated and you cannot loop feeding your Stream Sink.
- When you want to know when the data has been played for generating data on demand.
- When you just want to know when your previous packet has been played


If the App wants to keep synchronization with what is played, it uses the verb feedUint8FromStream(), feedInt16FromStream() or feedF32FromStream() to play data. 
- [feedUint8FromStream()](/tau/fs/api/player/FlutterSoundPlayer/feedUint8FromStream.html)
- [feedInt16FromStream()](/tau/fs/api/player/FlutterSoundPlayer/feedInt16FromStream.html)
- [feedF32FromStream()](/tau/fs/api/player/FlutterSoundPlayer/feedF32FromStream.html)

It is really very important not to call another `feedFromStream()` before the completion of the previous future. When each Future is completed, the App can be sure that the provided data are correctely either played, or at least put in low level internal buffers, and it knows that it is safe to do another one.

_Example:_

You can look to this [This example](fs-ex_playback_from_stream_2.html)

```text
await myPlayer.startPlayerFromStream(codec: Codec.pcm16, numChannels: 1, sampleRate: 48000);

await myPlayer.feedFromStream(aBuffer);
await myPlayer.feedFromStream(anotherBuffer);
await myPlayer.feedFromStream(myOtherBuffer);

await myPlayer.stopPlayer();
```

You will `await` or use `then()` for each call to `feedFromStream()`.

#### Notes :

* This new functionnality needs, at least, an Android SDK &gt;= 23

## _Examples_

You can look to the provided examples :

* [This simple example](fs-ex_playback_from_stream_2) shows how to play live data, with Back Pressure.
* [This example](fs-ex_playback_from_stream_1) shows how to play live data, without Back Pressure.
* [This example](fs-ex_streams.html) shows how to play Float32, or Int16, Interleaved or Planar.


--------------------

### Notes :

{% include note.html content="
Note: Floating Point PCM data is not yet supported on Android. It is actually only implemented on iOS and Web.
"%}

{% include note.html content="
Note: Non interleaved PCM data is not yet supported on Android. It is actually only implemented on iOS and Web.
"%}

{% include note.html content="
Note: Non interleaved Int16 PCM data is not yet supported on iOS and Web. It is only implemented with codec.pcmFloat32.
"%}

{% include note.html content="
Note: This functionnality needs, at least, an Android SDK &gt;= 21. This new functionnality works better with Android minSdk &gt;= 23, because previous SDK was not able to do UNBLOCKING `write`.
"%}

