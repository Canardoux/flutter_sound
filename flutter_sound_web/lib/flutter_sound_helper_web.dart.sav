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
import 'package:flutter_sound_platform_interface/flutter_sound_helper_platform_interface.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';


/// The web implementation of [FlutterSoundHelper].
///
/// This class implements the `package:flutter_sound_helper` functionality for the web.
class FlutterSoundHelperWeb extends FlutterSoundPlatform {
  /// Registers this class as the default instance of [FlutterSoundHelperPlatform].
  static void registerWith(Registrar registrar) {
    FlutterSoundHelperPlatform.instance = FlutterSoundHelperWeb();
  }

  @override
  Future<bool> launch(String url) {
    return Future<bool>.value(html.window.open(url, '') != null);
  }
}
