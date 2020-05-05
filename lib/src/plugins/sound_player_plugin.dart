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

import 'package:flutter/widgets.dart';

import '../audio_player.dart' as player;

import '../track.dart';
import '../util/log.dart';
import 'player_base_plugin.dart';

///
class SoundPlayerPlugin extends PlayerBasePlugin with WidgetsBindingObserver {
  static SoundPlayerPlugin _self;

  /// Factory
  factory SoundPlayerPlugin() {
    _self ??= SoundPlayerPlugin._internal();
    return _self;
  }
  SoundPlayerPlugin._internal() : super('com.dooboolab.flutter_sound_player') {
    /// as we are a singleton we never shutdown so we never shutdown
    /// the observer.
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        onSystemAppResumed();
        break;
      case AppLifecycleState.inactive:
        Log.w("Ignoreing AppLifecycleState.inactive");
        break;
      case AppLifecycleState.paused:
        onSystemAppPaused();
        break;
      case AppLifecycleState.detached:
        Log.w("Ignoreing AppLifecycleState.detached");
        break;
    }
  }

  Future<void> play(player.AudioPlayer player, Track track) async {
    /// sound player plugin does yet support in memory audio.
    trackForceToDisk(track);
    var args = <String, dynamic>{};
    args['path'] = trackStoragePath(track);
    // Flutter cannot transfer an enum to a native plugin.
    // We use an integer instead
    args['codec'] = track.codec.index;
    Log.d('calling invoke startPlayer');
    return invokeMethod(player, 'startPlayer', args);
  }

  /// Called when the OS resumes our app.
  /// We need to broadcast this to all player SlotEntries.
  void onSystemAppResumed() {
    forEachSlot((entry) {
      /// knowledge of the AudioPlayer at this level is a little
      /// ugly but I'm trying to keep the public api that
      /// AudioPlayer exposes clean.
      player.onSystemAppResumed(entry as player.AudioPlayer);
    });
  }

  /// Called when the OS resumes our app.
  /// We need to broadcast this to all player SlotEntries.
  void onSystemAppPaused() {
    forEachSlot((entry) {
      /// knowledge of the AudioPlayer at this level is a little
      /// ugly but I'm trying to keep the public api that
      /// AudioPlayer exposes clean.
      player.onSystemAppPaused(entry as player.AudioPlayer);
    });
  }
}
