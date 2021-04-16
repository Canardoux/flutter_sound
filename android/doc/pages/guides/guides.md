---
title:  "Guides"
description: "Various guides about The &tau; Project."
summary: "Various guides about The &tau; Project."
permalink: guides_guides.html
tags: [guide]
keywords: guides
---

## Supported Codecs

### On mobile OS

Actually, the following codecs are supported by flutter\_sound:

|  | iOS encoder | iOS decoder | Android encoder | Android decoder |
| :--- | :---: | :---: | :---: | :---: |
| AAC ADTS | ✅ | ✅ | ✅ \(1\) | ✅ |
| Opus OGG | ✅ \(\*\) | ✅ \(\*\) | ❌ | ✅ \(1\) |
| Opus CAF | ✅ | ✅ | ❌ | ✅ \(\*\) \(1\) |
| MP3 | ❌ | ✅ | ❌ | ✅ |
| Vorbis OGG | ❌ | ❌ | ❌ | ✅ |
| PCM16 | ✅ | ✅ | ✅ \(1\) | ✅ |
| PCM Wave | ✅ | ✅ | ✅ \(1\) | ✅ |
| PCM AIFF | ❌ | ✅ | ❌ | ✅ \(\*\) |
| PCM CAF | ✅ | ✅ | ❌ | ✅ \(\*\) |
| FLAC | ✅ | ✅ | ❌ | ✅ |
| AAC MP4 | ✅ | ✅ | ✅ \(1\) | ✅ |
| AMR NB | ❌ | ❌ | ✅ \(1\) | ✅ |
| AMR WB | ❌ | ❌ | ✅ \(1\) | ✅ |
| PCM8 | ❌ | ❌ | ❌ | ❌ |
| PCM F32 | ❌ | ❌ | ❌ | ❌ |
| PCM WEBM | ❌ | ❌ | ❌ | ❌ |
| Opus WEBM | ❌ | ❌ | ✅ | ✅ |
| Vorbis WEBM | ❌ | ❌ | ❌ | ✅ |

This table will eventually be upgraded when more codecs will be added.

* ✅ \(\*\) : The codec is supported by Flutter Sound, but with a File Format Conversion. This has several drawbacks :
  * Needs FFmpeg. FFmpeg is not included in the LITE flavor of Flutter Sound
  * Can add some delay before Playing Back the file, or after stopping the recording. This delay can be substancial for very large records.
* ✅ \(1\) : needs MinSDK &gt;=23

### On Web browsers

|  | Chrome encoder | Chrome decoder | Firefox encoder | Firefox decoder | Webkit encoder \(safari\) | Webkit decoder   \(Safari\) |  |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :--- |
| AAC ADTS | ❌ | ✅ | ❌ | ✅ | ❌ | ✅ |  |
| Opus OGG | ❌ | ✅ | ✅ | ✅ | ❌ | ❌ |  |
| Opus CAF | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |  |
| MP3 | ❌ | ✅ | ❌ | ✅ | ❌ | ✅ |  |
| Vorbis OGG | ❌ | ✅ | ❌ | ✅ | ❌ | ❌ |  |
| PCM16 | ❌ | ✅ | ❌ | ✅ | ❌ | ❌ | \(must be verified\) |
| PCM Wave | ❌ | ✅ | ❌ | ✅ | ❌ | ❌ |  |
| PCM AIFF | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |  |
| PCM CAF | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |  |
| FLAC | ❌ | ✅ | ❌ | ✅ | ❌ | ✅ |  |
| AAC MP4 | ❌ | ✅ | ❌ | ✅ | ❌ | ✅ |  |
| AMR NB | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |  |
| AMR WB | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |  |
| PCM8 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |  |
| PCM F32 | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |  |
| PCM WEBM | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |  |
| Opus WEBM | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ |  |
| Vorbis WEBM | ❌ | ✅ | ❌ | ✅ | ❌ | ❌ |  |

* Webkit is bull shit : you cannot record anything with Safari, or even Firefox/Chrome on iOS.
* Opus WEBM is a great Codec. It works on everything \(mobile and Web Browsers\), except Apple
* Edge is same as Chrome

---------

## Raw PCM and Wave files

Raw PCM is not an audio format. Raw PCM files store the raw data **without** any envelope. A simple way for playing a Raw PCM file, is to add a `Wave` header in front of the data before playing it. To do that, the helper verb `pcmToWave()` is convenient. You can also call directely the `startPlayer()` verb. If you do that, do not forget to provide the `sampleRate` and `numChannels` parameters.

A Wave file is just PCM data in a specific file format.

The Wave audio file format has a terrible drawback : it cannot be streamed. The Wave file is considered not valid, until it is closed. During the construction of the Wave file, it is considered as corrupted because the Wave header is still not written.

Note the following limitations in the current Flutter Sound version :

* The stream is  `PCM-Integer Linear 16` with just one channel. Actually, Flutter Sound does not manipulate Raw PCM with floating point PCM data nor with more than one audio channel.
* `FlutterSoundHelper duration()` does not work with Raw PCM file
* `startPlayer()` does not return the record duration.
* `withUI` parameter in `openAudioSession()` is actually incompatible with Raw PCM files.

## Recording or playing Raw PCM INT-Linerar 16 files

Please, remember that actually, Flutter Sound does not support Floating Point PCM data, nor records with more that one audio channel.

To record a Raw PCM16 file, you use the regular `startRecorder()` API verb. To play a Raw PCM16 file, you can either add a Wave header in front of the file with `pcm16ToWave()` verb, or call the regular `startPlayer()` API verb. If you do the later, you must provide the `sampleRate` and `numChannels` parameter during the call. You can look to the simple example provided with Flutter Sound. \[TODO\]

_Example_

```dart
Directory tempDir = await getTemporaryDirectory();
String outputFile = '${tempDir.path}/myFile.pcm';

await myRecorder.startRecorder
(
    codec: Codec.pcm16,
    toFile: outputFile,
    sampleRate: 16000,
    numChannels: 1,
);

...
myRecorder.stopRecorder();
...

await myPlayer.startPlayer
(
        fromURI: = outputFile,
        codec: Codec.pcm16,
        numChannels: 1,
        sampleRate: 16000, // Used only with codec == Codec.pcm16
        whenFinished: (){ /* Do something */},

);
```

---------------

## Recording PCM-16 to a Dart Stream

Please, remember that actually, Flutter Sound does not support Floating Point PCM data, nor records with more that one audio channel. On Flutter Sound, **Raw PCM is only PCM-LINEAR 16 monophony**

To record a Live PCM file, when calling the verb `startRecorder\(\)`, you specify the parameter `toStream:` with you Stream sink, instead of the parameter `toFile:`. This parameter is a StreamSink that you can listen to, for processing the input data.

## Notes :

* This new functionnality needs, at least, an Android SDK &gt;= 21
* This new functionnality works better with Android minSdk &gt;= 23, because previous SDK was not able to do UNBLOCKING `write`.

_Example_

You can look to the [simple example](flutter_sound_examples_record_to_stream) provided with Flutter Sound.

```dart
  IOSink outputFile = await createFile();
  StreamController<Food> recordingDataController = StreamController<Food>();
  _mRecordingDataSubscription =
          recordingDataController.stream.listen
            ((Uint8List buffer)
              {
                outputFile.add(buffer);
              }
            );
  await _mRecorder.startRecorder(
        toStream: recordingDataController.sink,
        codec: Codec.pcm16,
        numChannels: 1,
        sampleRate: 48000,
  );
```

---------------

## Playing PCM-16 from a Dart Stream

Please, remember that actually, Flutter Sound does not support Floating Point PCM data, nor records with more that one audio channel.

To play live stream, you start playing with the verb `startPlayerFromStream` instead of the regular `startPlayer()` verb:

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

The App does just `myPlayer.foodSink.add\( FoodData\(aBuffer\) \)` each time it wants to play some data. No need to await, no need to verify if the previous buffers have finished to be played. All the buffers added to `foodSink` are buffered, an are played sequentially. The App continues to work without knowing when the buffers are really played.

This means two things :

* If the App is very fast adding buffers to `foodSink` it can consume a lot of memory for the waiting buffers.
* When the App has finished feeding the sink, it cannot just do `myPlayer.stopPlayer()`, because there is perhaps many buffers not yet played.

  If it does a `stopPlayer()`, all the waiting buffers will be flushed which is probably not what it wants.

But there is a mechanism if the App wants to resynchronize with the output Stream. To resynchronize with the current playback, the App does `myPlayer.foodSink.add\( FoodEvent\(aCallback\) \);`

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

You can look to this simple [example](flutter_sound_examples_playback_from_stream_1) provided with Flutter Sound.

```dart
await myPlayer.startPlayerFromStream(codec: Codec.pcm16, numChannels: 1, sampleRate: 48000);

myPlayer.foodSink.add(FoodData(aBuffer));
myPlayer.foodSink.add(FoodData(anotherBuffer));
myPlayer.foodSink.add(FoodData(myOtherBuffer));

myPlayer.foodSink.add(FoodEvent((){_mPlayer.stopPlayer();}));
```

#### With back pressure

If the App wants to keep synchronization with what is played, it uses the verb `feedFromStream` to play data. It is really very important not to call another `feedFromStream()` before the completion of the previous future. When each Future is completed, the App can be sure that the provided data are correctely either played, or at least put in low level internal buffers, and it knows that it is safe to do another one.

_Example:_

You can look to this [example](flutter_sound_examples_playback_from_stream_2) and [this example](flutter_sound_examples_sound_effects)

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

* [This example](flutter_sound_examples_playback_from_stream_1) shows how to play Live data, with Back Pressure from Flutter Sound
* [This example](flutter_sound_examples_playback_from_stream_2) shows how to play Live data, without Back Pressure from Flutter Sound
* [This example](flutter_sound_examples_sound_effects) shows how to play some real time sound effects.
* [This example](flutter_sound_examples_stream_loop) play live stream what is recorded from the microphone.

