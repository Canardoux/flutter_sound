---
title:  "Player API"
description: "startPlayerFromMic()."
summary: "startPlayerFromMic()."
permalink: tau_api_player_start_player_from_mic.html
tags: [api, player]
keywords: API Player
---
# The &tau; Player API

-----------------------------------------------------------------------------------------------------------------

## `startPlayerFromMic()`

- Dart API: [startPlayerFromMic()](pages/flutter-sound/api/player/FlutterSoundPlayer/startPlayerFromMic.html).

Starts the Microphone and plays what is recorded.

The Speaker is directely linked to the Microphone.
There is no processing between the Microphone and the Speaker.

{% include tip.html content="If you want to process the data before playing them, actually you must define a loop between a FlutterSoundPlayer and a FlutterSoundRecorder.
(Please, look to [this example](flutter_sound_examples_stream_loop.html))." %}


startPlayerFromMic() has two optional parameters :
- `sampleRate:` the Sample Rate used. Optional. Only used on Android. The default value is probably a good choice and the App can ommit this optional parameter.
- `numChannels:` 1 for monophony, 2 for stereophony. Optional. Actually only monophony is implemented.

startPlayerFromMic() returns a Future, which is completed when the Player is really started.

{% include note.html content="Several τ users needs to play on the headset what is recorded by the microphone, in quasi-real-time.
I am convinced that implementing audio-graph will be the general solution and will be very elegant.
But I think that we can implement this new simple verb `startPlayerFromMic()` before the great global solution.

Later, we will implement the _Tau Audio Graph_ concept, which will be a more general object." %}


*Example:*
<ul id="profileTabs" class="nav nav-tabs">
    <li class="active"><a href="#dart" data-toggle="tab">Dart</a></li>
    <li><a href="#javascript" data-toggle="tab">Javascript</a></li>
</ul>
<div class="tab-content">

<div role="tabpanel" class="tab-pane active" id="dart">

<pre>
     await myPlayer.startPlayerFromMic();
     ...
     myPlayer.stopPlayer();
</pre>

</div>

<div role="tabpanel" class="tab-pane" id="javascript">
<pre>
        Lorem ipsum ...
</pre>
</div>

</div>

--------------------------------------------------------------------------------------------------------------------------------
