---
title:  "Recorder API"
description: "stopRecorder()"
summary: "stopRecorder()"
permalink: tau_api_recorder_stop_recorder.html
tags: [api,recorder]
keywords: API Recorder
---
# The &tau; Recorder API
----------------------------------------------------------------------------------------------------------------------

## `stopRecorder()`

- Dart API: [stopRecorder](pages/flutter-sound/api/recorder/FlutterSoundRecorder/stopRecorder.html)

Use this verb to stop a record.
Return a Future to an URL of the recorded sound.

*Example:*
<ul id="profileTabs" class="nav nav-tabs">
    <li class="active"><a href="#dart" data-toggle="tab">Dart</a></li>
    <li><a href="#javascript" data-toggle="tab">Javascript</a></li>
</ul>
<div class="tab-content">

<div role="tabpanel" class="tab-pane active" id="dart">

<pre>
        String anURL = await myRecorder.stopRecorder();
        if (_recorderSubscription != null)
        {
                _recorderSubscription.cancel();
                _recorderSubscription = null;
        }
</pre>

</div>

<div role="tabpanel" class="tab-pane" id="javascript">
<pre>
        Lorem ipsum ...
</pre>
</div>

</div>

------------------------------------------------------------------------------------------------------------------------
