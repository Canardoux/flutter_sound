---
title:  "Player API"
description: "`openPlayer()` and `closePlayer()`."
summary: "`openPlayer()` and `closePlayer()`."
permalink: tau_api_player_open_audio_session.html
tags: [api, player]
keywords: API Player
---
# The &tau; Player API

-------------------------------------------------------------------------------------------------------------------

## `openPlayer()` and `closePlayer()`

- Dart API: [openPlayer](pages/flutter-sound/api/player/FlutterSoundPlayer/openPlayer.html).
- Dart API: [closePlayer](pages/flutter-sound/api/player/FlutterSoundPlayer/closePlayer.html).

A player must be opened before used.
Opening a player takes resources inside the OS. Those resources are freed with the verb `closePlayer()`.
It is safe to call this procedure at any time.
- If the Player is not open, this verb will do nothing
- If the Player is currently in play or pause mode, it will be stopped before.

```dart
@override
void dispose()
{
        if (myPlayer != null)
        {
            myPlayer.closePlayer();
            myPlayer = null;
        }
        super.dispose();
}
```

You may not open many Audio Sessions without closing them.

`openPlayer()` and `closePlayer()` return Futures. You may not use your Player before the end of the initialization. So probably you will `await` the result of `openPlayer()`. This result is the Player itself, so that you can collapse instanciation and initialization together with `myPlayer = await FlutterSoundPlayer().openAudioSession();`

*Example:*
<ul id="profileTabs" class="nav nav-tabs">
    <li class="active"><a href="#dart" data-toggle="tab">Dart</a></li>
    <li><a href="#javascript" data-toggle="tab">Javascript</a></li>
</ul>
<div class="tab-content">

<div role="tabpanel" class="tab-pane active" id="dart">

<pre>
    FlutterSoundPlayer myPlayer = FlutterSoundPlayer();
    myPlayer = await FlutterSoundPlayer().openPlayer();

    ...
    (do something with myPlayer)
    ...

    await myPlayer.closePlayer();
    myPlayer = null;
</pre>

</div>

<div role="tabpanel" class="tab-pane" id="javascript">
<pre>
        Lorem ipsum ...
</pre>
</div>

</div>

------------------------------------------------------------------------------------------------------------------
