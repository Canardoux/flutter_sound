---
title:  "Utilities API"
description: "waveToPCMBuffer()"
summary: "waveToPCMBuffer()"
permalink: tau_api_utilities_wave_to_pcm_buffer.html
tags: [API, utilities, helpers]
keywords: API, utilities, helpers
---

# Flutter Sound Helpers API

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
