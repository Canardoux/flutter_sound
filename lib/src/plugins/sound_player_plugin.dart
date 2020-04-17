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
          connector.onPaused();
        }
        break;

      case 'resume':
        {
          connector.onResume();
        }
        break;

      default:
        throw ArgumentError('Unknown method ${call.method}');
    }
    return null;
  }
}
