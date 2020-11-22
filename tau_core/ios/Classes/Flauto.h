/*
 * Copyright 2018, 2019, 2020 Dooboolab.
 *
 * This file is part of the Tau project.
 *
 * Tau is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License version 3 (LGPL-V3), as published by
 * the Free Software Foundation.
 *
 * Tau is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with the Tau project.  If not, see <https://www.gnu.org/licenses/>.
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




/// Used by [AudioPlayer.audioFocus]
/// to control the focus mode.
typedef enum
{
          requestFocus,

          /// request focus and allow other audio
          /// to continue playing at their current volume.
          requestFocusAndKeepOthers,

          /// request focus and stop other audio playing
          requestFocusAndStopOthers,

          /// request focus and reduce the volume of other players
          /// In the Android world this is know as 'Duck Others'.
          requestFocusAndDuckOthers,
          
          requestFocusAndInterruptSpokenAudioAndMixWithOthers,
          
          requestFocusTransient,
          requestFocusTransientExclusive,


          /// relinquish the audio focus.
          abandonFocus,

          doNotRequestFocus,
} t_AUDIO_FOCUS;



typedef enum
{
          ambient,
          multiRoute,
          playAndRecord,
          playback,
          record,
          soloAmbient,
          audioProcessing,
} t_SESSION_CATEGORY ;


typedef enum
{
          modeDefault, // 'AVAudioSessionModeDefault',
          modeGameChat, //'AVAudioSessionModeGameChat',
          modeMeasurement, //'AVAudioSessionModeMeasurement',
          modeMoviePlayback, //'AVAudioSessionModeMoviePlayback',
          modeSpokenAudio, //'AVAudioSessionModeSpokenAudio',
          modeVideoChat, //'AVAudioSessionModeVideoChat',
          modeVideoRecording, // 'AVAudioSessionModeVideoRecording',
          modeVoiceChat, // 'AVAudioSessionModeVoiceChat',
          // ONLY iOS 12.0 // modeVoicePrompt, // 'AVAudioSessionModeVoicePrompt',
}  t_SESSION_MODE;


typedef enum
{
          speaker,
          headset,
          earPiece,
          blueTooth,
          blueToothA2DP,
          airPlay
} t_AUDIO_DEVICE;


typedef enum
{
        PLAYER_IS_STOPPED,
        PLAYER_IS_PLAYING,
        PLAYER_IS_PAUSED
} t_PLAYER_STATE;



typedef enum
{
          defaultSource,
          microphone,
          voiceDownlink, // (if someone can explain me what it is, I will be grateful ;-) )
          camCorder,
          remote_submix,
          unprocessed,
          voice_call,
          voice_communication,
          voice_performance,
          voice_recognition,
          voiceUpLink,
          bluetoothHFP,
          headsetMic,
          lineIn
} t_AUDIO_SOURCE;

// Audio Flags
// -----------
#define outputToSpeaker  1
// NOT USED // const int allowHeadset = 2;
// NOT USED // const int allowEarPiece = 4;
#define allowBlueTooth  8
#define allowAirPlay 16
#define allowBlueToothA2DP  32


@interface Flauto : NSObject
{
}
@end

extern Flauto* theFlautoEngine ; // The singleton


#endif
