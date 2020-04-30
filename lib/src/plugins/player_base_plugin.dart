import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../audio_player.dart';
import '../codec.dart';
import '../ios/ios_session_category.dart';
import '../ios/ios_session_mode.dart';
import '../playback_disposition.dart';

import '../track.dart';
import '../util/log.dart';
import 'base_plugin.dart';

typedef ConnectedCallback = void Function({bool result});

/// base for all plugins that provide Plaback services.
abstract class PlayerBasePlugin extends BasePlugin {
  /// The java TrackPlayer and FlutterSoundPlayer share a static
  /// array of slots. As such so must we.
  /// TODO: get the java/swift code so that each plugin has its own
  /// slots.
  /// ignore: prefer_final_fields
  static var _slots = <SlotEntry>[];

  /// Pass in the [_registeredName] which is the registered
  /// name of the plugin.
  PlayerBasePlugin(String registeredName) : super(registeredName, _slots);

  ConnectedCallback _onConnected;

  /// Allows you to register for connection events.
  /// ignore: avoid_setters_without_getters
  set onConnected(ConnectedCallback callback) => _onConnected = callback;

  /// Over load this method to play audio.
  Future<void> play(AudioPlayer player, Track track);

  /// Each Player must be initialised and registered.
  void initialisePlayer(SlotEntry player) async {
    register(player);
    await invokeMethod(player, 'initializeMediaPlayer', <String, dynamic>{});
  }

  /// Releases the slot used by the connector.
  /// To use a plugin you start by calling [register]
  /// and finish by calling [release].
  void releasePlayer(SlotEntry slotEntry) async {
    await invokeMethod(slotEntry, 'releaseMediaPlayer', <String, dynamic>{});
    super.release(slotEntry);
  }

  ///
  Future<void> stop(SlotEntry player) async {
    await invokeMethod(player, 'stopPlayer', <String, dynamic>{});
  }

  ///
  Future<void> pause(SlotEntry player) async {
    await invokeMethod(player, 'pausePlayer', <String, dynamic>{});
  }

  ///
  Future<void> resume(SlotEntry player) async {
    await invokeMethod(player, 'resumePlayer', <String, dynamic>{});
  }

  ///
  Future<void> seekToPlayer(SlotEntry player, Duration position) async {
    await invokeMethod(player, 'seekToPlayer', <String, dynamic>{
      'sec': position.inMilliseconds,
    });
  }

  ///
  Future<void> setVolume(SlotEntry player, double volume) async {
    var indexedVolume = Platform.isIOS ? volume * 100 : volume;
    if (volume < 0.0 || volume > 1.0) {
      throw RangeError('Value of volume should be between 0.0 and 1.0.');
    }
    await invokeMethod(player, 'setVolume', <String, dynamic>{
      'volume': indexedVolume,
    });
  }

  ///
  Future<bool> isSupported(SlotEntry player, Codec codec) async {
    var result = await invokeMethod(player, 'isDecoderSupported',
        <String, dynamic>{'codec': codec.index}) as bool;
    return result;
  }

  ///
  Future<bool> iosSetCategory(SlotEntry player, IOSSessionCategory category,
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
  Future<bool> androidFocusRequest(SlotEntry player, int focusGain) async {
    if (!Platform.isAndroid) return false;
    return await invokeMethod(player, 'androidAudioFocusRequest',
        <String, dynamic>{'focusGain': focusGain}) as bool;
  }

  ///
  Future<void> setSubscriptionDuration(
      SlotEntry player, Duration interval) async {
    await invokeMethod(player, 'setSubscriptionDuration', <String, dynamic>{
      /// we need to use milliseconds as if we use seconds we end
      /// up rounding down to zero.
      'sec': (interval.inMilliseconds).toDouble() / 1000,
    });
  }

  /// The caller can manage the audio focus with this function
  /// If [request] is true then we request the focus
  /// If [request] is false then we abandon the focus.
  Future<void> audioFocus(SlotEntry slotEntry, {bool request}) async {
    await invokeMethod(
        slotEntry, 'setActive', <String, dynamic>{'enabled': request});
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
      Log.d('Fixed position > duration $position $duration');
      duration = position;
    }
    return PlaybackDisposition(position, duration);
  }

  /// Handles callbacks from the platform specific plugin
  /// The below methods are shared by all the playback plugins.
  Future<dynamic> onMethodCallback(
      covariant AudioPlayer player, MethodCall call) {
    switch (call.method) {

      ///TODO implement in the OS code for each player.
      case "onConnected":
        {
          var result = call.arguments['arg'] as bool;
          Log.d('onConnected $result');
          if (_onConnected != null) _onConnected(result: result);
        }
        break;

      case "updateProgress":
        {
          var arguments = call.arguments['arg'] as String;
          updateProgress(
              player, PlayerBasePlugin.dispositionFromJSON(arguments));
        }
        break;

      case "audioPlayerFinishedPlaying":
        {
          var arguments = call.arguments['arg'] as String;

          audioPlayerFinished(
              player, PlayerBasePlugin.dispositionFromJSON(arguments));
        }
        break;

      case 'pause':
        {
          onSystemPaused(player);
        }
        break;

      case 'resume':
        {
          onSystemResumed(player);
        }
        break;

      default:
        throw ArgumentError('Unknown method ${call.method}');
    }
    return null;
  }
}
