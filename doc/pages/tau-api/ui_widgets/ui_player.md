---
title:  "UI Widgets API"
description: "UIPlayer"
summary: "UIPlayer"
permalink: tau_api_widgets_ui_player.html
tags: [api,ui,widget]
keywords: API, UI, widgets
---
# SoundPlayerUI


## How to use
First import the modules
``` import 'flutter_sound.dart```


The SoundPlayerUI provides a Playback widget styled after the HTML 5 audio player.![](https://raw.githubusercontent.com/bsutton/sounds/master/images/SoundPlayerUI.png)

The player displays a loading indicator and allows the user to pause/resume/skip via the progress bar.

You can also pause/resume the player via an api call to SoundPlayerUI's state using a GlobalKey.

The SoundPlayerUI widget allows you to playback audio from multiple sources:

* File
* Asset
* URL
* Buffer

## MediaFormat

When using the `SoundPlayerUI` you MUST pass a `Track` that has been initialised with a supported `MediaFormat`.

The Widget needs to obtain the duration of the audio that it is play and that can only be done if we know the `MediaFormat` of the Widget.

If you pass a `Track` that wasn't constructed with a `MediaFormat` then a `MediaFormatException` will be thrown.

The `MediaFormat` must also be natively supported by the OS. See `mediaformat.md` for additional details on checking for a supported format.

### Example:

```dart
Track track;

/// global key so we can pause/resume the player via the api.
var playerStateKey = GlobalKey<SoundPlayerUIState>();

void initState()
{
   track = Track.fromAsset('assets/rock.mp3', mediaFormat: Mp3MediaFormat());
}

Widget build(BuildContext build)
{
    var player = SoundPlayerUI.fromTrack(track, key: playerStateKey);
    return
        Column(child: [
            player,
            RaisedButton("Pause", onPressed: () => playerState.currentState.pause()),
            RaisedButton("Resume", onPressed: () => playerState.currentState.resume())
        ]);
}
```

`Sounds` uses Track as the primary method of handing around audio data.

You can also dynamically load a `Track` when the user clicks the 'Play' button on the `SoundPlayerUI` widget. This allows you to delay the decision on what Track is going to be played until the user clicks the 'Play' button.

```dart
Track track;


void initState()
{
   track = Track.fromAsset('assets/rock.mp3', mediaFormat: Mp3MediaFormat());
}

Widget build(BuildContext build)
{
    return SoundPlayerUI.fromLoader((context) => loadTrack());
}

Future<Track> loadTrack()
{
    Track track;
    track = Track.fromAsset('assets/rock.mp3', mediaFormat: Mp3MediaFormat());

    track.title = "Asset playback.";
    track.artist = "By sounds";
}
```
