---
title:  "Utilities API"
description: "executeFFmpegWithArguments()"
summary: "executeFFmpegWithArguments()"
permalink: tau_api_utilities_execute_ffmpeg_with_arguments.html
tags: [API, utilities, helpers]
keywords: API, utilities, helpers
---

# Flutter Sound Helpers API

---------------------------------------------------------------------------------------------------------------------------

## `executeFFmpegWithArguments()`

*Dart definition (prototype) :*
```
Future<int> executeFFmpegWithArguments(List<String> arguments)
```

This verb is a wrapper for the great FFmpeg application.
The command *"man ffmpeg"* (if you have installed ffmpeg on your computer) will give you many informations.
If you do not have `ffmpeg` on your computer you will find easyly on internet many documentation on this great program.

*Example:*
```dart
 int rc = await flutterSoundHelper.executeFFmpegWithArguments
 ([
        '-loglevel',
        'error',
        '-y',
        '-i',
        infile,
        '-c:a',
        'copy',
        outfile,
]); // remux OGG to CAF
```

---------------------------------------------------------------------------------------------------------------------------
