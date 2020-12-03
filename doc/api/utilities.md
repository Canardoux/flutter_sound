# The utilities

Flutter Sound offers some tools that can be convenient to work with sound :

* [Module instanciation](utilities.md#module-instanciation)
* [convertFile\(\)](utilities.md#convertfile) to convert an audio file to another format
* [pcmToWave\(\)](utilities.md#pcmtowave)  to add a WAVE header in front of a Raw PCM record
* [pcmToWaveBuffer\(\)](utilities.md#pcmtowavebuffer)  to add a WAVE header in front of a Raw PCM buffer
* [waveToPCM\(\)](utilities.md#wavetopcm)  to remove a WAVE header in front of a Wave record
* [waveToPCMBuffer\(\)](utilities.md#wavetopcmbuffer)  to remove a WAVE header in front of a Wave buffer
* [duration\(\)](utilities.md#duration) to know the appoximate duration of a sound
* [isFFmpegAvailable\(\)](utilities.md#isffmpegavailable) to know if the current App is linked with FFmpeg
* [executeFFmpegWithArguments\(\)](utilities.md#executeffmpegwitharguments) to execute an FFmpeg command
* [getLastFFmpegReturnCode\(\)](utilities.md#getlastffmpegreturncode) to get the return code of an FFmpeg command
* [getLastFFmpegCommandOutput\(\)](utilities.md#getlastffmpegcommandoutput) to get ouput of the last FFmpeg command
* [FFmpegGetMediaInformation\(\)](utilities.md#ffmpeggetmediainformation--informations-on-a-record) to get various informations on a sound file

## Module `instanciation`

_Dart definition \(prototype\) :_

```text
FlutterSoundHelper flutterSoundHelper = FlutterSoundHelper(); // Singleton
```

You do not need to instanciate the Flutter Sound Helper module. To use this module, you can just use the singleton offers by the module : `flutterSoundHelper`.

_Example:_

```dart
Duration t = await flutterSoundHelper.duration(aPathFile);
```

## `convertFile()`

_Dart definition \(prototype\) :_

```text
Future<bool> convertFile
(
        String infile,
        Codec codecin,
        String outfile,
        Codec codecout
) async
```

This verb is useful to convert a sound file to a new format.

* `infile` is the file path of the file you want to convert
* `codecin` is the actual file format
* `outfile` is the path of the file you want to create
* `codecout` is the new file format

Be careful : `outfile` and `codecout` must be compatible. The output file extension must be a correct file extension for the new format.

Note : this verb uses FFmpeg and is not available int the LITE flavor of Flutter Sound.

_Example:_

```dart
        String inputFile = '$myInputPath/bar.wav';
        var tempDir = await getTemporaryDirectory();
        String outpufFile = '${tempDir.path}/$foo.mp3';
        await flutterSoundHelper.convertFile(inputFile, codec.pcm16WAV, outputFile, Codec.mp3)
```

## `pcmToWave()`

_Dart definition \(prototype\) :_

```text
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

Note: the parameters `numChannels` and `sampleRate` **are mandatory, and must match the actual PCM data**. [See here](https://github.com/Canardoux/tau/tree/bb6acacc34205174a8438a13c8c0797f7bfa2143/doc/api/codec.md#note-on-raw-pcm-and-wave-files) a discussion about `Raw PCM` and `WAVE` file format.

_Example:_

```dart
        String inputFile = '$myInputPath/bar.pcm';
        var tempDir = await getTemporaryDirectory();
        String outpufFile = '${tempDir.path}/$foo.wav';
        await flutterSoundHelper.pcmToWave(inputFile: inputFile, outpoutFile: outputFile, numChannels: 1, sampleRate: 8000);
```

## `pcmToWaveBuffer()`

_Dart definition \(prototype\) :_

```text
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

Note: the parameters `numChannels` and `sampleRate` **are mandatory, and must match the actual PCM data**. [See here](https://github.com/Canardoux/tau/tree/bb6acacc34205174a8438a13c8c0797f7bfa2143/doc/api/codec.md#note-on-raw-pcm-and-wave-files) a discussion about `Raw PCM` and `WAVE` file format.

_Example:_

```dart
        Uint8List myWavBuffer = await flutterSoundHelper.pcmToWaveBuffer(inputBuffer: myPCMBuffer, numChannels: 1, sampleRate: 8000);
```

## `waveToPCM()`

_Dart definition \(prototype\) :_

```text
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

_Example:_

```dart
        String inputFile = '$myInputPath/bar.pcm';
        var tempDir = await getTemporaryDirectory();
        String outpufFile = '${tempDir.path}/$foo.wav';
        await flutterSoundHelper.waveToPCM(inputFile: inputFile, outpoutFile: outputFile);
```

## `waveToPCMBuffer()`

_Dart definition \(prototype\) :_

```text
Uint8List waveToPCMBuffer (Uint8List inputBuffer)
```

This verb is usefull to convert a Wave buffer to a Raw PCM buffer. Note that this verb is not asynchronous and does not return a Future.

It removes the `Wave` envelop from the PCM buffer.

_Example:_

```dart
        Uint8List pcmBuffer flutterSoundHelper.waveToPCMBuffer(inputBuffer: aWaveBuffer);
```

## `duration()`

_Dart definition \(prototype\) :_

```text
 Future<Duration> duration(String uri) async
```

This verb is used to get an estimation of the duration of a sound file. Be aware that it is just an estimation, based on the Codec used and the sample rate.

Note : this verb uses FFmpeg and is not available int the LITE flavor of Flutter Sound.

_Example:_

```dart
        Duration d = flutterSoundHelper.duration("$myFilePath/bar.wav");
```

## `isFFmpegAvailable()`

_Dart definition \(prototype\) :_

```text
Future<bool> isFFmpegAvailable() async
```

This verb is used to know during runtime if FFmpeg is linked with the App.

_Example:_

```dart
        if ( await flutterSoundHelper.isFFmpegAvailable() )
        {
                Duration d = flutterSoundHelper.duration("$myFilePath/bar.wav");
        }
```

## `executeFFmpegWithArguments()`

_Dart definition \(prototype\) :_

```text
Future<int> executeFFmpegWithArguments(List<String> arguments)
```

This verb is a wrapper for the great FFmpeg application. The command _"man ffmpeg"_ \(if you have installed ffmpeg on your computer\) will give you many informations. If you do not have `ffmpeg` on your computer you will find easyly on internet many documentation on this great program.

_Example:_

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

## `getLastFFmpegReturnCode()`

_Dart definition \(prototype\) :_

```text
Future<int> getLastFFmpegReturnCode() async
```

This simple verb is used to get the result of the last FFmpeg command

_Example:_

```dart
        int result = await getLastFFmpegReturnCode();
```

## `getLastFFmpegCommandOutput()`

_Dart definition \(prototype\) :_

```text
Future<String> getLastFFmpegCommandOutput() async
```

This simple verb is used to get the output of the last FFmpeg command

_Example:_

```dart
        print( await getLastFFmpegCommandOutput() );
```

## `FFmpegGetMediaInformation` : Informations on a record

_Dart definition \(prototype\) :_

```text
Future<Map<dynamic, dynamic>> FFmpegGetMediaInformation(String uri) async
```

This verb is used to get various informations on a file.

The informations got with FFmpegGetMediaInformation\(\) are [documented here](https://pub.dev/packages/flutter_ffmpeg).

_Example:_

```dart
Map<dynamic, dynamic> info = await flutterSoundHelper.FFmpegGetMediaInformation( uri );
```

