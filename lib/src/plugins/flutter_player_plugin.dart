import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

import '../flutter_sound_player.dart';
import '../playback_disposition.dart';
import 'base_plugin.dart';

///
class FlautoPlayerPlugin extends BasePlugin {
  static FlautoPlayerPlugin _self;

 
  /// Factory
  factory FlautoPlayerPlugin() {
    _self ??= FlautoPlayerPlugin._internal();
    return _self;
  }
  FlautoPlayerPlugin._internal()
  : super ('com.dooboolab.flutter_sound_player') {
    setCallback();
  }

  ///
  void setCallback() {
    channel = const MethodChannel('com.dooboolab.flutter_sound_player');
    channel.setMethodCallHandler(channelMethodCallHandler);
  }

  ///
  int lookupEmptySlot(PlayerPluginConnector aPlayer) {
    for (var i = 0; i < slots.length; ++i) {
      if (slots[i] == null) {
        slots[i] = aPlayer;
        return i;
      }
    }
    slots.add(aPlayer);
    return slots.length - 1;
  }

  ///
  void freeSlot(int slotNo) {
    slots[slotNo] = null;
  }

  ///
  MethodChannel getChannel() => channel;

  ///
  Future<dynamic> invokeMethod(String methodName, Map<String, dynamic> call) {
    return getChannel().invokeMethod<dynamic>(methodName, call);
  }

  ///
  Future<dynamic> channelMethodCallHandler(MethodCall call) {
    var slotNo = call.arguments['slotNo'] as int;
    var aPlayer = slots[slotNo];

    switch (call.method) {
      case "updateProgress":
        {
          aPlayer.updateProgress(call.arguments as Map);
        }
        break;

      case "audioPlayerFinishedPlaying":
        {
          var args = call.arguments['arg'] as String;
          var result = jsonDecode(args) as Map<String, dynamic>;
          var status = PlaybackDisposition.fromJSON(result);

          aPlayer.audioPlayerFinished(status);
        }
        break;

      case 'pause':
        {
          aPlayer.pause(call.arguments as Map);
        }
        break;

      case 'resume':
        {
          aPlayer.resume(call.arguments as Map);
        }
        break;

      default:
        throw ArgumentError('Unknown method ${call.method}');
    }
    return null;
  }
}
