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
import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

import '../android/android_audio_source.dart';
import '../android/android_encoder.dart';
import '../android/android_output_format.dart';
import '../codec.dart';
import '../ios/ios_quality.dart';

import '../sound_recorder.dart';
import 'base_plugin.dart';

/// Provides communications with the platform
/// specific plugin.
class SoundRecorderPlugin extends BasePlugin {
  /// ignore: prefer_final_fields
  static var _slots = <SlotEntry>[];

  static SoundRecorderPlugin _self;

  /// Factory
  factory SoundRecorderPlugin() {
    _self ??= SoundRecorderPlugin._internal();
    return _self;
  }
  SoundRecorderPlugin._internal()
      : super('com.dooboolab.flutter_sound_recorder', _slots);

  ///
  void initialise(covariant SoundRecorder recorder) async {
    register(recorder);
    await invokeMethod(
        recorder, 'initializeFlautoRecorder', <String, dynamic>{});
  }

  /// Releases the slot used by the connector.
  /// To use a plugin you start by calling [register]
  /// and finish by calling [release].
  void release(covariant SoundRecorder recorder) async {
    await invokeMethod(recorder, 'releaseFlautoRecorder', <String, dynamic>{});
    super.release(recorder);
  }

  /// Returns true if the specified encoder is supported by
  /// flutter_sound on this platform
  Future<bool> isSupported(SoundRecorder recorder, Codec codec) async {
    return await invokeMethod(recorder, 'isEncoderSupported',
        <String, dynamic>{'codec': codec.index}) as bool;
  }

  ///
  Future<void> start(
    SoundRecorder recorder,
    String path,
    int sampleRate,
    int numChannels,
    int bitRate,
    Codec codec,
    AndroidEncoder androidEncoder,
    AndroidAudioSource androidAudioSource,
    AndroidOutputFormat androidOutputFormat,
    IosQuality iosQuality,
  ) async {
    var param = <String, dynamic>{
      'path': path,
      'sampleRate': sampleRate,
      'numChannels': numChannels,
      'bitRate': bitRate,
      'codec': codec.index,
      'androidEncoder': androidEncoder?.value,
      'androidAudioSource': androidAudioSource?.value,
      'androidOutputFormat': androidOutputFormat?.value,
      'iosQuality': iosQuality?.value
    };

    await invokeMethod(recorder, 'startRecorder', param);
  }

  ///
  Future<void> stop(SoundRecorder recorder) async {
    await invokeMethod(recorder, 'stopRecorder', <String, dynamic>{});
  }

  ///
  Future<void> pause(SoundRecorder recorder) async {
    await invokeMethod(recorder, 'pauseRecorder', <String, dynamic>{});
  }

  ///
  Future<void> resume(SoundRecorder recorder) async {
    await invokeMethod(recorder, 'resumeRecorder', <String, dynamic>{});
  }

  ///
  Future<void> setSubscriptionDuration(
      SoundRecorder recorder, Duration interval) async {
    await invokeMethod(recorder, 'setSubscriptionDuration', <String, dynamic>{
      // we must convert to milli to stop rounding down
      'sec': interval.inMilliseconds.toDouble() / 1000.0,
    });
  }

  ///
  Future<void> setDbPeakLevelUpdate(
      SoundRecorder recorder, Duration interval) async {
    await invokeMethod(recorder, 'setDbPeakLevelUpdate', <String, dynamic>{
      // we must convert to milli to stop rounding down
      'sec': interval.inMilliseconds.toDouble() / 1000.0,
    });
  }

  /// Enables or disables processing the Peak level in db's. Default is disabled
  Future<void> setDbLevelEnabled(SoundRecorder recorder, {bool enabled}) async {
    await invokeMethod(recorder, 'setDbLevelEnabled', <String, dynamic>{
      'enabled': enabled,
    });
  }

  Future<dynamic> onMethodCallback(
      covariant SoundRecorder recorder, MethodCall call) {
    switch (call.method) {
      case "updateRecorderProgress":
        _updateRecorderProgress(call, recorder);
        break;

      case "updateDbPeakProgress":
        var decibels = call.arguments['arg'] as double;
        // We use max to ensure that we always report a +ve db.
        // We have seen -ve db come up from the OS which is not
        // valid (i.e. silence is 0 db).
        decibels = max(0, decibels);

        /// sanity check. 194 is the theoretical upper limit on undistorted
        ///  sound in air. (above this its a shock wave)
        decibels = min(194, decibels);
        recorderUpdateDbPeakDispostion(recorder, decibels);
        break;

      default:
        throw ArgumentError('Unknown method ${call.method}');
    }
    return null;
  }

  void _updateRecorderProgress(MethodCall call, SoundRecorder recorder) {
    var result =
        json.decode(call.arguments['arg'] as String) as Map<String, dynamic>;

    var duration = Duration(
        milliseconds:
            double.parse(result['current_position'] as String).toInt());

    recorderUpdateDuration(recorder, duration);
  }
}
