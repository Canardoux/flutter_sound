---
title:  "Record to stream"
summary: "Record to a dart stream"
permalink: fs-ex_record_to_stream.html
---

The example source [is there](https://github.com/canardoux/flutter_sound/blob/master/example/lib/recordToStream/record_to_stream_example.dart). You can have a live run of the examples [here](/tau/fs/live/index.html).

This is an example showing how to record to a Dart Stream. It writes all the recorded data from a Stream to a File, which is completely stupid: if an App wants to record something to a File, it must not use streams.

The real interest of recording to a Stream is for example to feed a
Speech-to-Text engine, or for processing the Live data in Dart in real time.
 
 You can also refer to the following example: 
 - [Dart Streams](fs-ex_streams.html):

{% include image.html file="/fs/ExampleScreenShots/RecordToStream.png" %}