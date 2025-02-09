---
title:  "Demo"
description: "Flutter Sound Demo."
summary: "A demonstration of the Flutter Sound features."
permalink: flutter_sound_examples_demo.html
tags: [example,demo]
keywords: Flutter, Flutter Sound, examples, demo
---
# Examples


## Demo

[Demo](https://github.com/dooboolab/flutter_sound/blob/master/flutter_sound/example/lib/demo/demo.dart)

{% include image.html file="examples/demo.png" %}

This is a Demo of what it is possible to do with Flutter Sound. The code of this Demo app is not so simple and unfortunately not very clean :-\( .

Flutter Sound beginners : you probably should look to [SimplePlayback](./#simpleplayback) and [SimpleRecorder](./#simplerecorder)

The biggest interest of this Demo is that it shows most of the features of Flutter Sound :

* Plays from various media with various codecs
* Records to various media with various codecs
* Pause and Resume control from recording or playback
* Shows how to use a Stream for getting the playback \(or recoding\) events
* Shows how to specify a callback function when a playback is terminated,
* Shows how to record to a Stream or playback from a stream
* Can show controls on the iOS or Android lock-screen
* ...

It would be really great if someone rewrite this demo soon

The complete example source [is there](https://github.com/dooboolab/flutter_sound/blob/master/flutter_sound/example/lib/demo/demo.dart)
