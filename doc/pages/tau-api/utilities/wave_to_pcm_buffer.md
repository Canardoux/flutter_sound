---
title:  "Utilities API"
description: "waveToPCMBuffer()"
summary: "waveToPCMBuffer()"
permalink: tau_api_utilities_wave_to_pcm_buffer.html
tags: [api,utilities,helpers]
keywords: API, utilities, helpers
---

# Flutter Sound Helpers API

------------------------------------------------------------------------------------------------------------------------

## `waveToPCMBuffer()`

- Dart API: [waveToPCMBuffer()](pages/flutter-sound/api/helper/FlutterSoundHelper/waveToPCMBuffer.html)

This verb is usefull to convert a Wave buffer to a Raw PCM buffer.
Note that this verb is not asynchronous and does not return a Future.

It removes the `Wave` envelop from the PCM buffer.

*Example:*
<ul id="profileTabs" class="nav nav-tabs">
    <li class="active"><a href="#dart" data-toggle="tab">Dart</a></li>
    <li><a href="#javascript" data-toggle="tab">Javascript</a></li>
</ul>
<div class="tab-content">

<div role="tabpanel" class="tab-pane active" id="dart">

<pre>
        Uint8List pcmBuffer flutterSoundHelper.waveToPCMBuffer(inputBuffer: aWaveBuffer);
</pre>

</div>

<div role="tabpanel" class="tab-pane" id="javascript">
<pre>
        Lorem ipsum ...
</pre>
</div>

</div>

----------------------------------------------------------------------------------------------------------------------------
