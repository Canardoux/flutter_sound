import 'package:flutter_sound/flutter_sound.dart';

/// Factory used to track what codec is currently selected.
class ActiveCodec {
  static final ActiveCodec _self = ActiveCodec._internal();

  Codec _codec = Codec.aacADTS;
  bool _encoderSupported = false;
  bool _decoderSupported = false;

  ///
  FlutterSoundRecorder recorderModule;

  /// Factory to access the active codec.
  factory ActiveCodec() {
    return _self;
  }
  ActiveCodec._internal();

  /// Set the active code for the the recording and player modules.
  void setCodec({bool withUI, Codec codec}) async {
     FlutterSoundPlayer player = FlutterSoundPlayer();
    if (withUI) {
      await player.openAudioSessionWithUI(focus: AudioFocus.requestFocusAndDuckOthers);
      _encoderSupported = await recorderModule.isEncoderSupported(codec);
      _decoderSupported = await player.isDecoderSupported(codec);
    } else {
      await player.openAudioSession(focus: AudioFocus.requestFocusAndDuckOthers);
      _encoderSupported = await recorderModule.isEncoderSupported(codec);
      _decoderSupported = await player.isDecoderSupported(codec);
    }
    _codec = codec;
  }

  /// [true] if the active coded is supported by the recorder
  bool get encoderSupported => _encoderSupported;

  /// [true] if the active coded is supported by the player
  bool get decoderSupported => _decoderSupported;

  /// returns the active codec.
  Codec get codec => _codec;
}
