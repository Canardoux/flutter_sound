/*
 * Copyright 2018, 2019, 2020 Dooboolab.
 *
 * This file is part of Flutter-Sound.
 *
 * Flutter-Sound is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License version 3 (LGPL-V3), as published by
 * the Free Software Foundation.
 *
 * Flutter-Sound is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with Flutter-Sound.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:io' show Platform;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flauto_platform_interface/flutter_sound_platform_interface.dart';
import 'package:flauto_platform_interface/flutter_sound_recorder_platform_interface.dart';
import 'package:synchronized/synchronized.dart';
import '../flutter_sound.dart';
import 'flutter_sound_helper.dart';

/// ----------------------------------------------------------------------------------------------------
///
/// A recorder is an object that can record from various sources.
/// Using a recorder is very simple :
///
/// 1. Create a new `FlutterSoundRecorder` (optional).
/// This is optional, and most of the time, APP will use the pre-built [defaultRecorder]
/// instead of creating a new object
///
/// 2. Start your record with `startRecording()`.
/// `startRecording()` returns a future, but you do not need
/// to wait for this future completed before working with your record.
///
/// 3. Use the various verbs (optional):
///    - `pauseRecorder()`
///    - `resumeRecorder()`
///
/// 5. Stop your recorder : `stopRecorder`
///
/// 6. Release your recorder when you have finished with it : `releaseRecorder()`.
/// This verb will call to `stopRecorder()` will be done if necessary.
///
/// ----------------------------------------------------------------------------------------------------
class FlutterSoundRecorder implements FlutterSoundRecorderCallback {
// Locals
  StreamSink<Food> _userStreamSink;
  bool _isOggOpus =
      false; // Set by startRecorder when the user wants to record an ogg/opus
  String
      _savedUri; // Used by startRecorder/stopRecorder to keep the caller wanted uri
  String
      _tmpUri; // Used by startRecorder/stopRecorder to keep the temporary uri to record CAF
  RecorderState _recorderState = RecorderState.isStopped;
  final Lock _lock = Lock();

// Public
  /// The current state of the recorder
  RecorderState get recorderState => _recorderState;

  /// The Stream of the progress informations
  Stream<RecordingDisposition> get onProgress =>
      (_recorderController != null) ? _recorderController.stream : null;

  /// True if `RecorderState.isRecording`
  bool get isRecording => (_recorderState == RecorderState.isRecording);

  /// True if `RecorderState.isStopped`
  bool get isStopped => (_recorderState == RecorderState.isStopped);

  /// True if `RecorderState.isPaused`
  bool get isPaused => (_recorderState == RecorderState.isPaused);

  /// This instance of [FlutterSoundRecorder] is just to be smart for the App.
  /// The Apps can use this instance without having to create a [FlutterSoundRecorder] themselves.
  static FlutterSoundRecorder defaultRecorder = FlutterSoundRecorder();

  /// This is the first thing to do, if you want to deal with recording.
  /// The instanciation of a new recorder does not do many thing.
  /// You are safe if you put this instanciation inside a global or instance variable initialization.
  ///Most of the time, APPs do not create any recorder, but use the [defaultRecorder]
  /* ctor */ FlutterSoundRecorder();

// ----------------------------------------------------------  Callbacks from the OS  -------------------------------------------------

  /// Callback from the OS. Do not use int the APPs
  @override
  void updateRecorderProgress({int duration, double dbPeakLevel}) {
    _recorderController.add(RecordingDisposition(
      Duration(milliseconds: duration),
      dbPeakLevel,
    ));
  }

  /// Callback from the OS.  Do not use int the APPs
  @override
  void recordingData({Uint8List data}) {
    if (_userStreamSink != null) {
      //Uint8List data = call['recordingData'] as Uint8List;
      _userStreamSink.add(FoodData(data));
    }
  }

  /// @nodoc.
  Initialized get isInited => _openState;
  Initialized _openState = Initialized.notInitialized;

  /// True if the recorder has been open
  bool get _isOpen => (_openState == Initialized.fullyInitialized ||
      _openState == Initialized.fullyInitializedWithUI);

  ///
  bool get isOpen => (isInited == Initialized.fullyInitialized);

  /// The Stream of the progress informations.
  /// Obsolete. Use [onProgress] instead
  Stream<RecordingDisposition> dispositionStream() {
    return (_recorderController != null) ? _recorderController.stream : null;
  }

  StreamController<RecordingDisposition> _recorderController;

  /// Obsolete. Please use `openRecorder()` instead
  Future<FlutterSoundRecorder> openAudioSession(
      {AudioFocus focus = AudioFocus.requestFocusTransient,
      SessionCategory category = SessionCategory.playAndRecord,
      SessionMode mode = SessionMode.modeDefault,
      int audioFlags = outputToSpeaker,
      AudioDevice device = AudioDevice.speaker}) async {
    if (isInited == Initialized.fullyInitialized) {
      return this;
    }
    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }

    _openState = Initialized.initializationInProgress;

    _setRecorderCallback();
    if (_userStreamSink != null) {
      await _userStreamSink.close();
      _userStreamSink = null;
    }
    FlutterSoundRecorderPlatform.instance.openSession(this);
    await FlutterSoundRecorderPlatform.instance.initializeFlautoRecorder(
      this,
      focus: focus,
      category: category,
      mode: mode,
      audioFlags: audioFlags,
      device: device,
    );

    _openState = Initialized.fullyInitialized;
    return this;
  }

  /// Sets the frequency at which duration updates are sent to
  /// duration listeners. Zero means "no callbacks".
  /// The default is zero.
  Future<void> setSubscriptionDuration(Duration duration) async {
    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (isInited != Initialized.fullyInitialized) {
      throw (_NotOpen());
    }
    await FlutterSoundRecorderPlatform.instance
        .setSubscriptionDuration(this, duration: duration);
  }

  ///
  Future<void> setAudioFocus(
      {AudioFocus focus = AudioFocus.requestFocusTransient,
      SessionCategory category = SessionCategory.playAndRecord,
      SessionMode mode = SessionMode.modeDefault,
      AudioDevice device = AudioDevice.speaker}) async {
    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (isInited != Initialized.fullyInitialized) {
      throw (_NotOpen());
    }
    await FlutterSoundRecorderPlatform.instance.setAudioFocus(
      this,
      focus: focus,
      category: category,
      mode: mode,
      device: device,
    );
  }

  ///
  Future<void> closeAudioSession() async {
    if (isInited == Initialized.notInitialized) {
      return this;
    }
    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    await stopRecorder();
    _openState = Initialized.initializationInProgress;
    _removeRecorderCallback(); // _recorderController will be closed by this function
    if (_userStreamSink != null) {
      await _userStreamSink.close();
      _userStreamSink = null;
    }
    await FlutterSoundRecorderPlatform.instance.releaseFlautoRecorder(this);
    FlutterSoundRecorderPlatform.instance.closeSession(this);
    _openState = Initialized.notInitialized;
  }

// ----------------------------------------------------------------------------------------------------------------------------------------------

  /// Returns true if the specified encoder is supported by flutter_sound on this platform
  /// `isEncoderSupported` is a method for legacy reason, but should be a static function.
  Future<bool> isEncoderSupported(Codec codec) async {
    // For encoding ogg/opus on ios, we need to support two steps :
    // - encode CAF/OPPUS (with native Apple AVFoundation)
    // - remux CAF file format to OPUS file format (with ffmpeg)
    if ((codec == Codec.opusOGG) && (!kIsWeb) && (Platform.isIOS)) {
      if (!await FlutterSoundHelper().isFFmpegAvailable()) {
        return false;
      }
      codec = Codec.opusCAF;
    }

    var needToClose = false;
    if (!_isOpen) // We must open a session for legacy reason. this is not clean and should be improved
    {
      await _lock.synchronized(() async {
        if (!_isOpen) // This could have been changed during waiting for the semaphore
        {
          needToClose = true;
          FlutterSound().internalOpenSessionForRecording();
        }
      });
    }

    var result = await FlutterSoundRecorderPlatform.instance
        .isEncoderSupported(this, codec: codec);
    if (needToClose) {
      await closeAudioSession();
    }
    return result;
  }

  void _setRecorderCallback() {
    _recorderController ??= StreamController.broadcast();
  }

  void _removeRecorderCallback() {
    if (_recorderController != null) {
      _recorderController..close();
      _recorderController = null;
    }
  }

  /// Return the file extension for the given path.
  /// path can be null. We return null in this case.
  String _fileExtension(String path) {
    if (path == null) return null;
    var r = p.extension(path);
    return r;
  }

  ///
  Future<void> releaseRecorder() async {
    await _lock.synchronized(() async {
      if (!_isOpen) {
        return null;
      }
      await stopRecorder();
      _openState = Initialized.initializationInProgress;
      _removeRecorderCallback(); // _recorderController will be closed by this function
      if (_userStreamSink != null) {
        await _userStreamSink.close();
        _userStreamSink = null;
      }
      await FlutterSoundRecorderPlatform.instance.releaseFlautoRecorder(this);
      FlutterSoundRecorderPlatform.instance.closeSession(this);
      _openState = Initialized.notInitialized;
    });
  }

  ///
  Future<void> startRecorder({
    Codec codec = Codec.defaultCodec,
    String toFile,
    StreamSink<Food> toStream,
    int sampleRate = 16000,
    int numChannels = 1,
    int bitRate = 16000,
    AudioSource audioSource = AudioSource.defaultSource,
  }) async {
    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (isInited != Initialized.fullyInitialized) {
      throw (_NotOpen());
    }
    // Request Microphone permission if needed
    /*
                if (requestPermission) {
                  PermissionStatus status = await Permission.microphone.request();
                  if (status != PermissionStatus.granted) {
                    throw RecordingPermissionException("Microphone permission not granted");
                  }
                }
                */
    if (_recorderState != null && _recorderState != RecorderState.isStopped) {
      throw _RecorderRunningException('Recorder is not stopped.');
    }
    if (!await isEncoderSupported(codec)) {
      throw _CodecNotSupportedException('Codec not supported.');
    }

    if ((toFile == null && toStream == null) ||
        (toFile != null && toStream != null)) {
      throw Exception(
          'One, and only one parameter "toFile"/"toStream" must be provided');
    }

    if (toStream != null && codec != Codec.pcm16) {
      throw Exception('toStream can only be used with codec == Codec.pcm16');
    }

    _userStreamSink = toStream;

    // If we want to record OGG/OPUS on iOS, we record with CAF/OPUS and we remux the CAF file format to a regular OGG/OPUS.
    // We use FFmpeg for that task.
    if ((!kIsWeb) &&
        (Platform.isIOS) &&
        ((codec == Codec.opusOGG) || (_fileExtension(toFile) == '.opus'))) {
      _savedUri = toFile;
      _isOggOpus = true;
      codec = Codec.opusCAF;
      var tempDir = await getTemporaryDirectory();
      var fout = File('${tempDir.path}/flutter_sound-tmp.caf');
      toFile = fout.path;
      _tmpUri = toFile;
    } else {
      _isOggOpus = false;
    }

    try {
      await FlutterSoundRecorderPlatform.instance.startRecorder(this,
          path: toFile,
          sampleRate: sampleRate,
          numChannels: numChannels,
          bitRate: bitRate,
          codec: codec,
          toStream: toStream != null,
          audioSource: audioSource);

      _recorderState = RecorderState.isRecording;
      // if the caller wants OGG/OPUS we must remux the temporary file
      if (_isOggOpus) {
        return _savedUri;
      }
    } on Exception catch (err) {
      throw Exception(err);
    }
  }

  ///
  Future<void> stopRecorder() async {
    await _lock.synchronized(() async {
      if (!_isOpen) {
        return null;
      }
      await FlutterSoundRecorderPlatform.instance.stopRecorder(this);
      _userStreamSink = null;

      _recorderState = RecorderState.isStopped;
      await closeAudioSession();

      if (_isOggOpus) {
        // delete the target if it exists
        // (ffmpeg gives an error if the output file already exists)
        var f = File(_savedUri);
        if (f.existsSync()) {
          await f.delete();
        }
        // The following ffmpeg instruction re-encode the Apple CAF to OPUS.
        // Unfortunately we cannot just remix the OPUS data,
        // because Apple does not set the "extradata" in its private OPUS format.
        // It will be good if we can improve this...
        var rc = await flutterSoundHelper.executeFFmpegWithArguments([
          '-loglevel',
          'error',
          '-y',
          '-i',
          _tmpUri,
          '-c:a',
          'libopus',
          _savedUri,
        ]); // remux CAF to OGG
        if (rc != 0) {
          return null;
        }
        return _savedUri;
      }
    });
  }

  ///
  Future<void> pauseRecorder() async {
    await _lock.synchronized(() async {
      if (!_isOpen) {
        throw _NotOpen();
      }
      await FlutterSoundRecorderPlatform.instance.pauseRecorder(this);
      _recorderState = RecorderState.isPaused;
    });
  }

  ///
  Future<void> resumeRecorder() async {
    await _lock.synchronized(() async {
      if (!_isOpen) {
        throw _NotOpen();
      }
      await FlutterSoundRecorderPlatform.instance.resumeRecorder(this);
      _recorderState = RecorderState.isRecording;
    });
  }
}

/// Holds point in time details of the recording disposition
/// including the current duration and decibels.
/// Use the `dispositionStream` method to subscribe to a stream
/// of `RecordingDisposition` will be emmmited while recording.
class RecordingDisposition {
  /// The total duration of the recording at this point in time.
  final Duration duration;

  /// The volume of the audio being captured
  /// at this point in time.
  /// Value ranges from 0 to 120
  final double decibels;

  /// ctor
  RecordingDisposition(this.duration, this.decibels);

  /// use this ctor to as the initial value when building
  /// a `StreamBuilder`
  RecordingDisposition.zero()
      : duration = Duration(seconds: 0),
        decibels = 0;

  /// Return a String representation of the Disposition
  @override
  String toString() {
    return 'duration: $duration decibels: $decibels';
  }
}

class _RecorderException implements Exception {
  final String _message;

  _RecorderException(this._message);

  String get message => _message;
}

class _RecorderRunningException extends _RecorderException {
  _RecorderRunningException(String message) : super(message);
}

class _CodecNotSupportedException extends _RecorderException {
  _CodecNotSupportedException(String message) : super(message);
}

/// Permission to record was not granted
class RecordingPermissionException extends _RecorderException {
  ///
  RecordingPermissionException(String message) : super(message);
}

class _InitializationInProgress implements Exception {
  _InitializationInProgress() {
    print('An initialization is currently already in progress.');
  }
}

class _NotOpen implements Exception {
  _NotOpen() {
    print('Audio session is not open');
  }
}
