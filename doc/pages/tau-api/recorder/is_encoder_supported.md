---
title:  "Recorder API"
description: "isEncoderSupported()"
summary: "isEncoderSupported()"
permalink: tau_api_recorder_is_encoder_supported.html
tags: [api,recorder]
keywords: API Recorder
---
# The &tau; Recorder API

---------------------------------------------------------------------------------------------------------------------------------

## `isEncoderSupported()`

- Dart API: [isEncoderSupported](pages/flutter-sound/api/recorder/FlutterSoundRecorder/isEncoderSupported.html)

This verb is useful to know if a particular codec is supported on the current platform;
Return a Future<bool>.

*Example:*
<ul id="profileTabs" class="nav nav-tabs">
    <li class="active"><a href="#dart" data-toggle="tab">Dart</a></li>
    <li><a href="#javascript" data-toggle="tab">Javascript</a></li>
</ul>
<div class="tab-content">

<div role="tabpanel" class="tab-pane active" id="dart">

<pre>
       if ( await myRecorder.isEncoderSupported(Codec.opusOGG) ) doSomething;
</pre>

</div>

<div role="tabpanel" class="tab-pane" id="javascript">
<pre>
        Lorem ipsum ...
</pre>
</div>

</div>

---------------------------------------------------------------------------------------------------------------------------------
