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
import 'package:flutter/widgets.dart';

import '../flutter_sound.dart';
import 'audio_source.dart';
import 'codec.dart';

import 'plugins/base_plugin.dart';
import 'plugins/sound_recorder_plugin.dart';
import 'quality.dart';
import 'recording_disposition.dart';
import 'track.dart';
import 'util/log.dart';
import 'util/recording_disposition_manager.dart';
import 'util/recording_track.dart';

enum _RecorderState {
  isStopped,
  isPaused,
  isRecording,
}

/// The [requestPermissions] callback allows you to provide an
/// UI informing the user that we are about to ask for a permission.
///
typedef RequestPermission = Future<bool> Function(Track track);

/// Provide an API for recording audio.
class SoundRecorder implements SlotEntry {
  bool _isInited = false;
  _RecorderState _recorderState = _RecorderState.isStopped;

  RecordingDispositionManager _dispositionManager;

  /// [SoundRecorder] calls the [onRequestPermissions] callback
  /// to give you a chance to grant the necessary permissions.
  ///
  /// The [onRequestPermissions] method is called just before recording
  /// starts (just after you call [record]).
  ///
  /// You may also want to pop a dialog
  /// explaining to the user why the permissions are being requested.
  ///
  /// If the required permissions are not in place then the recording will fail
  /// and an exception will be thrown.
  ///
  /// Return true if the app has the permissions and you want recording to
  /// continue.
  ///
  /// Return [false] if the app does not have the desired permissions.
  /// The recording will not be started if you return false and no
  /// error/exception will be returned from the [record] call.
  ///
  /// At a minimum SoundRecorder requires access to the microphone
  /// and possible external storage if the recording is to be placed
  /// on external storage.
  RequestPermission onRequestPermissions;

  /// track the total time we hav been paused during
  /// the current recording player.
  var _timePaused = Duration(seconds: 0);

  /// If we have paused during the current recording player this
  /// will be the time
  /// the most recent pause commenced.
  DateTime _pauseStarted;

  /// The track we are recording to.
  RecordingTrack _recordingTrack;

  /// Create a [SoundRecorder] to record audio.
  SoundRecorder() {
    _dispositionManager = RecordingDispositionManager(this);
  }

  /// Returns the duration of the recording
  Duration get duration => _dispositionManager.lastDuration;

  /// Starts the recorder recording to the
  /// passed in [Track].
  ///
  /// At this point the track MUST have been created via
  /// the [Track.fromPath] constructor.
  ///
  /// You must have permission to write to the path
  /// indicated by the Track and permissions to
  /// access the microphone.
  ///
  /// see: [onRequestPermissions] to get a callback
  /// as the recording is about to start.
  ///
  /// Support of recording to a databuffer is planned for a later
  /// release.
  ///
  /// The [track]s file will be truncated and over-written.
  ///
  ///```dart
  /// var track = Track.fromPath('fred.mpeg');
  ///
  /// var recorder = SoundRecorder();
  /// recorder.onStopped = () {
  ///   recorder.release();
  ///   // playback the recording we just made.
  ///   QuickPlay.fromTrack(track);
  /// });
  /// recorder.record(track);
  /// ```
  /// The [audioSource] is currently only supported on android.
  /// For iOS the source is always the microphone.
  /// The [quality] is currently only supported on iOS.
  Future<void> record(
    Track track, {
    int sampleRate = 16000,
    int numChannels = 1,
    int bitRate = 16000,
    AudioSource audioSource = AudioSource.mic,
    Quality quality = Quality.low,
  }) async {
    await _initialize();

    if (!track.isPath) {
      throw RecorderException(
          "Only file based tracks are supported. Used Track.fromPath().");
    }

    _recordingTrack = RecordingTrack(track);

    /// Throws an exception if the path isn't valid.
    _recordingTrack.validatePath();

    /// We must not already be recording.
    if (_recorderState != null && _recorderState != _RecorderState.isStopped) {
      throw RecorderRunningException('Recorder is not stopped.');
    }

    /// the codec must be supported.
    if (!await isSupported(_recordingTrack.nativeCodec)) {
      throw CodecNotSupportedException('Codec not supported.');
    }

    // we assume that we have all necessary permissions
    var hasPermissions = true;

    if (onRequestPermissions != null) {
      hasPermissions = await onRequestPermissions(track);
    }

    if (hasPermissions) {
      _timePaused = Duration(seconds: 0);

      await _getPlugin().start(
          this,
          _recordingTrack.recordingPath,
          sampleRate,
          numChannels,
          bitRate,
          _recordingTrack.nativeCodec,
          audioSource,
          quality);

      _recorderState = _RecorderState.isRecording;
    } else {
      Log.d('Call to SoundRecorder.record() failed as '
          'onRequestPermissions() returned false');
    }
  }

  /// Initialize a fresh new SoundRecorder
  Future<SoundRecorder> initialize() => _initialize();

  /// returns true if we are recording.
  bool get isRecording => (_recorderState ==
      _RecorderState
          .isRecording); //|| recorderState == t_RECORDER_STATE.IS_PAUSED);

  /// returns true if the record is stopped.
  bool get isStopped => (_recorderState == _RecorderState.isStopped);

  /// returns true if the recorder is paused.
  bool get isPaused => (_recorderState == _RecorderState.isPaused);

  ///
  SoundRecorderPlugin _getPlugin() => SoundRecorderPlugin();

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
  Future<SoundRecorder> _initialize() async {
    if (!_isInited) {
      _isInited = true;

      // TODO: do we need to wait until this completes before allowing
      // any further interactions with the recording subsystem.
      _getPlugin().initialise(this);
    }
    return this;
  }

  /// Call this method when you have finished with the recorder
  /// and want to release any resources the recorder has attached.
  Future<void> release() async {
    if (_isInited) {
      _isInited = false;
      await stop();
      _dispositionManager.release();
      _getPlugin().release(this);
    }
  }

  /// Returns true if the specified encoder is supported by
  /// flutter_sound on this platform
  Future<bool> isSupported(Codec codec) async {
    await _initialize();
    // For encoding ogg/opus on ios, we need to support two steps :
    // - encode CAF/OPPUS (with native Apple AVFoundation)
    // - remux CAF file format to OPUS file format (with ffmpeg)
    if ((codec == Codec.opusOGG) && (Platform.isIOS)) {
      codec = Codec.cafOpus;
    }

    return await _getPlugin().isSupported(this, codec);
  }

  /// Stops the current recording.
  /// An exception is thrown if the recording can't be stopped.
  ///
  /// [stopRecording] is also responsible for recode'ing the recording
  /// for some codecs which aren't natively support. Dependindig on the
  /// size of the file this could take a few moments to a few minutes.
  Future<void> stop() async {
    await _initialize();
    if (isRecording) {
      await _getPlugin().stop(this);

      _recorderState = _RecorderState.isStopped;

      // If requried, transcribe from the native codec to the requested codec.
      _recordingTrack.recode();
    } else {
      throw RecorderNotRunningException(
          "You cannot stop recording when the recorder is not running.");
    }
  }

  /// Pause recording.
  /// The recording must be recording when this method is called
  /// otherwise an [RecorderNotRunningException]
  Future<void> pause() async {
    await _initialize();
    if (!isRecording) {
      throw RecorderNotRunningException(
          "You cannot pause recording when the recorder is not running.");
    }

    await _getPlugin().pause(this);
    _pauseStarted = DateTime.now();
    _recorderState = _RecorderState.isPaused;
  }

  /// Resume recording.
  /// The recording must be paused when this method is called
  /// otherwise a [RecorderNotPausedException] will be thrown.
  Future<void> resume() async {
    await _initialize();
    if (!isPaused) {
      throw RecorderNotPausedException(
          "You cannot resume recording when the recorder is not paused.");
    }
    _timePaused += (DateTime.now().difference(_pauseStarted));

    try {
      await _getPlugin().resume(this);
    } on Object catch (e) {
      Log.d("Exception throw trying to resume the recorder $e");
      await stop();
      rethrow;
    }
    _recorderState = _RecorderState.isRecording;
  }

  /// Sets the frequency at which duration updates are sent to
  /// duration listeners.
  /// The default is every 10 milliseconds.
  Future<void> _setSubscriptionInterval(Duration interval) async {
    await _initialize();
    await _getPlugin().setSubscriptionDuration(this, interval);
  }

  /// Call by the plugin to notify us that the duration of the recording
  /// has changed.
  /// The plugin ignores pauses so it just gives us the time
  /// elapsed since the recording first started.
  ///
  /// We subtract the time we have spent paused to get the actual
  /// duration of the recording.
  ///
  void _updateDuration(Duration elapsedDuration) {
    var duration = elapsedDuration - _timePaused;
    // Log.d('update duration called: $elapsedDuration');
    _dispositionManager.updateDurationDisposition(duration);
    _recordingTrack.duration = duration;
  }

  /// Defines the interval at which the peak level should be updated.
  /// Default is 0.8 seconds
  Future<void> _setDbPeakLevelUpdateInterval(Duration interval) async {
    await _initialize();
    await _getPlugin().setDbPeakLevelUpdate(this, interval);
  }

  /// Enables or disables processing the Peak level in db's. Default is disabled
  Future<void> _setDbLevelEnabled({bool enabled}) async {
    await _initialize();
    await _getPlugin().setDbLevelEnabled(this, enabled: enabled);
  }

  /// Called by the plugin to notify us of the current Db Level of the
  /// recording.
  void _updateDbPeakDisposition(double decibels) async {
    await _initialize();
    _dispositionManager.updateDbPeakDisposition(decibels);
  }
}

/// INTERNAL APIS
/// functions to assist with hiding the internal api.
///

///
/// Duration monitoring
///

/// Sets the frequency at which duration updates are sent to
/// duration listeners.
void recorderSetSubscriptionInterval(
        SoundRecorder recorder, Duration interval) =>
    recorder._setSubscriptionInterval(interval);

///
void recorderUpdateDuration(SoundRecorder recorder, Duration duration) =>
    recorder._updateDuration(duration);

///
/// decibel monitoring
///

///
void recorderSetDbPeakLevelUpdate(SoundRecorder recorder, Duration interval) =>
    recorder._setDbPeakLevelUpdateInterval(interval);

/// enable db monitoring.
void recorderSetDbLevelEnabled(SoundRecorder recorder,
        {@required bool enabled}) =>
    recorder._setDbLevelEnabled(enabled: enabled);

/// called by the plugin when the db level changes
void recorderUpdateDbPeakDispostion(SoundRecorder recorder, double decibels) =>
    recorder._updateDbPeakDisposition(decibels);

///
/// Execeptions
///

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
