---
title:  "Utilities API"
description: "pcmToWave()"
summary: "pcmToWave()"
permalink: tau_api_utilities_pcm_to_wave.html
tags: [api,utilities,helpers]
keywords: API, utilities, helpers
---

# Flutter Sound Helpers API

------------------------------------------------------------------------------------------------------------------------

## `pcmToWave()`

- Dart API: [pcmToWave()](pages/flutter-sound/api/helper/FlutterSoundHelper/pcmToWave.html)

This verb is usefull to convert a Raw PCM file to a Wave file.

It adds a `Wave` envelop to the PCM file, so that the file can be played back with `startPlayer()`.

Note: the parameters `numChannels` and `sampleRate` **are mandatory, and must match the actual PCM data**. [See here](codec.md#note-on-raw-pcm-and-wave-files) a discussion about `Raw PCM` and `WAVE` file format.

*Example:*
<ul id="profileTabs" class="nav nav-tabs">
    <li class="active"><a href="#dart" data-toggle="tab">Dart</a></li>
    <li><a href="#javascript" data-toggle="tab">Javascript</a></li>
</ul>
<div class="tab-content">

<div role="tabpanel" class="tab-pane active" id="dart">

<pre>
        String inputFile = '$myInputPath/bar.pcm';
        var tempDir = await getTemporaryDirectory();
        String outpufFile = '${tempDir.path}/$foo.wav';
        await flutterSoundHelper.pcmToWave(inputFile: inputFile, outpoutFile: outputFile, numChannels: 1, sampleRate: 8000);
</pre>

</div>

<div role="tabpanel" class="tab-pane" id="javascript">
<pre>
        Lorem ipsum ...
</pre>
</div>

</div>

------------------------------------------------------------------------------------------------------------------------
