---
title:  "Utilities API"
description: "isFFmpegAvailable()"
summary: "isFFmpegAvailable()"
permalink: tau_api_utilities_is_ffmpeg_available.html
tags: [API, utilities, helpers]
keywords: API, utilities, helpers
---

# Flutter Sound Helpers API

----------------------------------------------------------------------------------------------------------------------------

## `isFFmpegAvailable()`

*Dart definition (prototype) :*
```
Future<bool> isFFmpegAvailable() async
```

This verb is used to know during runtime if FFmpeg is linked with the App.

*Example:*
```dart
        if ( await flutterSoundHelper.isFFmpegAvailable() )
        {
                Duration d = flutterSoundHelper.duration("$myFilePath/bar.wav");
        }
```

---------------------------------------------------------------------------------------------------------------------------
