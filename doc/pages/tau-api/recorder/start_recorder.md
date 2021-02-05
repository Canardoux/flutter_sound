---
title:  "Recorder API"
description: "startRecorder()"
summary: "startRecorder()"
permalink: tau_api_recorder_start_recorder.html
tags: [api,recorder]
keywords: API Recorder
---
# The &tau; Recorder API

-----------------------------------------------------------------------------------------------------------------

## `startRecorder()`

- Dart API: [startRecorder](pages/flutter-sound/api/recorder/FlutterSoundRecorder/startRecorder.html)

You use `startRecorder()` to start recording in an open session. `startRecorder()` has the destination file path as parameter.
It has also 7 optional parameters to specify :
- codec: The codec to be used. Please refer to the [Codec compatibility Table](guides_codec) to know which codecs are currently supported.
- toFile: a path to the file being recorded or the name of a temporary file (without slash '/').
- toStream: if you want to record to a Dart Stream. Please look to [the following notice](guides_record_stream). **This new functionnality needs, at least, Android SDK >= 21 (23 is better)**
- sampleRate: The sample rate in Hertz
- numChannels: The number of channels (1=monophony, 2=stereophony)
- bitRate: The bit rate in Hertz
- audioSource : possible value is :
   - defaultSource
   - microphone
   - voiceDownlink *(if someone can explain me what it is, I will be grateful ;-) )*

[path_provider](https://pub.dev/packages/path_provider) can be useful if you want to get access to some directories on your device.
To record a temporary file, the App can specify the name of this temporary file (without slash) instead of a real path.


Flutter Sound does not take care of the recording permission. It is the App responsability to check or require the Recording permission.
[Permission_handler](https://pub.dev/packages/permission_handler) is probably useful to do that.

*Example:*
<ul id="profileTabs" class="nav nav-tabs">
    <li class="active"><a href="#dart" data-toggle="tab">Dart</a></li>
    <li><a href="#javascript" data-toggle="tab">Javascript</a></li>
</ul>
<div class="tab-content">

<div role="tabpanel" class="tab-pane active" id="dart">

<pre>
    // Request Microphone permission if needed
    PermissionStatus status = await Permission.microphone.request();
    if (status != PermissionStatus.granted)
            throw RecordingPermissionException("Microphone permission not granted");

    await myRecorder.startRecorder(toFile: 'foo', codec: t_CODEC.CODEC_AAC,); // A temporary file named 'foo'
</pre>

</div>

<div role="tabpanel" class="tab-pane" id="javascript">
<pre>
        Lorem ipsum ...
</pre>
</div>

</div>

