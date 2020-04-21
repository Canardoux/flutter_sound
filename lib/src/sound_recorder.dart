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
import 'dart:core';

import 'package:flutter/foundation.dart';

import 'android/android_audio_source.dart';
import 'android/android_encoder.dart';
import 'android/android_output_format.dart';
import 'codec.dart';

import 'impl/sound_recorder_impl.dart';
import 'ios/ios_quality.dart';
import 'plugins/sound_recorder_plugin.dart';
import 'recording_disposition.dart';

/// Provide an API for recording audio.
class SoundRecorder {
  SoundRecorderImpl _impl;

  /// Create a [SoundRecorder] to record audio.
  SoundRecorder();

  /// returns true if we are recording.
  bool get isRecording => _impl.isRecording;

  /// returns true if the record is stopped.
  bool get isStopped => _impl.isStopped;

  /// returns true if the recorder is paused.
  bool get isPaused => _impl.isPaused;

  ///
  SoundRecorderPlugin getPlugin() => _impl.getPlugin();

  /// Returns a stream of [RecordingDisposition] which
  /// provides live updates as the recording proceeds.
  /// The [RecordingDisposition] items contain the duration
  /// and decibel level of the recording at the point in
  /// time that it is sent.
  /// Set the [interval] to control the time between each
  /// event. [interval] defaults to 10ms.
  Stream<RecordingDisposition> dispositionStream(
      {Duration interval = const Duration(milliseconds: 10)}) {
    return _impl.dispositionStream(interval: interval);
  }

  /// Call this method when you have finished with the recorder
  /// and want to release any resources the recorder has attached.
  Future<void> release() async => _impl.release();

  /// Returns true if the specified encoder is supported by
  /// flutter_sound on this platform
  Future<bool> isSupported(Codec codec) async => _impl.isSupported(codec);

  /// Starts the recorder, recording audio to the passed in [path]
  /// using the settings given.
  /// The file at [path] will be overwritten.
  Future<void> start({
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
  }) async =>
      _impl.startRecorder(
          path: path,
          sampleRate: sampleRate,
          numChannels: numChannels,
          bitRate: bitRate,
          codec: codec,
          androidEncoder: androidEncoder,
          androidAudioSource: androidAudioSource,
          androidOutputFormat: androidOutputFormat,
          iosQuality: iosQuality,
          requestPermission: requestPermission);

  /// Stops the current recording.
  /// An exception is thrown if the recording can't be stopped.
  ///
  /// [stopRecording] is also responsible for remux'ing the recording
  /// for some codecs which aren't natively support. Dependindig on the
  /// size of the file this could take a few moments to a few minutes.
  Future<void> stop() async => _impl.stop();

  /// Pause recording.
  /// The recording must be recording when this method is called
  /// otherwise an [RecorderNotRunningException]
  Future<void> pause() async => _impl.pause();

  /// Resume recording.
  /// The recording must be paused when this method is called
  /// otherwise a [RecorderNotPausedException] will be thrown.
  Future<void> resume() async => _impl.resume();
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
