---
title:  "openRecorder()"
description: "`openRecorder()` and `closeRecorder()`"
summary: "`openRecorder()` and `closeRecorder()`"
permalink: tau_api_recorder_open_audio_session.html
tags: [api,recorder]
keywords: API Recorder
---
# The &tau; Recorder API

--------------------------------------------------------------------------------------------------------------------

## `openRecorder()` and `closeRecorder()`

- Dart API: [openRecorder](pages/flutter-sound/api/recorder/FlutterSoundRecorder/openRecorder.html)
- Dart API: [closeRecorder](pages/flutter-sound/api/recorder/FlutterSoundRecorder/closeRecorder.html)


A recorder must be opened before used.
Opening a recorder takes resources inside the OS. Those resources are freed with the verb `closeRecorder()`.

You MUST ensure that the recorder has been closed when your widget is detached from the UI.
Overload your widget's `dispose()` method to close the recorder when your widget is disposed.
In this way you will reset the player and clean up the device resources, but the recorder will be no longer usable.

`closeRecorder()` delete all the temporary files created with `startRecorder()`

```dart
@override
void dispose()
{
        if (myRecorder != null)
        {
            myRecorder.closeRecorder();
            myPlayer = null;
        }
        super.dispose();
}
```

You maynot openAudioSession many recorders without releasing them.

`openRecorder()` and `closeRecorder()` return Futures. You may not use your Recorder before the end of the initialization. So probably you will `await` the result of `openRecorder()`. This result is the Recorder itself, so that you can collapse instanciation and initialization together with `myRecorder = await FlutterSoundPlayer().openRecorder();`


*Example:*
<ul id="profileTabs" class="nav nav-tabs">
    <li class="active"><a href="#dart" data-toggle="tab">Dart</a></li>
    <li><a href="#javascript" data-toggle="tab">Javascript</a></li>
</ul>
<div class="tab-content">

<div role="tabpanel" class="tab-pane active" id="dart">

<pre>
    myRecorder = await FlutterSoundRecorder().openRecorder();

    ...
    (do something with myRecorder)
    ...

    myRecorder.closeRecorder();
    myRecorder = null;
</pre>

</div>

<div role="tabpanel" class="tab-pane" id="javascript">
<pre>
        Lorem ipsum ...
</pre>
</div>

</div>


------------------------------------------------------------------------------------------------------------------
