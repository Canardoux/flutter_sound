---
title:  "Guides"
description: "Recording PCM."
summary: "Recording PCM."
permalink: guides_recording_pcm.html
tags: [guide]
keywords: guides
---

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

