import 'dart:io';

import 'package:flutter_sound/flauto.dart';
import 'package:intl/intl.dart';

import 'media_path.dart';

enum t_MEDIA {
  /// The media is stored in a local file
  file,
  // The media is stored in a in memory buffer
  buffer,
  // The media is stored in an asset.
  asset,
  // The media is being streamed
  stream,
  // The media is a remote sample file.
  remoteExampleFile,
}

Future<double> getDuration(t_CODEC codec) async {
  Future<double> duration;
  switch (MediaPath().media) {
    case t_MEDIA.file:
    case t_MEDIA.buffer:
      var d =
          await flutterSoundHelper.duration(MediaPath().pathForCodec(codec));
      duration = Future.value(d != null ? d / 1000.0 : null);
      break;
    case t_MEDIA.asset:
      duration = null;
      break;
    case t_MEDIA.remoteExampleFile:
      duration = null;
      break;
    case t_MEDIA.stream:
      duration = null;
      break;
  }
  return duration;
}

String formatDuration(double duration) {
  var date = DateTime.fromMillisecondsSinceEpoch(duration.toInt(), isUtc: true);
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
