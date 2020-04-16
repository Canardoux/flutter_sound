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

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import 'android/android_audio_source.dart';
import 'android/android_encoder.dart';
import 'android/android_output_format.dart';
import 'codec.dart';
import 'flutter_sound_helper.dart';

import 'ios/ios_quality.dart';
import 'plugins/flutter_recorder_plugin.dart';
import 'recording_disposition.dart';
import 'recording_disposition_manager.dart';

enum _RecorderState {
  isStopped,
  isPaused,
  isRecording,
}

FlautoRecorderPlugin _flautoRecorderPlugin; // Singleton, lazy initialized

/// Provide an API for recording audio.
class FlutterSoundRecorder {
  bool _isInited = false;
  _RecorderState _recorderState = _RecorderState.isStopped;

  RecordingDispositionManager _dispositionManager;

  int _slotNo;

// Set by startRecorder when the user wants to record an ogg/opus
  bool _isOggOpus = false;
  // Used by startRecorder/stopRecorder to keep the caller wanted uri
  String _recordingToOriginalPath;

  /// The path we will be recording to.
  /// This is often the same as [_recordingToOriginalPath] unless
  /// we need to record to a different codec and then remux
  /// the file after recording finishes.
  String _recordingToPath;

  /// track the total time we hav been paused during
  /// the current recording session.
  var _timePaused = Duration(seconds: 0);

  /// I fwe have paused during the current recording session this
  /// will be the time
  /// the most recent pause commenced.
  DateTime _pauseStarted;

  ///
  int get slotNo => _slotNo;

  /// returns true if we are recording.
  bool get isRecording => (_recorderState ==
      _RecorderState
          .isRecording); //|| recorderState == t_RECORDER_STATE.IS_PAUSED);

  /// returns true if the record is stopped.
  bool get isStopped => (_recorderState == _RecorderState.isStopped);

  /// returns true if the recorder is paused.
  bool get isPaused => (_recorderState == _RecorderState.isPaused);

  ///
  FlautoRecorderPlugin getPlugin() => _flautoRecorderPlugin;

  ///
  Future<dynamic> invokeMethod(String methodName, Map<String, dynamic> call) {
    call['slotNo'] = slotNo;
    return getPlugin().invokeMethod(methodName, call);
  }

  /// Returns a stream of [RecordingDisposition] which
  /// provides live updates as the recording proceeds.
  /// The [RecordingDisposition] items contain the duration
  /// and decibel level of the recording at the point in
  /// time that it is sent.
  /// Set the [interval] to control the time between each
  /// event. [interval] defaults to 10ms.
  Stream<RecordingDisposition> dispositionStream(
      {Duration interval = const Duration(milliseconds: 10)}) {
    return _dispositionManager.stream(interval: interval);
  }

  /// internal method.
  Future<FlutterSoundRecorder> initialize() async {
    if (!_isInited) {
      _isInited = true;
      _dispositionManager = RecordingDispositionManager(this);
      if (_flautoRecorderPlugin == null) {
        _flautoRecorderPlugin = FlautoRecorderPlugin();
      } // The lazy singleton
      _slotNo = getPlugin().lookupEmptySlot(RecorderPluginConnector(this));
      await invokeMethod('initializeFlautoRecorder', <String, dynamic>{});
    }
    return this;
  }

  /// Call this method when you have finished with the recorder
  /// and want to release any resources the recorder has attached.
  Future<void> release() async {
    if (_isInited) {
      _isInited = false;
      await stopRecorder();
      await invokeMethod('releaseFlautoRecorder', <String, dynamic>{});
      getPlugin().freeSlot(slotNo);
      _slotNo = null;
    }
  }

  /// Returns true if the specified encoder is supported by
  /// flutter_sound on this platform
  Future<bool> isEncoderSupported(Codec codec) async {
    await initialize();
    bool result;
    // For encoding ogg/opus on ios, we need to support two steps :
    // - encode CAF/OPPUS (with native Apple AVFoundation)
    // - remux CAF file format to OPUS file format (with ffmpeg)

    if ((codec == Codec.codecOpus) && (Platform.isIOS)) {
      //if (!await isFFmpegSupported( ))
      //result = false;
      //else
      result = await invokeMethod('isEncoderSupported',
          <String, dynamic>{'codec': Codec.codecCafOpus.index}) as bool;
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

  /// Starts the recorder, recording audio to the passed in [path]
  /// using the settings given.
  /// The file at [path] will be overwritten.
  Future<void> startRecorder({
    @required String path,
    int sampleRate = 16000,
    int numChannels = 1,
    int bitRate = 16000,
    Codec codec = Codec.codecAac,
    AndroidEncoder androidEncoder = AndroidEncoder.aacCodec,
    AndroidAudioSource androidAudioSource = AndroidAudioSource.mic,
    AndroidOutputFormat androidOutputFormat = AndroidOutputFormat.defaultFormat,
    IosQuality iosQuality = IosQuality.low,
    bool requestPermission = true,
  }) async {
    await initialize();

    _recordingToOriginalPath = path;
    _recordingToPath = path;

    /// the directory where we are recording to MUST exist.
    if (!File(dirname(path)).existsSync()) {
      throw DirectoryNotFoundException(
          'The directory ${dirname(path)} must exists');
    }

    // Request Microphone permission if needed
    if (requestPermission) {
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw RecordingPermissionException("Microphone permission not granted");
      }
    }

    /// We must not be recording.
    if (_recorderState != null && _recorderState != _RecorderState.isStopped) {
      throw RecorderRunningException('Recorder is not stopped.');
    }

    /// the codec must be supported.
    if (!await isEncoderSupported(codec)) {
      throw CodecNotSupportedException('Codec not supported.');
    }

    _timePaused = Duration(seconds: 0);

    // If we want to record OGG/OPUS on iOS, we record with CAF/OPUS and we remux the CAF file format to a regular OGG/OPUS.
    // We use FFmpeg for that task.
    // The remux occurs when we call stopRecorder
    if ((Platform.isIOS) &&
        ((codec == Codec.codecOpus) || (fileExtension(path) == '.opus'))) {
      _isOggOpus = true;
      codec = Codec.codecCafOpus;

      /// temp file to record CAF/OPUS file to
      _recordingToPath = tempFile(suffix: '.caf');
    } else {
      _isOggOpus = false;
    }

    try {
      var param = <String, dynamic>{
        'path': _recordingToPath,
        'sampleRate': sampleRate,
        'numChannels': numChannels,
        'bitRate': bitRate,
        'codec': codec.index,
        'androidEncoder': androidEncoder?.value,
        'androidAudioSource': androidAudioSource?.value,
        'androidOutputFormat': androidOutputFormat?.value,
        'iosQuality': iosQuality?.value
      };

      var f = File(_recordingToPath);
      if (f.existsSync()) f.deleteSync();
      await invokeMethod('startRecorder', param) as String;
      _recorderState = _RecorderState.isRecording;
    } on Object catch (err) {
      throw Exception(err);
    }
  }

  /// Stops the current recording.
  /// An exception is thrown if the recording can't be stopped.
  ///
  /// [stopRecording] is also responsible for remux'ing the recording
  /// for some codecs which aren't natively support. Dependindig on the
  /// size of the file this could take a few moments to a few minutes.
  Future<void> stopRecorder() async {
    await invokeMethod('stopRecorder', <String, dynamic>{}) as String;

    _recorderState = _RecorderState.isStopped;

    _dispositionManager.release();

    if (_isOggOpus) {
      /// we have to remux the file to get it into the required codec.
      // delete the target if it exists
      // (ffmpeg gives an error if the output file already exists)
      var f = File(_recordingToOriginalPath);
      if (f.existsSync()) await f.deleteSync();
      // The following ffmpeg instruction re-encode the Apple CAF to OPUS.
      // Unfortunately we cannot just remix the OPUS data,
      // because Apple does not set the "extradata" in its private OPUS format.
      // It will be good if we can improve this...
      var rc = await FlutterSoundHelper().executeFFmpegWithArguments([
        '-loglevel',
        'error',
        '-y',
        '-i',
        _recordingToPath,
        '-c:a',
        'libopus',
        _recordingToOriginalPath,
      ]); // remux CAF to OGG
      if (rc != 0) return null;
      return _recordingToOriginalPath;
    }
  }

  /// Pause recording.
  /// The recording must be recording when this method is called
  /// otherwise an [RecorderNotRunningException]
  Future<void> pauseRecorder() async {
    if (!isRecording) {
      throw RecorderNotRunningException(
          "You cannot pause recording when the recorder is not running.");
    }

    await invokeMethod('pauseRecorder', <String, dynamic>{}) as String;
    _pauseStarted = DateTime.now();
    _recorderState = _RecorderState.isPaused;
  }

  /// Resume recording.
  /// The recording must be paused when this method is called
  /// otherwise a [RecorderNotPausedException] will be thrown.
  Future<void> resumeRecorder() async {
    if (!isPaused) {
      throw RecorderNotPausedException(
          "You cannot resume recording when the recorder is not paused.");
    }
    _timePaused += (DateTime.now().difference(_pauseStarted));

    try {
      await invokeMethod('resumeRecorder', <String, dynamic>{}) as bool;
    } on Object catch (e) {
      print("Exception throw trying to resume the recorder $e");
      await stopRecorder();
      rethrow;
    }
    _recorderState = _RecorderState.isRecording;
  }

  void _updateDurationDisposition(Map arguments) {
    _dispositionManager.updateDurationDisposition(arguments, _timePaused);
  }

  void _updateDbPeakDispostion(Map arguments) {
    _dispositionManager.updateDbPeakDispostion(arguments);
  }

  /// creates an empty temporary file in the system temp directory.
  /// You are responsible for deleting the file once done.
  /// The temp file name will be <uuid>.tmp
  /// unless you provide a [suffix] in which
  /// case the file name will be <uuid>.<suffix>

  static String tempFile({String suffix}) {
    suffix ??= 'tmp';

    if (!suffix.startsWith('.')) {
      suffix = '.$suffix';
    }
    var uuid = Uuid();
    return '${join(Directory.systemTemp.path, uuid.v4())}$suffix';
  }
}

/// Class exists to help us reduce the public interface
/// that we expose to users.
class RecorderPluginConnector {
  final FlutterSoundRecorder _recorder;

  ///
  RecorderPluginConnector(this._recorder);

  ///
  void updateDurationDisposition(Map arguments) {
    _recorder._updateDurationDisposition(arguments);
  }

  ///
  void updateDbPeakDispostion(Map arguments) {
    _recorder._updateDbPeakDispostion(arguments);
  }
}

/// Base class for all exeception throw via
/// the recorder.
class RecorderException implements Exception {
  final String _message;

  ///
  RecorderException(this._message);

  String toString() => _message;
}

/// Thrown if you attempt an operation that requires the recorder
/// to be stopped (not recording) and it is currently recording.
class RecorderRunningException extends RecorderException {
  ///
  RecorderRunningException(String message) : super(message);
}

/// Thrown when you attempt to make a recording with a codec
/// that is not supported on the current platform.
class CodecNotSupportedException extends RecorderException {
  ///
  CodecNotSupportedException(String message) : super(message);
}

/// Thrown when you attempt to make a recording and don't have
/// OS permissions to record.
class RecordingPermissionException extends RecorderException {
  ///
  RecordingPermissionException(String message) : super(message);
}

/// Thrown if the directory that you want to record into
/// doesn't exists.
class DirectoryNotFoundException extends RecorderException {
  ///
  DirectoryNotFoundException(String message) : super(message);
}

/// Thrown if you attempt an operation that requires the recorder
/// to be running (recording) and it is not currently recording.
class RecorderNotRunningException extends RecorderException {
  ///
  RecorderNotRunningException(String message) : super(message);
}

/// Throw if you attempt to resume recording but the
/// record is not currently paused.
class RecorderNotPausedException extends RecorderException {
  ///
  RecorderNotPausedException(String message) : super(message);
}
