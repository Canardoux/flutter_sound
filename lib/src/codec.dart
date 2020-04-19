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

/// this enum MUST be synchronized with fluttersound/AudioInterface.java
/// and ios/Classes/FlutterSoundPlugin.h
enum Codec {

  /// AAC codec in an ADTS container
  aacADTS,

  /// OPUS in an OGG container
  opusOGG,

  /// Apple encapsulates its bits in its own special envelope
  /// .caf instead of a regular ogg/opus (.opus).
  /// This is completely stupid, this is Apple.
  opusCAF,

  /// For those who really insist about supporting MP3. Shame on you !
  mp3,

  /// VORBIS in a OGG container
  vorbisOGG,

  /// Linear 16 PCM
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
