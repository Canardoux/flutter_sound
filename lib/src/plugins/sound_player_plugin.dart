import 'dart:async';

import 'package:flutter/services.dart';
import '../audio_session/audio_session.dart';
import '../audio_session/audio_session_impl.dart';

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
    track.audio.forceToDisk();
    var args = <String, dynamic>{};
    args['path'] = track.audio.uri;
    // Flutter cannot transfer an enum to a native plugin.
    // We use an integer instead
    args['codec'] = track.audio.codec.index;
    await invokeMethod(session, 'startPlayer', args);
  }

  ///
  Future<dynamic> onMethodCallback(
      AudioSessionImpl audioSession, MethodCall call) {
    switch (call.method) {
      case "updateProgress":
        {
          var arguments = call.arguments['arg'] as String;
          audioSession
              .updateProgress(BasePlugin.dispositionFromJSON(arguments));
        }
        break;

      case "audioPlayerFinishedPlaying":
        {
          var arguments = call.arguments['arg'] as String;
          audioSession
              .audioPlayerFinished(BasePlugin.dispositionFromJSON(arguments));
        }
        break;

      case 'pause':
        {
          audioSession.onSystemPaused();
        }
        break;

      case 'resume':
        {
          audioSession.onSystemResumed();
        }
        break;

      default:
        throw ArgumentError('Unknown method ${call.method}');
    }
    return null;
  }
}
