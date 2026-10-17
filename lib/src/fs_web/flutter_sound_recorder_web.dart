/*
 * Copyright 2018, 2019, 2020 Dooboolab.
 * Copyright 2021, 2022, 2023, 2024 Canardoux.
 *
 * This file is part of Flutter-Sound.
 *
 * Flutter-Sound is free software: you can redistribute it and/or modify
 * it under the terms of the Mozilla Public License version 2 (MPL-2.0),
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

@JS()
library flutter_sound;

import 'dart:async';
import 'package:flutter_sound_advanced/src/fs_platform/flutter_sound_platform_interface.dart';
import 'package:flutter_sound_advanced/src/fs_platform/flutter_sound_recorder_platform_interface.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:flutter_sound_advanced/src/fs_logger_compat.dart' show Level;
import 'flutter_sound_media_recorder_web.dart';
import 'dart:js_interop';
import 'flutter_sound_web.dart';

//========================================  JS  ===============================================================

@JS('newRecorderInstance')
external FlutterSoundRecorder newRecorderInstance(
  JSBoxedDartObject callBack,
  JSArray<JSExportedDartFunction> callbackTable,
);

@JS()
extension type FlutterSoundRecorder._(JSObject _) {
  // @JS('newInstance')
  // external static FlutterSoundRecorder newInstance(
  //     FlutterSoundRecorderCallback callBack, List<Function> callbackTable);

  @JS('initializeFlautoRecorder')
  external void initializeFlautoRecorder();

  @JS('releaseFlautoRecorder')
  external void releaseFlautoRecorder();

  @JS('isEncoderSupported')
  external bool isEncoderSupported(int codec);

  @JS('setAudioFocus')
  external void setAudioFocus(
    int focus,
    int category,
    int mode,
    int? audioFlags,
    int device,
  );

  @JS('setSubscriptionDuration')
  external void setSubscriptionDuration(int duration);

  @JS('startRecorder')
  external void startRecorder(
    String? path,
    int? sampleRate,
    int? numChannels,
    int? bitRate,
    int? bufferSize,
    bool? enableVoiceProcessing,
    int codec,
    bool? toStream,
    int audioSource,
  );

  @JS('stopRecorder')
  external void stopRecorder();

  @JS('pauseRecorder')
  external void pauseRecorder();

  @JS('resumeRecorder')
  external void resumeRecorder();

  @JS('getRecordURL')
  external String getRecordURL(String path);

  @JS('deleteRecord')
  external bool deleteRecord(String path);
}

List<JSExportedDartFunction> callbackTable = [
  (JSBoxedDartObject cb, int duration, double dbPeakLevel) {
    (cb.toDart as FlutterSoundRecorderCallback).updateRecorderProgress(
      duration: duration,
      dbPeakLevel: dbPeakLevel,
    );
  }.toJS,
  /*
  (JSBoxedDartObject cb, Uint8List? data) {
    (cb.toDart as FlutterSoundRecorderCallback).recordingData(data: data);
  }.toJS,
   */
  (JSBoxedDartObject cb, int state, bool success) {
    (cb.toDart as FlutterSoundRecorderCallback).startRecorderCompleted(
      state,
      success,
    );
  }.toJS,
  (JSBoxedDartObject cb, int state, bool success) {
    (cb.toDart as FlutterSoundRecorderCallback).pauseRecorderCompleted(
      state,
      success,
    );
  }.toJS,
  (JSBoxedDartObject cb, int state, bool success) {
    (cb.toDart as FlutterSoundRecorderCallback).resumeRecorderCompleted(
      state,
      success,
    );
  }.toJS,
  (JSBoxedDartObject cb, int state, bool success, String url) {
    (cb.toDart as FlutterSoundRecorderCallback).stopRecorderCompleted(
      state,
      success,
      url,
    );
  }.toJS,
  (JSBoxedDartObject cb, int state, bool success) {
    (cb.toDart as FlutterSoundRecorderCallback).openRecorderCompleted(
      state,
      success,
    );
  }.toJS,
  (JSBoxedDartObject cb, int level, String msg) {
    (cb.toDart as FlutterSoundRecorderCallback).log(Level.values[level], msg);
  }.toJS,
];

//============================================================================================================================

/// The web implementation of [FlutterSoundRecorderPlatform].
///
/// This class implements the `package:FlutterSoundPlayerPlatform` functionality for the web.
class FlutterSoundRecorderWeb extends FlutterSoundRecorderPlatform {
  /// Registers this class as the default instance of [FlutterSoundRecorderPlatform].
  static void registerWith(Registrar registrar) {
    FlutterSoundRecorderPlatform.instance = FlutterSoundRecorderWeb();
  }

  List<FlutterSoundRecorder?> _slots = [];
  FlutterSoundRecorder? getWebSession(FlutterSoundRecorderCallback callback) {
    return _slots[findSession(callback)];
  }

  FlutterSoundMediaRecorderWeb? _mediaRecorderWeb;
  Duration? mSubscriptionDuration;

  //================================================================================================================

  @override
  int getSampleRate(FlutterSoundRecorderCallback callback) {
    //  num sampleRate = audioCtx!.sampleRate!;
    //return sampleRate.floor();
    return 0; // TODO
  }

  @override
  Future<bool> isEncoderSupported(
    FlutterSoundRecorderCallback callback, {
    required Codec codec,
  }) async {
    if (codec == Codec.pcmFloat32 || codec == Codec.pcm16) {
      return true;
    }

    /*
    var r = mediaRecorderWeb!.isTypeSupported(mime_types[codec.index]);
    if (r)
      callback.log(Level.debug, 'mime_types[codec] encoder is supported');
    else
      callback.log(Level.debug, 'mime_types[codec] encoder is NOT supported');
    return r;
    */

    return getWebSession(callback)!.isEncoderSupported(codec.index);
  }

  @override
  void requestData(FlutterSoundRecorderCallback callback) {
    if (_mediaRecorderWeb != null) {
      _mediaRecorderWeb!.requestData();
    }
  }

  //static bool _alreadyInited = false;

  /// The current state of the Recorder
  @override
  RecorderState get recorderState => RecorderState.isStopped; // TODO

  @override
  Future<bool> initPlugin() {
    return FlutterSoundPlugin.loadScripts();
  }

  @override
  Future<void>? resetPlugin(FlutterSoundRecorderCallback callback) async {
    callback.log(Level.debug, '---> resetPlugin');
    for (int i = 0; i < _slots.length; ++i) {
      callback.log(Level.debug, "Releasing slot #$i");
      _slots[i]!.releaseFlautoRecorder();
    }
    _slots = [];
    callback.log(Level.debug, '<--- resetPlugin');
    return null;
  }

  @override
  Future<void> openRecorder(
    FlutterSoundRecorderCallback callback, {
    required Level logLevel,
  }) async {
    int slotno = findSession(callback);
    if (slotno < _slots.length) {
      assert(_slots[slotno] == null);
      _slots[slotno] = newRecorderInstance(
        callback.toJSBox,
        callbackTable.toJS,
      );
    } else {
      assert(slotno == _slots.length);
      _slots.add(newRecorderInstance(callback.toJSBox, callbackTable.toJS));
    }
    //audioCtx = AudioContext();

    getWebSession(callback)!.initializeFlautoRecorder();
  }

  @override
  Future<void> closeRecorder(FlutterSoundRecorderCallback callback) async {
    if (_mediaRecorderWeb != null) {
      _mediaRecorderWeb!.stopRecorder();
      _mediaRecorderWeb = null;
    }
    int slotno = findSession(callback);
    _slots[slotno]!.releaseFlautoRecorder();
    _slots[slotno] = null;
  }

  @override
  Future<void> setSubscriptionDuration(
    FlutterSoundRecorderCallback callback, {
    Duration? duration,
  }) async {
    mSubscriptionDuration = duration;
    if (_mediaRecorderWeb != null) {
      _mediaRecorderWeb!.setSubscriptionDuration(duration);
    } else {
      getWebSession(
        callback,
      )!
          .setSubscriptionDuration(duration!.inMilliseconds);
    }
  }

  @override
  Future<void> startRecorder(
    FlutterSoundRecorderCallback callback, {
    Codec? codec,
    String? path,
    int sampleRate = 44100,
    int numChannels = 1,
    int bitRate = 16000,
    int bufferSize = 8192,
    Duration timeSlice = Duration.zero,
    bool enableVoiceProcessing = false,
    bool interleaved = true,
    required bool toStream,
    AudioSource? audioSource,
    bool enableNoiseSuppression = false,
    bool enableEchoCancellation = true,
  }) async {
    _mediaRecorderWeb = null;

    if (toStream) {
      _mediaRecorderWeb = FlutterSoundMediaRecorderWeb();
      return _mediaRecorderWeb!.startRecorderToStream(
        callback,
        codec: codec!,
        //toStream: toStream,
        audioSource: audioSource,
        timeSlice: timeSlice,
        sampleRate: sampleRate,
        numChannels: numChannels,
        bufferSize: bufferSize,
        interleaved: interleaved,
      );
    } else {
      assert(codec != Codec.pcmFloat32 && codec != Codec.pcm16);
      getWebSession(callback)!.startRecorder(
        path,
        sampleRate,
        numChannels,
        bitRate,
        bufferSize,
        enableVoiceProcessing,
        codec!.index,
        toStream,
        audioSource!.index,
      );
    }
  }

  @override
  Future<void> stopRecorder(FlutterSoundRecorderCallback callback) async {
    if (_mediaRecorderWeb != null) {
      await _mediaRecorderWeb!.stopRecorder();
      _mediaRecorderWeb = null;
    } else {
      FlutterSoundRecorder? session = getWebSession(callback);
      if (session != null)
        session.stopRecorder();
      else
        callback.log(Level.debug, 'Recorder already stopped');
    }
  }

  @override
  Future<void> pauseRecorder(FlutterSoundRecorderCallback callback) async {
    if (_mediaRecorderWeb != null) {
      return _mediaRecorderWeb!.pauseRecorder();
    } else {
      getWebSession(callback)!.pauseRecorder();
    }
  }

  @override
  Future<void> resumeRecorder(FlutterSoundRecorderCallback callback) async {
    if (_mediaRecorderWeb != null) {
      return _mediaRecorderWeb!.resumeRecorder();
    } else {
      getWebSession(callback)!.resumeRecorder();
    }
  }

  @override
  Future<String> getRecordURL(
    FlutterSoundRecorderCallback callback,
    String path,
  ) async {
    return getWebSession(callback)!.getRecordURL(path);
  }

  @override
  Future<bool> deleteRecord(
    FlutterSoundRecorderCallback callback,
    String path,
  ) async {
    return getWebSession(callback)!.deleteRecord(path);
  }
}
