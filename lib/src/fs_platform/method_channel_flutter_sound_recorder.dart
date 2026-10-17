/*
 * Copyright 2018, 2019, 2020, 2021 Canardoux.
 *
 * This file is part of Flutter-Sound.
 *
 * Flutter-Sound is free software: you can redistribute it and/or modify
 * it under the terms of the Mozilla Public License version 2 (MPL2.0),
 * as published by the Mozilla organization.
 *
 * Flutter-Sound is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * MPL General Public License for more details.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';

import 'package:flutter_sound_advanced/src/fs_logger_compat.dart' show Level;
import 'package:flutter/services.dart';

import 'flutter_sound_platform_interface.dart';
import 'flutter_sound_recorder_platform_interface.dart';
import 'dart:typed_data';

const MethodChannel _channel =
    MethodChannel('xyz.canardoux.flutter_sound_recorder');

/// An implementation of [UrlLauncherPlatform] that uses method channels.
class MethodChannelFlutterSoundRecorder extends FlutterSoundRecorderPlatform {
  /*ctor */ MethodChannelFlutterSoundRecorder() {
    _setCallback();
  }

  void _setCallback() {
    //channel = const MethodChannel('xyz.canardoux.flutter_sound_recorder');
    _channel.setMethodCallHandler((MethodCall call) {
      return channelMethodCallHandler(call);
    });
  }

  @override
  int getSampleRate(
    FlutterSoundRecorderCallback callback,
  ) {
    return 0;
  }

  @override
  void requestData(
    FlutterSoundRecorderCallback callback,
  ) {}

  Future<bool> channelMethodCallHandler(MethodCall call) {
    return Future<bool>(() {
      FlutterSoundRecorderCallback? aRecorder =
          getSession(call.arguments['slotNo'] as int);
      //bool? success = call.arguments['success'] as bool?;
      bool success = call.arguments['success'] != null
          ? call.arguments['success'] as bool
          : false;

      switch (call.method) {
        case "updateRecorderProgress":
          {
            aRecorder!.updateRecorderProgress(
                duration: call.arguments['duration'],
                dbPeakLevel: call.arguments['dbPeakLevel']);
          }
          break;

        case "recordingDataFloat32":
          {
            List<Float32List> r = [];
            var data = call.arguments['data'] as List<Object?>;
            for (var d in data) {
              r.add(d as Float32List);
            }
            aRecorder!.recordingDataFloat32(data: r);
          }
          break;

        case "recordingDataInt16":
          {
            List<Int16List> r = [];
            var data = call.arguments['data'] as List<Object?>;
            for (var d in data) {
              // For each channel
              Uint8List xx = d as Uint8List;

              // For an unknown reason, I had to clone xx to have a correct xx.buffer
              //if (!kIsWeb && Platform.isIOS) {
              int ln = xx.length;
              Uint8List clone = Uint8List(ln);
              for (int i = 0; i < ln; ++i) {
                clone[i] = xx[i];
              }
              xx = clone;
              //}

              var x = Int16List.view(xx.buffer);
              r.add(x);
            }
            aRecorder!.recordingDataInt16(data: r);
          }
          break;

        case "recordingData":
          {
            var data = call.arguments['data'] as Uint8List;
            aRecorder!.interleavedRecording(data: data);
          }
          break;

        /*
        case "interleavedRecordingData16": // Interleaved
          {
            var data = call.arguments['data'] as Uint8List;
            aRecorder!.interleavedRecording(data: data);
          }
          break;
         */

        case "startRecorderCompleted":
          {
            aRecorder!.startRecorderCompleted(call.arguments['state'], success);
          }
          break;

        case "stopRecorderCompleted":
          {
            aRecorder!.stopRecorderCompleted(
                call.arguments['state'], success, call.arguments['arg']);
          }
          break;

        case "pauseRecorderCompleted":
          {
            aRecorder!.pauseRecorderCompleted(call.arguments['state'], success);
          }
          break;

        case "resumeRecorderCompleted":
          {
            aRecorder!
                .resumeRecorderCompleted(call.arguments['state'], success);
          }
          break;

        case "openRecorderCompleted":
          {
            aRecorder!.openRecorderCompleted(call.arguments['state'], success);
          }
          break;

        case "log":
          {
            int i = call.arguments['level'];
            Level l = Level.values.firstWhere((x) => x.value == i);
            aRecorder!.log(l, call.arguments['msg']);
          }
          break;

        default:
          throw ArgumentError('Unknown method ${call.method}');
      }

      return success;
    });
  }

  Future<void> invokeMethodVoid(FlutterSoundRecorderCallback callback,
      String methodName, Map<String, dynamic> call) {
    call['slotNo'] = findSession(callback);
    return _channel.invokeMethod(methodName, call);
  }

  Future<int?> invokeMethodInt(FlutterSoundRecorderCallback callback,
      String methodName, Map<String, dynamic> call) {
    call['slotNo'] = findSession(callback);
    return _channel.invokeMethod(methodName, call);
  }

  Future<bool> invokeMethodBool(FlutterSoundRecorderCallback callback,
      String methodName, Map<String, dynamic> call) async {
    call['slotNo'] = findSession(callback);
    bool r = await _channel.invokeMethod(methodName, call) as bool;
    return r;
  }

  Future<String?> invokeMethodString(FlutterSoundRecorderCallback callback,
      String methodName, Map<String, dynamic> call) {
    call['slotNo'] = findSession(callback);
    return _channel.invokeMethod(methodName, call);
  }

  @override
  Future<bool> initPlugin() async {
    return true;
  }

  @override
  Future<void>? setLogLevel(
      FlutterSoundRecorderCallback callback, Level logLevel) {
    return invokeMethodVoid(callback, 'setLogLevel', {
      'logLevel': logLevel.index,
    });
  }

  @override
  Future<void>? resetPlugin(
    FlutterSoundRecorderCallback callback,
  ) {
    return invokeMethodVoid(
      callback,
      'resetPlugin',
      Map<String, dynamic>(),
    );
  }

  @override
  Future<void> openRecorder(
    FlutterSoundRecorderCallback callback, {
    required Level logLevel,
  }) {
    return invokeMethodVoid(
      callback,
      'openRecorder',
      {
        'logLevel': logLevel.index,
      },
    );
  }

  @override
  Future<void> closeRecorder(
    FlutterSoundRecorderCallback callback,
  ) {
    return invokeMethodVoid(
      callback,
      'closeRecorder',
      Map<String, dynamic>(),
    );
  }

  @override
  Future<bool> isEncoderSupported(
    FlutterSoundRecorderCallback callback, {
    Codec codec = Codec.defaultCodec,
  }) {
    return invokeMethodBool(
      callback,
      'isEncoderSupported',
      {
        'codec': codec.index,
      },
    );
  }

  @override
  Future<void> setSubscriptionDuration(
    FlutterSoundRecorderCallback callback, {
    Duration? duration,
  }) {
    return invokeMethodVoid(
      callback,
      'setSubscriptionDuration',
      {'duration': duration!.inMilliseconds},
    );
  }

  @override
  Future<void> startRecorder(
    FlutterSoundRecorderCallback callback, {
    String? path,
    int? sampleRate,
    int numChannels = 2,
    int? bitRate,
    int bufferSize = 8192,
    Duration timeSlice = Duration.zero,
    bool enableVoiceProcessing = false,
    bool interleaved = true,
    bool toStream = false,
    Codec? codec,
    AudioSource? audioSource,
    bool enableNoiseSuppression = false,
    bool enableEchoCancellation = true,
  }) {
    return invokeMethodVoid(
      callback,
      'startRecorder',
      {
        'path': path,
        'sampleRate': sampleRate,
        'numChannels': numChannels,
        'bitRate': bitRate,
        'bufferSize': bufferSize,
        'enableVoiceProcessing': enableVoiceProcessing, // ? 1 : 0,
        'codec': codec!.index,
        'toStream': toStream,
        'interleaved': interleaved,
        'audioSource': audioSource!.index,
        'enableNoiseSuppression': enableNoiseSuppression,
        'enableEchoCancellation': enableEchoCancellation,
      },
    );
  }

  @override
  Future<void> stopRecorder(
    FlutterSoundRecorderCallback callback,
  ) {
    return invokeMethodVoid(
      callback,
      'stopRecorder',
      Map<String, dynamic>(),
    );
  }

  @override
  Future<void> pauseRecorder(
    FlutterSoundRecorderCallback callback,
  ) {
    return invokeMethodVoid(
      callback,
      'pauseRecorder',
      Map<String, dynamic>(),
    );
  }

  @override
  Future<void> resumeRecorder(
    FlutterSoundRecorderCallback callback,
  ) {
    return invokeMethodVoid(
      callback,
      'resumeRecorder',
      Map<String, dynamic>(),
    );
  }

  @override
  Future<bool?> deleteRecord(
      FlutterSoundRecorderCallback callback, String path) {
    return invokeMethodBool(callback, 'deleteRecord', {'path': path});
  }

  @override
  Future<String?> getRecordURL(
      FlutterSoundRecorderCallback callback, String path) {
    return invokeMethodString(callback, 'getRecordURL', {'path': path});
  }
}
