import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import '../playback_disposition.dart';
import '../sound_player.dart';

import 'base_plugin.dart';

///
class FlutterPlayerPlugin extends BasePluginInterface {
  static FlutterPlayerPlugin _self;

  /// Factory
  factory FlutterPlayerPlugin() {
    _self ??= FlutterPlayerPlugin._internal();
    return _self;
  }
  FlutterPlayerPlugin._internal() : super('com.dooboolab.flutter_sound_player');

  ///
  Future<dynamic> onMethodCallback(
      covariant SoundPlayerProxy connector, MethodCall call) {
    switch (call.method) {
      case "updateProgress":
        {
          connector.updateProgress(call.arguments as Map<String, dynamic>);
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
          connector.pause();
        }
        break;

      case 'resume':
        {
          connector.resume();
        }
        break;

      default:
        throw ArgumentError('Unknown method ${call.method}');
    }
    return null;
  }
}
