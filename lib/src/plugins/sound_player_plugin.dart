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

import 'package:flutter/services.dart';
import '../audio_session.dart';

import '../track.dart';
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

  Future<void> play(AudioSession session, Track track) async {
    /// sound player plugin does yet support in memory audio.
    trackForceToDisk(track);
    var args = <String, dynamic>{};
    args['path'] = trackUri(track);
    // Flutter cannot transfer an enum to a native plugin.
    // We use an integer instead
    args['codec'] = track.codec.index;
    await invokeMethod(session, 'startPlayer', args);
  }

  ///
  Future<dynamic> onMethodCallback(AudioSession audioSession, MethodCall call) {
    switch (call.method) {
      case "updateProgress":
        {
          var arguments = call.arguments['arg'] as String;
          updateProgress(
              audioSession, BasePlugin.dispositionFromJSON(arguments));
        }
        break;

      case "audioPlayerFinishedPlaying":
        {
          var arguments = call.arguments['arg'] as String;

          audioPlayerFinished(
              audioSession, BasePlugin.dispositionFromJSON(arguments));
        }
        break;

      case 'pause':
        {
          onSystemPaused(audioSession);
        }
        break;

      case 'resume':
        {
          onSystemResumed(audioSession);
        }
        break;

      default:
        throw ArgumentError('Unknown method ${call.method}');
    }
    return null;
  }
}
