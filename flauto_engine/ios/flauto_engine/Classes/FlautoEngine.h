/*
 * Copyright 2018, 2019, 2020 Dooboolab.
 *
 * This file is part of Flutter-Sound.
 *
 * Flutter-Sound is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License version 3 (LGPL-V3), as published by
 * the Free Software Foundation.
 *
 * Flutter-Sound is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with Flutter-Sound.  If not, see <https://www.gnu.org/licenses/>.
 */



// this enum MUST be synchronized with lib/flutter_sound.dart and fluttersound/AudioInterface.java
typedef enum
{

  /// This is the default codec. If used
  /// Flutter Sound will use the files extension to guess the codec.
  /// If the file extension doesn't match a known codec then
  /// Flutter Sound will throw an exception in which case you need
  /// pass one of the know codec.
  defaultCodec,

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

  /// VORBIS in an OGG container
  vorbisOGG,

  /// Linear 16 PCM, without envelope
  pcm16,

  /// Linear 16 PCM, which is a Wave file.
  pcm16WAV,


  /// Linear 16 PCM, which is a AIFF file
  pcm16AIFF,

  /// Linear 16 PCM, which is a CAF file
  pcm16CAF,

  /// FLAC
  flac,

  /// AAC in a MPEG4 container
  aacMP4,
  
  // AMR-NB
  amrNB,
  
  /// AMR-WB
  amrWB,

  /// Raw PCM Linear 8
  pcm8,

  /// Raw PCM with 32 bits Floating Points
  pcmFloat32,
  
} t_CODEC;


external FlautoEngine* theFlautoEngine ; // The singleton
@interface FlautoEngine : NSObject
{
}

@end

