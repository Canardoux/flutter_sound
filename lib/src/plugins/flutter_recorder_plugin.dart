import 'dart:async';

import 'package:flutter/services.dart';

import '../flutter_sound_recorder.dart';

/// Provides communications with the platform
/// specific plugin.
class FlautoRecorderPlugin {
  MethodChannel _channel;

  final List<RecorderPluginConnector> _slots = [];

  /// ctor
  FlautoRecorderPlugin() {
    _channel = const MethodChannel('com.dooboolab.flutter_sound_recorder');
    _channel.setMethodCallHandler(_channelMethodCallHandler);
  }

  /// Finds and allocates a communications slot.
  int lookupEmptySlot(RecorderPluginConnector aRecorder) {
    for (var i = 0; i < _slots.length; ++i) {
      if (_slots[i] == null) {
        _slots[i] = aRecorder;
        return i;
      }
    }
    _slots.add(aRecorder);
    return _slots.length - 1;
  }

  /// frees up a communications slot allocated via a call
  /// to [lookupEmptySlot].
  void freeSlot(int slotNo) {
    _slots[slotNo] = null;
  }

  MethodChannel _getChannel() => _channel;

  /// Invokes a method on the platform specific plugin.
  Future<dynamic> invokeMethod(String methodName, Map<String, dynamic> call) {
    return _getChannel().invokeMethod<dynamic>(methodName, call);
  }

  Future<dynamic> _channelMethodCallHandler(MethodCall call) {
    var slotNo = call.arguments['slotNo'] as int;
    var aRecorder = _slots[slotNo];
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
