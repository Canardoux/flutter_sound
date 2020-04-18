/// this enum MUST be synchronized with fluttersound/AudioInterface.java
/// and ios/Classes/FlutterSoundPlugin.h
enum Codec {
  ///
  defaultCodec,

  ///
  codecAac,

  ///
  codecOpus,

  /// Apple encapsulates its bits in its own special envelope
  /// .caf instead of a regular ogg/opus (.opus).
  /// This is completely stupid, this is Apple.
  codecCafOpus,

  ///
  codecMp3,

  ///
  codecVorbis,

  ///
  codecPcm,
}
