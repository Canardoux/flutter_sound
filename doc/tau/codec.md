# Getting Started

-------------------------------------------------------------------------------------------------------------------------------------

# Flutter Sound Codecs

Actually, the following codecs are supported by flutter_sound:

|                   | AAC ADTS | Opus OGG | Opus CAF    | MP3 | Vorbis OGG | PCM16  | PCM WAV | PCM AIFF | PCM CAF | FLAC    | AAC MP4 | AMR-NB | AMR-WB | PCM-8     | PCM F32  | PCM WEBM | Opus WEBM   | Vorbis WEBM |
| :---------------- | :------: | :------: | :---------: | :-: | :--------: | :----: | :-----: | :------: | :-----: | :-----: | :-----: | :----: | :----: | :-------: | :------: | :------: | :---------: | :---------: |
|                   |          |          |             |     |            |        |         |          |         |         |         |        |        |           |          |          |             |             |
| iOS encoder       | Yes      | Yes(*)   | Yes         | No  | No         | Yes    | Yes     | No       | Yes     | Yes     | Yes     | No     | No     | No        | No       | No       | No          | No          |
| iOS decoder       | Yes      | Yes(*)   | Yes         | Yes | No         | Yes    | Yes     | Yes      | Yes     | Yes     | Yes     | No     | No     | No        | No       | No       | No          | No          |
|                   |          |          |             |     |            |        |         |          |         |         |         |        |        |           |          |          |             |             |
| Android encoder   | Yes(1)   | No       | No          | No  | No         | Yes(1) | Yes(1)  | No       | No      | No      | Yes(1)  | Yes(1) | Yes(1) | No        | No       | No       | Yes         | No          |
| Android decoder   | Yes      | Yes(1)   | Yes(*)(1)   | Yes | Yes        | Yes    | Yes     | Yes(*)   | Yes(*)  | Yes     | Yes     | Yes    | Yes    | No        | No       | No       | Yes         | Yes         |
|                   |          |          |             |     |            |        |         |          |         |         |         |        |        |           |          |          |             |             |
| Chrome encoder    | No       | No       | No          | No  | No         | No     | No      | No       | No      | No      | No      | No     | No     | No        | No       | No       | Yes         | No          |
| Chrome decoder    | Yes      | Yes      | No          | Yes | Yes        | Yes    | Yes     | No       | No      | Yes     | Yes     | No     | No     | No        | No       | No       | Yes         | Yes         |
|                   |          |          |             |     |            |        |         |          |         |         |         |        |        |           |          |          |             |             |
| Firefox encoder   | No       | Yes      | No          | No  | No         | No     | No      | No       | No      | No      | No      | No     | No     | No        | No       | No       | Yes         | No          |
| Firefox decoder   | Yes      | Yes      | No          | Yes | Yes        | Yes    | Yes     | No       | No      | Yes     | Yes     | No     | No     | No        | No       | No       | Yes         | yes         |
|                   |          |          |             |     |            |        |         |          |         |         |         |        |        |           |          |          |             |             |
| Edge encoder      | No       | No       | No          | No  | No         | No     | No      | No       | No      | No      | no      | No     | No     | No        | No       | No       | Yes         | No          |
| Edge decoder      | Yes      | Yes      | No          | Yes | Yes        | Yes    | Yes     | No       | No      | Yes     | Yes     | No     | No     | No        | No       | no       | Yes         | Yes         |
|                   |          |          |             |     |            |        |         |          |         |         |         |        |        |           |          |          |             |             |
| Webkit encoder (Safari)   | No       | No       | No          | No  | No         | No     | No      | No       | No      | No      | No      | No     | No     | No        | No       | No       | No          | No          |
| Webkit decoder (Safari)   | Yes      | No       | Yes         | Yes | No         | No     | No      | No       | Yes     | Yes     | Yes     | No     | No     | No        | No       | No       | No          | No          |
|                   |          |          |             |     |            |        |         |          |         |         |         |        |        |           |          |          |             |             |


This table will eventually be upgraded when more codecs will be added.

- Yes(*) : The codec is supported by Flutter Sound, but with a File Format Conversion. This has several drawbacks :
   - Needs FFmpeg. FFmpeg is not included in the LITE flavor of Flutter Sound
   - Can add some delay before Playing Back the file, or after stopping the recording. This delay can be substancial for very large records.

- Yes(1) : needs MinSDK >=23

- Webkit is bull shit : you cannot record anything with Safari, or Firefox/Chrome on iOS.
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# Raw PCM and Wave files

Raw PCM is not an audio format. Raw PCM files store the raw data **without** any envelope.
A simple way for playing a Raw PCM file, is to add a `Wave` header in front of the data before playing it. To do that, the helper verb `pcmToWave()` is convenient. You can also call directely the `startPlayer()` verb. If you do that, do not forget to provide the `sampleRate` and `numChannels` parameters.

A Wave file is just PCM data in a specific file format.

The Wave audio file format has a terrible drawback : it cannot be streamed.
The Wave file is considered not valid, until it is closed. During the construction of the Wave file, it is considered as corrupted because the Wave header is still not written.

Note the following limitations in the current Flutter Sound version :
- The stream is  `PCM-Integer Linear 16` with just one channel. Actually, Flutter Sound does not manipulate Raw PCM with floating point PCM data nor with more than one audio channel.
- `FlutterSoundHelper duration()` does not work with Raw PCM file
- `startPlayer()` does not return the record duration.
- `withUI` parameter in `openAudioSession()` is actually incompatible with Raw PCM files.

-------------------------------------------------------------------------------------------------------------------------------------

# Recording or playing Raw PCM INT-Linerar 16 files

Please, remember that actually, Flutter Sound does not support Floating Point PCM data, nor records with more that one audio channel.

To record a Raw PCM16 file, you use the regular `startRecorder()` API verb.
To play a Raw PCM16 file, you can either add a Wave header in front of the file with `pcm16ToWave()` verb, or call the regular `startPlayer()` API verb. If you do the later, you must provide the `sampleRate` and `numChannels` parameter during the call.
You can look to the simple example provided with Flutter Sound. [TODO]

*Example*
``` dart
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

-------------------------------------------------------------------------------------------------------------------------------------

# Recording PCM-16 to a Dart Stream

Please, remember that actually, Flutter Sound does not support Floating Point PCM data, nor records with more that one audio channel.
On Flutter Sound, **Raw PCM is only PCM-LINEAR 16 monophony**

This works only with [openAudioSession()](recorder#openAudioSession-and-closeAudioSession) and  does not work with `openAudioSessionWithUI()`.
To record a Live PCM file, when calling the verb [startRecorder()](recorder.md#startrecorder), you specify the parameter `toStream:` with you Stream sink, instead of the parameter `toFile:`.
This parameter is a StreamSink that you can listen to, for processing the input data.

# Notes :

- This new functionnality needs, at least, an Android SDK >= 21
- This new functionnality works better with Android minSdk >= 23, because previous SDK was not able to do UNBLOCKING `write`.

*Example*

You can look to the [simple example](../example/README.md#recordtostream) provided with Flutter Sound.

``` dart
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

-------------------------------------------------------------------------------------------------------------------------------------

# Playing PCM-16 from a Dart Stream

Please, remember that actually, Flutter Sound does not support Floating Point PCM data, nor records with more that one audio channel.

This works only with [openAudioSession](player.md#openaudiosession-and-closeaudiosession) and does not work with `openAudioSessionWithUI()`.
To play live stream, you start playing with the verb [startPlayerFromStream](player.md#startplayerfromstream) instead of the regular `startPlayer()` verb:
```
await myPlayer.startPlayerFromStream
(
    codec: Codec.pcm16 // Actually this is the only codec possible
    numChannels: 1 // Actually this is the only value possible. You cannot have several channels.
    sampleRate: 48100 // This parameter is very important if you want to specify your own sample rate
);
```

The first thing you have to do if you want to play live audio is to answer this question:
```Do I need back pressure from Flutter Sound, or not```?

### Without back pressure,

The App does just [myPlayer.foodSink.add( FoodData(aBuffer) )](player.md#food) each time it wants to play some data.
No need to await, no need to verify if the previous buffers have finished to be played.
All the buffers added to `foodSink` are buffered, an are played sequentially. The App continues to work without knowing when the buffers are really played.

This means two things :
   - If the App is very fast adding buffers to `foodSink` it can consume a lot of memory for the waiting buffers.
   - When the App has finished feeding the sink, it cannot just do `myPlayer.stopPlayer()`, because there is perhaps many buffers not yet played.
If it does a `stopPlayer()`, all the waiting buffers will be flushed which is probably not what it wants.

But there is a mechanism if the App wants to resynchronize with the output Stream. To resynchronize with the current playback, the App does [myPlayer.foodSink.add( FoodEvent(aCallback) );](player.md#food)

```
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

*Example:*

You can look to this simple [example](../example/README.md#liveplaybackwithoutbackpressure) provided with Flutter Sound.

```dart
await myPlayer.startPlayerFromStream(codec: Codec.pcm16, numChannels: 1, sampleRate: 48000);

myPlayer.foodSink.add(FoodData(aBuffer));
myPlayer.foodSink.add(FoodData(anotherBuffer));
myPlayer.foodSink.add(FoodData(myOtherBuffer));

myPlayer.foodSink.add(FoodEvent((){_mPlayer.stopPlayer();}));
```

### With back pressure

If the App wants to keep synchronization with what is played, it uses the verb [feedFromStream](player.md#feedfromstream) to play data.
It is really very important not to call another `feedFromStream()` before the completion of the previous future. When each Future is completed, the App can be sure that the provided data are correctely either played, or at least put in low level internal buffers, and it knows that it is safe to do another one.


*Example:*

You can look to this [example](../flutter_sound/example/example.md#liveplaybackwithbackpressure) and [this example](../flutter_sound/example/example.md#soundeffect)
```
await myPlayer.startPlayerFromStream(codec: Codec.pcm16, numChannels: 1, sampleRate: 48000);

await myPlayer.feedFromStream(aBuffer);
await myPlayer.feedFromStream(anotherBuffer);
await myPlayer.feedFromStream(myOtherBuffer);

await myPlayer.stopPlayer();
```
You probably will `await` or use `then()` for each call to `feedFromStream()`.

### Notes :

- This new functionnality needs, at least, an Android SDK >= 21
- This new functionnality works better with Android minSdk >= 23, because previous SDK was not able to do UNBLOCKING `write`.

*Examples*
You can look to the  provided examples :

- [This example](../flutter_sound/example/example.md#liveplaybackwithbackpressure) shows how to play Live data, with Back Pressure from Flutter Sound
- [This example](../flutter_sound/example/example.md#liveplaybackwithoutbackpressure) shows how to play Live data, without Back Pressure from Flutter Sound
- [This example](../flutter_sound/example/example.md#soundeffect) shows how to play some real time sound effects.
- [This example](../flutter_sound/example/example.md#streamloop) play live stream what is recorded from the microphone.

-------------------------------------------------------------------------------------------------------------------------------------
