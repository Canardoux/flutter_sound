---
title:  "openAudioSession()"
description: "`openAudioSession()` and `closeAudioSession()`"
summary: "`openAudioSession()` and `closeAudioSession()`"
permalink: tau_api_recorder_open_audio_session.html
tags: [API, recorder]
keywords: API Recorder
---
# The &tau; Recorder API

--------------------------------------------------------------------------------------------------------------------

## `openAudioSession()` and `closeAudioSession()`

- [Dart API: openAudioSession](https://canardoux.github.io/tau/doc/flutter_sound/api/recorder/FlutterSoundRecorder/openAudioSession.html)
- [Dart API: closeAudioSession](https://canardoux.github.io/tau/doc/flutter_sound/api/recorder/FlutterSoundRecorder/closeAudioSession.html)


A recorder must be opened before used. A recorder correspond to an Audio Session. With other words, you must *open* the Audio Session before using it.
When you have finished with a Recorder, you must close it. With other words, you must close your Audio Session.
Opening a recorder takes resources inside the OS. Those resources are freed with the verb `closeAudioSession()`.

You MUST ensure that the recorder has been closed when your widget is detached from the UI.
Overload your widget's `dispose()` method to close the recorder when your widget is disposed.
In this way you will reset the player and clean up the device resources, but the recorder will be no longer usable.

```dart
@override
void dispose()
{
        if (myRecorder != null)
        {
            myRecorder.closeAudioSession();
            myPlayer = null;
        }
        super.dispose();
}
```

You maynot openAudioSession many recorders without releasing them.
You will be very bad if you try something like :
```dart
    while (aCondition)  // *DO'NT DO THAT*
    {
            flutterSound = FlutterSoundRecorder().openAudioSession(); // A **new** Flutter Sound instance is created and opened
            ...
    }
```

`openAudioSession()` and `closeAudioSession()` return Futures. You may not use your Recorder before the end of the initialization. So probably you will `await` the result of `openAudioSession()`. This result is the Recorder itself, so that you can collapse instanciation and initialization together with `myRecorder = await FlutterSoundPlayer().openAudioSession();`

The four optional parameters are used if you want to control the Audio Focus. Please look to [FlutterSoundPlayer openAudioSession()](player.md#openaudiosession-and-closeaudiosession) to understand the meaning of those parameters

*Example:*
```dart
    myRecorder = await FlutterSoundRecorder().openAudioSession();

    ...
    (do something with myRecorder)
    ...

    myRecorder.closeAudioSession();
    myRecorder = null;
```

------------------------------------------------------------------------------------------------------------------
