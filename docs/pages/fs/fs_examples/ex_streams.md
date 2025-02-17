---
title:  "Dart Streams"
summary: "Audio Streams with Flutter Sound,"
permalink: fs-ex_streams.html
---
The example source [is there](https://github.com/canardoux/flutter_sound/blob/master/example/lib/streams/streams.dart). You can have a live run of the examples [here](/tau/fs/live/index.html).

The real interest of recording to a Stream is for example to feed a Speech-to-Text engine, or for processing the Live data in Dart in real time.

This example can record something to a Stream. It handle the stream to stored the data in memory.

Then, the user can play a Stream that read the data store in memory.

The example is just a little bit complicated because there are inside both a player stream and a recorder stream,
because the user can select if he/she wants to use streams interleaved or planed, and because he/she can select to use
Float32 PCM or Int16 PCM

You can also refer to the following examples that uses UInt8List:

- [Record To Stream](ex_record_to_stream)
- [Live Playback Without Backpressure](fs-ex_playback_from_stream_1)
- [Live Playback With Backpressure](fs-ex_playback_from_stream_2)

{% include image.html file="/fs/ExampleScreenShots/Streams.png" %}