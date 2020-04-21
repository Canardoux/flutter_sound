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
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../codec.dart';
import '../ios/ios_session_category.dart';
import '../ios/ios_session_mode.dart';
import '../playback_disposition.dart';
import '../sound_player.dart';
import '../track.dart';

/// provides a set of common methods used by
/// PluginInterfaces to talk to the underlying
/// Platform specific plugin.
abstract class BasePlugin {
  final List<SoundPlayer> _slots = [];

  ///
  @protected
  MethodChannel channel;

  /// The registered name of the plugin.
  final String _registeredName;

  /// Pass in the [_registeredName] which is the registered
  /// name of the plugin.
  BasePlugin(this._registeredName) {
    channel = MethodChannel(_registeredName);
    channel.setMethodCallHandler(_onMethodCallback);
  }

  /// Over load this method to play audio.
  Future<void> play(SoundPlayer player, Track track);

  /// overload this method to handle callbacks from the underlying
  /// platform specific plugin
  Future<dynamic> onMethodCallback(SoundPlayer player, MethodCall call);

  Future<dynamic> _onMethodCallback(MethodCall call) {
    var slotNo = call.arguments['slotNo'] as int;
    var audioSession = _slots[slotNo];

    return onMethodCallback(audioSession, call);
  }

  /// Invokes a method in the platform specific plugin for the
  /// given [player]. The connector is a link either
  /// a specific SoundRecorder or QuickPlay instance.
  Future<dynamic> invokeMethod(
      SoundPlayer player, String methodName, Map<String, dynamic> call) {
    /// allocate a slot for this call.
    var slotNo = _findSlot(player);
    call['slotNo'] = slotNo;
    return getChannel().invokeMethod<dynamic>(methodName, call);
  }

  ///
  @protected
  MethodChannel getChannel() => channel;

  /// Allows you to register a connector with the plugin.
  /// Registering a connector allocates a slot for communicating
  /// with the platform specific plugin.
  /// To use a plugin you start by calling [register]
  /// and finish by calling [release].
  void register(SoundPlayer player) {
    var inserted = false;
    for (var i = 0; i < _slots.length; ++i) {
      if (_slots[i] == null) {
        _slots[i] = player;
        inserted = true;
        break;
      }
    }
    if (!inserted) {
      _slots.add(player);
    }
    print('registered SoundPlayer to slot: ${_slots.length - 1}');
  }

  /// Releases the slot used by the connector.
  /// To use a plugin you start by calling [register]
  /// and finish by calling [release].
  void release(SoundPlayer player) async {
    await invokeMethod(player, 'releaseMediaPlayer', <String, dynamic>{});

    var slot = _findSlot(player);
    if (slot != -1) {
      _slots[slot] = null;
    } else {
      throw AudioSessionNotRegisteredException(
          'The SoundPlayer was not found when releasing the player.');
    }
  }

  ///
  void initialise(SoundPlayer player) async {
    await invokeMethod(player, 'initializeMediaPlayer', <String, dynamic>{});
  }

  ///
  Future<void> stop(SoundPlayer player) async {
    await invokeMethod(player, 'stopPlayer', <String, dynamic>{});
  }

  ///
  Future<void> pause(SoundPlayer player) async {
    await invokeMethod(player, 'pausePlayer', <String, dynamic>{});
  }

  ///
  Future<void> resume(SoundPlayer player) async {
    await invokeMethod(player, 'resumePlayer', <String, dynamic>{});
  }

  ///
  Future<void> seekToPlayer(SoundPlayer player, Duration position) async {
    await invokeMethod(player, 'seekToPlayer', <String, dynamic>{
      'sec': position.inMilliseconds,
    });
  }

  ///
  Future<void> setVolume(SoundPlayer player, double volume) async {
    var indexedVolume = Platform.isIOS ? volume * 100 : volume;
    if (volume < 0.0 || volume > 1.0) {
      throw RangeError('Value of volume should be between 0.0 and 1.0.');
    }
    await invokeMethod(player, 'setVolume', <String, dynamic>{
      'volume': indexedVolume,
    });
  }

  ///
  Future<bool> isSupported(SoundPlayer player, Codec codec) async {
    var result = await invokeMethod(player, 'isDecoderSupported',
        <String, dynamic>{'codec': codec.index}) as bool;
    return result;
  }

  ///
  Future<bool> iosSetCategory(SoundPlayer player, IOSSessionCategory category,
      IOSSessionMode mode, int options) async {
    if (!Platform.isIOS) return false;
    var r = await invokeMethod(player, 'iosSetCategory', <String, dynamic>{
      'category': iosSessionCategory[category.index],
      'mode': iosSessionMode[mode.index],
      'options': options
    }) as bool;

    return r;
  }

  ///
  Future<bool> androidFocusRequest(SoundPlayer player, int focusGain) async {
    if (!Platform.isAndroid) return false;
    return await invokeMethod(player, 'androidAudioFocusRequest',
        <String, dynamic>{'focusGain': focusGain}) as bool;
  }

  ///
  Future<void> setSubscriptionDuration(
      SoundPlayer player, Duration interval) async {
    await invokeMethod(player, 'setSubscriptionDuration', <String, dynamic>{
      /// we need to use milliseconds as if we use seconds we end
      /// up rounding down to zero.
      'sec': (interval.inMilliseconds).toDouble() / 1000,
    });
  }

  ///
  @protected
  int _findSlot(SoundPlayer player) {
    var slot = -1;
    for (var i = 0; i < _slots.length; ++i) {
      if (_slots[i] == player) {
        slot = i;
        break;
      }
    }
    if (slot == -1) {
      throw AudioSessionNotRegisteredException(
          'The SoundPlayer was not found.');
    }
    return slot;
  }

  ///  The caller can manage his audio focus with this function
  /// Depending on your configuration this will either make
  /// this player the loudest stream or it will silence all other stream.
  Future<void> requestAudioFocus(SoundPlayer player) async {
    await invokeMethod(player, 'setActive', <String, dynamic>{'enabled': true});
  }

  ///  The caller can manage his audio focus with this function
  /// Depending on your configuration this will either make
  /// this player the loudest stream or it will silence all other stream.
  Future<void> abandonAudioFocus(SoundPlayer player) async {
    await invokeMethod(
        player, 'setActive', <String, dynamic>{'enabled': false});
  }

  /// Contrucsts a PlaybackDisposition from a json object.
  /// This is used internally to deserialise data coming
  /// up from the underlying OS.
  static PlaybackDisposition dispositionFromJSON(String serializedJson) {
    var json = jsonDecode(serializedJson) as Map<String, dynamic>;
    var duration = Duration(
        milliseconds: double.parse(json['duration'] as String).toInt());
    var position = Duration(
        milliseconds: double.parse(json['current_position'] as String).toInt());

    /// looks like the android subsystem can generate -ve values
    /// during some transitions so we protect ourselves.
    if (duration.inMilliseconds < 0) duration = Duration.zero;
    if (position.inMilliseconds < 0) position = Duration.zero;

    /// when playing an mp3 I've seen occurances where the position is after
    /// the duration. So I've added this protection.
    if (position > duration) {
      print('Fixed position > duration $position $duration');
      duration = position;
    }
    return PlaybackDisposition(position, duration);
  }
}

/// Thrown if you try to release or access a connector that isn't
/// registered.
class AudioSessionNotRegisteredException implements Exception {
  final String _message;

  ///
  AudioSessionNotRegisteredException(this._message);

  String toString() => _message;
}
