---
title:  "Player API"
description: "`openAudioSession()` and `closeAudioSession()`."
summary: "`openAudioSession()` and `closeAudioSession()`."
permalink: tau_api_player_open_audio_session.html
tags: [api, player]
keywords: API Player
---
# The &tau; Player API

-------------------------------------------------------------------------------------------------------------------

## `openAudioSession()` and `closeAudioSession()`

- Dart API: [openAudioSession](pages/flutter-sound/api/player/FlutterSoundPlayer/openAudioSession.html).
- Dart API: [closeAudioSession](pages/flutter-sound/api/player/FlutterSoundPlayer/closeAudioSession.html).

A player must be opened before used. A player correspond to an Audio Session. With other words, you must *open* the Audio Session before using it.
When you have finished with a Player, you must close it. With other words, you must close your Audio Session.
Opening a player takes resources inside the OS. Those resources are freed with the verb `closeAudioSession()`.
It is safe to call this procedure at any time.
- If the Player is not open, this verb will do nothing
- If the Player is currently in play or pause mode, it will be stopped before.


### `focus:` parameter

`focus` is an optional parameter can be specified during the opening : the Audio Focus.
This parameter can have the following values :
- AudioFocus.requestFocusAndStopOthers (your app will have **exclusive use** of the output audio)
- AudioFocus.requestFocusAndDuckOthers (if another App like Spotify use the output audio, its volume will be **lowered**)
- AudioFocus.requestFocusAndKeepOthers (your App will play sound **above** others App)
- AudioFocus.requestFocusAndInterruptSpokenAudioAndMixWithOthers (for Android)
- AudioFocus.requestFocusTransient (for Android)
- AudioFocus.requestFocusTransientExclusive (for Android)
- AudioFocus.doNotRequestFocus (useful if you want to mangage yourself the Audio Focus with the verb ```setAudioFocus()```)

The Audio Focus is abandoned when you close your player. If your App must play several sounds, you will probably open  your player just once, and close it when you have finished with the last sound. If you close and reopen an Audio Session for each sound, you will probably get unpleasant things for the ears with the Audio Focus.

### `category`

`category` is an optional parameter used only on iOS.
This parameter can have the following values :
- ambient
- multiRoute
- playAndRecord
- playback
- record
- soloAmbient
- audioProcessing

See [iOS documentation](https://developer.apple.com/documentation/avfoundation/avaudiosessioncategory?language=objc) to understand the meaning of this parameter.

### `mode`

`mode` is an optional parameter used only on iOS.
This parameter can have the following values :
- modeDefault
- modeGameChat
- modeMeasurement
- modeMoviePlayback
- modeSpokenAudio
- modeVideoChat
- modeVideoRecording
- modeVoiceChat
- modeVoicePrompt

See [iOS documentation](https://developer.apple.com/documentation/avfoundation/avaudiosessionmode?language=objc) to understand the meaning of this parameter.

### `audioFlags`
 are a set of optional flags (used on iOS):

- outputToSpeaker
- allowHeadset
- allowEarPiece
- allowBlueTooth
- allowAirPlay
- allowBlueToothA2DP

### `device`
 is the output device (used on Android)

- speaker
- headset,
- earPiece,
- blueTooth,
- blueToothA2DP,
- airPlay

### `withUI`
is a boolean that you set to `true` if you want to control your App from the lock-screen (using [startPlayerFromTrack()](player.md#startplayerfromtrack) during your Audio Session).

You MUST ensure that the player has been closed when your widget is detached from the UI.
Overload your widget's `dispose()` method to closeAudioSession the player when your widget is disposed.
In this way you will reset the player and clean up the device resources, but the player will be no longer usable.

```dart
@override
void dispose()
{
        if (myPlayer != null)
        {
            myPlayer.closeAudioSession();
            myPlayer = null;
        }
        super.dispose();
}
```

You may not open many Audio Sessions without closing them.
You will be very bad if you try something like :
```dart
    while (aCondition)  // *DON'T DO THAT*
    {
            flutterSound = FlutterSoundPlayer().openAudioSession(); // A **new** Flutter Sound instance is created and opened
            flutterSound.startPlayer(bipSound);
    }
```

`openAudioSession()` and `closeAudioSession()` return Futures. You may not use your Player before the end of the initialization. So probably you will `await` the result of `openAudioSession()`. This result is the Player itself, so that you can collapse instanciation and initialization together with `myPlayer = await FlutterSoundPlayer().openAudioSession();`

*Example:*
<ul id="profileTabs" class="nav nav-tabs">
    <li class="active"><a href="#dart" data-toggle="tab">Dart</a></li>
    <li><a href="#javascript" data-toggle="tab">Javascript</a></li>
</ul>
<div class="tab-content">

<div role="tabpanel" class="tab-pane active" id="dart">

<pre>
    myPlayer = await FlutterSoundPlayer().openAudioSession(focus: Focus.requestFocusAndDuckOthers, outputToSpeaker | allowBlueTooth);

    ...
    (do something with myPlayer)
    ...

    await myPlayer.closeAudioSession();
    myPlayer = null;
    FlutterSoundPlayer myPlayer = FlutterSoundPlayer();
</pre>

</div>

<div role="tabpanel" class="tab-pane" id="javascript">
<pre>
        Lorem ipsum ...
</pre>
</div>

</div>

------------------------------------------------------------------------------------------------------------------
