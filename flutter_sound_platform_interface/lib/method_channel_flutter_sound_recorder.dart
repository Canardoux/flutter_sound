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

import 'package:logger/logger.dart' show Level;
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
            List<Float32List>? data = [];

            int channelCount =
                data.length; //call.arguments['channelCount'] as int;
            for (int i = 0; i < channelCount; ++i) {
              var x = call.arguments['DataChannel$i'] as Float32List;
              /*
              var buf = x.buffer;
                Float32List bb = buf.asFloat32List();
                var bbln = bb.length;
              var blob = ByteData.sublistView(x);
              var ln = (x.length/4).floor();
              var zzz = Float32List(ln);
              for (int j = 0; j < ln; ++j)
                {
                  var z = blob.getFloat32(4*j);
                  zzz[j] = z;
                }
                
               */
              data.add(x);
            }
            //List<Object?> dd = call.arguments['data'] as List<Float32List>;
            List<Object?> d = call.arguments['data'];
            List<Float32List>? dd = [];

            for (Object? x in d) {
              var xx = x as Float32List;
              dd.add(xx);
            }

            aRecorder!.recordingDataFloat32(data: dd);
          }
          break;

        case "recordingDataInt16":
          {
            List<Object?> d = call.arguments['data'];
            List<Int16List>? dd = [];
            for (Object? x in d) {
              if (x is Int16List) {
                dd.add(x);
              } else if (x is Uint8List) // On iOS i am not able to handle that
              {}
            }
            aRecorder!.recordingDataInt16(data: dd);
          }
          break;

        case "recordingData":
          {
            aRecorder!.recordingData(data: call.arguments['recordingData']);
          }
          break;

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
    StreamSink<List<Float32List>>? toStreamFloat32,
    StreamSink<List<Int16List>>? toStreamInt16,
    Codec? codec,
    StreamSink<Uint8List>? toStream,
    AudioSource? audioSource,
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
        'toStream': toStream != null ||
            toStreamInt16 != null ||
            toStreamFloat32 != null, // ? 1 : 0,
        'interleaved':
            toStreamFloat32 == null && toStreamInt16 == null, // ? 1 : 0,
        'audioSource': audioSource!.index,
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
