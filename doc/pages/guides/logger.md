---
title:  "Logger"
description: "Logging"
summary: "Debugging logs."
permalink: logger.html
tags: [flutter_sound]
keywords: Flutter, &tau;
---
# Managing the &tau; logs

The &tau; project uses now the `logger` plugin.

There are three loggers : 

- One in the FlutterSoundPlayer module.
- One in the FlutterSoundRecorder module.
- One in the FlutterSoundHelper module.

The FlutterSoundPlayer logger and the FlutterSoundRecorder logger are instanciated when you create those modules.
By default, the Logger has a Log Level set to `Level.debug`.

The possible values for the Log Level are :

```dart
enum Level 
{
        verbose,
        debug,
        info,
        warning,
        error,
        wtf,
        nothing,
}
```

If you want to debugg or develop The &tau; Project you can sepecify another Log Level during the instanciation of your modules : 

```dart
FlutterSoundPlayer myPlayer = FlutterSoundPlayer(logLevel: Level.debug);
FlutterSoundRecorder myRecorder = FlutterSoundRecorder(logLevel: Level.debug);
```

You probably do not need, but if exceptionaly you want to dynamicaly change the Log Level after the module instanciation, you can use the `setLogLevel` verb :

```dart
        myPlayer.setLogLevel(Level.debug);
        myRecorder.setLogLevel(Level.debug);
```

`setLogLeve()` is also used with the Helper module, because the App does not instanciate this module, but uses a singleton :

```dart
        flutterSoundHelper.setLogLevel(Level.debug);
```

A simple example doing `setLogLevel()` [is here](flutter_sound_examples_setLogLevel).