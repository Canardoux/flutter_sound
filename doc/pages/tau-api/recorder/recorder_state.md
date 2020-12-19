---
title:  "Recorder API"
description: "`recorderState`, `isRecording`, `isPaused`, `isStopped`."
summary: "`recorderState`, `isRecording`, `isPaused`, `isStopped`."
permalink: tau_api_recorder_recorder_state.html
tags: [API, recorder]
keywords: API Recorder
---
# The &tau; Recorder API

---------------------------------------------------------------------------------------------------------------------------------

## `recorderState`, `isRecording`, `isPaused`, `isStopped`

-[Dart API: isRecording](https://canardoux.github.io/tau/doc/flutter_sound/api/recorder/FlutterSoundRecorder/isRecording.html)
-[Dart API: isStopped](https://canardoux.github.io/tau/doc/flutter_sound/api/recorder/FlutterSoundRecorder/isStopped.html)
-[Dart API: isPaused](https://canardoux.github.io/tau/doc/flutter_sound/api/recorder/FlutterSoundRecorder/isPaused.html)
-[Dart API: recorderState](https://canardoux.github.io/tau/doc/flutter_sound/api/recorder/FlutterSoundRecorder/RecorderState.html)

This four verbs is used when the app wants to get the current Audio State of the recorder.

`recorderState` is an attribut which can have the following values :

  - isStopped   /// Recorder is stopped
  - isRecording   /// Recorder is recording
  - isPaused    /// Recorder is paused

- isRecording is a boolean attribut which is `true` when the recorder is in the "Recording" mode.
- isPaused is a boolean atrribut which  is `true` when the recorder is in the "Paused" mode.
- isStopped is a boolean atrribut which  is `true` when the recorder is in the "Stopped" mode.

*Example:*
```dart
        swtich(myRecorder.recorderState)
        {
                case RecorderState.isRecording: doSomething; break;
                case RecorderState.isStopped: doSomething; break;
                case RecorderState.isPaused: doSomething; break;
        }
        ...
        if (myRecorder.isStopped) doSomething;
        if (myRecorder.isRecording) doSomething;
        if (myRecorder.isPaused) doSomething;

```

---------------------------------------------------------------------------------------------------------------------------------
