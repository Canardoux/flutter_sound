---
title:  "Play Stream with flow control"
summary: "Play from a dart stream, with flow control."
permalink: fs-ex_playback_from_stream_2.html
---

The example source [is there](https://github.com/canardoux/flutter_sound/blob/master/example/lib/livePlaybackWithBackPressure/live_playback_with_back_pressure.dart). You can have a live run of the examples [here](/tau/fs/live/index.html).

An example showing how to play Live Data with back pressure. It feeds a live stream, waiting that the futures are completed for each block.

This example get the data from an asset file, which is completely stupid : if an App wants to play an asset file he must use `StartPlayer(fromBuffer:)`.

If you do not need any back pressure, you can see another simple example : [LivePlaybackWithoutBackPressure.dart](fs-ex_playback_from_stream_1.html).
This other example is a little bit simpler because the App does not need to await the playback for each block before playing another one.

- [Record To Stream](ex_record_to_stream)
- [Live Playback Without Backpressure](fs-ex_playback_from_stream_1)

{% include image.html file="/fs/ExampleScreenShots/PlaybackWithBackPressure.png" %}