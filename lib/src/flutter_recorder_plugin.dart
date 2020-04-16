import 'dart:async';

import 'package:flutter/services.dart';

import '../flutter_sound_recorder.dart';

class FlautoRecorderPlugin {
  MethodChannel channel;

  List<RecorderPluginConnector> slots = [];

  FlautoRecorderPlugin() {
    channel = const MethodChannel('com.dooboolab.flutter_sound_recorder');
    channel.setMethodCallHandler((MethodCall call) {
      // This lambda function is necessary because channelMethodCallHandler is a virtual function (polymorphism)
      return channelMethodCallHandler(call);
    });
  }

  int lookupEmptySlot(RecorderPluginConnector aRecorder) {
    for (int i = 0; i < slots.length; ++i) {
      if (slots[i] == null) {
        slots[i] = aRecorder;
        return i;
      }
    }
    slots.add(aRecorder);
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
    RecorderPluginConnector aRecorder = slots[slotNo];
    switch (call.method) {
      case "updateRecorderProgress":
        {
          aRecorder.updateDurationDisposition(
              call.arguments as Map<dynamic, dynamic>);
        }
        break;

      case "updateDbPeakProgress":
        {
          aRecorder
              .updateDbPeakDispostion(call.arguments as Map<dynamic, dynamic>);
        }
        break;

      default:
        throw ArgumentError('Unknown method ${call.method}');
    }
    return null;
  }
}
