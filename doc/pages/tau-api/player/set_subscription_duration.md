---
title:  "Player API"
description: "setSubscriptionDuration()"
summary: "setSubscriptionDuration()"
permalink: tau_api_player_set_subscription_duration.html
tags: [API, player]
keywords: API Player
---
# The &tau; Player API

---------------------------------------------------------------------------------------------------------------------------------

## `setSubscriptionDuration()`

[Dart API: isStopped()](https://canardoux.github.io/tau/doc/flutter_sound/api/player/FlutterSoundPlayer/setSubscriptionDuration.html)

This verb is used to change the default interval between two post on the "Update Progress" stream. (The default interval is 0 (zero) which means "NO post")

*Example:*
```dart
myPlayer.setSubscriptionDuration(Duration(milliseconds: 100));
```
