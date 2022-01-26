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
import 'dart:core';
import 'dart:typed_data';

import 'package:flutter_sound_platform_interface/flutter_sound_recorder_platform_interface.dart';
import 'package:logger/logger.dart' show Level, Logger;
import 'package:path/path.dart' as p;
import 'package:synchronized/synchronized.dart';

import '../flutter_sound.dart';

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
  /// The FlutterSoundRecorder Logger
  Logger _logger = Logger(level: Level.debug);
  Level _logLevel = Level.debug;

  /// The FlutterSoundRecorder Logger getter
  Logger get logger => _logger;

  /// Used if the App wants to dynamically change the Log Level.
  /// Seldom used. Most of the time the Log Level is specified during the constructor.
  Future<void> setLogLevel(Level aLevel) async {
    _logLevel = aLevel;
    _logger = Logger(level: aLevel);
    await _lock.synchronized(() async {
      if (_isInited != Initialized.notInitialized) {
        await FlutterSoundRecorderPlatform.instance.setLogLevel(
          this,
          aLevel,
        );
      }
    });
  }

  /// Locals
  /// ------
  ///
  Completer<void>? _startRecorderCompleter;
  Completer<void>? _pauseRecorderCompleter;
  Completer<void>? _resumeRecorderCompleter;
  Completer<String>? _stopRecorderCompleter;
  Completer<void>? _closeRecorderCompleter;
  Completer<FlutterSoundRecorder>? _openRecorderCompleter;

  final _lock = Lock();
  static bool _reStarted = true;

  Initialized _isInited = Initialized.notInitialized;

  RecorderState _recorderState = RecorderState.isStopped;
  StreamController<RecordingDisposition>? _recorderController;

  /// A reference to the User Sink during `StartRecorder(toStream:...)`
  StreamSink<Food>? _userStreamSink;

  /// The current state of the Recorder
  RecorderState get recorderState => _recorderState;

  /// Used by the UI Widget.
  ///
  /// It is a duplicate from [onProgress] and should not be here
  /// @nodoc
  Stream<RecordingDisposition>? dispositionStream() {
    return (_recorderController != null) ? _recorderController!.stream : null;
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
  Stream<RecordingDisposition>? get onProgress =>
      (_recorderController != null) ? _recorderController!.stream : null;

  /// True if `recorderState.isRecording`
  bool get isRecording => (_recorderState == RecorderState.isRecording);

  /// True if `recorderState.isStopped`
  bool get isStopped => (_recorderState == RecorderState.isStopped);

  /// True if `recorderState.isPaused`
  bool get isPaused => (_recorderState == RecorderState.isPaused);

  /// Instanciate a new Flutter Sound Recorder.
  /// The optional paramater `Level logLevel` specify the Logger Level you are interested by.
  /* ctor */ FlutterSoundRecorder({Level logLevel = Level.debug}) {
    _logger = Logger(level: logLevel);
    _logger.d('ctor: FlutterSoundRecorder()');
  }

  //===================================  Callbacks ================================================================

  /// Callback from the &tau; Core. Must not be called by the App
  /// @nodoc
  @override
  void recordingData({Uint8List? data}) {
    if (_userStreamSink != null) {
      //Uint8List data = call['recordingData'] as Uint8List;
      _userStreamSink!.add(FoodData(data));
    }
  }

  /// Callback from the &tau; Core. Must not be called by the App
  /// @nodoc
  @override
  void updateRecorderProgress({int? duration, double? dbPeakLevel}) {
    //int duration = call['duration'] as int;
    //double dbPeakLevel = call['dbPeakLevel'] as double;
    _recorderController!.add(RecordingDisposition(
      Duration(milliseconds: duration!),
      dbPeakLevel,
    ));
  }

  /// Callback from the &tau; Core. Must not be called by the App
  /// @nodoc
  @override
  void openRecorderCompleted(int? state, bool? success) {
    _logger.d('---> openRecorderCompleted: $success');

    _recorderState = RecorderState.values[state!];
    _isInited =
        success! ? Initialized.fullyInitialized : Initialized.notInitialized;
    if (success) {
      _openRecorderCompleter!.complete(this);
    } else {
      _pauseRecorderCompleter!.completeError('openRecorder failed');
    }
    _openRecorderCompleter = null;
    _logger.d('<--- openRecorderCompleted: $success');
  }

  /// Callback from the &tau; Core. Must not be called by the App
  /// @nodoc
  @override
  void closeRecorderCompleted(int? state, bool? success) {
    _logger.d('---> closeRecorderCompleted');
    _recorderState = RecorderState.values[state!];
    _isInited = Initialized.notInitialized;
    _closeRecorderCompleter!.complete();
    _closeRecorderCompleter = null;
    _cleanCompleters();
    _logger.d('<--- closeRecorderCompleted');
  }

  /// Callback from the &tau; Core. Must not be called by the App
  /// @nodoc
  @override
  void pauseRecorderCompleted(int? state, bool? success) {
    _logger.d('---> pauseRecorderCompleted: $success');
    assert(state != null);
    _recorderState = RecorderState.values[state!];
    if (success!) {
      _pauseRecorderCompleter!.complete();
    } else {
      _pauseRecorderCompleter!.completeError('pauseRecorder failed');
    }
    _pauseRecorderCompleter = null;
    _logger.d('<--- pauseRecorderCompleted: $success');
  }

  /// Callback from the &tau; Core. Must not be called by the App
  /// @nodoc
  @override
  void resumeRecorderCompleted(int? state, bool? success) {
    _logger.d('---> resumeRecorderCompleted: $success');
    assert(state != null);
    _recorderState = RecorderState.values[state!];
    if (success!) {
      _resumeRecorderCompleter!.complete();
    } else {
      _resumeRecorderCompleter!.completeError('resumeRecorder failed');
    }
    _resumeRecorderCompleter = null;
    _logger.d('<--- resumeRecorderCompleted: $success');
  }

  /// Callback from the &tau; Core. Must not be called by the App
  /// @nodoc
  @override
  void startRecorderCompleted(int? state, bool? success) {
    _logger.d('---> startRecorderCompleted: $success');
    assert(state != null);
    _recorderState = RecorderState.values[state!];
    if (success!) {
      _startRecorderCompleter!.complete();
    } else {
      _startRecorderCompleter!.completeError('startRecorder() failed');
    }
    _startRecorderCompleter = null;
    _logger.d('<--- startRecorderCompleted: $success');
  }

  /// Callback from the &tau; Core. Must not be called by the App
  /// @nodoc
  @override
  void stopRecorderCompleted(int? state, bool? success, String? url) {
    _logger.d('---> stopRecorderCompleted: $success');
    assert(state != null);
    _recorderState = RecorderState.values[state!];
    var s = url ?? '';
    if (success!) {
      _stopRecorderCompleter!.complete(s);
    } // stopRecorder must not gives errors
    else {
      _stopRecorderCompleter!.completeError('stopRecorder failed');
    }
    _stopRecorderCompleter = null;
    // _cleanCompleters(); ????
    _logger.d('<---- stopRecorderCompleted: $success');
  }

  void _cleanCompleters() {
    if (_pauseRecorderCompleter != null) {
      _logger.w('Kill _pauseRecorder()');
      var completer = _pauseRecorderCompleter!;
      _pauseRecorderCompleter = null;
      completer.completeError('killed by cleanCompleters');
    }
    if (_resumeRecorderCompleter != null) {
      _logger.w('Kill _resumeRecorder()');
      var completer = _resumeRecorderCompleter!;
      _resumeRecorderCompleter = null;
      completer.completeError('killed by cleanCompleters');
    }

    if (_startRecorderCompleter != null) {
      _logger.w('Kill _startRecorder()');
      var completer = _startRecorderCompleter!;
      _startRecorderCompleter = null;
      completer.completeError('killed by cleanCompleters');
    }

    if (_stopRecorderCompleter != null) {
      _logger.w('Kill _stopRecorder()');
      Completer<void> completer = _stopRecorderCompleter!;
      _stopRecorderCompleter = null;
      completer.completeError('killed by cleanCompleters');
    }

    if (_openRecorderCompleter != null) {
      _logger.w('Kill openRecorder()');
      Completer<void> completer = _openRecorderCompleter!;
      _openRecorderCompleter = null;
      completer.completeError('killed by cleanCompleters');
    }

    if (_closeRecorderCompleter != null) {
      _logger.w('Kill _closeRecorder()');
      var completer = _closeRecorderCompleter!;
      _closeRecorderCompleter = null;
      completer.completeError('killed by cleanCompleters');
    }
  }

  @override
  void log(Level logLevel, String msg) {
    _logger.log(logLevel, msg);
  }

// ----------------------------------------------------------------------------------------------------------------------------------------------

  Future<void> _waitOpen() async {
    while (_openRecorderCompleter != null) {
      _logger.w('Waiting for the recorder being opened');
      await _openRecorderCompleter!.future;
    }
    if (_isInited == Initialized.notInitialized) {
      throw Exception('Recorder is not open');
    }
  }

  /// Open a Recorder
  ///
  /// A recorder must be opened before used.
  /// Opening a recorder takes resources inside the OS. Those resources are freed with the verb `closeRecorder()`.
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
  ///             myRecorder.closeRecorder();
  ///             myRecorder = null;
  ///         }
  ///         super.dispose();
  /// }
  /// ```
  ///
  /// You may not openAudioSession many recorders without releasing them.
  ///
  /// `openRecorder()` and `closeRecorder()` return Futures.
  /// You do not need to wait the end of the initialization before [startRecorder()].
  /// [startRecorder] will automaticaly wait the end of `openRecorder()` before starting the recorder.
  ///
  /// The four optional parameters are used if you want to control the Audio Focus. Please look to [FlutterSoundRecorder openAudioSession()](Recorder.md#openaudiosession-and-closeaudiosession) to understand the meaning of those parameters
  ///
  /// *Example:*
  /// ```dart
  ///     myRecorder = await FlutterSoundRecorder().openRecorder();
  ///
  ///     ...
  ///     (do something with myRecorder)
  ///     ...
  ///
  ///     myRecorder.closeRecorder();
  ///     myRecorder = null;
  /// ```
  Future<FlutterSoundRecorder?> openRecorder() async {
    if (_isInited != Initialized.notInitialized) {
      return this;
    }

    FlutterSoundRecorder? r;
    _logger.d('FS:---> openAudioSession ');
    await _lock.synchronized(() async {
      r = await _openAudioSession();
    });
    _logger.d('FS:<--- openAudioSession ');
    return r;
  }

  Future<FlutterSoundRecorder> _openAudioSession() async {
    _logger.d('---> openAudioSession');

    Completer<FlutterSoundRecorder>? completer;

    _setRecorderCallback();
    if (_userStreamSink != null) {
      await _userStreamSink!.close();
      _userStreamSink = null;
    }
    assert(_openRecorderCompleter == null);
    _openRecorderCompleter = Completer<FlutterSoundRecorder>();
    completer = _openRecorderCompleter;
    try {
      if (_reStarted) {
        // Perhaps a Hot Restart ?  We must reset the plugin
        _logger.d('Resetting flutter_sound Recorder Plugin');
        _reStarted = false;
        await FlutterSoundRecorderPlatform.instance.resetPlugin(this);
      }

      FlutterSoundRecorderPlatform.instance.openSession(this);
      await FlutterSoundRecorderPlatform.instance.openRecorder(
        this,
        logLevel: _logLevel,
      );

      //_isInited = Initialized.fullyInitialized;
    } on Exception {
      _openRecorderCompleter = null;
      rethrow;
    }
    _logger.d('<--- openAudioSession');
    return completer!.future;
  }

  /// Close a Recorder
  ///
  /// You must close your recorder when you have finished with it, for releasing the resources.
  /// Delete all the temporary files created with `startRecorder()`

  Future<void> closeRecorder() async {
    _logger.d('FS:---> closeAudioSession ');
    await _lock.synchronized(() async {
      await _closeAudioSession();
    });
    _logger.d('FS:<--- closeAudioSession ');
  }

  Future<void> _closeAudioSession() async {
    _logger.d('FS:---> closeAudioSession ');
    // If another closeRecorder() is already in progress, wait until finished
    while (_closeRecorderCompleter != null) {
      try {
        _logger.w('Another closeRecorder() in progress');
        await _closeRecorderCompleter!.future;
      } catch (_) {}
    }
    if (_isInited == Initialized.notInitialized) {
      // Already close
      _logger.i('Recorder already close');
      return;
    }

    Completer<void>? completer;

    try {
      await _stop(); // Stop the recorder if running
    } catch (e) {
      _logger.e(e.toString());
    }
    //_isInited = Initialized.initializationInProgress; // BOF
    _removeRecorderCallback(); // _recorderController will be closed by this function
    if (_userStreamSink != null) {
      await _userStreamSink!.close();
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
    _logger.d('FS:<--- closeAudioSession ');
    return completer!.future;
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
    var result = false;
    // For encoding ogg/opus on ios, we need to support two steps :
    // - encode CAF/OPPUS (with native Apple AVFoundation)
    // - remux CAF file format to OPUS file format (with ffmpeg)

    result = await FlutterSoundRecorderPlatform.instance
        .isEncoderSupported(this, codec: codec);
    return result;
  }

  void _setRecorderCallback() {
    _recorderController ??= StreamController.broadcast();
  }

  void _removeRecorderCallback() {
    _recorderController?.close();
    _recorderController = null;
  }

  /// Sets the frequency at which duration updates are sent to
  /// duration listeners.
  ///
  /// Zero means "no callbacks".
  /// The default is zero.
  Future<void> setSubscriptionDuration(Duration duration) async {
    _logger.d('FS:---> setSubscriptionDuration ');
    await _waitOpen();
    if (_isInited != Initialized.fullyInitialized) {
      throw Exception('Recorder is not open');
    }
    await FlutterSoundRecorderPlatform.instance
        .setSubscriptionDuration(this, duration: duration);
    _logger.d('FS:<--- setSubscriptionDuration ');
  }

  /// Return the file extension for the given path.
  /// path can be null. We return null in this case.
  String _fileExtension(String path) {
    var r = p.extension(path);
    return r;
  }

  Codec? _getCodecFromExtension(extension) {
    for (var codec in Codec.values) {
      if (ext[codec.index] == extension) {
        return codec;
      }
    }
    return null;
  }

  bool _isValidFileExtension(Codec codec, String extension) {
    var extList = validExt[codec.index];
    for (var s in extList) {
      if (s == extension) return true;
    }
    return false;
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
    String? toFile,
    StreamSink<Food>? toStream,
    int sampleRate = 16000,
    int numChannels = 1,
    int bitRate = 16000,
    AudioSource audioSource = AudioSource.defaultSource,
  }) async {
    _logger.d('FS:---> startRecorder ');
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
    _logger.d('FS:<--- startRecorder ');
  }

  Future<void> _startRecorder({
    Codec codec = Codec.defaultCodec,
    String? toFile,
    StreamSink<Food>? toStream,
    int sampleRate = 16000,
    int numChannels = 1,
    int bitRate = 16000,
    AudioSource audioSource = AudioSource.defaultSource,
  }) async {
    _logger.d('FS:---> _startRecorder.');
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
    if (_recorderState != RecorderState.isStopped) {
      throw _RecorderRunningException('Recorder is not stopped.');
    }

    if (toFile != null) {
      var extension = _fileExtension(toFile);
      if (codec == Codec.defaultCodec) {
        var codecExt = _getCodecFromExtension(extension);
        if (codecExt == null) {
          throw _CodecNotSupportedException(
              "File extension '$extension' not recognized.");
        }
        codec = codecExt;
      }
      if (!_isValidFileExtension(codec, extension)) {
        throw _CodecNotSupportedException(
            "File extension '$extension' is incorrect for the audio codec '$codec'");
      }
    }

    if (!await (isEncoderSupported(codec))) {
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
    Completer<void>? completer;
    // Maybe we should stop any recording already running... (stopRecorder does that)
    _userStreamSink = toStream;
    if (_startRecorderCompleter != null) {
      _startRecorderCompleter!
          .completeError('Killed by another startRecorder()');
    }
    _startRecorderCompleter = Completer<void>();
    completer = _startRecorderCompleter;
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
    _logger.d('FS:<--- _startRecorder.');
    return completer!.future;
  }

  Future<String> _stop() async {
    _logger.d('FS:---> _stop');
    _stopRecorderCompleter = Completer<String>();
    var completer = _stopRecorderCompleter!;
    try {
      await FlutterSoundRecorderPlatform.instance.stopRecorder(this);
      _userStreamSink = null;

      _recorderState = RecorderState.isStopped;
    } on Exception {
      _stopRecorderCompleter = null;
      rethrow;
    }

    _logger.d('FS:<--- _stop');
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
  Future<String?> stopRecorder() async {
    _logger.d('FS:---> stopRecorder ');
    String? r;
    await _lock.synchronized(() async {
      r = await _stopRecorder();
    });
    _logger.d('FS:<--- stopRecorder ');
    return r;
  }

  Future<String?> _stopRecorder() async {
    _logger.d('FS:---> _stopRecorder ');
    while (_openRecorderCompleter != null) {
      _logger.w('Waiting for the recorder being opened');
      await _openRecorderCompleter!.future;
    }
    if (_isInited != Initialized.fullyInitialized) {
      _logger.d('<--- _stopRecorder : Recorder is not open');
      return 'Recorder is not open';
    }
    String? r;

    try {
      r = await _stop();
    } on Exception catch (e) {
      _logger.e(e);
    }
    _logger.d('FS:<--- _stopRecorder : $r');
    return r;
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
    _logger.d('FS:---> pauseRecorder ');
    await _lock.synchronized(() async {
      await _pauseRecorder();
    });
    _logger.d('FS:<--- pauseRecorder ');
  }

  Future<void> _pauseRecorder() async {
    _logger.d('FS:---> pauseRecorder');
    await _waitOpen();
    if (_isInited != Initialized.fullyInitialized) {
      throw Exception('Recorder is not open');
    }
    Completer<void>? completer;
    try {
      if (_pauseRecorderCompleter != null) {
        _pauseRecorderCompleter!
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
    _logger.d('FS:<--- pauseRecorder');
    return completer!.future;
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
    _logger.d('FS:---> pausePlayer ');
    await _lock.synchronized(() async {
      await _resumeRecorder();
    });
    _logger.d('FS:<--- resumeRecorder ');
  }

  Future<void> _resumeRecorder() async {
    _logger.d('FS:---> resumeRecorder ');
    await _waitOpen();
    if (_isInited != Initialized.fullyInitialized) {
      throw Exception('Recorder is not open');
    }
    Completer<void>? completer;
    try {
      if (_resumeRecorderCompleter != null) {
        _resumeRecorderCompleter!
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
    _logger.d('FS:<--- resumeRecorder ');
    return completer!.future;
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
  Future<bool?> deleteRecord({required String fileName}) async {
    _logger.d('FS:---> deleteRecord');
    await _waitOpen();
    if (_isInited != Initialized.fullyInitialized) {
      throw Exception('Recorder is not open');
    }
    var b = await FlutterSoundRecorderPlatform.instance
        .deleteRecord(this, fileName);
    _logger.d('FS:<--- deleteRecord');
    return b;
  }

  /// Get the URI of a recorded file.
  ///
  /// This is same as the result of [stopRecorder()].
  /// Be careful : on Flutter Web, this verb cannot be used before stoping
  /// the recorder.
  /// This verb is seldom used. Most of the time, the App will use the result
  /// of [stopRecorder()].
  Future<String?> getRecordURL({required String path}) async {
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
  final double? decibels;

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
