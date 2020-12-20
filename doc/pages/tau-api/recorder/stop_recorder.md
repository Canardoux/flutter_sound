---
title:  "Recorder API"
description: "stopRecorder()"
summary: "stopRecorder()"
permalink: tau_api_recorder_stop_recorder.html
tags: [API, recorder]
keywords: API Recorder
---
# The &tau; Recorder API
----------------------------------------------------------------------------------------------------------------------

## `stopRecorder()`

- Dart API: [stopRecorder](pages/flutter-sound/api/recorder/FlutterSoundRecorder/stopRecorder.html)

Use this verb to stop a record. This verb never throws any exception. It is safe to call it everywhere,
for example when the App is not sure of the current Audio State and want to recover a clean reset state.

*Example:*
<ul id="profileTabs" class="nav nav-tabs">
    <li class="active"><a href="#dart" data-toggle="tab">Dart</a></li>
    <li><a href="#javascript" data-toggle="tab">Javascript</a></li>
</ul>
<div class="tab-content">

<div role="tabpanel" class="tab-pane active" id="dart">

<pre>
        await myRecorder.stopRecorder();
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
