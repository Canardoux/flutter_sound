---
title:  "Utilities API"
description: "FFmpegGetMediaInformation()"
summary: "FFmpegGetMediaInformation()"
permalink: tau_api_utilities_ffmpeg_get_media_information.html
tags: [API, utilities, helpers]
keywords: API, utilities, helpers
---

# Flutter Sound Helpers API

---------------------------------------------------------------------------------------------------------------------------

## `FFmpegGetMediaInformation()`

*Dart definition (prototype) :*
```
Future<Map<dynamic, dynamic>> FFmpegGetMediaInformation(String uri) async
```

This verb is used to get various informations on a file.

The informations got with FFmpegGetMediaInformation() are [documented here](https://pub.dev/packages/flutter_ffmpeg).

*Example:*
```dart
Map<dynamic, dynamic> info = await flutterSoundHelper.FFmpegGetMediaInformation( uri );
```
