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
(Please, look to [this example](pages/flutter-sound/api/topics/flutter_sound_examples_play_from_mic.html))." %}


startPlayerFromMic() has two optional parameters :
- `sampleRate:` the Sample Rate used. Optional. Only used on Android. The default value is probably a good choice and the App can ommit this optional parameter.
- `numChannels:` 1 for monophony, 2 for stereophony. Optional. Actually only monophony is implemented.

startPlayerFromMic() returns a Future, which is completed when the Player is really started.

{% include note.html content="Several τ users needs to play on the headset what is recorded by the microphone, in quasi-real-time.
I am convinced that implementing audio-graph will be the general solution and will be very elegant.
But I think that we can implement this new simple verb `startPlayerFromMic()` before the great global solution.

Later, we will implement the _Tau Audio Graph_ concept, which will be a more general object." %}

[This new example](http://www.canardoux.xyz/tau_sound/doc/pages/flutter-sound/api/topics/flutter_sound_examples_play_from_mic.html) can be compared to [the old loop example](http://www.canardoux.xyz/tau_sound/doc/pages/flutter-sound/api/topics/flutter_sound_examples_stream_loop.html).

### 1. iOS

`startPlayerFromMic()` directely links the microphone to the headset **inside the OS itself**, without any processing by &tau;

The improvement is really good. The delay between what is recorded and what is played is much better.

### 2. Android

The link beetween the microphone and the headset is done inside &tau;-core.
The messaging channels between Java and Dart is not involved. The audio data are just transfered from the recording-thread to the player thread.

This is a great disappointment : the performances are marginally improved.
This means that implementing data transfert from/to Dart with FFI will not benefit from using FFI.


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
