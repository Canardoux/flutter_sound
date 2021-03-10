---
title:  "Utilities API"
description: "The &tau; utilities API."
summary: "The &tau; Project offers several helper utilities."
permalink: tau_api_utilities
tags: [api,utilities,helpers]
keywords: API, utilities, helpers
---

# Flutter Sound Helpers API

-----------------------------------------------------------------------------------------------------------------------

## Module `instanciation`

*Dart definition (prototype) :*
```
FlutterSoundHelper flutterSoundHelper = FlutterSoundHelper(); // Singleton
```

You do not need to instanciate the Flutter Sound Helper module.
To use this module, you can just use the singleton offers by the module : `flutterSoundHelper`.

*Example:*
```dart
Duration t = await flutterSoundHelper.duration(aPathFile);
```

------------------------------------------------------------------------------------------------------------------------

## `convertFile()`

*Dart definition (prototype) :*
```
Future<bool> convertFile
(
        String infile,
        Codec codecin,
        String outfile,
        Codec codecout
) async
```

This verb is useful to convert a sound file to a new format.

- `infile` is the file path of the file you want to convert
- `codecin` is the actual file format
- `outfile` is the path of the file you want to create
- `codecout` is the new file format

Be careful : `outfile` and `codecout` must be compatible. The output file extension must be a correct file extension for the new format.

Note : this verb uses FFmpeg and is not available int the LITE flavor of Flutter Sound.

*Example:*
```dart
        String inputFile = '$myInputPath/bar.wav';
        var tempDir = await getTemporaryDirectory();
        String outpufFile = '${tempDir.path}/$foo.mp3';
        await flutterSoundHelper.convertFile(inputFile, codec.pcm16WAV, outputFile, Codec.mp3)
```

------------------------------------------------------------------------------------------------------------------------

## `pcmToWave()`

*Dart definition (prototype) :*
```
Future<void> pcmToWave
(
      {
          String inputFile,
          String outputFile,
          int numChannels,
          int sampleRate,
      }
) async
```

This verb is usefull to convert a Raw PCM file to a Wave file.

It adds a `Wave` envelop to the PCM file, so that the file can be played back with `startPlayer()`.

Note: the parameters `numChannels` and `sampleRate` **are mandatory, and must match the actual PCM data**. [See here](codec.md#note-on-raw-pcm-and-wave-files) a discussion about `Raw PCM` and `WAVE` file format.

*Example:*
```dart
        String inputFile = '$myInputPath/bar.pcm';
        var tempDir = await getTemporaryDirectory();
        String outpufFile = '${tempDir.path}/$foo.wav';
        await flutterSoundHelper.pcmToWave(inputFile: inputFile, outpoutFile: outputFile, numChannels: 1, sampleRate: 8000);
```

------------------------------------------------------------------------------------------------------------------------

## `pcmToWaveBuffer()`

*Dart definition (prototype) :*
```
Future<Uint8List> pcmToWaveBuffer
(
      {
        Uint8List inputBuffer,
        int numChannels,
        int sampleRate,
      }
) async

```

This verb is usefull to convert a Raw PCM buffer to a Wave buffer.

It adds a `Wave` envelop in front of the PCM buffer, so that the file can be played back with `startPlayerFromBuffer()`.

Note: the parameters `numChannels` and `sampleRate` **are mandatory, and must match the actual PCM data**. [See here](codec.md#note-on-raw-pcm-and-wave-files) a discussion about `Raw PCM` and `WAVE` file format.

*Example:*
```dart
        Uint8List myWavBuffer = await flutterSoundHelper.pcmToWaveBuffer(inputBuffer: myPCMBuffer, numChannels: 1, sampleRate: 8000);
```

------------------------------------------------------------------------------------------------------------------------

## `waveToPCM()`

*Dart definition (prototype) :*
```
Future<void> waveToPCM
(
      {
          String inputFile,
          String outputFile,
       }
) async
```

This verb is usefull to convert a Wave file to a Raw PCM file.

It removes the `Wave` envelop from the PCM file.

*Example:*
```dart
        String inputFile = '$myInputPath/bar.pcm';
        var tempDir = await getTemporaryDirectory();
        String outpufFile = '${tempDir.path}/$foo.wav';
        await flutterSoundHelper.waveToPCM(inputFile: inputFile, outpoutFile: outputFile);
```

------------------------------------------------------------------------------------------------------------------------

## `waveToPCMBuffer()`

*Dart definition (prototype) :*
```
Uint8List waveToPCMBuffer (Uint8List inputBuffer)
```

This verb is usefull to convert a Wave buffer to a Raw PCM buffer.
Note that this verb is not asynchronous and does not return a Future.

It removes the `Wave` envelop from the PCM buffer.

*Example:*
```dart
        Uint8List pcmBuffer flutterSoundHelper.waveToPCMBuffer(inputBuffer: aWaveBuffer);
```

----------------------------------------------------------------------------------------------------------------------------

## `duration()`

*Dart definition (prototype) :*
```
 Future<Duration> duration(String uri) async
```

This verb is used to get an estimation of the duration of a sound file.
Be aware that it is just an estimation, based on the Codec used and the sample rate.

Note : this verb uses FFmpeg and is not available int the LITE flavor of Flutter Sound.

*Example:*
```dart
        Duration d = flutterSoundHelper.duration("$myFilePath/bar.wav");
```

----------------------------------------------------------------------------------------------------------------------------

## `isFFmpegAvailable()`

*Dart definition (prototype) :*
```
Future<bool> isFFmpegAvailable() async
```

This verb is used to know during runtime if FFmpeg is linked with the App.

*Example:*
```dart
        if ( await flutterSoundHelper.isFFmpegAvailable() )
        {
                Duration d = flutterSoundHelper.duration("$myFilePath/bar.wav");
        }
```

---------------------------------------------------------------------------------------------------------------------------

## `executeFFmpegWithArguments()`

*Dart definition (prototype) :*
```
Future<int> executeFFmpegWithArguments(List<String> arguments)
```

This verb is a wrapper for the great FFmpeg application.
The command *"man ffmpeg"* (if you have installed ffmpeg on your computer) will give you many informations.
If you do not have `ffmpeg` on your computer you will find easyly on internet many documentation on this great program.

*Example:*
```dart
 int rc = await flutterSoundHelper.executeFFmpegWithArguments
 ([
        '-loglevel',
        'error',
        '-y',
        '-i',
        infile,
        '-c:a',
        'copy',
        outfile,
]); // remux OGG to CAF
```

---------------------------------------------------------------------------------------------------------------------------

## `getLastFFmpegReturnCode()`

*Dart definition (prototype) :*
```
Future<int> getLastFFmpegReturnCode() async
```

This simple verb is used to get the result of the last FFmpeg command

*Example:*
```dart
        int result = await getLastFFmpegReturnCode();
```

---------------------------------------------------------------------------------------------------------------------------

## `getLastFFmpegCommandOutput()`

*Dart definition (prototype) :*
```
Future<String> getLastFFmpegCommandOutput() async
```

This simple verb is used to get the output of the last FFmpeg command

*Example:*
```dart
        print( await getLastFFmpegCommandOutput() );
```

---------------------------------------------------------------------------------------------------------------------------

## `FFmpegGetMediaInformation`

*Dart definition (prototype) :*
```
Future<Map<dynamic, dynamic>> FFmpegGetMediaInformation(String uri) async
```

This verb is used to get various informations on a file.

The informations got with FFmpegGetMediaInformation() are [documented here](https://pub.dev/packages/flutter_ffmpeg).

*Example:*
```dart
Map<dynamic, dynamic> info = await flutterSoundHelper.FFmpegGetMediaInformation( uri );
```
