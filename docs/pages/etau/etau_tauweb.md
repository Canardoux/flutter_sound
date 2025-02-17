---
title:  "Tauweb"
summary: "Tauweb : an `Etau` implementation for Flutter Web"
permalink: etau-tauweb.html
---

## RecordToStream

[RecordToStream](https://github.com/dooboolab/flutter_sound/blob/master/flutter_sound/example/lib/recordToStream/record_to_stream_example.dart)

{% include image.html file="examples/record_to_stream.png" %}

This is an example showing how to record to a Dart Stream. It writes all the recorded data from a Stream to a File, which is completely stupid: if an App wants to record something to a File, it must not use Streams.

The real interest of recording to a Stream is for example to feed a Speech-to-Text engine, or for processing the Live data in Dart in real time.

The complete example source [is there](https://github.com/dooboolab/flutter_sound/blob/master/flutter_sound/example/lib/recordToStream/record_to_stream_example.dart)
