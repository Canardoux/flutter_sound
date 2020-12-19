---
title:  "Utilities API"
description: "waveToPCM()"
summary: "waveToPCM()"
permalink: tau_api_utilities_wave_to_pcm.html
tags: [API, utilities, helpers]
keywords: API, utilities, helpers
---

# Flutter Sound Helpers API

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
