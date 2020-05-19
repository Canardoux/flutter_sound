[Back to the README](../README.md#flutter-sound-api)

-----------------------------------------------------------------------------------------------------------------------

# Flutter Sound Helper API

Flutter Sound offers some tools that can be convenient to work with sound :

- [Module instanciation](#module-instanciation)
- [convertFile()](#convertfile) to convert an audio file to another format
- [duration()](#duration) to know the appoximate duration of a sound
- [isFFmpegAvailable()](#isffmpegavailable) to know if the current App is linked with FFmpeg
- [executeFFmpegWithArguments()](#executeffmpegwitharguments) to execute an FFmpeg command
- [getLastFFmpegReturnCode()](#getlastffmpegreturncode) to get the return code of an FFmpeg command
- [getLastFFmpegCommandOutput()](#getlastffmpegcommandoutput) to get ouput of the last FFmpeg command
- [FFmpegGetMediaInformation()](#ffmpeggetmediainformation--informations-on-a-record) to get various informations on a sound file

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

-------------------------------------------------------------------------------------------------------------------------------

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
]); // remux OGG to CAF```
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

## `FFmpegGetMediaInformation` : Informations on a record

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

-----------------------------------------------------------------------------------------------------------------------

[Back to the README](../README.md#flutter-sound-api)
