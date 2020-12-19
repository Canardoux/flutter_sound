---
title:  "Player API"
description: "getProgress()"
summary: "getProgress()"
permalink: tau_api_player_get_progress.html
tags: [API, player]
keywords: API Player
---
# The &tau; Player API

---------------------------------------------------------------------------------------------------------------------------------

## `getProgress()`

[Dart API: isStopped()](https://canardoux.github.io/tau/doc/flutter_sound/api/player/FlutterSoundPlayer/getProgress.html)

This verb is used to get the current progress of a playback.
It returns a `Map` with two Duration entries : `'progress'` and `'duration'`.
Remark : actually only implemented on iOS.

*Example:*
```dart
        Duration progress = (await getProgress())['progress'];
        Duration duration = (await getProgress())['duration'];
```

---------------------------------------------------------------------------------------------------------------------------------

