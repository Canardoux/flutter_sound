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

import 'dart:async';
import 'dart:html' as html;

import 'package:meta/meta.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_recorder_platform_interface.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:flutter_sound_web/flutter_sound_player_web.dart';
import 'package:flutter_sound_web/flutter_sound_recorder_web.dart';



/// The web implementation of [FlutterSoundRecorderPlatform].
///
/// This class implements the `package:FlutterSoundPlayerPlatform` functionality for the web.
class FlutterSoundPlugin //extends FlutterSoundPlatform
{
        /// Registers this class as the default instance of [FlutterSoundPlatform].
        static void registerWith(Registrar registrar)
        {
                FlutterSoundPlayerWeb.registerWith(registrar);
                FlutterSoundRecorderWeb.registerWith(registrar);
        }
}
