---
title:  "Lock-screen"
description: "Controls on the lock-screen."
summary: "The &tau; Project allows the App to be controlled from the Lock Screen."
permalink: guides_lock_screen.html
tags: [guide]
keywords: lock_screen
---
# Notification/Lock Screen

A number of Platforms \(android/IOS\) support the concept of a 'Shade' or 'notification' area with the ability to control audio playback via the Shade.

When using a Shade a Platform may also allow the user to control the media playback from the Platform's 'Lock' screen.

Using a Shade does not stop you from also displaying an in app Widget to control audio. The SoundPlayerUI widget will work in conjunction with the Shade.

The Shade may also display information contained in the Track such as Album, Artist of artwork.

A Shade often allows the user to pause and resume audio as well skip forward a track and skip backward to the prior Track.

τ allows you to enable the Shade controls when you start playback. It also allows you \(where the Platform supports it\) to control which of the media buttons are displayed \(pause, resume, skip forward, skip backwards\).

To start audio playback using the Shade use:

```text
SoundPlayer.withShadeUI(track);
```

The `withShadeUI`constuctor allows you to control which of the Shade buttons are displayed. The Platform MAY choose to ignore any of the button choices you make.

## Skipping Tracks

If you allow the Shade to display the Skip Forward and Skip Back buttons you must provide callbacks for the onSkipForward and on onSkipBackward methods. When the user clicks the respective buttons you will receive the relevant callback.

```text
var player = SoundPlayer.withShadeUI(track, canSkipBackward:true
    , canSkipForward:true);
player.onSkipBackwards = () => player.startPlayer(getPreviousTrack());
player.onSkipForwards = () => player.startPlayer(getNextTrack());
```

