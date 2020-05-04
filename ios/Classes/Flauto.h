//
//  Flauto.h
//  Pods
//
//  Created by larpoux on 24/03/2020.
//
/*
 * This file is part of Flutter-Sound (Flauto).
 *
 *   Flutter-Sound (Flauto) is free software: you can redistribute it and/or modify
 *   it under the terms of the Lesser GNU General Public License
 *   version 3 (LGPL3) as published by the Free Software Foundation.
 *
 *   Flutter-Sound (Flauto) is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the Lesser GNU General Public License
 *   along with Flutter-Sound (Flauto).  If not, see <https://www.gnu.org/licenses/>.
 */

#import <Flutter/Flutter.h>
#import <AVFoundation/AVFoundation.h>
#ifndef Flauto_h
#define Flauto_h


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
} t_CODEC;

typedef enum
{
        NOT_SET,
        FOR_PLAYING,   // Flutter_sound did it during startPlayer()
        FOR_RECORDING, // Flutter_sound did it during startRecorder()
        BY_USER        // The caller did it himself : flutterSound must not change that)
} t_SET_CATEGORY_DONE;



@interface Flauto : NSObject <FlutterPlugin, AVAudioPlayerDelegate>
{
}

@end

#endif /* Flauto_h */
