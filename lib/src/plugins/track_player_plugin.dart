import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import '../playback_disposition.dart';
import '../track_player.dart';
import 'flutter_player_plugin.dart';

/// Communications layer with the underlying platform
/// audio player.
class TrackPlayerPlugin extends FlautoPlayerPlugin {
  static TrackPlayerPlugin _self;
  MethodChannel channel;

  /// Factory
  factory TrackPlayerPlugin() {
    _self ??= TrackPlayerPlugin._internal();
    return _self;
  }

  TrackPlayerPlugin._internal() {
    setCallback();
  }

  void setCallback() {
    channel = const MethodChannel('com.dooboolab.flutter_sound_track_player');
    channel.setMethodCallHandler(channelMethodCallHandler);
  }

  ///
  int lookupEmptyTrackPlayerSlot(PlayerPluginConnector playerConnector) {
    for (var i = 0; i < slots.length; ++i) {
      if (slots[i] == null) {
        slots[i] = playerConnector;
        return i;
      }
    }
    slots.add(playerConnector);
    return slots.length - 1;
  }

  void freeSlot(int slotNo) {
    slots[slotNo] = null;
  }

  MethodChannel getChannel() => channel;

  Future<dynamic> invokeMethod(String methodName, Map<String, dynamic> call) {
    return getChannel().invokeMethod<dynamic>(methodName, call);
  }

  Future<dynamic> channelMethodCallHandler(MethodCall call) {
    var slotNo = call.arguments['slotNo'] as int;
    var aTrackPlayer = slots[slotNo] as TrackPlayer;
    // for the methods that don't have return values
    // we still need to return a future.
    var result = Future<dynamic>.value(null);
    switch (call.method) {
      case 'audioPlayerFinishedPlaying':
        {
          var args = call.arguments['arg'] as String;
          var result = jsonDecode(args) as Map<String, dynamic>;
          var status = PlaybackDisposition.fromJSON(result);
          aTrackPlayer.audioPlayerFinished(status);
        }
        break;
      case 'skipForward':
        {
          aTrackPlayer.skipForward(call.arguments as Map<String, dynamic>);
        }
        break;
      case 'skipBackward':
        {
          aTrackPlayer.skipBackward(call.arguments as Map<String, dynamic>);
        }
        break;

      default:
        result = super.channelMethodCallHandler(call);
    }

    return result;
  }
}
