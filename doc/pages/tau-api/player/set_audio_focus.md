---
title:  "Player API"
description: "setAudioFocus."
summary: "setAudioFocus."
permalink: tau_api_player_set_audio_focus.html
tags: [api, player]
keywords: API Player
---
# The &tau; Player API

------------------------------------------------------------------------------------------------------------------

## `setAudioFocus()`

- Dart API: [setAudioFocus](pages/flutter-sound/api/player/FlutterSoundPlayer/setAudioFocus.html).

### `focus:` parameter possible values are
- AudioFocus.requestFocus (request focus, but do not do anything special with others App)
- AudioFocus.requestFocusAndStopOthers (your app will have **exclusive use** of the output audio)
- AudioFocus.requestFocusAndDuckOthers (if another App like Spotify use the output audio, its volume will be **lowered**)
- AudioFocus.requestFocusAndKeepOthers (your App will play sound **above** others App)
- AudioFocus.requestFocusAndInterruptSpokenAudioAndMixWithOthers
- AudioFocus.requestFocusTransient (for Android)
- AudioFocus.requestFocusTransientExclusive (for Android)
- AudioFocus.abandonFocus (Your App will not have anymore the audio focus)

### Other parameters :

Please look to [openAudioSession()](tau_api_player_open_audio_session) to understand the meaning of the other parameters


*Example:*
<ul id="profileTabs" class="nav nav-tabs">
    <li class="active"><a href="#dart" data-toggle="tab">Dart</a></li>
    <li><a href="#javascript" data-toggle="tab">Javascript</a></li>
</ul>
<div class="tab-content">

<div role="tabpanel" class="tab-pane active" id="dart">

<pre>
        myPlayer.setAudioFocus(focus: AudioFocus.requestFocusAndDuckOthers);
</pre>

</div>

<div role="tabpanel" class="tab-pane" id="javascript">
<pre>
        Lorem ipsum ...
</pre>
</div>

</div>

-----------------------------------------------------------------------------------------------------------------
