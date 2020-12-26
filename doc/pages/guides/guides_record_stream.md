---
title:  "Guides"
description: "Recording PCM-16 to a Dart Stream."
summary: "Recording PCM-16 to a Dart Stream."
permalink: guides_record_stream.html
tags: [guide]
keywords: guides
---

---------------

## Recording PCM-16 to a Dart Stream

Please, remember that actually, Flutter Sound does not support Floating Point PCM data, nor records with more that one audio channel. On Flutter Sound, **Raw PCM is only PCM-LINEAR 16 monophony**

To record a Live PCM file, when calling the verb `startRecorder()`, you specify the parameter `toStream:` with you Stream sink, instead of the parameter `toFile:`. This parameter is a StreamSink that you can listen to, for processing the input data.

## Notes :

* This new functionnality needs, at least, an Android SDK &gt;= 21
* This new functionnality works better with Android minSdk &gt;= 23, because previous SDK was not able to do UNBLOCKING `write`.

_Example_

You can look to the [simple example](https://github.com/dooboolab/flutter_sound/blob/master/flutter_sound/example/lib/recordToStream/record_to_stream_example.dart) provided with Flutter Sound.

```dart
  IOSink outputFile = await createFile();
  StreamController<Food> recordingDataController = StreamController<Food>();
  _mRecordingDataSubscription =
          recordingDataController.stream.listen
            ((Uint8List buffer)
              {
                outputFile.add(buffer);
              }
            );
  await _mRecorder.startRecorder(
        toStream: recordingDataController.sink,
        codec: Codec.pcm16,
        numChannels: 1,
        sampleRate: 48000,
  );
```

---------------
