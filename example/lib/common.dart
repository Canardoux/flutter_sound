import 'dart:io';

import 'package:flutter_sound/flutter_sound.dart';
import 'package:intl/intl.dart';

import 'media_path.dart';

/// Describes how the media is stored.
enum MediaStorage {
  /// The media is stored in a local file
  file,

  /// The media is stored in a in memory buffer
  buffer,

  /// The media is stored in an asset.
  asset,

  /// The media is being streamed
  stream,

  /// The media is a remote sample file.
  remoteExampleFile,
}

/// get the duration for the media with the given codec.
Future<double> getDuration(Codec codec) async {
  Future<double> duration;
  switch (MediaPath().media) {
    case MediaStorage.file:
    case MediaStorage.buffer:
      var d = await FFMpegUtil().duration(MediaPath().pathForCodec(codec));
      duration = Future.value(d != null ? d / 1000.0 : null);
      break;
    case MediaStorage.asset:
      duration = null;
      break;
    case MediaStorage.remoteExampleFile:
      duration = null;
      break;
    case MediaStorage.stream:
      duration = null;
      break;
  }
  return duration;
}

/// formats a duration for printing.
///  mm:ss
String formatDuration(Duration duration) {
  var date =
      DateTime.fromMillisecondsSinceEpoch(duration.inMilliseconds, isUtc: true);
  return DateFormat('mm:ss', 'en_GB').format(date);
}

/// the set of samples availble as assets.
List<String> assetSample = [
  'assets/samples/sample.aac',
  'assets/samples/sample.aac',
  'assets/samples/sample.opus',
  'assets/samples/sample.caf',
  'assets/samples/sample.mp3',
  'assets/samples/sample.ogg',
  'assets/samples/sample.wav',
];

/// Checks if the past file exists
bool fileExists(String path) {
  return File(path).existsSync();
}

/// checks if the given directory exists.
bool directoryExists(String path) {
  return Directory(path).existsSync();
}
