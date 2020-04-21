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
class SoundPlayerTrackPlugin extends BasePlugin {
  static SoundPlayerTrackPlugin _self;

  /// Factory
  factory SoundPlayerTrackPlugin() {
    _self ??= SoundPlayerTrackPlugin._internal();
    return _self;
  }
  SoundPlayerTrackPlugin._internal()
      : super('com.dooboolab.flutter_sound_track_player');

  /// Plays the given [track]. [canSkipForward] and [canSkipBackward] must be
  /// passed to provide information on whether the user can skip to the next
  /// or to the previous song in the lock screen controls.
  ///
  /// This method should only be used if the player has been initialize
  /// with the audio player specific features.
  Future<void> play(AudioSession session, Track track) async {
    final trackMap = <String, dynamic>{
      "title": track.title,
      "author": track.author,
      "albumArtUrl": track.albumArtUrl,
      "albumArtAsset": track.albumArtAsset,
      // TODO is this necessary if we aren't passing a buffer?
      "bufferCodecIndex": track.codec?.index,
    };

    if (track.isURI) {
      trackMap["path"] = trackUri(track);
    } else {
      trackMap["dataBuffer"] = trackBuffer(track);
    }

    await invokeMethod(session, 'startPlayerFromTrack', <String, dynamic>{
      'track': trackMap,
      'canPause': session.canPause,
      'canSkipForward': session.canSkipForward,
      'canSkipBackward': session.canSkipBackward,
    });
  }

  ///
  Future<dynamic> onMethodCallback(
      covariant AudioSession session, MethodCall call) {
    switch (call.method) {
      case "updateProgress":
        var arguments = call.arguments['arg'] as String;
        updateProgress(session, BasePlugin.dispositionFromJSON(arguments));
        break;

      case "audioPlayerFinishedPlaying":
        var arguments = call.arguments['arg'] as String;
        audioPlayerFinished(session, BasePlugin.dispositionFromJSON(arguments));
        break;

      case 'pause':
        onSystemPaused(session);
        break;

      case 'resume':
        onSystemResumed(session);
        break;

      /// track specific methods
      case 'skipForward':
        onSystemSkipForward(session);
        break;

      case 'skipBackward':
        onSystemSkipBackward(session);
        break;

      default:
        throw ArgumentError('Unknown method ${call.method}');
    }
    return null;
  }
}
