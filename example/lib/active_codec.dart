import 'package:flutter_sound/flauto.dart';
import 'package:flutter_sound/flutter_sound_player.dart';
import 'package:flutter_sound/flutter_sound_recorder.dart';

class ActiveCodec {
  static final ActiveCodec _self = ActiveCodec._internal();

  t_CODEC _codec = t_CODEC.CODEC_AAC;
  bool _encoderSupported = false;
  bool _decoderSupported = false;

  FlutterSoundPlayer playerModule;
  FlutterSoundRecorder recorderModule;

  factory ActiveCodec() {
    return _self;
  }
  ActiveCodec._internal();

  void setCodec(t_CODEC codec) async {
    _encoderSupported = await recorderModule.isEncoderSupported(codec);
    _decoderSupported = await playerModule.isDecoderSupported(codec);

    _codec = codec;
  }

  bool get encoderSupported => _encoderSupported;
  bool get decoderSupported => _decoderSupported;

  t_CODEC get codec => _codec;
}
