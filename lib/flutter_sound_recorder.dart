/*
 * This file is part of Flutter-Sound (Flauto).
 *
 *   Flutter-Sound (Flauto) is free software: you can redistribute it and/or modify
 *   it under the terms of the Lesser GNU General Public License
 *   version 3 (LGPL3) as published by the Free Software Foundation.
 *
 *   Flutter-Sound (Flauto) is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the Lesser GNU General Public License
 *   along with Flutter-Sound (Flauto).  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:io' show Platform;
import 'dart:typed_data' show Uint8List;

import 'package:flutter/services.dart';
import 'package:flutter_sound/android_encoder.dart';
import 'package:flutter_sound/ios_quality.dart';
import 'package:flutter_sound/flauto.dart';
import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

enum t_RECORDER_STATE {
  IS_STOPPED,
  IS_PAUSED,
  IS_RECORDING,
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
    return getChannel().invokeMethod(methodName, call);
  }

  Future<dynamic> channelMethodCallHandler(MethodCall call) // This procedure is superCharged in "flauto"
  {
    int slotNo = call.arguments['slotNo'];
    FlutterSoundRecorder aRecorder = slots[slotNo];
    switch (call.method) {
      case "updateRecorderProgress":
        {
          aRecorder.upgradeRecorderProgress(call.arguments);
        }
        break;

      case "updateDbPeakProgress":
        {
          aRecorder.updateDbPeakProgress(call.arguments);
        }
        break;

      default:
        throw new ArgumentError('Unknown method ${call.method}');
    }
    return null;
  }
}

final List<String> defaultPaths = [
  'flauto.aac', // DEFAULT
  'flauto.aac', // CODEC_AAC
  'flauto.opus', // CODEC_OPUS
  'flauto.caf', // CODEC_CAF_OPUS
  'flauto.mp3', // CODEC_MP3
  'flauto.ogg', // CODEC_VORBIS
  'flauto.wav', // CODEC_PCM
];

class FlutterSoundRecorder {
  bool isInited = false;
  t_RECORDER_STATE recorderState = t_RECORDER_STATE.IS_STOPPED;
  StreamController<RecordStatus> _recorderController;
  StreamController<double> _dbPeakController;
  int slotNo = null;

  bool isOggOpus = false; // Set by startRecorder when the user wants to record an ogg/opus
  String savedUri; // Used by startRecorder/stopRecorder to keep the caller wanted uri
  String tmpUri; // Used by startRecorder/stopRecorder to keep the temporary uri to record CAF

  bool get isRecording => (recorderState == t_RECORDER_STATE.IS_RECORDING || recorderState == t_RECORDER_STATE.IS_PAUSED);

  bool get isStopped => (recorderState == t_RECORDER_STATE.IS_STOPPED);

  bool get isPaused => (recorderState == t_RECORDER_STATE.IS_PAUSED);

  Stream<RecordStatus> get onRecorderStateChanged => _recorderController.stream;

  /// Value ranges from 0 to 120
  Stream<double> get onRecorderDbPeakChanged => _dbPeakController.stream;

  FlutterSoundRecorder() {}

  FlautoRecorderPlugin getPlugin() => flautoRecorderPlugin;

  Future<dynamic> invokeMethod(String methodName, Map<String, dynamic> call) {
    call['slotNo'] = slotNo;
    return getPlugin().invokeMethod(methodName, call);
  }

  Future<FlutterSoundRecorder> initialize() async {
    if (!isInited) {
      isInited = true;
      if (flautoRecorderPlugin == null) flautoRecorderPlugin = FlautoRecorderPlugin(); // The lazy singleton
      slotNo = getPlugin().lookupEmptySlot(this);
      await invokeMethod('initializeFlautoRecorder', {});
    }
    return this;
  }

  Future<void> release() async {
    isInited = false;
    await stopRecorder();
    _removeRecorderCallback();
    await invokeMethod('releaseFlautoRecorder', {});
    getPlugin().freeSlot(slotNo);
    slotNo = null;
  }

  void upgradeRecorderProgress(Map call) {
    Map<String, dynamic> result = json.decode(call['arg']);
    if (_recorderController != null) _recorderController.add(new RecordStatus.fromJSON(result));
  }

  void updateDbPeakProgress(Map call) {
    if (_dbPeakController != null) _dbPeakController.add(call['arg']);
  }

  /// Returns true if the specified encoder is supported by flutter_sound on this platform
  Future<bool> isEncoderSupported(t_CODEC codec) async {
    bool result;
    // For encoding ogg/opus on ios, we need to support two steps :
    // - encode CAF/OPPUS (with native Apple AVFoundation)
    // - remux CAF file format to OPUS file format (with ffmpeg)

    if ((codec == t_CODEC.CODEC_OPUS) && (Platform.isIOS)) {
      //if (!await isFFmpegSupported( ))
      //result = false;
      //else
      result = await invokeMethod('isEncoderSupported', <String, dynamic>{'codec': t_CODEC.CODEC_CAF_OPUS.index});
    } else
      result = await invokeMethod('isEncoderSupported', <String, dynamic>{'codec': codec.index});
    return result;
  }

  Future<void> _setRecorderCallback() async {
    if (_recorderController == null) {
      _recorderController = new StreamController.broadcast();
    }
    if (_dbPeakController == null) {
      _dbPeakController = new StreamController.broadcast();
    }
  }

  void _removeRecorderCallback() {
    if (_recorderController != null) {
      _recorderController
        ..add(null) // We keep that strange line for backward compatibility
        ..close();
      _recorderController = null;
    }
  }

  void _removeDbPeakCallback() {
    if (_dbPeakController != null) {
      _dbPeakController
        ..add(null)
        ..close();
      _dbPeakController = null;
    }
  }

  Future<String> setSubscriptionDuration(double sec) async {
    String r = await invokeMethod('setSubscriptionDuration', <String, dynamic>{
      'sec': sec,
    });
    return r;
  }

  /// Defines the interval at which the peak level should be updated.
  /// Default is 0.8 seconds
  Future<String> setDbPeakLevelUpdate(double intervalInSecs) async {
    String r = await invokeMethod('setDbPeakLevelUpdate', <String, dynamic>{
      'intervalInSecs': intervalInSecs,
    });
    return r;
  }

  /// Enables or disables processing the Peak level in db's. Default is disabled
  Future<String> setDbLevelEnabled(bool enabled) async {
    String r = await invokeMethod('setDbLevelEnabled', <String, dynamic>{
      'enabled': enabled,
    });
    return r;
  }

  /// Return the file extension for the given path.
  /// path can be null. We return null in this case.
  String fileExtension(String path) {
    if (path == null) return null;
    String r = p.extension(path);
    return r;
  }

  Future<String> defaultPath(t_CODEC codec) async {
    Directory tempDir = await getTemporaryDirectory();
    File fout = File('${tempDir.path}/${defaultPaths[codec.index]}');
    return fout.path;
  }

  Future<String> startRecorder({
    String uri,
    int sampleRate = 16000,
    int numChannels = 1,
    int bitRate = 16000,
    t_CODEC codec = t_CODEC.CODEC_AAC,
    AndroidEncoder androidEncoder = AndroidEncoder.AAC,
    AndroidAudioSource androidAudioSource = AndroidAudioSource.MIC,
    AndroidOutputFormat androidOutputFormat = AndroidOutputFormat.DEFAULT,
    IosQuality iosQuality = IosQuality.LOW,
  }) async {
    // Request Microphone permission if needed
    Map<PermissionGroup, PermissionStatus> permission = await PermissionHandler().requestPermissions([PermissionGroup.microphone]);
    if (permission[PermissionGroup.microphone] != PermissionStatus.granted) throw new Exception("Microphone permission not granted");

    if (recorderState != null && recorderState != t_RECORDER_STATE.IS_STOPPED) {
      throw new RecorderRunningException('Recorder is not stopped.');
    }
    if (!await isEncoderSupported(codec)) throw new RecorderRunningException('Codec not supported.');

    if (uri == null) uri = await defaultPath(codec);

    // If we want to record OGG/OPUS on iOS, we record with CAF/OPUS and we remux the CAF file format to a regular OGG/OPUS.
    // We use FFmpeg for that task.
    if ((Platform.isIOS) && ((codec == t_CODEC.CODEC_OPUS) || (fileExtension(uri) == '.opus'))) {
      savedUri = uri;
      isOggOpus = true;
      codec = t_CODEC.CODEC_CAF_OPUS;
      Directory tempDir = await getTemporaryDirectory();
      File fout = File('${tempDir.path}/$slotNo-flutter_sound-tmp.caf');
      if (fout.existsSync()) // delete the old temporary file if it exists
        await fout.delete();
      uri = fout.path;
      tmpUri = uri;
    } else
      isOggOpus = false;

    try {
      var param = <String, dynamic>{
        'path': uri,
        'sampleRate': sampleRate,
        'numChannels': numChannels,
        'bitRate': bitRate,
        'codec': codec.index,
        'androidEncoder': androidEncoder?.value,
        'androidAudioSource': androidAudioSource?.value,
        'androidOutputFormat': androidOutputFormat?.value,
        'iosQuality': iosQuality?.value
      };

      String result = await invokeMethod('startRecorder', param);

      _setRecorderCallback();
      recorderState = t_RECORDER_STATE.IS_RECORDING;
      // if the caller wants OGG/OPUS we must remux the temporary file
      if ((result != null) && isOggOpus) {
        return savedUri;
      }
      return result;
    } catch (err) {
      throw new Exception(err);
    }
  }

  Future<String> stopRecorder() async {
    String result = await invokeMethod('stopRecorder', {});

    recorderState = t_RECORDER_STATE.IS_STOPPED;

    _removeRecorderCallback();
    _removeDbPeakCallback();

    if (isOggOpus) {
      // delete the target if it exists (ffmpeg gives an error if the output file already exists)
      File f = File(savedUri);
      if (f.existsSync()) await f.delete();
      // The following ffmpeg instruction re-encode the Apple CAF to OPUS. Unfortunatly we cannot just remix the OPUS data,
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
    String result = await invokeMethod('pauseRecorder', {});
    recorderState = t_RECORDER_STATE.IS_PAUSED;
    return result;
  }

  Future<bool> resumeRecorder() async {
    bool b = await invokeMethod('resumeRecorder', {});
    if (!b) {
      stopRecorder();
      return false;
    }
    recorderState = t_RECORDER_STATE.IS_RECORDING;
    return true;
  }
}

class RecordStatus {
  final double currentPosition;

  RecordStatus.fromJSON(Map<String, dynamic> json) : currentPosition = double.parse(json['current_position']);

  @override
  String toString() {
    return 'currentPosition: $currentPosition';
  }
}

class RecorderRunningException implements Exception {
  final String message;

  RecorderRunningException(this.message);
}
