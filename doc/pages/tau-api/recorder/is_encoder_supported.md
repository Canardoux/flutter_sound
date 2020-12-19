---
title:  "Recorder API"
description: "isEncoderSupported()"
summary: "isEncoderSupported()"
permalink: tau_api_recorder_is_encoder_supported.html
tags: [API, recorder]
keywords: API Recorder
---
# The &tau; Recorder API

---------------------------------------------------------------------------------------------------------------------------------

## `isEncoderSupported()`

[Dart API](https://canardoux.github.io/tau/doc/flutter_sound/api/recorder/FlutterSoundRecorder/isEncoderSupported.html)

This verb is useful to know if a particular codec is supported on the current platform;
Return a Future<bool>.

*Example:*
```dart
        if ( await myRecorder.isEncoderSupported(Codec.opusOGG) ) doSomething;
```

---------------------------------------------------------------------------------------------------------------------------------
