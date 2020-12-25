---
title:  "Flutter Sound on web"
description: "Flutter Sound on web."
summary: "Flutter Sound on web."
permalink: flutter_sound_web.html
tags: [flutter_sound,web]
keywords: Flutter, Flutter Sound, Web
---
# Flutter Sound on Flutter Web

Flutter Sound is now supported by Flutter Web \(with some limitations\). Please [go to there](install.md#flutter-web) to have informations on how to setup your App for web.

The big problem \(as usual\) is Apple. Webkit is bull shit : you cannot use MediaRecorder to record anything with it. It means that Flutter Sound on Safari cannot record. And because Apple forces Firefox and Chrome to use also Webkit on iOS, you cannot record anything on iOS with Flutter Sound. Apple really sucks :-\(.

You can play with [this live demo on the web](pages/flutter-sound/web_example/index.html), but better if not Safari and not iOS if you want to record something.

## Player

* Flutter Sound can play buffers with `startPlayerFromBuffer()`, exactly like with other platforms. Please refer to [the codecs compatibility table](guides_codec)
* Flutter Sound can play remote URL with `startPlayer()`, exactly like with other platforms. Again, refer to [the codecs compatibility table](guides_codec)
* Playing from a Dart Stream with `startPlayerFromStream()`is not yet implemented.
* Playing with UI is obviously not implemented, because we do not have control to the lock screen inside a web app.
* Flutter Sound does not have control of the audio-focus.

The web App does not have access to any file system. But you can store an URL into your local SessionStorage, and use the key as if it was an audio file. This is compatible with the Flutter Sound recorder.

## Recorder

Flutter Sound on web cannot have access to any file system. You can use `startRecorder()` like others platforms, but the recorded data will be stored inside an internal HTTP object. When the recorder is stopped, `startRecorder` stores the URL of this object into your local sessionStorage.

Please refer to [the codecs compatibility table](guides_codec) : Flutter Sound Recorder does not work on Safari nor iOS.

```text
await startRecorder(codec: opusWebM, toFile: 'foo'); // the LocalSessionStorage key `foo` will contain the URL of the recorded object
...
await stopRecorder();
await startPlayer('foo'); // ('foo' is the LocalSessionStorage key of the recorded sound URL object)
```

Limitations :

* Recording to a Dart Stream is not yet implemented
* Flutter Sound does not have access to the audio focus
* Flutter Sound does not provide the audio peak level in the Recorder Progress events.

## FFmpeg

Actually, Flutter Sound on Web does not support FFmpeg. We are still actually not sure if we should support it or if the code weight would be too high for a Web App.

