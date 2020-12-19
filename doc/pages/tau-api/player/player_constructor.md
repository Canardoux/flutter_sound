---
title:  "Player API"
description: "The &tau; player API."
summary: "The &tau; player API."
permalink: tau_api_player_constructor.html
tags: [API, player]
keywords: API Player
---
# The &tau; Player API

-------------------------------------------------------------------------------------------------------------------

## Creating the `Player` instance.

*Dart definition (prototype) :*
```
/* ctor */ FlutterSoundPlayer()
```

This is the first thing to do, if you want to deal with playbacks. The instanciation of a new player does not do many thing. You are safe if you put this instanciation inside a global or instance variable initialization.

*Example:*
```dart
FlutterSoundPlayer myPlayer = FlutterSoundPlayer();
```

--------------------------------------------------------------------------------------------------------------------
