---
title:  "Raw PCM and Wave files"
description: "Raw PCM and Wave files."
summary: "Raw PCM and Wave files."
permalink: guides_pcm_wave.html
tags: [guide]
keywords: guides
---
---------

## Raw PCM and Wave files

Raw PCM is not an audio format. Raw PCM files store the raw data **without** any envelope. A simple way for playing a Raw PCM file, is to add a `Wave` header in front of the data before playing it. To do that, the helper verb `pcmToWave()` is convenient. You can also call directely the `startPlayer()` verb. If you do that, do not forget to provide the `sampleRate` and `numChannels` parameters.

A Wave file is just PCM data in a specific file format.

The Wave audio file format has a terrible drawback : it cannot be streamed. The Wave file is considered not valid, until it is closed. During the construction of the Wave file, it is considered as corrupted because the Wave header is still not written.

Note the following limitations in the current Flutter Sound version :

* The stream is  `PCM-Integer Linear 16` with just one channel. Actually, Flutter Sound does not manipulate Raw PCM with floating point PCM data nor with more than one audio channel.
* `FlutterSoundHelper duration()` does not work with Raw PCM file
* `startPlayer()` does not return the record duration.
* `withUI` parameter in `openAudioSession()` is actually incompatible with Raw PCM files.

