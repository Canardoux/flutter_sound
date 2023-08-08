/*
 * Copyright 2018, 2019, 2020, 2021 Dooboolab.
 *
 * This file is part of Flutter-Sound.
 *
 * Flutter-Sound is free software: you can redistribute it and/or modify
 * it under the terms of the Mozilla Public License version 2 (MPL2.0),
 * as published by the Mozilla organization.
 *
 * Flutter-Sound is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * MPL General Public License for more details.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */


#ifndef FLAUTO_H
#define FLAUTO_H

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
          
          /// pcm with a WebM format
          pcmWebM,
          
          /// Opus with a WebM format
          opusWebM,
          
          /// Vorbis with a WebM format
          vorbisWebM,
  
} t_CODEC;



typedef enum
{
        PLAYER_IS_STOPPED,
        PLAYER_IS_PLAYING,
        PLAYER_IS_PAUSED
} t_PLAYER_STATE;



typedef enum
{
     VERBOSE,
     DBG,
     INFO,
     WARNING,
     ERROR,
     WTF,
     NOTHING,
} t_LOG_LEVEL;



@interface Flauto : NSObject
{
}
@end

extern Flauto* theFlautoEngine ; // The singleton


#endif
