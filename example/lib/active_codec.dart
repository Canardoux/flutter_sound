import 'package:flutter_sound/flauto.dart';
import 'package:flutter_sound/flutter_sound_player.dart';
import 'package:flutter_sound/flutter_sound_recorder.dart';

class ActiveCodec {
  static ActiveCodec _self = ActiveCodec._internal();

  t_CODEC _codec = t_CODEC.CODEC_AAC;
  bool _encoderSupported = false;
  bool _decoderSupported = false;

  FlutterSoundPlayer _playerModule;
  FlutterSoundRecorder _recorderModule;

  factory ActiveCodec() {
    return _self;
  }
  ActiveCodec._internal();

  set playerModule(FlutterSoundPlayer playerModule) =>
      _playerModule = playerModule;
  set recorderModule(FlutterSoundRecorder recorderModule) =>
      _recorderModule = recorderModule;

  void setCodec(t_CODEC codec) async {
    _encoderSupported = await _recorderModule.isEncoderSupported(codec);
    _decoderSupported = await _playerModule.isDecoderSupported(codec);

    _codec = codec;
  }

  bool get encoderSupported => _encoderSupported;
  bool get decoderSupported => _decoderSupported;

  t_CODEC get codec => _codec;
}
