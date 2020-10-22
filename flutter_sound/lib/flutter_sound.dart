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

export 'package:flutter_sound_platform_interface/flutter_sound_platform_interface.dart';
export 'package:flutter_sound_platform_interface/flutter_sound_player_platform_interface.dart';
export 'package:flutter_sound_platform_interface/flutter_sound_recorder_platform_interface.dart';
export 'src/flutter_ffmpeg.dart';
export 'src/flutter_sound_player.dart';
export 'src/flutter_sound_recorder.dart';
export 'src/food.dart';
export 'src/flutter_sound_helper.dart';
export 'src/util/log.dart';
export 'src/util/recorded_audio.dart';
export 'src/util/ansi_color.dart';
export 'src/ui/grayed_out.dart';
export 'src/food.dart';

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
  '.pcm', // pcm8
  '.pcm', // pcmFloat32
];


enum Initialized {
  notInitialized,
  initializationInProgress,
  fullyInitialized,
}

