/*
 * Copyright 2018, 2019, 2020 Dooboolab.
 *
 * This file is part of Flutter-Sound.
 *
 * Flutter-Sound is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3, as published by
 * the Free Software Foundation.
 *
 * Flutter-Sound is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Flutter-Sound.  If not, see <https://www.gnu.org/licenses/>.
 */


import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum RecorderState {
  isStopped,
  isPaused,
  isRecording,
}

FlautoRecorderPlugin flautoRecorderPlugin; // Singleton, lazy initialized

class FlautoRecorderPlugin {
  MethodChannel channel;

  List<FlutterSoundRecorder> slots = [];

  FlautoRecorderPlugin() {
    channel = const MethodChannel('com.dooboolab.flutter_sound_recorder');
    channel.setMethodCallHandler((MethodCall call) {
      // This lambda function is necessary because channelMethodCallHandler is a virtual function (polymorphism)
      return channelMethodCallHandler(call);
    });
  }

  int lookupEmptySlot(FlutterSoundRecorder aRecorder) {
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
    FlutterSoundRecorder aRecorder = slots[slotNo];
    switch (call.method) {
      case "updateRecorderProgress":
        {
          aRecorder
              .updateRecorderProgress(call.arguments as Map<dynamic, dynamic>);
        }
        break;

      case "updateDbPeakProgress":
        {
          aRecorder
              .updateDbPeakProgress(call.arguments as Map<dynamic, dynamic>);
        }
        break;

      default:
        throw ArgumentError('Unknown method ${call.method}');
    }
    return null;
  }
}

enum _Initialized {
  notInitialized,
  fullyInitialized,
  initializationInProgress,
}

class FlutterSoundRecorder {
  _Initialized isInited = _Initialized.notInitialized;
  RecorderState recorderState = RecorderState.isStopped;
  StreamController<RecordStatus> _recorderController;
  StreamController<double> _dbPeakController;
  int slotNo;

  bool isOggOpus =
      false; // Set by startRecorder when the user wants to record an ogg/opus
  String
      savedUri; // Used by startRecorder/stopRecorder to keep the caller wanted uri
  String
      tmpUri; // Used by startRecorder/stopRecorder to keep the temporary uri to record CAF

  bool get isRecording => (recorderState ==
      RecorderState
          .isRecording); //|| recorderState == t_RECORDER_STATE.IS_PAUSED);

  bool get isStopped => (recorderState == RecorderState.isStopped);

  bool get isPaused => (recorderState == RecorderState.isPaused);

  Stream<RecordStatus> get onProgress => _recorderController.stream;

  /// Value ranges from 0 to 120
  Stream<double> get onRecorderDbPeakChanged => _dbPeakController.stream;

  //FlutterSoundRecorder() {}

  FlautoRecorderPlugin getPlugin() => flautoRecorderPlugin;

  Future<dynamic> invokeMethod(String methodName, Map<String, dynamic> call) {
    call['slotNo'] = slotNo;
    return getPlugin().invokeMethod(methodName, call);
  }

  Future<FlutterSoundRecorder> initialize() async {
    if (isInited == _Initialized.fullyInitialized) {
      return this;
    }
    if (isInited == _Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }

    isInited = _Initialized.initializationInProgress;

    if (flautoRecorderPlugin == null) {
      flautoRecorderPlugin = FlautoRecorderPlugin();
    } // The lazy singleton
    slotNo = getPlugin().lookupEmptySlot(this);
    await invokeMethod('initializeFlautoRecorder', <String, dynamic>{});
    isInited = _Initialized.fullyInitialized;
    return this;
  }

  Future<void> release() async {
    if (isInited == _Initialized.notInitialized) {
      return this;
    }
    if (isInited == _Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    isInited = _Initialized.initializationInProgress;

    await stopRecorder();
    _removeRecorderCallback(); // _recorderController will be closed by this function
    _removeDbPeakCallback(); // _dbPeakController will be closed by this function
    await invokeMethod('releaseFlautoRecorder', <String, dynamic>{});
    getPlugin().freeSlot(slotNo);
    slotNo = null;
    isInited = _Initialized.notInitialized;
  }

  void updateRecorderProgress(Map call) {
    Map<String, dynamic> result =
        json.decode(call['arg'] as String) as Map<String, dynamic>;
    if (_recorderController != null) {
      _recorderController.add(RecordStatus.fromJSON(result));
    }
  }

  void updateDbPeakProgress(Map<dynamic, dynamic> call) {
    if (_dbPeakController != null) _dbPeakController.add(call['arg'] as double);
  }

  /// Returns true if the specified encoder is supported by flutter_sound on this platform
  Future<bool> isEncoderSupported(Codec codec) async {
    await initialize();
    bool result;
    // For encoding ogg/opus on ios, we need to support two steps :
    // - encode CAF/OPPUS (with native Apple AVFoundation)
    // - remux CAF file format to OPUS file format (with ffmpeg)

    if ((codec == Codec.opusOGG) && (Platform.isIOS)) {
      //if (!await isFFmpegSupported( ))
      //result = false;
      //else
      result = await invokeMethod('isEncoderSupported',
          <String, dynamic>{'codec': Codec.opusCAF.index}) as bool;
    } else {
      result = await invokeMethod(
              'isEncoderSupported', <String, dynamic>{'codec': codec.index})
          as bool;
    }
    return result;
  }

  Future<void> _setRecorderCallback() async {
    if (_recorderController == null) {
      _recorderController = StreamController.broadcast();
    }
    if (_dbPeakController == null) {
      _dbPeakController = StreamController.broadcast();
    }
  }

  void _removeRecorderCallback() {
    if (_recorderController != null) {
      _recorderController
        //..add(null) // We keep that strange line for backward compatibility
        ..close();
      _recorderController = null;
    }
  }

  void _removeDbPeakCallback() {
    if (_dbPeakController != null) {
      _dbPeakController
        //..add(null)
        ..close();
      _dbPeakController = null;
    }
  }

  /// Sets the frequency at which duration updates are sent to
  /// duration listeners.
  /// The default is every 10 milliseconds.
  Future<String> setSubscriptionDuration(double sec) async {
    await initialize();
    String r = await invokeMethod('setSubscriptionDuration', <String, dynamic>{
      'sec': sec,
    }) as String;
    return r;
  }

  /// Defines the interval at which the peak level should be updated.
  /// Default is 0.8 seconds
  Future<String> setDbPeakLevelUpdate(double intervalInSecs) async {
    await initialize();
    String r = await invokeMethod('setDbPeakLevelUpdate', <String, dynamic>{
      'intervalInSecs': intervalInSecs,
    }) as String;
    return r;
  }

  /// Enables or disables processing the Peak level in db's. Default is disabled
  Future<String> setDbLevelEnabled(bool enabled) async {
    await initialize();
    String r = await invokeMethod('setDbLevelEnabled', <String, dynamic>{
      'enabled': enabled,
    }) as String;
    return r;
  }

  /// Return the file extension for the given path.
  /// path can be null. We return null in this case.
  String fileExtension(String path) {
    if (path == null) return null;
    var r = p.extension(path);
    return r;
  }

  Future<String> defaultPath(Codec codec) async {
    var tempDir = await getTemporaryDirectory();
    var fout = File('${tempDir.path}/flutter_sound${ext[codec.index]}');
    return fout.path;
  }

  Future<String> startRecorder( String uri, {
    Codec codec = Codec.aacADTS,
    int sampleRate = 16000,
    int numChannels = 1,
    int bitRate = 16000,
  }) async {
    await initialize();
    // Request Microphone permission if needed
    /*
    if (requestPermission) {
      PermissionStatus status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw RecordingPermissionException("Microphone permission not granted");
      }
    }
    */
    if (recorderState != null && recorderState != RecorderState.isStopped) {
      throw RecorderRunningException('Recorder is not stopped.');
    }
    if (!await isEncoderSupported(codec)) {
      throw CodecNotSupportedException('Codec not supported.');
    }

    if (uri == null) uri = await defaultPath(codec);

    // If we want to record OGG/OPUS on iOS, we record with CAF/OPUS and we remux the CAF file format to a regular OGG/OPUS.
    // We use FFmpeg for that task.
    if ((Platform.isIOS) &&
        ((codec == Codec.opusOGG) || (fileExtension(uri) == '.opus'))) {
      savedUri = uri;
      isOggOpus = true;
      codec = Codec.opusCAF;
      var tempDir = await getTemporaryDirectory();
      var fout = File('${tempDir.path}/$slotNo-flutter_sound-tmp.caf');
      uri = fout.path;
      tmpUri = uri;
    } else {
      isOggOpus = false;
    }

    try {
      var param = <String, dynamic>{
        'path': uri,
        'sampleRate': sampleRate,
        'numChannels': numChannels,
        'bitRate': bitRate,
        'codec': codec.index,
      };

      String result = await invokeMethod('startRecorder', param) as String;

      await _setRecorderCallback();
      recorderState = RecorderState.isRecording;
      // if the caller wants OGG/OPUS we must remux the temporary file
      if ((result != null) && isOggOpus) {
        return savedUri;
      }
      return result;
    } catch (err) {
      throw Exception(err);
    }
  }

  Future<String> stopRecorder() async {
    String result =
        await invokeMethod('stopRecorder', <String, dynamic>{}) as String;

    recorderState = RecorderState.isStopped;

    _removeRecorderCallback();
    _removeDbPeakCallback();

    if (isOggOpus) {
      // delete the target if it exists
      // (ffmpeg gives an error if the output file already exists)
      File f = File(savedUri);
      if (f.existsSync()) await f.delete();
      // The following ffmpeg instruction re-encode the Apple CAF to OPUS.
      // Unfortunately we cannot just remix the OPUS data,
      // because Apple does not set the "extradata" in its private OPUS format.
      // It will be good if we can improve this...
      int rc = await flutterSoundHelper.executeFFmpegWithArguments([
        '-loglevel',
        'error',
        '-y',
        '-i',
        tmpUri,
        '-c:a',
        'libopus',
        savedUri,
      ]); // remux CAF to OGG
      if (rc != 0) return null;
      return savedUri;
    }
    return result;
  }

  Future<String> pauseRecorder() async {
    String result =
        await invokeMethod('pauseRecorder', <String, dynamic>{}) as String;
    recorderState = RecorderState.isPaused;
    return result;
  }

  Future<String> resumeRecorder() async {
    String result =
        await invokeMethod('resumeRecorder', <String, dynamic>{}) as String;
    recorderState = RecorderState.isRecording;
    return result;
  }
}

class RecordStatus {
  final double currentPosition;

  RecordStatus.fromJSON(Map<String, dynamic> json)
      : currentPosition = double.parse(json['current_position'] as String);

  @override
  String toString() {
    return 'currentPosition: $currentPosition';
  }
}

class RecorderException implements Exception {
  final String _message;

  RecorderException(this._message);

  String get message => _message;
}

class RecorderRunningException extends RecorderException {
  RecorderRunningException(String message) : super(message);
}

class CodecNotSupportedException extends RecorderException {
  CodecNotSupportedException(String message) : super(message);
}

class RecordingPermissionException extends RecorderException {
  RecordingPermissionException(String message) : super(message);
}

class _InitializationInProgress implements Exception {
  _InitializationInProgress() {
    print('An initialization is currently already in progress.');
  }
}
