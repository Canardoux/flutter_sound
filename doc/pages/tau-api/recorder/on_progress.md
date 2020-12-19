---
title:  "Recorder API"
description: "onProgress"
summary: "onProgress"
permalink: tau_api_recorder_on_progress.html
tags: [API, recorder]
keywords: API Recorder
---
# The &tau; Recorder API

---------------------------------------------------------------------------------------------------------------------------------

## `onProgress`

[Dart API](https://canardoux.github.io/tau/doc/flutter_sound/api/recorder/FlutterSoundRecorder/onProgress.html)

The attribut `onProgress` is a stream on which FlutterSound will post the recorder progression.
You may listen to this Stream to have feedback on the current recording.

*Example:*
```dart
        _recorderSubscription = myrecorder.onProgress.listen((e)
        {
                Duration maxDuration = e.duration;
                double decibels = e.decibels
                ...
        }
```

---------------------------------------------------------------------------------------------------------------------------------
