---
title:  "Temporary files"
description: "Temporary files"
summary: "Using temporary files."
permalink: temporary_files.html
tags: [flutter_sound]
keywords: Flutter, &tau;
---
# Managing temporary records

## Using path_provider

The App can get the temporary directory with the plugin `path_provider` and use it for `startRecorder()` parameter :

```
        var tempDir = await getTemporaryDirectory();
        String path = '${tempDir.path}/flutter_sound.aac';
        await myRecorder.startRecorder( toFile: path, codec: Codec.aacADTS );
        ...
        await myRecorder.stopRecorder();
        await myPlayer.startPlayer( fromURI: path, codec: Codec.aacADTS );
```

This does not work well on Flutter Web.

## Using a temporary file name

If the App does not specify a full path to the startRecorder parameter,
the `startRecorder()` argument is considered as a temporary file name.

```
        await myRecorder.startRecorder( toFile: 'foo.aac', codec: Codec.aacADTS ); // Without any slash '/'.
        ...
        await myRecorder.stopRecorder();
        await myPlayer.startPlayer( fromURI: 'foo.aac', codec: Codec.aacADTS );
```

`stopRecorder()` returns a Future to the URL of the temporary file created if the App needs it.

```
        await myRecorder.startRecorder( toFile: 'foo.aac', codec: Codec.aacADTS ); // Without any slash '/'.
        ...
        String url = await myRecorder.stopRecorder();
        await myPlayer.startPlayer( fromURI: url, codec: Codec.aacADTS );
```

All the temporary files created are automaticaly deleted when the App does a `closeAudioSession()`.

This works on :
- Android
- iOS
- Flutter Web