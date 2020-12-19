---
title:  "Utilities API"
description: "duration()"
summary: "duration()"
permalink: tau_api_utilities_duration.html
tags: [API, utilities, helpers]
keywords: API, utilities, helpers
---

# Flutter Sound Helpers API

----------------------------------------------------------------------------------------------------------------------------

## `duration()`

*Dart definition (prototype) :*
```
 Future<Duration> duration(String uri) async
```

This verb is used to get an estimation of the duration of a sound file.
Be aware that it is just an estimation, based on the Codec used and the sample rate.

Note : this verb uses FFmpeg and is not available int the LITE flavor of Flutter Sound.

*Example:*
```dart
        Duration d = flutterSoundHelper.duration("$myFilePath/bar.wav");
```

----------------------------------------------------------------------------------------------------------------------------
