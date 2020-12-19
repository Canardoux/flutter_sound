---
title:  "Recorder API"
description: "StopRecorder()"
summary: "StopRecorder()"
permalink: tau_api_recorder_stop_recorder.html
tags: [API, recorder]
keywords: API Recorder
---
# The &tau; Recorder API
----------------------------------------------------------------------------------------------------------------------

## `StopRecorder()`

[Dart API](https://canardoux.github.io/tau/doc/flutter_sound/api/recorder/FlutterSoundRecorder/StopRecorder.html)

Use this verb to stop a record. This verb never throws any exception. It is safe to call it everywhere,
for example when the App is not sure of the current Audio State and want to recover a clean reset state.

*Example:*
```dart
        await myRecorder.stopRecorder();
        if (_recorderSubscription != null)
        {
                _recorderSubscription.cancel();
                _recorderSubscription = null;
        }
}
```

------------------------------------------------------------------------------------------------------------------------
