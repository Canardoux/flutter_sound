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

/// **THE** Flutter Sound Recorder
/// {@category Main}
library recorder;

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
import 'package:flutter_sound_platform_interface/flutter_sound_platform_interface.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_recorder_platform_interface.dart';
import '../flutter_sound.dart';
import 'util/flutter_sound_helper.dart';

/// A Recorder is an object that can playback from various sources.
///
/// ----------------------------------------------------------------------------------------------------
///
/// Using a recorder is very simple :
///
/// 1. Create a new `FlutterSoundRecorder`
///
/// 2. Open it with [openAudioSession()]
///
/// 3. Start your recording with [startRecorder()].
///
/// 4. Use the various verbs (optional):
///    - [pauseRecorder()]
///    - [resumeRecorder()]
///    - ...
///
/// 5. Stop your recorder : [stopRecorder()]
///
/// 6. Release your recorder when you have finished with it : [closeAudioSession()].
/// This verb will call [stopRecorder()] if necessary.
///
/// ----------------------------------------------------------------------------------------------------
class FlutterSoundRecorder implements FlutterSoundRecorderCallback {
// Locals
  /// Locals
  Initialized _isInited = Initialized.notInitialized;
  bool _isOggOpus =
      false; // Set by startRecorder when the user wants to record an ogg/opus
  String
      _savedUri; // Used by startRecorder/stopRecorder to keep the caller wanted uri
  String
      _tmpUri; // Used by startRecorder/stopRecorder to keep the temporary uri to record CAF
  RecorderState _recorderState = RecorderState.isStopped;
  StreamController<RecordingDisposition> _recorderController;

  /// A reference to the User Sink during `StartRecorder(toStream:...)`
  StreamSink<Food> _userStreamSink;

  /// The current state of the Recorder
  RecorderState get recorderState => _recorderState;

  /// Used by the UI Widget.
  ///
  /// It is a duplicate from [onProgress] and should not be here
  /// @nodoc
  Stream<RecordingDisposition> dispositionStream() {
    return (_recorderController != null) ? _recorderController.stream : null;
  }

  /// A stream on which FlutterSound will post the recorder progression.
  /// You may listen to this Stream to have feedback on the current recording.
  ///
  /// *Example:*
  /// ```dart
  ///         _recorderSubscription = myRecorder.onProgress.listen((e)
  ///         {
  ///                 Duration maxDuration = e.duration;
  ///                 double decibels = e.decibels
  ///                 ...
  ///         }
  /// ```
  Stream<RecordingDisposition> get onProgress =>
      (_recorderController != null) ? _recorderController.stream : null;

  /// True if `RecorderState.isRecording`
  bool get isRecording => (_recorderState == RecorderState.isRecording);

  /// True if `RecorderState.isStopped`
  bool get isStopped => (_recorderState == RecorderState.isStopped);

  /// True if `RecorderState.isPaused`
  bool get isPaused => (_recorderState == RecorderState.isPaused);

  //===================================  Callbacks ================================================================

  /// Callback from the &tau; Core. Must not be called by the App
  /// @nodoc
  @override
  void recordingData({Uint8List data}) {
    if (_userStreamSink != null) {
      //Uint8List data = call['recordingData'] as Uint8List;
      _userStreamSink.add(FoodData(data));
    }
  }

  /// Callback from the &tau; Core. Must not be called by the App
  /// @nodoc
  @override
  void updateRecorderProgress({int duration, double dbPeakLevel}) {
    //int duration = call['duration'] as int;
    //double dbPeakLevel = call['dbPeakLevel'] as double;
    _recorderController.add(RecordingDisposition(
      Duration(milliseconds: duration),
      dbPeakLevel,
    ));
  }

// ----------------------------------------------------------------------------------------------------------------------------------------------

  /// Open a Recorder
  ///
  /// A recorder must be opened before used. A recorder correspond to an Audio Session. With other words, you must *open* the Audio Session before using it.
  /// When you have finished with a Recorder, you must close it. With other words, you must close your Audio Session.
  /// Opening a recorder takes resources inside the OS. Those resources are freed with the verb `closeAudioSession()`.
  ///
  /// You MUST ensure that the recorder has been closed when your widget is detached from the UI.
  /// Overload your widget's `dispose()` method to close the recorder when your widget is disposed.
  /// In this way you will reset the player and clean up the device resources, but the recorder will be no longer usable.
  ///
  /// ```dart
  /// @override
  /// void dispose()
  /// {
  ///         if (myRecorder != null)
  ///         {
  ///             myRecorder.closeAudioSession();
  ///             myPlayer = null;
  ///         }
  ///         super.dispose();
  /// }
  /// ```
  ///
  /// You may not openAudioSession many recorders without releasing them.
  ///
  /// `openAudioSession()` and `closeAudioSession()` return Futures. You may not use your Recorder before the end of the initialization. So probably you will `await` the result of `openAudioSession()`. This result is the Recorder itself, so that you can collapse instanciation and initialization together with `myRecorder = await FlutterSoundPlayer().openAudioSession();`
  ///
  /// The four optional parameters are used if you want to control the Audio Focus. Please look to [FlutterSoundPlayer openAudioSession()](player.md#openaudiosession-and-closeaudiosession) to understand the meaning of those parameters
  ///
  /// *Example:*
  /// ```dart
  ///     myRecorder = await FlutterSoundRecorder().openAudioSession();
  ///
  ///     ...
  ///     (do something with myRecorder)
  ///     ...
  ///
  ///     myRecorder.closeAudioSession();
  ///     myRecorder = null;
  /// ```
  Future<FlutterSoundRecorder> openAudioSession(
      {AudioFocus focus = AudioFocus.requestFocusTransient,
      SessionCategory category = SessionCategory.playAndRecord,
      SessionMode mode = SessionMode.modeDefault,
      int audioFlags = outputToSpeaker,
      AudioDevice device = AudioDevice.speaker}) async {
    if (_isInited == Initialized.fullyInitialized) {
      return this;
    }
    if (_isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }

    _isInited = Initialized.initializationInProgress;

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

    _isInited = Initialized.fullyInitialized;
    return this;
  }

  /// Close a Recorder
  ///
  /// You must close your recorder when you have finished with it, for releasing the resources.
  Future<void> closeAudioSession() async {
    if (_isInited == Initialized.notInitialized) {
      return this;
    }
    if (_isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    await stopRecorder();
    _isInited = Initialized.initializationInProgress;
    _removeRecorderCallback(); // _recorderController will be closed by this function
    if (_userStreamSink != null) {
      await _userStreamSink.close();
      _userStreamSink = null;
    }
    await FlutterSoundRecorderPlatform.instance.releaseFlautoRecorder(this);
    FlutterSoundRecorderPlatform.instance.closeSession(this);
    _isInited = Initialized.notInitialized;
  }

  /// Returns true if the specified encoder is supported by flutter_sound on this platform.
  ///
  /// This verb is useful to know if a particular codec is supported on the current platform;
  /// Return a Future<bool>.
  ///
  /// *Example:*
  /// ```dart
  ///         if ( await myRecorder.isEncoderSupported(Codec.opusOGG) ) doSomething;
  /// ```
  /// `isEncoderSupported` is a method for legacy reason, but should be a static function.
  Future<bool> isEncoderSupported(Codec codec) async {
    // For encoding ogg/opus on ios, we need to support two steps :
    // - encode CAF/OPPUS (with native Apple AVFoundation)
    // - remux CAF file format to OPUS file format (with ffmpeg)
    if (_isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (_isInited != Initialized.fullyInitialized) {
      throw (_NotOpen());
    }

    bool result;
    // For encoding ogg/opus on ios, we need to support two steps :
    // - encode CAF/OPPUS (with native Apple AVFoundation)
    // - remux CAF file format to OPUS file format (with ffmpeg)

    if ((codec == Codec.opusOGG) && (!kIsWeb) && (Platform.isIOS)) {
      //if (!await isFFmpegSupported( ))
      //result = false;
      //else
      result = await FlutterSoundRecorderPlatform.instance
          .isEncoderSupported(this, codec: Codec.opusCAF);
    } else {
      result = await FlutterSoundRecorderPlatform.instance
          .isEncoderSupported(this, codec: codec);
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

  /// Sets the frequency at which duration updates are sent to
  /// duration listeners.
  ///
  /// Zero means "no callbacks".
  /// The default is zero.
  Future<void> setSubscriptionDuration(Duration duration) async {
    if (_isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (_isInited != Initialized.fullyInitialized) {
      throw (_NotOpen());
    }
    await FlutterSoundRecorderPlatform.instance
        .setSubscriptionDuration(this, duration: duration);
  }

  /// Return the file extension for the given path.
  /// path can be null. We return null in this case.
  String _fileExtension(String path) {
    if (path == null) return null;
    var r = p.extension(path);
    return r;
  }

  /// `startRecorder()` starts recording with an open session.
  ///
  /// `startRecorder()` has the destination file path as parameter.
  /// It has also 7 optional parameters to specify :
  /// - codec: The codec to be used. Please refer to the [Codec compatibility Table](codec.md#actually-the-following-codecs-are-supported-by-flutter_sound) to know which codecs are currently supported.
  /// - toFile: a path to the file being recorded
  /// - toStream: if you want to record to a Dart Stream. Please look to [the following notice](codec.md#recording-pcm-16-to-a-dart-stream). **This new functionnality needs, at least, Android SDK >= 21 (23 is better)**
  /// - sampleRate: The sample rate in Hertz
  /// - numChannels: The number of channels (1=monophony, 2=stereophony)
  /// - bitRate: The bit rate in Hertz
  /// - audioSource : possible value is :
  ///    - defaultSource
  ///    - microphone
  ///    - voiceDownlink *(if someone can explain me what it is, I will be grateful ;-) )*
  ///
  /// [path_provider](https://pub.dev/packages/path_provider) can be useful if you want to get access to some directories on your device.
  ///
  /// Flutter Sound does not take care of the recording permission. It is the App responsability to check or require the Recording permission.
  /// [Permission_handler](https://pub.dev/packages/permission_handler) is probably useful to do that.
  ///
  /// *Example:*
  /// ```dart
  ///     // Request Microphone permission if needed
  ///     PermissionStatus status = await Permission.microphone.request();
  ///     if (status != PermissionStatus.granted)
  ///             throw RecordingPermissionException("Microphone permission not granted");
  ///
  ///     Directory tempDir = await getTemporaryDirectory();
  ///     File outputFile = await File ('${tempDir.path}/flutter_sound-tmp.aac');
  ///     await myRecorder.startRecorder(toFile: outputFile.path, codec: t_CODEC.CODEC_AAC,);
  /// ```
  Future<void> startRecorder({
    Codec codec = Codec.defaultCodec,
    String toFile,
    StreamSink<Food> toStream,
    int sampleRate = 16000,
    int numChannels = 1,
    int bitRate = 16000,
    AudioSource audioSource = AudioSource.defaultSource,
  }) async {
    if (_isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (_isInited != Initialized.fullyInitialized) {
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

  /// Stop a record.
  ///
  /// This verb never throws any exception. It is safe to call it everywhere,
  /// for example when the App is not sure of the current Audio State and want to recover a clean reset state.
  ///
  /// *Example:*
  /// ```dart
  ///         await myRecorder.stopRecorder();
  ///         if (_recorderSubscription != null)
  ///         {
  ///                 _recorderSubscription.cancel();
  ///                 _recorderSubscription = null;
  ///         }
  /// }
  /// ```
  Future<void> stopRecorder() async {
    if (_isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (_isInited != Initialized.fullyInitialized) {
      throw (_NotOpen());
    }
    await FlutterSoundRecorderPlatform.instance.stopRecorder(this);
    _userStreamSink = null;

    _recorderState = RecorderState.isStopped;

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
  }

  /// Changes the audio focus in an open Recorder
  ///
  /// ### `focus:` parameter possible values are
  /// - AudioFocus.requestFocus (request focus, but do not do anything special with others App)
  /// - AudioFocus.requestFocusAndStopOthers (your app will have **exclusive use** of the output audio)
  /// - AudioFocus.requestFocusAndDuckOthers (if another App like Spotify use the output audio, its volume will be **lowered**)
  /// - AudioFocus.requestFocusAndKeepOthers (your App will play sound **above** others App)
  /// - AudioFocus.requestFocusAndInterruptSpokenAudioAndMixWithOthers
  /// - AudioFocus.requestFocusTransient (for Android)
  /// - AudioFocus.requestFocusTransientExclusive (for Android)
  /// - AudioFocus.abandonFocus (Your App will not have anymore the audio focus)
  ///
  /// ### Other parameters :
  ///
  /// Please look to [openAudioSession()](player.md#openaudiosession-and-closeaudiosession) to understand the meaning of the other parameters
  ///
  ///
  /// *Example:*
  /// ```dart
  ///         myPlayer.setAudioFocus(focus: AudioFocus.requestFocusAndDuckOthers);
  /// ```
  Future<void> setAudioFocus(
      {AudioFocus focus = AudioFocus.requestFocusTransient,
      SessionCategory category = SessionCategory.playAndRecord,
      SessionMode mode = SessionMode.modeDefault,
      AudioDevice device = AudioDevice.speaker}) async {
    if (_isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (_isInited != Initialized.fullyInitialized) {
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

  /// Pause the recorder
  ///
  /// On Android this API verb needs al least SDK-24.
  /// An exception is thrown if the Recorder is not currently recording.
  ///
  /// *Example:*
  /// ```dart
  /// await myRecorder.pauseRecorder();
  /// ```
  Future<void> pauseRecorder() async {
    if (_isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (_isInited != Initialized.fullyInitialized) {
      throw (_NotOpen());
    }
    await FlutterSoundRecorderPlatform.instance.pauseRecorder(this);
    _recorderState = RecorderState.isPaused;
  }

  /// Resume a paused Recorder
  ///
  /// On Android this API verb needs al least SDK-24.
  /// An exception is thrown if the Recorder is not currently paused.
  ///
  /// *Example:*
  /// ```dart
  /// await myRecorder.resumeRecorder();
  /// ```
  Future<void> resumeRecorder() async {
    if (_isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (_isInited != Initialized.fullyInitialized) {
      throw (_NotOpen());
    }
    await FlutterSoundRecorderPlatform.instance.resumeRecorder(this);
    _recorderState = RecorderState.isRecording;
  }
}

/// Holds point in time details of the recording disposition
/// including the current duration and decibels.
///
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
  ///  Permission to record was not granted
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
