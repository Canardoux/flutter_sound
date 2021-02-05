---
title:  "Player API"
description: "startPlayer()."
summary: "startPlayer()."
permalink: tau_api_player_startPlayer.html
tags: [api, player]
keywords: API Player
---
# The &tau; Player API

-----------------------------------------------------------------------------------------------------------------

## `startPlayer()`

- Dart API: [startPlayer()](pages/flutter-sound/api/player/FlutterSoundPlayer/startPlayer.html).

You can use `startPlayer` to play a sound.

- `startPlayer()` has three optional parameters, depending on your sound source :
   - `fromUri:`  (if you want to play a file or a remote URI)
   - `fromDataBuffer:` (if you want to play from a data buffer)
   - `sampleRate` is mandatory if `codec` == `Codec.pcm16`. Not used for other codecs.

You must specify one or the three parameters : `fromUri`, `fromDataBuffer`, `fromStream`.

- You use the optional parameter`codec:` for specifying the audio and file format of the file. Please refer to the [Codec compatibility Table](codec.md#actually-the-following-codecs-are-supported-by-flutter_sound) to know which codecs are currently supported.

- `whenFinished:()` : A lambda function for specifying what to do when the playback will be finished.

Very often, the `codec:` parameter is not useful. Flutter Sound will adapt itself depending on the real format of the file provided.
But this parameter is necessary when Flutter Sound must do format conversion (for example to play opusOGG on iOS).

`startPlayer()` returns a Duration Future, which is the record duration.

The `fromUri` parameter, if specified, can be one of three possibilities :
- The URL of a remote file
- The path of a local file
- The name of a temporary file (without any slash '/')

Hint: [path_provider](https://pub.dev/packages/path_provider) can be useful if you want to get access to some directories on your device.


*Example:*

<ul id="profileTabs" class="nav nav-tabs">
    <li class="active"><a href="#dart" data-toggle="tab">Dart</a></li>
    <li><a href="#javascript" data-toggle="tab">Javascript</a></li>
</ul>
<div class="tab-content">

<div role="tabpanel" class="tab-pane active" id="dart">

<pre>
        Duration d = await myPlayer.startPlayer(fromURI: 'foo', codec: Codec.aacADTS); // Play a temporary file

        _playerSubscription = myPlayer.onProgress.listen((e)
        {
                // ...
        });
</pre>

</div>

<div role="tabpanel" class="tab-pane" id="javascript">
<pre>
        Lorem ipsum ...
</pre>
</div>

</div>


*Example:*
<ul id="profileTabs" class="nav nav-tabs">
    <li class="active"><a href="#dart" data-toggle="tab">Dart</a></li>
    <li><a href="#javascript" data-toggle="tab">Javascript</a></li>
</ul>
<div class="tab-content">

<div role="tabpanel" class="tab-pane active" id="dart">

<pre>
    final fileUri = "https://file-examples.com/wp-content/uploads/2017/11/file_example_MP3_700KB.mp3";

    Duration d = await myPlayer.startPlayer
    (
                fromURI: fileUri,
                codec: Codec.mp3,
                whenFinished: ()
                {
                         print( 'I hope you enjoyed listening to this song' );
                },
    );
</pre>

</div>

<div role="tabpanel" class="tab-pane" id="javascript">
<pre>
        Lorem ipsum ...
</pre>
</div>

</div>

--------------------------------------------------------------------------------------------------------------------------------
