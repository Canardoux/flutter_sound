/*
 * This file is part of Flutter-Sound.
 *
 *   Flutter-Sound is free software: you can redistribute it and/or modify
 *   it under the terms of the Lesser GNU General Public License
 *   version 3 (LGPL3) as published by the Free Software Foundation.
 *
 *   Flutter-Sound is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the Lesser GNU General Public License
 *   along with Flutter-Sound.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:async';

import 'package:flutter/services.dart';

import '../sound_recorder.dart';
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
      covariant SoundRecorderProxy connector, MethodCall call) {
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
