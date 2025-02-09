---
title:  "Widgets"
description: "The &tau; built-in widgets."
summary: "The &tau; Project offers two built-in widgets."
permalink: guides_ui.html
tags: [guide]
keywords: ui_widgets
---
# Widgets

The easiest way to start with Sounds is to use one of the built in Widgets.

* SoundPlayerUI
* SoundRecorderUI
* RecorderPlaybackController

If you don't like any of the provided Widgets you can build your own from scratch.

The Sounds widgets are all built using the public Sounds API and also provide working examples when building your own widget.

## SoundPlayerUI

The SoundPlayerUI widget provides a Playback widget styled after the HTML 5 audio player.![](https://raw.githubusercontent.com/bsutton/sounds/master/images/SoundPlayerUI.png)

The player displays a loading indicator and allows the user to pause/resume/skip via the progress bar.

You can also pause/resume the player via an api call to SoundPlayerUI's state using a GlobalKey.

The [SoundPlayerUI](https://github.com/dooboolab/flutter_sound/tree/e09bcd3935cdb61ae166e1ad562b7a20512c884d/doc/api/soundplayerui.md) api documentation provides examples on using the SoundPlayerUI widget.

## SoundRecorderUI

The SoundRecorderUI widget provide a simple UI for recording audio.

The audio is recorded to a Track.

TODO: add image here.

The [SoundRecorderUI](https://github.com/dooboolab/flutter_sound/tree/e09bcd3935cdb61ae166e1ad562b7a20512c884d/doc/api/soundrecorderui.md) api documentation provides examples on using the [SoundRecorderUI](https://github.com/dooboolab/flutter_sound/tree/e09bcd3935cdb61ae166e1ad562b7a20512c884d/doc/api/soundrecorderui.md) widget.

## RecorderPlaybackController

The RecorderPlaybackController is a specialised Widget which is used to co-ordinate a paired SoundPlayerUI and a SoundRecorderUI widgets.

Often when providing an interface to record audio you will want to allow the user to playback the audio after recording it. However you don't want the user to try and start the playback before the recording is complete.

The RecorderPlaybackController widget does not have a UI \(its actually an InheritedWidget\) but rather is used to as a bridge to allow the paired SoundPlayerUI and SoundRecorderUI to communicate with each other.

The RecorderPlaybackController co-ordinates the UI state between the two components so that playback and recording cannot happen at the same time.

See the API documenation on [RecorderPlaybackController](https://github.com/dooboolab/flutter_sound/tree/e09bcd3935cdb61ae166e1ad562b7a20512c884d/doc/api/recorderplaybackcontroller.md) for examples of how to use it.

