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
import 'dart:core';
import 'dart:io';
import 'dart:io' show Platform;

import 'package:flutter_sound/src/flutter_recorder_plugin.dart';

import 'ios_quality.dart';
import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'src/android_encoder.dart';
import 'src/flauto.dart';
import 'src/recording_disposition.dart';
import 'src/recording_disposition_manager.dart';

enum t_RECORDER_STATE {
  IS_STOPPED,
  IS_PAUSED,
  IS_RECORDING,
}

FlautoRecorderPlugin flautoRecorderPlugin; // Singleton, lazy initialized

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
  bool _isInited = false;
  t_RECORDER_STATE _recorderState = t_RECORDER_STATE.IS_STOPPED;

  RecordingDispositionManager _dispositionManager;

  int _slotNo;

  bool _isOggOpus =
      false; // Set by startRecorder when the user wants to record an ogg/opus
  String
      _savedUri; // Used by startRecorder/stopRecorder to keep the caller wanted uri
  String
      _tmpUri; // Used by startRecorder/stopRecorder to keep the temporary uri to record CAF

  /// track the total time we hav been paused during the current recording session.
  var _timePaused = Duration(seconds: 0);

  /// I fwe have paused during the current recording session this will be the time
  /// the most recent pause commenced.
  DateTime _pauseStarted;

  int get slotNo => _slotNo;

  bool get isRecording => (_recorderState ==
      t_RECORDER_STATE
          .IS_RECORDING); //|| recorderState == t_RECORDER_STATE.IS_PAUSED);

  bool get isStopped => (_recorderState == t_RECORDER_STATE.IS_STOPPED);

  bool get isPaused => (_recorderState == t_RECORDER_STATE.IS_PAUSED);

  FlautoRecorderPlugin getPlugin() => flautoRecorderPlugin;

  Future<dynamic> invokeMethod(String methodName, Map<String, dynamic> call) {
    call['slotNo'] = slotNo;
    return getPlugin().invokeMethod(methodName, call);
  }

  Stream<RecordingDisposition> dispositionStream(Duration interval) {
    return _dispositionManager.stream(interval: interval);
  }

  Future<FlutterSoundRecorder> initialize() async {
    if (!_isInited) {
      _isInited = true;
      _dispositionManager = RecordingDispositionManager(this);
      if (flautoRecorderPlugin == null) {
        flautoRecorderPlugin = FlautoRecorderPlugin();
      } // The lazy singleton
      _slotNo = getPlugin().lookupEmptySlot(RecorderPluginConnector(this));
      await invokeMethod('initializeFlautoRecorder', <String, dynamic>{});
    }
    return this;
  }

  Future<void> release() async {
    if (_isInited) {
      _isInited = false;
      await stopRecorder();
      await invokeMethod('releaseFlautoRecorder', <String, dynamic>{});
      getPlugin().freeSlot(slotNo);
      _slotNo = null;
    }
  }

  /// Returns true if the specified encoder is supported by flutter_sound on this platform
  Future<bool> isEncoderSupported(Codec codec) async {
    await initialize();
    bool result;
    // For encoding ogg/opus on ios, we need to support two steps :
    // - encode CAF/OPPUS (with native Apple AVFoundation)
    // - remux CAF file format to OPUS file format (with ffmpeg)

    if ((codec == Codec.CODEC_OPUS) && (Platform.isIOS)) {
      //if (!await isFFmpegSupported( ))
      //result = false;
      //else
      result = await invokeMethod('isEncoderSupported',
          <String, dynamic>{'codec': Codec.CODEC_CAF_OPUS.index}) as bool;
    } else {
      result = await invokeMethod(
              'isEncoderSupported', <String, dynamic>{'codec': codec.index})
          as bool;
    }
    return result;
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
    var fout = File('${tempDir.path}/${defaultPaths[codec.index]}');
    return fout.path;
  }

  Future<String> startRecorder({
    String uri,
    int sampleRate = 16000,
    int numChannels = 1,
    int bitRate = 16000,
    Codec codec = Codec.CODEC_AAC,
    AndroidEncoder androidEncoder = AndroidEncoder.AAC,
    AndroidAudioSource androidAudioSource = AndroidAudioSource.MIC,
    AndroidOutputFormat androidOutputFormat = AndroidOutputFormat.DEFAULT,
    IosQuality iosQuality = IosQuality.LOW,
    bool requestPermission = true,
  }) async {
    await initialize();
    _timePaused = Duration(seconds: 0);
    // Request Microphone permission if needed
    if (requestPermission) {
      PermissionStatus status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw RecordingPermissionException("Microphone permission not granted");
      }
    }

    if (_recorderState != null &&
        _recorderState != t_RECORDER_STATE.IS_STOPPED) {
      throw RecorderRunningException('Recorder is not stopped.');
    }
    if (!await isEncoderSupported(codec)) {
      throw CodecNotSupportedException('Codec not supported.');
    }

    if (uri == null) uri = await defaultPath(codec);

    // If we want to record OGG/OPUS on iOS, we record with CAF/OPUS and we remux the CAF file format to a regular OGG/OPUS.
    // We use FFmpeg for that task.
    if ((Platform.isIOS) &&
        ((codec == Codec.CODEC_OPUS) || (fileExtension(uri) == '.opus'))) {
      _savedUri = uri;
      _isOggOpus = true;
      codec = Codec.CODEC_CAF_OPUS;
      var tempDir = await getTemporaryDirectory();
      var fout = File('${tempDir.path}/$slotNo-flutter_sound-tmp.caf');
      if (fout.existsSync()) {
        // delete the old temporary file if it exists
      }
      await fout.delete();
      uri = fout.path;
      _tmpUri = uri;
    } else {
      _isOggOpus = false;
    }

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

      String result = await invokeMethod('startRecorder', param) as String;
      _recorderState = t_RECORDER_STATE.IS_RECORDING;
      // if the caller wants OGG/OPUS we must remux the temporary file
      if ((result != null) && _isOggOpus) {
        return _savedUri;
      }
      return result;
    } catch (err) {
      throw Exception(err);
    }
  }

  Future<String> stopRecorder() async {
    String result =
        await invokeMethod('stopRecorder', <String, dynamic>{}) as String;

    _recorderState = t_RECORDER_STATE.IS_STOPPED;

    _dispositionManager.release();

    if (_isOggOpus) {
      // delete the target if it exists
      // (ffmpeg gives an error if the output file already exists)
      File f = File(_savedUri);
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
        _tmpUri,
        '-c:a',
        'libopus',
        _savedUri,
      ]); // remux CAF to OGG
      if (rc != 0) return null;
      return _savedUri;
    }
    return result;
  }

  Future<String> pauseRecorder() async {
    String result =
        await invokeMethod('pauseRecorder', <String, dynamic>{}) as String;
    _pauseStarted = DateTime.now();
    _recorderState = t_RECORDER_STATE.IS_PAUSED;
    return result;
  }

  Future<bool> resumeRecorder() async {
    _timePaused += (DateTime.now().difference(_pauseStarted));
    bool b = await invokeMethod('resumeRecorder', <String, dynamic>{}) as bool;
    if (!b) {
      await stopRecorder();
      return false;
    }
    _recorderState = t_RECORDER_STATE.IS_RECORDING;
    return true;
  }

  void _updateDurationDisposition(Map arguments) {
    _dispositionManager.updateDurationDisposition(arguments, _timePaused);
  }

  void _updateDbPeakDispostion(Map arguments) {
    _dispositionManager.updateDbPeakDispostion(arguments);
  }
}

/// Class exists to help us reduce the public interface
/// that we expose to users.
class RecorderPluginConnector {
  FlutterSoundRecorder recorder;
  RecorderPluginConnector(this.recorder);

  void updateDurationDisposition(Map arguments) {
    recorder._updateDurationDisposition(arguments);
  }

  void updateDbPeakDispostion(Map arguments) {
    recorder._updateDbPeakDispostion(arguments);
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
