---
title:  "Utilities API"
description: "convertFile()"
summary: "convertFile()"
permalink: tau_api_utilities_convert_file.html
tags: [API, utilities, helpers]
keywords: API, utilities, helpers
---

# Flutter Sound Helpers API

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
