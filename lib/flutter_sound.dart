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


export 'src/flutter_ffmpeg.dart';
export 'src/flutter_sound_player.dart';
export 'src/flutter_sound_recorder.dart';
//export 'src/track_player.dart';
export 'src/flutter_sound_helper.dart';
export 'src/util/log.dart';
export 'src/util/ansi_color.dart';

export 'src/ui/recorder_playback_controller.dart'
            show RecorderPlaybackController;
export 'src/ui/sound_player_ui.dart' show SoundPlayerUI;
export 'src/ui/sound_recorder_ui.dart' show SoundRecorderUI;


const List<String> ext = [
  '.aac', // defaultCodec
  '.aac', // aacADTS
  '.opus', // opusOGG
  '_opus.caf', // opusCAF
  '.mp3', // mp3
  '.ogg', // vorbisOGG
  '.pcm', // pcm16
  '.wav', // pcm16WAV
  '.aiff', // pcm16AIFF
  '_pcm.caf', // pcm16CAF
  '.flac', // flac
  '.mp4', // aacMP4
  '.amr', // AMR-NB
  '.amr', // amr-WB
];

enum Codec {
  // this enum MUST be synchronized with fluttersound/AudioInterface.java
  // and ios/Classes/FlutterSoundPlugin.h

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

  /// AMR-NB
  amrNB,

  /// AMR-WB
  amrWB,

}


enum SessionCategory {
  ambient,
  multiRoute,
  playAndRecord,
  playback,
  record,
  soloAmbient,
  audioProcessing,
}


enum SessionMode
{
  modeDefault, // 'AVAudioSessionModeDefault',
  modeGameChat, //'AVAudioSessionModeGameChat',
  modeMeasurement, //'AVAudioSessionModeMeasurement',
  modeMoviePlayback, //'AVAudioSessionModeMoviePlayback',
  modeSpokenAudio, //'AVAudioSessionModeSpokenAudio',
  modeVideoChat, //'AVAudioSessionModeVideoChat',
  modeVideoRecording, // 'AVAudioSessionModeVideoRecording',
  modeVoiceChat, // 'AVAudioSessionModeVoiceChat',
  modeVoicePrompt, // 'AVAudioSessionModeVoicePrompt',
}

/// Used by [AudioPlayer.audioFocus]
/// to control the focus mode.
enum AudioFocus {
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
}


// Audio Flags
// -----------
const outputToSpeaker = 1;
const allowHeadset = 2;
const allowEarPiece = 4;
const allowBlueTooth = 8;
const allowAirPlay = 16;
const allowBlueToothA2DP = 32;

/*
final List<String> iosSessionCategory = [
  'AVAudioSessionCategoryAmbient',
  'AVAudioSessionCategoryMultiRoute',
  'AVAudioSessionCategoryPlayAndRecord',
  'AVAudioSessionCategoryPlayback',
  'AVAudioSessionCategoryRecord',
  'AVAudioSessionCategorySoloAmbient',
];

 */

// Values for AUDIO_FOCUS_GAIN on Android
enum AndroidFocusGain {
  defaultFocusGain,
  audioFocusGain,
  audioFocusGainTransient,
  audioFocusGainTransientMayDuck,
  audioFocusGainTransientExclusive,
}

// Options for setSessionCategory on iOS
const int iosMixWithOthers = 0x1;
const int iosDuckOthers = 0x2;
const int iosInterruptSpokenAudioAndMixWithOthers = 0x11;
const int iosAllowBluetooth = 0x4;
const int iosAllowBluetoothA2DP = 0x20;
const int iosAllowAirplay = 0x40;
const int iosDefaultToSpeaker = 0x8;
