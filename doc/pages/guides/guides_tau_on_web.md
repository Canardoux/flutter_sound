---
title:  "&tau; on web"
description: "&tau; on web."
summary: "&tau; on web."
permalink: guides_web.html
tags: [flutter_sound,web]
keywords: Flutter, &tau;, Web
---
# &tau; on Web

&tau; is now supported by Flutter Web \(with some limitations\). Please [go to there](install.md#flutter-web) to have informations on how to setup your App for web.

You can play with [this live demo on the web](pages/flutter-sound/web_example/index.html).


## Installation

To use Flutter Sound in a web application, you can either :

### Static reference

Add those 4 lines at the end of the `<head>` section of your `index.html` file :

```text
  <script src="assets/packages/flutter_sound_web/js/flutter_sound/flutter_sound.js"></script>
  <script src="assets/packages/flutter_sound_web/js/flutter_sound/flutter_sound_player.js"></script>
  <script src="assets/packages/flutter_sound_web/js/flutter_sound/flutter_sound_recorder.js"></script>
  <script src="assets/packages/flutter_sound_web/js/howler/howler.js"></script>
```

### or Dynamic reference

Add those 4 lines at the end of the `<head>` section of your `index.html` file :

```text
  <script src="https://cdn.jsdelivr.net/npm/tau_sound_core@7.4.13/js/flutter_sound/flutter_sound.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/tau_sound_core@7.4.13/js/flutter_sound/flutter_sound_player.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/tau_sound_core@7.4.13/js/flutter_sound/flutter_sound_recorder.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/howler@2/dist/howler.min.js"></script>
```

Please [read this](https://www.jsdelivr.com/features) to understand how you can specify the interval of the versions you are interested by.


## Player

* &tau; can play buffers with `startPlayerFromBuffer()`, exactly like with other platforms. Please refer to [the codecs compatibility table](guides_codec)
* &tau; can play remote URL with `startPlayer()`, exactly like with other platforms. Again, refer to [the codecs compatibility table](guides_codec)
* Playing from a Dart Stream with `startPlayerFromStream()`is not yet implemented.
* Playing with UI is obviously not implemented, because we do not have control to the lock screen inside a web app.
* &tau; does not have control of the audio-focus.

The web App does not have access to any file system. But you can store an URL into your local SessionStorage, and use the key as if it was an audio file. This is compatible with the &tau; recorder.

## Recorder

&tau; on web cannot have access to any file system. You can use `startRecorder()` like others platforms, but the recorded data will be stored inside an internal HTTP object. When the recorder is stopped, `startRecorder` stores the URL of this object into your local sessionStorage.

Please refer to [the codecs compatibility table](guides_codec) : &tau; Recorder does not work on Safari nor iOS.

```text
await startRecorder(codec: opusWebM, toFile: 'foo'); // the LocalSessionStorage key `foo` will contain the URL of the recorded object
...
await stopRecorder();
await startPlayer('foo'); // ('foo' is the LocalSessionStorage key of the recorded sound URL object)
```

Limitations :

* Recording to a Dart Stream is not yet implemented
* &tau; does not have access to the audio focus
* &tau; does not provide the audio peak level in the Recorder Progress events.

## FFmpeg

Actually, &tau; on Web does not support FFmpeg. We are still actually not sure if we should support it or if the code weight would be too high for a Web App.

## CORS

Web Browsers have a security system which is called `CORS`. [See here](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS).

If you try to play a remote sound and have a security alert, it can mean that your server did not put the correct Header
and that you must check the behavior of your server.

For example, to run correctly the Demo App, and play a remote AAC sound which is stored on the [canardoux.xyz host](https://www.canardoux.xyz/tau_sound/web_example/sample.aac),
I had to add :
```
Header set Access-Control-Allow-Origin "*"
```
in the configuration file of my Apache2 server.
([see here](https://enable-cors.org/server_apache.html))


After adding this parameter, it is now possible to do :
- [call the example app](https://www.canardoux.xyz/tau_sound/web_example/index.html)
- Enter the "Demo example"
- Select "media = Remote URL"
- Select "Codec = AAC"
- Play

This will play correctly the remote AAC file.