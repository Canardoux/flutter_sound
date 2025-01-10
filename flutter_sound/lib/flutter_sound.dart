/*
 * Copyright 2018, 2019, 2020 Dooboolab.
 * Copyright 2021, 2022, 2023, 2024 Canardoux.
 *
 * This file is part of Flutter-Sound.
 *
 * Flutter-Sound is free software: you can redistribute it and/or modify
 * it under the terms of the Mozilla Public License version 2 (MPL-2.0),
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
///library util;
export 'public/util/flutter_sound_helper.dart';
