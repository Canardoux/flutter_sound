# Shade/Notification area

A number of Platforms \(android/IOS\) support the concept of a 'Shade' or 'notification' area with the ability to control audio playback via the Shade.

When using a Shade a Platform may also allow the user to control the media playback from the Platform's 'Lock' screen.

{% hint style="info" %}
Using a Shade does not stop you from also displaying an in app Widget to control audio. The SoundPlayerUI widget will work in conjunction with the Shade.
{% endhint %}

The Shade may also display information contained in the [Track](../api/track.md) such as Album, Artist of artwork.

A Shade often allows the user to pause and resume audio as well skip forward a track and skip backward to the prior Track.

Sounds allows you to enable the Shade controls when you  start playback. It also allows you \(where the Platform supports it\) to control which of the media buttons are displayed \(pause, resume, skip forward, skip backwards\).

When you app runs on a user's device you can determine what features the Platform supports be calling one or more of the 'is' method on the [SoundPlayer](../api/soundplayer.md) class.

| Method |  |
| :--- | :--- |
| isShadeSupported | True if the Platform supports displaying Track information on a the OS's Shade. |
| isShadePauseSupported | True if the Platform supports a 'Pause/Resume' button on the Shade. |
| isShadeSkipForwardSupported | True if the Platform supports a Skip Forward button on the Shade. |
| isShadeSkipBackwardsSupported | True if the Platform supports a Skip Backwards button on the Shade. |

To start audio playback using the Shade use:

```text
SoundPlayer.withShadeUI(track);
```

The `withShadeUI`constuctor allows you to control which of the Shade buttons are displayed. The Platform MAY choose to ignore any of the button choices you make.

## Skipping Tracks

If you allow the Shade to display the Skip Forward and Skip Back buttons you must provide callbacks for the onSkipForward and on onSkipBackward methods.  When the user clicks the respective buttons you will receive the relevant callback.

```text
var player = SoundPlayer.withShadeUI(track, canSkipBackward:true
    , canSkipForward:true);
player.onSkipBackwards = () => player.startPlayer(getPreviousTrack());
player.onSkipForwards = () => player.startPlayer(getNextTrack());
```



