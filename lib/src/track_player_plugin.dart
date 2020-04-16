import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

import '../flutter_sound_player.dart';
import '../track_player.dart';
import 'flutter_player_plugin.dart';
import 'playback_disposition.dart';

class TrackPlayerPlugin extends FlautoPlayerPlugin {
  MethodChannel channel;

  //List<TrackPlayer> trackPlayerSlots = [];
  TrackPlayerPlugin() {
    setCallback();
  }

  void setCallback() {
    channel = const MethodChannel('com.dooboolab.flutter_sound_track_player');
    channel.setMethodCallHandler((MethodCall call) {
      // This lambda function is necessary because channelMethodCallHandler
      // is a virtual function (polymorphism)
      return channelMethodCallHandler(call);
    });
  }

  int lookupEmptyTrackPlayerSlot(TrackPlayer aTrackPlayer) {
    for (int i = 0; i < slots.length; ++i) {
      if (slots[i] == null) {
        slots[i] = aTrackPlayer;
        return i;
      }
    }
    slots.add(aTrackPlayer);
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
    int slotNo = call.arguments['slotNo'] as int;
    TrackPlayer aTrackPlayer = slots[slotNo] as TrackPlayer;
    // for the methods that don't have return values
    // we still need to return a future.
    Future<dynamic> result = Future<dynamic>.value(null);
    switch (call.method) {
      case 'audioPlayerFinishedPlaying':
        {
          String args = call.arguments['arg'] as String;
          Map<String, dynamic> result =
              jsonDecode(args) as Map<String, dynamic>;
          PlaybackDisposition status = PlaybackDisposition.fromJSON(result);
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
