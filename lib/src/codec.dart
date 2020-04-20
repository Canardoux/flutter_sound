/*
 * This file is part of Flutter-Sound.
 *
 *   Flutter-Sound is free software: you can redistribute it and/or modify
 *   it under the terms of the Lesser GNU General Public License
 *   version 3 (LGPL3) as published by the Free Software Foundation.
 *
 *   Flutter-Sound is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the Lesser GNU General Public License
 *   along with Flutter-Sound.  If not, see <https://www.gnu.org/licenses/>.
 */
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
  aacADTS,

  ///
  opusOGG,

  /// AAC codec in an ADTS container
  aacADTS,

  /// OPUS in an OGG container
  opusOGG,

  /// Apple encapsulates its bits in its own special envelope
  /// .caf instead of a regular ogg/opus (.opus).
  /// This is completely stupid, this is Apple.
  cafOpus,
  
  /// For those who really insist about supporting MP3. Shame on you !
  mp3,

  /// VORBIS in a OGG container
  vorbisOGG,

  /// Linear 16 PCM, which is a Wav file.
  pcm,

  /// AAC codec in a MPEG4 container
  aacLC,

  /// AAC codec in a 3GP container
  aac3GP,

  /// AAC in a MPEG4 container
  aacMP4,

  /// PCM in a .wav container
  wav,

  ///
  flac,
}

/// Helper functions for the Codec enum becuase
/// dart's enums are crap.
class CodecHelper {
  /// Provides mappings from common file extensions to
  /// the codec those files use.
  static const extensionToCodecMap = <String, Codec>{
    '.aac': Codec.aacADTS,
    '.wav': Codec.pcm,
    '.opus': Codec.opusOGG,
    '.caf': Codec.cafOpus,
    '.mp3': Codec.mp3,
    '.ogg': Codec.vorbisOGG,
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
