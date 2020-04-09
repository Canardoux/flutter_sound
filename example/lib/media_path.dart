import 'package:flutter_sound/flauto.dart';

import 'common.dart';

class MediaPath {
  static MediaPath _self = MediaPath._internal();
  static const List<String> paths = [
    'flutter_sound_example.aac', // DEFAULT
    'flutter_sound_example.aac', // CODEC_AAC
    'flutter_sound_example.opus', // CODEC_OPUS
    'flutter_sound_example.caf', // CODEC_CAF_OPUS
    'flutter_sound_example.mp3', // CODEC_MP3
    'flutter_sound_example.ogg', // CODEC_VORBIS
    'flutter_sound_example.wav', // CODEC_PCM
  ];

  List<String> _path = [null, null, null, null, null, null, null];
  t_MEDIA _media = t_MEDIA.FILE;

  factory MediaPath() {
    return _self;
  }
  MediaPath._internal();

  bool get isAsset => _media == t_MEDIA.ASSET;

  bool get isFile => _media == t_MEDIA.FILE;

  bool get isBuffer => _media == t_MEDIA.BUFFER;

  bool get isExampleFile => _media == t_MEDIA.REMOTE_EXAMPLE_FILE;

  void setCodecPath(t_CODEC codec, String path) {
    _path[codec.index] = path;
  }

  String pathForCodec(t_CODEC codec) {
    return _path[codec.index];
  }

  bool exists(t_CODEC codec) {
    return _path[codec.index] != null;
  }

  t_MEDIA get media => _media;

  set media(t_MEDIA media) => _media = media;
}
