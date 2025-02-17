---
title:  "PCM files"
summary: "Raw PCM and Wave files."
permalink: fs-guides_pcm_wave.html
---
---------

Raw PCM audio data are not a compressed format. The data are composed by samples which are taken very rapidly.
A raw codec is completely specified by :
- The PCM file format (RAW PCM or WAVE)
- The way samples are coded (Int16 or Float32)
- The sample rate
- The number of channels
- The interleaving state (Interleaved or Plan-Mode state)

Fluttter Sound supports four PCM Codecs :
- Codec.pcm16
- Codec.pcm16WAV
- Codec.pcmFloat32,
- Codec.pcmFloat32WAV

{% include tip.html content="
RAW PCM Formats are REALLY!!!, REALLY!!! great with Dart Streams. See the [guide here](fs-guides_live_streams.html).
"%}

---------------------

## The PCM file format

Flutter Sound supports two PCM file formats :
- RAW PCM
   - Codec.pcm16
   - Codec.pcmFloat32
- WAVE Format
   - Codec.pcm16WAV
   - pcmFloat32WAV

A Wave file is a WAVE header + RAW PCM data. When you want to play a WAVE file, all the PCM attributs can be found in the header. You don't have to specify those parameters when you want to play such a file. The Wave audio file format has a terrible drawback : it cannot be streamed. The Wave file is considered not valid, until it is closed. During the construction of the Wave file, it is considered as corrupted because the Wave header is still not written.

Raw PCM is not really an audio format. Raw PCM files store the raw data **without** any envelope. This means that when you want to play RAW PCM files, you must specified all the PCM attributs (Sample Rate, coding, number of channels, ...).
A simple way for playing a RAW PCM file, is to add a `Wave` header in front of the data before playing it. To do that, the helper verb [pcmToWave()](/tau/fs/api/helper/FlutterSoundHelper/pcmToWave.html) is convenient. You can also call directely the [startPlayer()](/tau/fs/api/player/FlutterSoundPlayer/startPlayer.html) verb. If you do that, do not forget to provide the `sampleRate` and `numChannels` parameters.

{% include tip.html content="
If you need to remove the header from a WAVE file, the helper verb [waveToPCM()](/tau/fs/api/helper/FlutterSoundHelper/waveToPCM.html) is convenient.
"%}
{% include tip.html content="
If you need to add a header in front of a RAW file, the helper verb [pcmToWave()](/tau/fs/api/helper/FlutterSoundHelper/pcmToWave.html) is convenient.
"%}

----------------------------

## Recording or playing Raw PCM files

To record a RAW PCM16 file, you use the regular [startRecorder()](/tau/fs/api/recorder/FlutterSoundRecorder/startRecorder.html) API verb. To play a Raw PCM16 file, you can either add a Wave header in front of the file with [pcm16ToWave](/tau/fs/api/helper/FlutterSoundHelper/pcmToWave.html) verb, or call the regular [startPlayer()](/tau/fs/api/player/FlutterSoundPlayer/startPlayer.html) or [startPlayerFromStream](/tau/fs/api/player/FlutterSoundPlayer/startPlayerFromStream.html) API verb. If you do the later, you must provide the `sampleRate` and `numChannels` parameter during the call. You can look to the examples provided with Flutter Sound.

_Example_:

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
        fromURI: outputFile,
        codec: Codec.pcm16,
        numChannels: 1,
        sampleRate: 16000,
        whenFinished: (){ /* Do something */},
);
```

---------------------------------------

## The way samples are coded

Flutter Sound supports two ways of sample coding :
- INT16
   - Codec.pcm16
   - Codec.pcm16WAV
- FLOAT32
   - Codec.pcmFloat32
   - Codec.pcmFloat32WAV

With the two INT16 Codecs, each sample is coded with signed integers on 16 bits. With the two FLOAT32 Ccodecs, each sample is coded with a floating point number on 32 bits.

{% include tip.html content="It is not very difficult to convert INT16 to FLOAT32 or FLOAT32 to INT16. A future Flutter Sound version will probably offer helper functions to do that. This is actually not done." %}

{% include note.html content="FLOAT32 is not yet supported on Android and Web. It is actually only implemented on iOS." %}

-----------------------------------

## The sample rate

The sample rate is the number of sampling per second (in Hertz). You can specify what you want : 
- 1600 Hz for example is a low sample rate
- 4100 Hz is very often used because it is the sampling done for Audio CD
- 4800 Hz if considered as plain Hifi and is often used because of the quality

----------------------------------

## The number of channels

The number of channels can be anything between 1 and 9.
- 1 : the record is monophony
- 2 : the record is stereophony
- greater than 2 : this is proably not used very often

---------------------------------

## Interleaving

When you want to play data from a stream, or when you want to record something to a stream, you can specify the interleaving state. See [this guide](fs-guides_live_streams.html) for Dart Streams support.
- When the data are interleaved, the samples are given for each channel in a row (ch0, ch1, ch0, ch1, ch0, ch1, ...).
- When the data are not interleaved (Plan Mode), the samples are given separately for each channel (ch0, ch0, ch0, ...)(ch1, ch1, ch1, ...).

{% include note.html content="Files and buffers are always interleaved. The non interleaved state is only for `Record To Strean` and `Play from Stream`." %}

--------------------------------

## Computing the Record duration

It is very easy to compute the duration of a record. Just devide the length of the record (without the header if any) by the number of channels, the sample rate and the size of each sample.
- ``` t = length / (channelCount * sampleRate * 2)``` for the two PCM16 Codecs
- ``` t = length / (channelCount * sampleRate * 4)``` for the two PCMFloat32 Codecs

------------------------------

## Current Limitations
Note the following limitations in the current Flutter Sound version :

- FlutterSoundHelper `duration()` does not work with Raw PCM file
- `startPlayer()` does not return the record duration of a PCM file.
- On iOS : codec==Codec.pcm16WAV  --  startRecorder()  --  The frames are not correctely coded with int16 but float32.
- On iOS : codec==Codec.pcm32WAV  --  The peak level is not computed correctly
- On iOS : Codec.pcmINT16 -- Works only with interleaved state = true
- The two Float32 codecs does not work on Web and Android
- Non interleaving state does not work on Web and Android

These limitations will be removed very soon. I Promise.
