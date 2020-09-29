import 'dart:async';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'method_channel_flutter_sound_recorder.dart';
import 'flutter_sound_platform_interface.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:io' show Platform;
import 'dart:typed_data' show Uint8List;



enum RecorderState {
  isStopped,
  isPaused,
  isRecording,
}

enum AudioSource {
  defaultSource,
  microphone,
  voiceDownlink, // (if someone can explain me what it is, I will be grateful ;-) )
  camCorder,
  remote_submix,
  unprocessed,
  voice_call,
  voice_communication,
  voice_performance,
  voice_recognition,
  voiceUpLink,
  bluetoothHFP,
  headsetMic,
  lineIn,
}


abstract class FlutterSoundRecorderCallback
{
  void updateRecorderProgress({Duration duration, double dbPeakLevel});
  void recordingData({Uint8List data} );
}


/// The interface that implementations of url_launcher must implement.
///
/// Platform implementations should extend this class rather than implement it as `url_launcher`
/// does not consider newly added methods to be breaking changes. Extending this class
/// (using `extends`) ensures that the subclass will get the default implementation, while
/// platform implementations that `implements` this interface will be broken by newly added
/// [FlutterSoundPlatform] methods.
abstract class FlutterSoundRecorderPlatform extends PlatformInterface {


  /// Constructs a UrlLauncherPlatform.
  FlutterSoundRecorderPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterSoundRecorderPlatform _instance = MethodChannelFlutterSoundRecorder();

  /// The default instance of [FlutterSoundRecorderPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterSoundRecorder].
  static FlutterSoundRecorderPlatform get instance => _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [UrlLauncherPlatform] when they register themselves.
  static set instance(FlutterSoundRecorderPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  void openSession(FlutterSoundRecorderCallback aSession)
  {
    throw UnimplementedError('invokeMethod() has not been implemented.');
  }

  void closeSession(FlutterSoundRecorderCallback aSession)
  {
    throw UnimplementedError('invokeMethod() has not been implemented.');
  }

  Future<void> initializeFlautoRecorder(FlutterSoundRecorderCallback callback, {AudioFocus focus, SessionCategory category, SessionMode mode, int audioFlags, AudioDevice device})
  {
    throw UnimplementedError('invokeMethod() has not been implemented.');
  }

  Future<void> releaseFlautoRecorder(FlutterSoundRecorderCallback callback, )
  {
    throw UnimplementedError('invokeMethod() has not been implemented.');
  }

  Future<void> setAudioFocus(FlutterSoundRecorderCallback callback, {AudioFocus focus, SessionCategory category, SessionMode mode, int audioFlags, AudioDevice device,} )
  {
    throw UnimplementedError('invokeMethod() has not been implemented.');
  }

  Future<bool> isEncoderSupported(FlutterSoundRecorderCallback callback, {Codec codec,})
  {
    throw UnimplementedError('invokeMethod() has not been implemented.');
  }

  Future<void> setSubscriptionDuration(FlutterSoundRecorderCallback callback, { Duration duration,})
  {
    throw UnimplementedError('invokeMethod() has not been implemented.');
  }

  Future<void> startRecorder(FlutterSoundRecorderCallback callback,
  {
  String path,
  int sampleRate,
  int numChannels,
  int bitRate,
  Codec codec,
  bool toStream,
  AudioSource audioSource,
  })
  {
    throw UnimplementedError('invokeMethod() has not been implemented.');
  }

  Future<void> stopRecorder(FlutterSoundRecorderCallback callback, )
  {
    throw UnimplementedError('invokeMethod() has not been implemented.');
  }

  Future<void> pauseRecorder(FlutterSoundRecorderCallback callback, )
  {
    throw UnimplementedError('invokeMethod() has not been implemented.');
  }

  Future<void> resumeRecorder(FlutterSoundRecorderCallback callback, )
  {
    throw UnimplementedError('invokeMethod() has not been implemented.');
  }


}