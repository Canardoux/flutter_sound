import 'package:path/path.dart';

/// this enum MUST be synchronized with fluttersound/AudioInterface.java
/// and ios/Classes/FlutterSoundPlugin.h
enum Codec {
  /// This is the default codec. If used
  /// Flutter Sound will use the files extension to guess the codec.
  /// If the file extension doesn't match a known codec then
  /// Flutter Sound will throw an exception in which case you need
  /// pass one of the know codec.
  fromExtension,

  ///
  aac,

  ///
  opus,

  /// Apple encapsulates its bits in its own special envelope
  /// .caf instead of a regular ogg/opus (.opus).
  /// This is completely stupid, this is Apple.
  cafOpus,

  ///
  mp3,

  ///
  vorbis,

  /// PCM which is a Wav file.
  pcm,
}

/// Helper functions for the Codec enum becuase
/// dart's enums are crap.
class CodecHelper {
  /// Provides mappings from common file extensions to
  /// the codec those files use.
  static const extensionToCodecMap = <String, Codec>{
    '.aac': Codec.aac,
    '.wav': Codec.pcm,
    '.opus': Codec.opus,
    '.caf': Codec.cafOpus,
    '.mp3': Codec.mp3,
    '.ogg': Codec.vorbis,
    '.pcm': Codec.pcm,
  };

  /// Returns the codec for the given [path]
  /// by using the filename's extension.
  /// If the filename's extension doesn't match one of the supported
  /// file extensions listed in [extensionToCodecMap] then
  /// null is returned.
  static Codec determineCodec(String path) {
    var ext = extension(path);

    var codec = extensionToCodecMap[ext];

    return codec;
  }
}

/// Throw if an unsupported codec is passed.
/// Different OS's support a different set of codecs.
/// This can also be thrown if you pass in fromExtension
/// and the file extension isn't recognized.
class CodecNotSupportedException implements Exception {
  final String _message;

  ///
  CodecNotSupportedException(this._message);

  String toString() => _message;
}
