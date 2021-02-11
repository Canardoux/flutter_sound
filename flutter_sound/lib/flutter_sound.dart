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

// The three interfaces to the platform
// ------------------------------------

/// ------------------------------------------------------------------
/// # The Flutter Sound library
///
/// Flutter Sound is composed with four main modules/classes
/// - [FlutterSound]. This is the main Flutter Sound module.
/// - [FlutterSoundPlayer]. Everything about the playback functions
/// - [FlutterSoundRecorder]. Everything about the recording functions
/// - [FlutterSoundHelper]. Some utilities to manage audio data.
/// And two modules for the Widget UI
/// - [SoundPlayerUI]
/// - [SoundRecorderUI]
/// ------------------------------------------------------------------
//library flutter_sound;

// The interfaces to the platforms specific implementations
// --------------------------------------------------------
//export 'package:flutter_sound_platform_interface/flutter_sound_platform_interface.dart';

/// everything : no documentation
/// @nodoc
library everything;

export 'package:flutter_sound_platform_interface/flutter_sound_platform_interface.dart';

/// Main
///library tau;
export 'public/flutter_sound_player.dart';
export 'public/flutter_sound_recorder.dart';
export 'public/tau.dart';

///
///library UI;
export 'public/ui/recorder_playback_controller.dart';
export 'public/ui/sound_player_ui.dart';
export 'public/ui/sound_recorder_ui.dart';

///
///library util;
export 'public/util/flutter_sound_ffmpeg.dart';
export 'public/util/flutter_sound_helper.dart';
export 'public/util/log.dart';
