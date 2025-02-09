---
title:  "Utilities API"
description: "pcmToWaveBuffer()"
summary: "pcmToWaveBuffer()"
permalink: tau_api_utilities_pcm_to_wave_buffer.html
tags: [api,utilities,helpers]
keywords: API, utilities, helpers
---

# Flutter Sound Helpers API

------------------------------------------------------------------------------------------------------------------------

## `pcmToWaveBuffer()`

- Dart API: [pcmToWaveBuffer()](pages/flutter-sound/api/helper/FlutterSoundHelper/pcmToWaveBuffer.html)

This verb is usefull to convert a Raw PCM buffer to a Wave buffer.

It adds a `Wave` envelop in front of the PCM buffer, so that the file can be played back with `startPlayerFromBuffer()`.

Note: the parameters `numChannels` and `sampleRate` **are mandatory, and must match the actual PCM data**. [See here](codec.md#note-on-raw-pcm-and-wave-files) a discussion about `Raw PCM` and `WAVE` file format.

*Example:*
<ul id="profileTabs" class="nav nav-tabs">
    <li class="active"><a href="#dart" data-toggle="tab">Dart</a></li>
    <li><a href="#javascript" data-toggle="tab">Javascript</a></li>
</ul>
<div class="tab-content">

<div role="tabpanel" class="tab-pane active" id="dart">

<pre>
        Uint8List myWavBuffer = await flutterSoundHelper.pcmToWaveBuffer(inputBuffer: myPCMBuffer, numChannels: 1, sampleRate: 8000);
</pre>

</div>

<div role="tabpanel" class="tab-pane" id="javascript">
<pre>
        Lorem ipsum ...
</pre>
</div>

</div>

------------------------------------------------------------------------------------------------------------------------
