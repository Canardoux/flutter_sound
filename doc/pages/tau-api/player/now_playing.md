---
title:  "Player API"
description: "nowPlaying()"
summary: "nowPlaying()"
permalink: tau_api_player_now_playing.html
tags: [API, player]
keywords: API Player
---
# The &tau; Player API

---------------------------------------------------------------------------------------------------------------------------------

## `nowPlaying()`

[Dart API: isStopped()](https://canardoux.github.io/tau/doc/flutter_sound/api/player/FlutterSoundPlayer/nowPlaying.html)

This verb is used to set the Lock screen fields without starting a new playback.
The fields 'dataBuffer' and 'trackPath' of the Track parameter are not used.
Please refer to 'startPlayerFromTrack' for the meaning of the others parameters.
Remark `setUIProgressBar()` is implemented only on iOS.

*Example:*
```dart
    Track track = Track( codec: Codec.opusOGG, trackPath: fileUri, trackAuthor: '3 Inches of Blood', trackTitle: 'Axes of Evil', albumArtAsset: albumArt );
    await nowPlaying(Track);
```
