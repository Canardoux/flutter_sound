---
title:  "Utilities API"
description: "waveToPCM()"
summary: "waveToPCM()"
permalink: tau_api_utilities_wave_to_pcm.html
tags: [api,utilities,helpers]
keywords: API, utilities, helpers
---

# Flutter Sound Helpers API

------------------------------------------------------------------------------------------------------------------------

## `waveToPCM()`

- Dart API: [waveToPCM()](pages/flutter-sound/api/helper/FlutterSoundHelper/waveToPCM.html)

This verb is usefull to convert a Wave file to a Raw PCM file.

It removes the `Wave` envelop from the PCM file.

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
        await flutterSoundHelper.waveToPCM(inputFile: inputFile, outpoutFile: outputFile);
</pre>

</div>

<div role="tabpanel" class="tab-pane" id="javascript">
<pre>
        Lorem ipsum ...
</pre>
</div>

</div>

------------------------------------------------------------------------------------------------------------------------
