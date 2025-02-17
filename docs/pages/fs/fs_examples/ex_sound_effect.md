---
title:  "Sound Effects"
summary: "Play some sound effects, using a stream"
permalink: fs-ex_sound_effects.html
---

The example source [is there](https://github.com/canardoux/flutter_sound/blob/master/example/lib/soundEffect/sound_effect.dart). You can have a live run of the examples [here](/tau/fs/live/index.html).

Play from stream can be very efficient to play sound effects in real time. For example in a game App. In this example, the App open the Audio Session and call `startPlayerFromStream()` during initialization. When it want to play a noise, it has just to call the synchronous verb `feed`. Very fast.

{% include image.html file="/fs/ExampleScreenShots/SoundEffect.png" %}