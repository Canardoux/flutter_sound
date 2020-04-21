import 'dart:async';

import 'package:flutter/services.dart';

import '../impl/sound_recorder_impl.dart';
import 'base_plugin.dart';

/// Provides communications with the platform
/// specific plugin.
class SoundRecorderPlugin extends BasePlugin {
  static SoundRecorderPlugin _self;

  /// Factory
  factory SoundRecorderPlugin() {
    _self ??= SoundRecorderPlugin._internal();
    return _self;
  }
  SoundRecorderPlugin._internal()
      : super('com.dooboolab.flutter_sound_recorder');

  Future<dynamic> onMethodCallback(
      covariant SoundRecorderImpl connector, MethodCall call) {
    switch (call.method) {
      case "updateRecorderProgress":
        {
          connector.updateDurationDisposition(
              call.arguments as Map<dynamic, dynamic>);
        }
        break;

      case "updateDbPeakProgress":
        {
          connector
              .updateDbPeakDispostion(call.arguments as Map<dynamic, dynamic>);
        }
        break;

      default:
        throw ArgumentError('Unknown method ${call.method}');
    }
    return null;
  }
}
