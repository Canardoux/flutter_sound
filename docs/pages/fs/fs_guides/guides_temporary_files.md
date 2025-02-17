---
title:  "Temporary files"
summary: "Using temporary files."
permalink: fs-guides_temporary_files.html
---
# Managing temporary records

## Using path_provider

The App can get the temporary directory with the plugin [path_provider](https://pub.dev/packages/path_provider) and use it for [startRecorder()](/tau/fs/api/recorder/FlutterSoundRecorder/startRecorder.html) parameter :

```dart
        var tempDir = await getTemporaryDirectory();
        String path = '${tempDir.path}/flutter_sound.aac';
        await myRecorder.startRecorder( toFile: path, codec: Codec.aacADTS );
        ...
        await myRecorder.stopRecorder();
        await myPlayer.startPlayer( fromURI: path, codec: Codec.aacADTS );
```

This does not work well on Flutter Web, because you don't have access to a real file system in a Web Browser.
{% include note.html content="
Temporary files are emulated by Flutter Sound on Flutter Web, using `Blob` objects.
"%}


## Using a temporary file name

If the App does not specify a full path to the startRecorder parameter (without any '/'),
the [startRecorder()](/tau/fs/api/recorder/FlutterSoundRecorder/startRecorder.html) argument is considered as a temporary file name.

```dart
        await myRecorder.startRecorder( toFile: 'foo.aac', codec: Codec.aacADTS ); // Without any slash '/'.
        ...
        await myRecorder.stopRecorder();
        await myPlayer.startPlayer( fromURI: 'foo.aac', codec: Codec.aacADTS );
```

[stopRecorder()](/tau/fs/api/recorder/FlutterSoundRecorder/stopRecorder.html) returns a Future to the URL of the temporary file created if the App needs it.

```dart
        await myRecorder.startRecorder( toFile: 'foo.aac', codec: Codec.aacADTS ); // Without any slash '/'.
        ...
        String url = await myRecorder.stopRecorder();
        await myPlayer.startPlayer( fromURI: url, codec: Codec.aacADTS );
```

All the temporary files created are automaticaly deleted when the App does a [closeRecorder()](/tau/fs/api/recorder/FlutterSoundRecorder/closeRecorder.html)].

This works on :
- Android
- iOS
- Flutter Web