import 'package:flutter_sound/flauto.dart';

import 'common.dart';

class MediaPath {
  static final MediaPath _self = MediaPath._internal();
  static const List<String> paths = [
    'flutter_sound_example.aac', // DEFAULT
    'flutter_sound_example.aac', // CODEC_AAC
    'flutter_sound_example.opus', // CODEC_OPUS
    'flutter_sound_example.caf', // CODEC_CAF_OPUS
    'flutter_sound_example.mp3', // CODEC_MP3
    'flutter_sound_example.ogg', // CODEC_VORBIS
    'flutter_sound_example.wav', // CODEC_PCM
  ];

  final List<String> _path = [null, null, null, null, null, null, null];
  t_MEDIA media = t_MEDIA.file;

  factory MediaPath() {
    return _self;
  }
  MediaPath._internal();

  bool get isAsset => media == t_MEDIA.asset;

  bool get isFile => media == t_MEDIA.file;

  bool get isBuffer => media == t_MEDIA.buffer;

  bool get isExampleFile => media == t_MEDIA.remoteExampleFile;

  void setCodecPath(t_CODEC codec, String path) {
    _path[codec.index] = path;
  }

  String pathForCodec(t_CODEC codec) {
    return _path[codec.index];
  }

  bool exists(t_CODEC codec) {
    return _path[codec.index] != null;
  }

 
}
