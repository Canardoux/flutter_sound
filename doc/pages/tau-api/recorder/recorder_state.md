---
title:  "Recorder API"
description: "`recorderState`, `isRecording`, `isPaused`, `isStopped`."
summary: "`recorderState`, `isRecording`, `isPaused`, `isStopped`."
permalink: tau_api_recorder_recorder_state.html
tags: [api,recorder]
keywords: API Recorder
---
# The &tau; Recorder API

---------------------------------------------------------------------------------------------------------------------------------

## `recorderState`, `isRecording`, `isPaused`, `isStopped`

- Dart API: [recorderState](pages/flutter-sound/api/recorder/FlutterSoundRecorder/recorderState.html)
- Dart API: [isRecording](pages/flutter-sound/api/recorder/FlutterSoundRecorder/isRecording.html)
- Dart API: [isPaused](pages/flutter-sound/api/recorder/FlutterSoundRecorder/isPaused.html)
- Dart API: [isStopped](pages/flutter-sound/api/recorder/FlutterSoundRecorder/isStopped.html)

This four attributs is used when the app wants to get the current Audio State of the recorder.

`recorderState` is an attribut which can have the following values :

  - isStopped   /// Recorder is stopped
  - isRecording   /// Recorder is recording
  - isPaused    /// Recorder is paused

- isRecording is a boolean attribut which is `true` when the recorder is in the "Recording" mode.
- isPaused is a boolean atrribut which  is `true` when the recorder is in the "Paused" mode.
- isStopped is a boolean atrribut which  is `true` when the recorder is in the "Stopped" mode.

*Example:*
<ul id="profileTabs" class="nav nav-tabs">
    <li class="active"><a href="#dart" data-toggle="tab">Dart</a></li>
    <li><a href="#javascript" data-toggle="tab">Javascript</a></li>
</ul>
<div class="tab-content">

<div role="tabpanel" class="tab-pane active" id="dart">

<pre>
        switch(myRecorder.recorderState)
        {
                case RecorderState.isRecording: doSomething; break;
                case RecorderState.isStopped: doSomething; break;
                case RecorderState.isPaused: doSomething; break;
        }
        ...
        if (myRecorder.isStopped) doSomething;
        if (myRecorder.isRecording) doSomething;
        if (myRecorder.isPaused) doSomething;
</pre>

</div>

<div role="tabpanel" class="tab-pane" id="javascript">
<pre>
        Lorem ipsum ...
</pre>
</div>

</div>

---------------------------------------------------------------------------------------------------------------------------------
