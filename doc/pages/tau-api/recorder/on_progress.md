---
title:  "Recorder API"
description: "onProgress"
summary: "onProgress"
permalink: tau_api_recorder_on_progress.html
tags: [api,recorder]
keywords: API Recorder
---
# The &tau; Recorder API

---------------------------------------------------------------------------------------------------------------------------------

## `onProgress`

- Dart API: [onProgress](pages/flutter-sound/api/recorder/FlutterSoundRecorder/onProgress.html)

The attribut `onProgress` is a stream on which FlutterSound will post the recorder progression.
You may listen to this Stream to have feedback on the current recording.

*Example:*
<ul id="profileTabs" class="nav nav-tabs">
    <li class="active"><a href="#dart" data-toggle="tab">Dart</a></li>
    <li><a href="#javascript" data-toggle="tab">Javascript</a></li>
</ul>
<div class="tab-content">

<div role="tabpanel" class="tab-pane active" id="dart">

<pre>
        _recorderSubscription = myrecorder.onProgress.listen((e)
        {
                Duration maxDuration = e.duration;
                double decibels = e.decibels
                ...
        }
</pre>

</div>

<div role="tabpanel" class="tab-pane" id="javascript">
<pre>
        Lorem ipsum ...
</pre>
</div>

</div>

---------------------------------------------------------------------------------------------------------------------------------
