---
title:  "Utilities API"
description: "pcmToWaveBuffer()"
summary: "pcmToWaveBuffer()"
permalink: tau_api_utilities_pcm_to_wave_buffer.html
tags: [API, utilities, helpers]
keywords: API, utilities, helpers
---

# Flutter Sound Helpers API

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
