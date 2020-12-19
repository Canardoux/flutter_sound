---
title:  "Recorder API"
description: "setAudioFocus()"
summary: "setAudioFocus()"
permalink: tau_api_recorder_set_audio_focus.html
tags: [API, recorder]
keywords: API Recorder
---
# The &tau; Recorder API

-
------------------------------------------------------------------------------------------------------------------

## `setAudioFocus()`

[Dart API](https://canardoux.github.io/tau/doc/flutter_sound/api/recorder/FlutterSoundRecorder/setAudioFocus.html)

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

Please look to [openAudioSession()](player.md#openaudiosession-and-closeaudiosession) to understand the meaning of the other parameters


*Example:*
```dart
        myPlayer.setAudioFocus(focus: AudioFocus.requestFocusAndDuckOthers);
```

-----------------------------------------------------------------------------------------------------------------
