---
title:  "Examples"
description: "Stream Loop"
summary: "Stream Loop"
permalink: flutter_sound_examples_stream_loop.html
tags: [example,demo]
keywords: Flutter, Flutter Sound, examples, demo
---
# Examples


## streamLoop

[streamLoop](https://github.com/dooboolab/flutter_sound/blob/master/flutter_sound/example/lib/streamLoop/stream_loop.dart)

{% include image.html file="examples/stream_loop.png" %}

`streamLoop()` is a very simple example which connect the FlutterSoundRecorder sink to the FlutterSoundPlayer Stream. Of course, we do not play to the loudspeaker to avoid a very unpleasant Larsen effect. this example does not use a new StreamController, but use directely `foodStreamController` from flutter\_sound\_player.dart.

The complete example source [is there](https://github.com/dooboolab/flutter_sound/blob/master/flutter_sound/example/lib/streamLoop/stream_loop.dart)

