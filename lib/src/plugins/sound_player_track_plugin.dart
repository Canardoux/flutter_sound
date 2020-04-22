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

import '../sound_player.dart';
import '../track.dart';
import 'player_base_plugin.dart';

///
class SoundPlayerTrackPlugin extends PlayerBasePlugin {
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
  Future<void> play(SoundPlayer player, Track track) async {
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

    await invokeMethod(player, 'startPlayerFromTrack', <String, dynamic>{
      'track': trackMap,
      'canPause': player.canPause,
      'canSkipForward': player.canSkipForward,
      'canSkipBackward': player.canSkipBackward,
    });
  }

  ///
  Future<dynamic> onMethodCallback(
      covariant SoundPlayer player, MethodCall call) {
    switch (call.method) {

      /// track specific methods
      case 'skipForward':
        onSystemSkipForward(player);
        break;

      case 'skipBackward':
        onSystemSkipBackward(player);
        break;

      default:
        super.onMethodCallback(player, call);
    }
    return null;
  }
}
