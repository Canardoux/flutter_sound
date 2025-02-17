---
title:  Flutter Sound on web"
summary: "Flutter Sound on web."
permalink: fs-guides_web.html
---
# Flutter Sound on Web

Flutter Sound is now supported by Flutter Web.
You can play with [this live demo on the web](/tau\/fs\/live\/index.html).

```dart
NoSuchMethodError: tried to call a non-function, such as null: 'dart.global.newRecorderInstance'
```

{% include tip.html content=
"If you get this error above, it probably means that the required javascript sources are not correctly loaded by your index.html file.
Double check if your javascript source files are correct.
" %}

## Player

* Flutter Sound can play buffers with [startPlayer(fromDataBuffer: )](/tau/fs/api/player/FlutterSoundPlayer/startPlayer.html), exactly like with other platforms. Please refer to [the codecs compatibility table](fs-guides_codec.html#on-web-browsers)
* Flutter Sound can play remote URL with [startPlayer()](/tau/fs/api/player/FlutterSoundPlayer/startPlayer.html), exactly like with other platforms. Again, refer to [the codecs compatibility table](fs-guides_codec.html#on-web-browsers)
* Playing from a Dart Stream with [startPlayerFromStream()](/tau/fs/api/player/FlutterSoundPlayer/startPlayerFromStream.html) is now implemented.

The web App does not have access to any file system. But you can store a `Blob Object` URL into your local SessionStorage, and use the key as if it was an audio file. This is compatible with the Flutter Sound recorder.

## Recorder

Flutter Sound on web cannot have access to any file system. You can use [startRecorder()](/tau/fs/api/recorder/FlutterSoundRecorder/startRecorder.html) like others platforms, but the recorded data will be stored inside an internal HTTP `Blob Object`. When the recorder is stopped, `startRecorder` stores the URL of this object into your local sessionStorage.

Please refer to [the codecs compatibility table](fs-guides_codec.html#on-web-browsers) : Flutter Sound Recorder does not work on Safari nor iOS.

```text
await startRecorder(codec: opusWebM, toFile: 'foo'); // the LocalSessionStorage key `foo` will contain the URL of the recorded object
...
await stopRecorder();
await startPlayer('foo'); // ('foo' is the LocalSessionStorage key of the recorded sound URL object)
```

## CORS

Web Browsers have a security system which is called `CORS`. [See here](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS).

If you try to play a remote sound and have a security alert, it can mean that your server did not put the correct header
and that you must check the behavior of your server.

For example, to run correctly the Demo App, and play a remote AAC sound which is stored on the `canardoux.xyz` host,
I had to add :
```
        Header set Access-Control-Allow-Origin "*"
```
in the configuration file of my Apache2 server ([see here](https://enable-cors.org/server_apache.html)), 

and
```
        add_header Access-Control-Allow-Origin *;
```
in the configuration file of my nginx server.



After adding this parameter, it is now possible to do :
- [call to the example app](/tau\/fs\/live\/index.html).


This will play correctly the remote AAC file.