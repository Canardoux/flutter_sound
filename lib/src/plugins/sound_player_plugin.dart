/*
 * This file is part of Flutter-Sound.
 *
 *   Flutter-Sound is free software: you can redistribute it and/or modify
 *   it under the terms of the Lesser GNU General Public License
 *   version 3 (LGPL3) as published by the Free Software Foundation.
 *
 *   Flutter-Sound is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the Lesser GNU General Public License
 *   along with Flutter-Sound.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import '../playback_disposition.dart';
import '../sound_player.dart';

import 'base_plugin.dart';

///
class SoundPlayerPlugin extends BasePlugin {
  static SoundPlayerPlugin _self;

  /// Factory
  factory SoundPlayerPlugin() {
    _self ??= SoundPlayerPlugin._internal();
    return _self;
  }
  SoundPlayerPlugin._internal() : super('com.dooboolab.flutter_sound_player');

  ///
  Future<dynamic> onMethodCallback(
      covariant SoundPlayerProxy connector, MethodCall call) {
    switch (call.method) {
      case "updateProgress":
        {
          var arguments = call.arguments['arg'] as String;
          connector.updateProgress(arguments);
        }
        break;

      case "audioPlayerFinishedPlaying":
        {
          var args = call.arguments['arg'] as String;
          var result = jsonDecode(args) as Map<String, dynamic>;
          var status = PlaybackDisposition.fromJSON(result);

          connector.audioPlayerFinished(status);
        }
        break;

      case 'pause':
        {
          connector.onSystemPaused();
        }
        break;

      case 'resume':
        {
          connector.onSystemResumed();
        }
        break;

      default:
        throw ArgumentError('Unknown method ${call.method}');
    }
    return null;
  }
}
