---
title:  "Examples"
description: "Sound Effects"
summary: "Sound Effects"
permalink: flutter_sound_examples_sound_effects.html
tags: [example,demo]
keywords: Flutter, Flutter Sound, examples, demo
---
# Examples

## soundEffect

[soundEffect](https://github.com/dooboolab/flutter_sound/blob/master/flutter_sound/example/lib/soundEffect/sound_effect.dart)

{% include image.html file="examples/sound_effect.png" %}

[startPlayerFromStream](https://github.com/dooboolab/flutter_sound/tree/bb6acacc34205174a8438a13c8c0797f7bfa2143/doc/tau/player.md##startplayerfromstream) can be very efficient to play sound effects in real time. For example in a game App. In this example, the App open the Audio Session and call `startPlayerFromStream()` during initialization. When it want to play a noise, it has just to call the synchronous verb `feed`. Very fast.

The complete example source [is there](https://github.com/dooboolab/flutter_sound/blob/master/flutter_sound/example/lib/soundEffect/sound_effect.dart)
