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
//import 'dart:convert';
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
import 'package:synchronized/synchronized.dart';
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
  /// Locals
  /// ------
  ///
  Completer<void> _startRecorderCompleter;
  Completer<void> _pauseRecorderCompleter;
  Completer<void> _resumeRecorderCompleter;
  Completer<String> _stopRecorderCompleter;
  Completer<void> _closeRecorderCompleter;
  Completer<FlutterSoundRecorder> _openRecorderCompleter;

  final _lock = Lock();
  static bool _reStarted = true;

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

  /// True if `recorderState.isRecording`
  bool get isRecording => (_recorderState == RecorderState.isRecording);

  /// True if `recorderState.isStopped`
  bool get isStopped => (_recorderState == RecorderState.isStopped);

  /// True if `recorderState.isPaused`
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

  /// Callback from the &tau; Core. Must not be called by the App
  /// @nodoc
  @override
  void openRecorderCompleted(int state, bool success) {
    print('---> openRecorderCompleted: $success');

    _recorderState = RecorderState.values[state];
    _isInited =
        success ? Initialized.fullyInitialized : Initialized.notInitialized;
    if (success) {
      _openRecorderCompleter.complete(this);
    } else {
      _pauseRecorderCompleter.completeError('openRecorder failed');
    }
    _openRecorderCompleter = null;
    print('<--- openRecorderCompleted: $success');
  }

  /// Callback from the &tau; Core. Must not be called by the App
  /// @nodoc
  @override
  void closeRecorderCompleted(int state, bool success) {
    print('---> closeRecorderCompleted');
    _recorderState = RecorderState.values[state];
    _isInited = Initialized.notInitialized;
    _closeRecorderCompleter.complete();
    _closeRecorderCompleter = null;
    _cleanCompleters();
    print('<--- closeRecorderCompleted');
  }

  /// Callback from the &tau; Core. Must not be called by the App
  /// @nodoc
  @override
  void pauseRecorderCompleted(int state, bool success) {
    print('---> pauseRecorderCompleted: $success');
    assert(state != null);
    _recorderState = RecorderState.values[state];
    if (success) {
      _pauseRecorderCompleter.complete();
    } else {
      _pauseRecorderCompleter.completeError('pauseRecorder failed');
    }
    _pauseRecorderCompleter = null;
    print('<--- pauseRecorderCompleted: $success');
  }

  /// Callback from the &tau; Core. Must not be called by the App
  /// @nodoc
  @override
  void resumeRecorderCompleted(int state, bool success) {
    print('---> resumeRecorderCompleted: $success');
    assert(state != null);
    _recorderState = RecorderState.values[state];
    if (success) {
      _resumeRecorderCompleter.complete();
    } else {
      _resumeRecorderCompleter.completeError('resumeRecorder failed');
    }
    _resumeRecorderCompleter = null;
    print('<--- resumeRecorderCompleted: $success');
  }

  /// Callback from the &tau; Core. Must not be called by the App
  /// @nodoc
  @override
  void startRecorderCompleted(int state, bool success) {
    print('---> startRecorderCompleted: $success');
    assert(state != null);
    _recorderState = RecorderState.values[state];
    if (success) {
      _startRecorderCompleter.complete();
    } else {
      _startRecorderCompleter.completeError('startRecorder() failed');
    }
    _startRecorderCompleter = null;
    print('<--- startRecorderCompleted: $success');
  }

  /// Callback from the &tau; Core. Must not be called by the App
  /// @nodoc
  @override
  void stopRecorderCompleted(int state, bool success, String url) {
    print('---> stopRecorderCompleted: $success');
    assert(state != null);
    _recorderState = RecorderState.values[state];
    if (success) {
      _stopRecorderCompleter.complete(url);
    } // stopRecorder must not gives errors
    else {
      _stopRecorderCompleter.completeError('stopRecorder failed');
    }
    _stopRecorderCompleter = null;
    // _cleanCompleters(); ????
    print('<---- stopRecorderCompleted: $success');
  }

  void _cleanCompleters() {
    if (_pauseRecorderCompleter != null) {
      print('Kill _pauseRecorder()');
      var completer = _pauseRecorderCompleter;
      _pauseRecorderCompleter = null;
      completer.completeError('killed by cleanCompleters');
    }
    if (_resumeRecorderCompleter != null) {
      print('Kill _resumeRecorder()');
      var completer = _resumeRecorderCompleter;
      _resumeRecorderCompleter = null;
      completer.completeError('killed by cleanCompleters');
    }

    if (_startRecorderCompleter != null) {
      print('Kill _startRecorder()');
      var completer = _startRecorderCompleter;
      _startRecorderCompleter = null;
      completer.completeError('killed by cleanCompleters');
    }

    if (_stopRecorderCompleter != null) {
      print('Kill _stopRecorder()');
      Completer<void> completer = _stopRecorderCompleter;
      _stopRecorderCompleter = null;
      completer.completeError('killed by cleanCompleters');
    }

    if (_openRecorderCompleter != null) {
      print('Kill openRecorder()');
      Completer<void> completer = _openRecorderCompleter;
      _openRecorderCompleter = null;
      completer.completeError('killed by cleanCompleters');
    }

    if (_closeRecorderCompleter != null) {
      print('Kill _closeRecorder()');
      var completer = _closeRecorderCompleter;
      _closeRecorderCompleter = null;
      completer.completeError('killed by cleanCompleters');
    }
  }

// ----------------------------------------------------------------------------------------------------------------------------------------------

  Future<void> _waitOpen() async {
    while (_openRecorderCompleter != null) {
      print('Waiting for the recorder being opened');
      await _openRecorderCompleter.future;
    }
    if (_isInited == Initialized.notInitialized) {
      throw Exception('Recorder is not open');
    }
  }

  /// Open a Recorder
  ///
  /// A recorder must be opened before used. A recorder correspond to an Audio Session. With other words, you must *open* the Audio Session before using it.
  /// When you have finished with a Recorder, you must close it. With other words, you must close your Audio Session.
  /// Opening a recorder takes resources inside the OS. Those resources are freed with the verb `closeAudioSession()`.
  ///
  /// You MUST ensure that the recorder has been closed when your widget is detached from the UI.
  /// Overload your widget's `dispose()` method to close the recorder when your widget is disposed.
  /// In this way you will reset the Recorder and clean up the device resources, but the recorder will be no longer usable.
  ///
  /// ```dart
  /// @override
  /// void dispose()
  /// {
  ///         if (myRecorder != null)
  ///         {
  ///             myRecorder.closeAudioSession();
  ///             myRecorder = null;
  ///         }
  ///         super.dispose();
  /// }
  /// ```
  ///
  /// You may not openAudioSession many recorders without releasing them.
  ///
  /// `openAudioSession()` and `closeAudioSession()` return Futures.
  /// You do not need to wait the end of the initialization before [startRecorder()].
  /// [startRecorder] will automaticaly wait the end of `openAudioSession()` before starting the recorder.
  ///
  /// The four optional parameters are used if you want to control the Audio Focus. Please look to [FlutterSoundRecorder openAudioSession()](Recorder.md#openaudiosession-and-closeaudiosession) to understand the meaning of those parameters
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
    FlutterSoundRecorder r;
    print('FS:---> openAudioSession ');
    await _lock.synchronized(() async {
      r = await _openAudioSession(
        focus: focus,
        category: category,
        mode: mode,
        audioFlags: audioFlags,
        device: device,
      );
    });
    print('FS:<--- openAudioSession ');
    return r;
  }

  Future<FlutterSoundRecorder> _openAudioSession(
      {AudioFocus focus = AudioFocus.requestFocusTransient,
      SessionCategory category = SessionCategory.playAndRecord,
      SessionMode mode = SessionMode.modeDefault,
      int audioFlags = outputToSpeaker,
      AudioDevice device = AudioDevice.speaker}) async {
    print('---> openAudioSession');

    if (_isInited != Initialized.notInitialized) {
      throw Exception('Recorder is already initialized');
    } // to be in a clean state
    Completer<FlutterSoundRecorder> completer;

    _setRecorderCallback();
    if (_userStreamSink != null) {
      await _userStreamSink.close();
      _userStreamSink = null;
    }
    assert(_openRecorderCompleter == null);
    _openRecorderCompleter = Completer<FlutterSoundRecorder>();
    completer = _openRecorderCompleter;
    try {
      if (_reStarted) {
        // Perhaps a Hot Restart ?  We must reset the plugin
        print("Resetting flutter_sound Recorder Plugin");
        _reStarted = false;
        await FlutterSoundRecorderPlatform.instance.resetPlugin(this);
      }

      FlutterSoundRecorderPlatform.instance.openSession(this);
      await FlutterSoundRecorderPlatform.instance.openRecorder(
        this,
        focus: focus,
        category: category,
        mode: mode,
        audioFlags: audioFlags,
        device: device,
      );

      //_isInited = Initialized.fullyInitialized;
    } on Exception {
      _openRecorderCompleter = null;
      rethrow;
    }
    print('<--- openAudioSession');
    return completer.future;
  }

  /// Close a Recorder
  ///
  /// You must close your recorder when you have finished with it, for releasing the resources.
  /// Delete all the temporary files created with `startRecorder()`

  Future<void> closeAudioSession() async {
    print('FS:---> closeAudioSession ');
    await _lock.synchronized(() async {
      await _closeAudioSession();
    });
    print('FS:<--- closeAudioSession ');
  }

  Future<void> _closeAudioSession() async {
    print('FS:---> closeAudioSession ');
    // If another closeRecorder() is already in progress, wait until finished
    while (_closeRecorderCompleter != null) {
      try {
        print('Another closeRecorder() in progress');
        await _closeRecorderCompleter.future;
      } on Exception {}
    }
    if (_isInited == Initialized.notInitialized) {
      // Already close
      print('Recorder already close');
      return this;
    }

    Completer<void> completer;

    try {
      await _stop(); // Stop the recorder if running
    } on Exception {}
    //_isInited = Initialized.initializationInProgress; // BOF
    _removeRecorderCallback(); // _recorderController will be closed by this function
    if (_userStreamSink != null) {
      await _userStreamSink.close();
      _userStreamSink = null;
    }
    assert(_closeRecorderCompleter == null);
    _closeRecorderCompleter = Completer<void>();
    try {
      completer = _closeRecorderCompleter;

      await FlutterSoundRecorderPlatform.instance.closeRecorder(this);
      FlutterSoundRecorderPlatform.instance.closeSession(this);
      //_isInited = Initialized.notInitialized;
    } on Exception {
      _closeRecorderCompleter = null;
      rethrow;
    }
    print('FS:<--- closeAudioSession ');
    return completer.future;
  }

  /// Returns true if the specified encoder is supported by flutter_sound on this platform.
  ///
  /// This verb is useful to know if a particular codec is supported on the current platform;
  /// Returns a Future<bool>.
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
    await _waitOpen();
    if (_isInited != Initialized.fullyInitialized) {
      throw Exception('Recorder is not open');
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
    print('FS:---> setSubscriptionDuration ');
    await _waitOpen();
    if (_isInited != Initialized.fullyInitialized) {
      throw Exception('Recorder is not open');
    }
    await FlutterSoundRecorderPlatform.instance
        .setSubscriptionDuration(this, duration: duration);
    print('FS:<--- setSubscriptionDuration ');
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
  /// If an [openAudioSession()] is in progress, `startRecorder()` will automatically wait the end of the opening.
  /// `startRecorder()` has the destination file path as parameter.
  /// It has also 7 optional parameters to specify :
  /// - codec: The codec to be used. Please refer to the [Codec compatibility Table](codec.md#actually-the-following-codecs-are-supported-by-flutter_sound) to know which codecs are currently supported.
  /// - toFile: a path to the file being recorded or the name of a temporary file (without slash '/').
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
  /// To record a temporary file, the App can specify the name of this temporary file (without slash) instead of a real path.
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
  ///     await myRecorder.startRecorder(toFile: 'foo', codec: t_CODEC.CODEC_AAC,); // A temporary file named 'foo'
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
    print('FS:---> startRecorder ');
    await _lock.synchronized(() async {
      await _startRecorder(
        codec: codec,
        toFile: toFile,
        toStream: toStream,
        sampleRate: sampleRate,
        numChannels: numChannels,
        bitRate: bitRate,
        audioSource: audioSource,
      );
    });
    print('FS:<--- startRecorder ');
  }

  Future<void> _startRecorder({
    Codec codec = Codec.defaultCodec,
    String toFile,
    StreamSink<Food> toStream,
    int sampleRate = 16000,
    int numChannels = 1,
    int bitRate = 16000,
    AudioSource audioSource = AudioSource.defaultSource,
  }) async {
    print('FS:---> _startRecorder.');
    await _waitOpen();
    if (_isInited != Initialized.fullyInitialized) {
      throw Exception('Recorder is not open');
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
    Completer<void> completer;
    // Maybe we should stop any recording already running... (stopRecorder does that)
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
    if (_startRecorderCompleter != null) {
      _startRecorderCompleter
          .completeError('Killed by another startRecorder()');
    }
    _startRecorderCompleter = Completer<void>();
    completer = _startRecorderCompleter;
    print('Calling instance.startRecorder');
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
      //if (_isOggOpus) {
      //return _savedUri;
      //}
    } on Exception {
      _startRecorderCompleter = null;
      rethrow;
    }
    print('FS:<--- _startRecorder.');
    return completer.future;
  }

  Future<String> _stop() async {
    print('FS:---> stop');
    _stopRecorderCompleter = Completer<String>();
    var completer = _stopRecorderCompleter;
    try {
      await FlutterSoundRecorderPlatform.instance.stopRecorder(this);
    } on Exception {
      _stopRecorderCompleter = null;
      rethrow;
    }
    _userStreamSink = null;

    _recorderState = RecorderState.isStopped;
    print('FS:<--- stop');
    return completer.future;
  }

  /// Stop a record.
  ///
  /// Return a Future to an URL of the recorded sound.
  ///
  /// *Example:*
  /// ```dart
  ///         String anURL = await myRecorder.stopRecorder();
  ///         if (_recorderSubscription != null)
  ///         {
  ///                 _recorderSubscription.cancel();
  ///                 _recorderSubscription = null;
  ///         }
  /// }
  /// ```
  Future<String> stopRecorder() async {
    print('FS:---> stopRecorder ');
    String r;
    await _lock.synchronized(() async {
      r = await _stopRecorder();
    });
    print('FS:<--- stopRecorder ');
    return r;
  }

  Future<String> _stopRecorder() async {
    print('FS:---> stopRecorder ');
    while (_openRecorderCompleter != null) {
      print('Waiting for the recorder being opened');
      await _openRecorderCompleter.future;
    }
    if (_isInited != Initialized.fullyInitialized) {
      print('<--- stopRecorder : Recorder is not open');
      return 'Recorder is not open';
    }
    String r;

    try {
      r = await _stop();

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
        r = _savedUri;
      }
    } on Exception catch (e) {
      print(e);
    }
    print('FS:<--- stopRecorder : $r');
    return r;
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
  /// Please look to [openAudioSession()](Recorder.md#openaudiosession-and-closeaudiosession) to understand the meaning of the other parameters
  ///
  ///
  /// *Example:*
  /// ```dart
  ///         myRecorder.setAudioFocus(focus: AudioFocus.requestFocusAndDuckOthers);
  /// ```
  Future<void> setAudioFocus(
      {AudioFocus focus = AudioFocus.requestFocusTransient,
      SessionCategory category = SessionCategory.playAndRecord,
      SessionMode mode = SessionMode.modeDefault,
      AudioDevice device = AudioDevice.speaker}) async {
    print('FS:---> setAudioFocus ');
    await _lock.synchronized(() async {
      await _setAudioFocus(
        focus: focus,
        category: category,
        mode: mode,
        device: device,
      );
    });
    print('FS:<--- setAudioFocus ');
  }

  Future<void> _setAudioFocus(
      {AudioFocus focus = AudioFocus.requestFocusTransient,
      SessionCategory category = SessionCategory.playAndRecord,
      SessionMode mode = SessionMode.modeDefault,
      AudioDevice device = AudioDevice.speaker}) async {
    print('FS:---> setAudioFocus ');
    await _waitOpen();
    if (_isInited != Initialized.fullyInitialized) {
      throw Exception('Recorder is not open');
    }

    await FlutterSoundRecorderPlatform.instance.setAudioFocus(
      this,
      focus: focus,
      category: category,
      mode: mode,
      device: device,
    );
    //_recorderState = recorderState.values[state];
    print('FS:<--- setAudioFocus ');
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
    print('FS:---> pauseRecorder ');
    await _lock.synchronized(() async {
      await _pauseRecorder();
    });
    print('FS:<--- pauseRecorder ');
  }

  Future<void> _pauseRecorder() async {
    print('FS:---> pauseRecorder');
    await _waitOpen();
    if (_isInited != Initialized.fullyInitialized) {
      throw Exception('Recorder is not open');
    }
    Completer<void> completer;
    try {
      if (_pauseRecorderCompleter != null) {
        _pauseRecorderCompleter
            .completeError('Killed by another pauseRecorder()');
      }
      _pauseRecorderCompleter = Completer<void>();
      completer = _pauseRecorderCompleter;
      await FlutterSoundRecorderPlatform.instance.pauseRecorder(this);
    } on Exception {
      _pauseRecorderCompleter = null;
      rethrow;
    }
    _recorderState = RecorderState.isPaused;
    print('FS:<--- pauseRecorder');
    return completer.future;
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
    print('FS:---> pausePlayer ');
    await _lock.synchronized(() async {
      await _resumeRecorder();
    });
    print('FS:<--- resumeRecorder ');
  }

  Future<void> _resumeRecorder() async {
    print('FS:---> resumeRecorder ');
    await _waitOpen();
    if (_isInited != Initialized.fullyInitialized) {
      throw Exception('Recorder is not open');
    }
    Completer<void> completer;
    try {
      if (_resumeRecorderCompleter != null) {
        _resumeRecorderCompleter
            .completeError('Killed by another resumeRecorder()');
      }
      _resumeRecorderCompleter = Completer<void>();
      completer = _resumeRecorderCompleter;
      await FlutterSoundRecorderPlatform.instance.resumeRecorder(this);
    } on Exception {
      _resumeRecorderCompleter = null;
      rethrow;
    }
    _recorderState = RecorderState.isRecording;
    print('FS:<--- resumeRecorder ');
    return completer.future;
  }

  /// Delete a temporary file
  ///
  /// Delete a temporary file created during [startRecorder()].
  /// the argument must be a file name without any path.
  /// This function is seldom used, because [closeAudioSession()] delete automaticaly
  /// all the temporary files created.
  ///
  /// *Example:*
  /// ```dart
  ///      await myRecorder.startRecorder(toFile: 'foo'); // This is a temporary file, because no slash '/' in the argument
  ///      await myPlayer.startPlayer(fromURI: 'foo');
  ///      await myRecorder.deleteRecord('foo');
  /// ```
  Future<bool> deleteRecord({String fileName}) async {
    print('FS:---> deleteRecord');
    await _waitOpen();
    if (_isInited != Initialized.fullyInitialized) {
      throw Exception('Recorder is not open');
    }
    var b = await FlutterSoundRecorderPlatform.instance
        .deleteRecord(this, fileName);
    print('FS:<--- deleteRecord');
    return b;
  }

  /// Get the URI of a recorded file.
  ///
  /// This is same as the result of [stopRecorder()].
  /// Be careful : on Flutter Web, this verb cannot be used before stoping
  /// the recorder.
  /// This verb is seldom used. Most of the time, the App will use the result
  /// of [stopRecorder()].
  Future<String> getRecordURL({String path}) async {
    await _waitOpen();
    if (_isInited != Initialized.fullyInitialized) {
      throw Exception('Recorder is not open');
    }
    var url =
        await FlutterSoundRecorderPlatform.instance.getRecordURL(this, path);
    return url;
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
