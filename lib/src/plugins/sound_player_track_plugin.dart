import 'dart:async';

import 'package:flutter/services.dart';
import '../audio_session/audio_session_impl.dart';

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
  Future<void> play(AudioSessionImpl session, Track track) async {
    final trackMap = <String, dynamic>{
      "title": track.title,
      "author": track.author,
      "albumArtUrl": track.albumArtUrl,
      "albumArtAsset": track.albumArtAsset,
      // TODO is this necessary if we aren't passing a buffer?
      "bufferCodecIndex": track.codec?.index,
    };

    if (track.audio.isURI) {
      trackMap["path"] = track.audio.uri;
    } else {
      trackMap["dataBuffer"] = track.audio.buffer;
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
      covariant AudioSessionImpl session, MethodCall call) {
    switch (call.method) {
      case "updateProgress":
        var arguments = call.arguments['arg'] as String;
        session.updateProgress(BasePlugin.dispositionFromJSON(arguments));
        break;

      case "audioPlayerFinishedPlaying":
        var arguments = call.arguments['arg'] as String;
        session.audioPlayerFinished(BasePlugin.dispositionFromJSON(arguments));
        break;

      case 'pause':
        session.onSystemPaused();
        break;

      case 'resume':
        session.onSystemResumed();
        break;

      /// track specific methods
      case 'skipForward':
        session.onSystemSkipForward();
        break;

      case 'skipBackward':
        session.onSystemSkipBackward();
        break;

      default:
        throw ArgumentError('Unknown method ${call.method}');
    }
    return null;
  }
}
