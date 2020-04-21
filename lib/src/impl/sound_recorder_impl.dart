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
import 'package:permission_handler/permission_handler.dart';

import '../android/android_audio_source.dart';
import '../android/android_encoder.dart';
import '../android/android_output_format.dart';
import '../codec.dart';

import '../ios/ios_quality.dart';
import '../plugins/sound_recorder_plugin.dart';
import '../recording_disposition.dart';
import '../sound_recorder.dart';
import '../util/codec_conversions.dart';
import '../util/file_management.dart';
import 'recording_disposition_manager.dart';

enum _RecorderState {
  isStopped,
  isPaused,
  isRecording,
}

/// Provide an API for recording audio.
class SoundRecorderImpl {
  bool _isInited = false;
  _RecorderState _recorderState = _RecorderState.isStopped;

  RecordingDispositionManager _dispositionManager;

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

  /// Create a [SoundRecorderImpl] to record audio.
  SoundRecorderImpl();

  /// returns true if we are recording.
  bool get isRecording => (_recorderState ==
      _RecorderState
          .isRecording); //|| recorderState == t_RECORDER_STATE.IS_PAUSED);

  /// returns true if the record is stopped.
  bool get isStopped => (_recorderState == _RecorderState.isStopped);

  /// returns true if the recorder is paused.
  bool get isPaused => (_recorderState == _RecorderState.isPaused);

  ///
  SoundRecorderPlugin getPlugin() => SoundRecorderPlugin();

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

  Future<dynamic> _invokeMethod(String methodName, Map<String, dynamic> args) {
    return getPlugin().invokeMethod(this, methodName, args);
  }

  /// internal method.
  Future<SoundRecorderImpl> initialize() async {
    if (!_isInited) {
      _isInited = true;
      _dispositionManager = RecordingDispositionManager(this);
      getPlugin().register(this);
      await _invokeMethod('initializeFlautoRecorder', <String, dynamic>{});
    }
    return this;
  }

  /// Call this method when you have finished with the recorder
  /// and want to release any resources the recorder has attached.
  Future<void> release() async {
    if (_isInited) {
      _isInited = false;
      await stop();
      await _invokeMethod('releaseFlautoRecorder', <String, dynamic>{});
      getPlugin().release(this);
    }
  }

  /// Returns true if the specified encoder is supported by
  /// flutter_sound on this platform
  Future<bool> isSupported(Codec codec) async {
    await initialize();
    bool result;
    // For encoding ogg/opus on ios, we need to support two steps :
    // - encode CAF/OPPUS (with native Apple AVFoundation)
    // - remux CAF file format to OPUS file format (with ffmpeg)
    if ((codec == Codec.opusOGG) && (Platform.isIOS)) {
      codec = Codec.cafOpus;
    }

    result = await _invokeMethod(
        'isEncoderSupported', <String, dynamic>{'codec': codec.index}) as bool;

    return result;
  }

  /// Starts the recorder, recording audio to the passed in [path]
  /// using the settings given.
  /// The file at [path] will be overwritten.
  Future<void> startRecorder({
    @required String path,
    int sampleRate = 16000,
    int numChannels = 1,
    int bitRate = 16000,
    Codec codec = Codec.aacADTS,
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
    if (!directoryExists(dirname(path))) {
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
    if (!await isSupported(codec)) {
      throw CodecNotSupportedException('Codec not supported.');
    }

    _timePaused = Duration(seconds: 0);

    // If we want to record OGG/OPUS on iOS, we record with CAF/OPUS and we remux the CAF file format to a regular OGG/OPUS.
    // We use FFmpeg for that task.
    // The remux occurs when we call stopRecorder
    if ((Platform.isIOS) &&
        ((codec == Codec.opusOGG) || (fileExtension(path) == '.opus'))) {
      _isOggOpus = true;
      codec = Codec.cafOpus;

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

      if (exists(_recordingToPath)) delete(_recordingToPath);
      await _invokeMethod('startRecorder', param) as String;
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
  Future<void> stop() async {
    await _invokeMethod('stopRecorder', <String, dynamic>{}) as String;

    _recorderState = _RecorderState.isStopped;

    _dispositionManager.release();

    if (_isOggOpus) {
      CodecConversions.cafOpusToOpus(
          _recordingToPath, _recordingToOriginalPath);

      return _recordingToOriginalPath;
    }
  }

  /// Pause recording.
  /// The recording must be recording when this method is called
  /// otherwise an [RecorderNotRunningException]
  Future<void> pause() async {
    if (!isRecording) {
      throw RecorderNotRunningException(
          "You cannot pause recording when the recorder is not running.");
    }

    await _invokeMethod('pauseRecorder', <String, dynamic>{}) as String;
    _pauseStarted = DateTime.now();
    _recorderState = _RecorderState.isPaused;
  }

  /// Resume recording.
  /// The recording must be paused when this method is called
  /// otherwise a [RecorderNotPausedException] will be thrown.
  Future<void> resume() async {
    if (!isPaused) {
      throw RecorderNotPausedException(
          "You cannot resume recording when the recorder is not paused.");
    }
    _timePaused += (DateTime.now().difference(_pauseStarted));

    try {
      await _invokeMethod('resumeRecorder', <String, dynamic>{}) as bool;
    } on Object catch (e) {
      print("Exception throw trying to resume the recorder $e");
      await stop();
      rethrow;
    }
    _recorderState = _RecorderState.isRecording;
  }

  /// Sets the frequency at which duration updates are sent to
  /// duration listeners.
  /// The default is every 10 milliseconds.
  Future<String> setSubscriptionDuration(Duration interval) async {
    await initialize();
    var r = await _invokeMethod('setSubscriptionDuration', <String, dynamic>{
      'sec': interval.inSeconds.toDouble(),
    }) as String;
    return r;
  }

  /// Defines the interval at which the peak level should be updated.
  /// Default is 0.8 seconds
  Future<String> setDbPeakLevelUpdate(Duration interval) async {
    await initialize();
    var r = await _invokeMethod('setDbPeakLevelUpdate', <String, dynamic>{
      'intervalInSecs': interval.inSeconds.toDouble(),
    }) as String;
    return r;
  }

  /// Enables or disables processing the Peak level in db's. Default is disabled
  Future<String> setDbLevelEnabled({bool enabled}) async {
    await initialize();
    var r = await _invokeMethod('setDbLevelEnabled', <String, dynamic>{
      'enabled': enabled,
    }) as String;
    return r;
  }

  /// Call by the plugin to notify us that the duration of the recording
  /// has changed.
  void updateDurationDisposition(Map arguments) {
    _dispositionManager.updateDurationDisposition(arguments, _timePaused);
  }

  /// Called by the plugin to notify us of the current Db Level of the
  /// recording.
  void updateDbPeakDispostion(Map arguments) {
    _dispositionManager.updateDbPeakDispostion(arguments);
  }
}
