import 'package:flutter_sound/flutter_sound.dart';

/// Factory used to track what codec is currently selected.
class ActiveCodec {
  static final ActiveCodec _self = ActiveCodec._internal();

  Codec _codec = Codec.codecAac;
  bool _encoderSupported = false;
  bool _decoderSupported = false;

  ///
  SoundPlayer playerModule;

  ///
  SoundRecorder recorderModule;

  /// Factory to access the active codec.
  factory ActiveCodec() {
    return _self;
  }
  ActiveCodec._internal();

  /// Set the active code for the the recording and player modules.
  void setCodec(Codec codec) async {
    _encoderSupported = await recorderModule.isSupported(codec);
    _decoderSupported = await playerModule.isSupported(codec);

    _codec = codec;
  }

  /// [true] if the active coded is supported by the recorder
  bool get encoderSupported => _encoderSupported;

  /// [true] if the active coded is supported by the player
  bool get decoderSupported => _decoderSupported;

  /// returns the active codec.
  Codec get codec => _codec;
}
