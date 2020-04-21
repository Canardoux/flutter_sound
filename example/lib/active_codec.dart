import 'package:flutter_sound/flutter_sound.dart';

/// Factory used to track what codec is currently selected.
class ActiveCodec {
  static final ActiveCodec _self = ActiveCodec._internal();

  Codec _codec = Codec.aac;
  bool _encoderSupported = false;
  bool _decoderSupported = false;

  ///
  SoundRecorder recorderModule;

  /// Factory to access the active codec.
  factory ActiveCodec() {
    return _self;
  }
  ActiveCodec._internal();

  /// Set the active code for the the recording and player modules.
  void setCodec(bool withUI, Codec codec) async {
    _encoderSupported = await recorderModule.isSupported(codec);
    AudioSession session;
    if (withUI)
      session = AudioSession.withUI();
    else
      session = AudioSession.noUI();

    _decoderSupported = await session.isSupported(codec);

    _codec = codec;
  }

  /// [true] if the active coded is supported by the recorder
  bool get encoderSupported => _encoderSupported;

  /// [true] if the active coded is supported by the player
  bool get decoderSupported => _decoderSupported;

  /// returns the active codec.
  Codec get codec => _codec;
}
