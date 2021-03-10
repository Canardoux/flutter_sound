---
title:  "Player API"
description: "startPlayerFromTrack()."
summary: "startPlayerFromTrack()."
permalink: tau_api_player_start_player_from_track.html
tags: [api, player]
keywords: API Player
---
# The &tau; Player API


--------------------------------------------------------------------------------------------------------------------------------

## `startPlayerFromTrack()`

- Dart API: [startPlayerFromTrack()](pages/flutter-sound/api/player/FlutterSoundPlayer/startPlayerFromTrack.html).

Use this verb to play data from a track specification and display controls on the lock screen or an Apple Watch. The Audio Session must have been open with the parameter `withUI`.

- `track` parameter is a simple structure which describe the sound to play.

- `whenFinished:()` : A function for specifying what to do when the playback will be finished.

- `onPaused:()` : this parameter can be :
   - a call back function to call when the user hit the Skip Pause button on the lock screen
   - `null` : The pause button will be handled by Flutter Sound internal

- `onSkipForward:()` : this parameter can be :
   - a call back function to call when the user hit the Skip Forward button on the lock screen
   - `null` : The Skip Forward button will be disabled

- `onSkipBackward:()` : this parameter can be :
   - a call back function to call when the user hit the Skip Backward button on the lock screen
   - <null> : The Skip Backward button will be disabled

- `removeUIWhenStopped` : is a boolean to specify if the UI on the lock screen must be removed when the sound is finished or when the App does a `stopPlayer()`. Most of the time this parameter must be true. It is used only for the rare cases where the App wants to control the lock screen between two playbacks. Be aware that if the UI is not removed, the button Pause/Resume, Skip Backward and Skip Forward remain active between two playbacks. If you want to disable those button, use the API verb ```nowPlaying()```.
Remark: actually this parameter is implemented only on iOS.

- `defaultPauseResume` : is a boolean value to specify if Flutter Sound must pause/resume the playback by itself when the user hit the pause/resume button. Set this parameter to *FALSE* if the App wants to manage itself the pause/resume button. If you do not specify this parameter and the `onPaused` parameter is specified then Flutter Sound will assume `FALSE`. If you do not specify this parameter and the `onPaused` parameter is not specified then Flutter Sound will assume `TRUE`.
Remark: actually this parameter is implemented only on iOS.


`startPlayerFromTrack()` returns a Duration Future, which is the record duration.


*Example:*
<ul id="profileTabs" class="nav nav-tabs">
    <li class="active"><a href="#dart" data-toggle="tab">Dart</a></li>
    <li><a href="#javascript" data-toggle="tab">Javascript</a></li>
</ul>
<div class="tab-content">

<div role="tabpanel" class="tab-pane active" id="dart">

<pre>
    final fileUri = "https://file-examples.com/wp-content/uploads/2017/11/file_example_MP3_700KB.mp3";
    Track track = Track( codec: Codec.opusOGG, trackPath: fileUri, trackAuthor: '3 Inches of Blood', trackTitle: 'Axes of Evil', albumArtAsset: albumArt )
    Duration d = await myPlayer.startPlayerFromTrack
    (
                track,
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
