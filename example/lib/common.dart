import 'dart:io';

import 'package:flutter_sound/flauto.dart';
import 'package:intl/intl.dart';

import 'media_path.dart';

enum t_MEDIA {
  FILE,
  BUFFER,
  ASSET,
  STREAM,
  REMOTE_EXAMPLE_FILE,
}

Future<double> getDuration(t_CODEC codec) async {
  Future<double> duration;
  switch (MediaPath().media) {
    case t_MEDIA.FILE:
    case t_MEDIA.BUFFER:
      int d =
          await flutterSoundHelper.duration(MediaPath().pathForCodec(codec));
      duration = Future.value(d != null ? d / 1000.0 : null);
      break;
    case t_MEDIA.ASSET:
      duration = null;
      break;
    case t_MEDIA.REMOTE_EXAMPLE_FILE:
      duration = null;
      break;
    case t_MEDIA.STREAM:
      duration = null;
      break;
  }
  return duration;
}

String formatDuration(double duration) {
  DateTime date =
      DateTime.fromMillisecondsSinceEpoch(duration.toInt(), isUtc: true);
  return DateFormat('mm:ss', 'en_GB').format(date);
}

List<String> assetSample = [
  'assets/samples/sample.aac',
  'assets/samples/sample.aac',
  'assets/samples/sample.opus',
  'assets/samples/sample.caf',
  'assets/samples/sample.mp3',
  'assets/samples/sample.ogg',
  'assets/samples/sample.wav',
];

Future<bool> fileExists(String path) async {
  return await File(path).exists();
}
