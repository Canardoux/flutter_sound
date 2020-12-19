---
title:  "Recorder API"
description: "startRecorder()"
summary: "startRecorder()"
permalink: tau_api_recorder_start_recorder.html
tags: [API, recorder]
keywords: API Recorder
---
# The &tau; Recorder API

-----------------------------------------------------------------------------------------------------------------

## `startRecorder()`

[Dart API](https://canardoux.github.io/tau/doc/flutter_sound/api/recorder/FlutterSoundRecorder/startRecorder.html)

You use `startRecorder()` to start recording in an open session. `startRecorder()` has the destination file path as parameter.
It has also 7 optional parameters to specify :
- codec: The codec to be used. Please refer to the [Codec compatibility Table](codec.md#actually-the-following-codecs-are-supported-by-flutter_sound) to know which codecs are currently supported.
- toFile: a path to the file being recorded
- toStream: if you want to record to a Dart Stream. Please look to [the following notice](codec.md#recording-pcm-16-to-a-dart-stream). **This new functionnality needs, at least, Android SDK >= 21 (23 is better)**
- sampleRate: The sample rate in Hertz
- numChannels: The number of channels (1=monophony, 2=stereophony)
- bitRate: The bit rate in Hertz
- audioSource : possible value is :
   - defaultSource
   - microphone
   - voiceDownlink *(if someone can explain me what it is, I will be grateful ;-) )*

[path_provider](https://pub.dev/packages/path_provider) can be useful if you want to get access to some directories on your device.

Flutter Sound does not take care of the recording permission. It is the App responsability to check or require the Recording permission.
[Permission_handler](https://pub.dev/packages/permission_handler) is probably useful to do that.

*Example:*
```dart
    // Request Microphone permission if needed
    PermissionStatus status = await Permission.microphone.request();
    if (status != PermissionStatus.granted)
            throw RecordingPermissionException("Microphone permission not granted");

    Directory tempDir = await getTemporaryDirectory();
    File outputFile = await File ('${tempDir.path}/flutter_sound-tmp.aac');
    await myRecorder.startRecorder(toFile: outputFile.path, codec: t_CODEC.CODEC_AAC,);
```
