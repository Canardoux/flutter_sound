---
title:  "Player API"
description: "isDecoderSupported()"
summary: "isDecoderSupported()"
permalink: tau_api_player_is_decoder_supported.html
tags: [API, player]
keywords: API Player
---
# The &tau; Player API

---------------------------------------------------------------------------------------------------------------------------------

## `isDecoderSupported()`


[Dart API: isStopped()](https://canardoux.github.io/tau/doc/flutter_sound/api/player/FlutterSoundPlayer/isDecoderSupported.html)

This verb is useful to know if a particular codec is supported on the current platform.
Returns a Future<bool>.

*Example:*
```dart
        if ( await myPlayer.isDecoderSupported(Codec.opusOGG) ) doSomething;
```

---------------------------------------------------------------------------------------------------------------------------------
