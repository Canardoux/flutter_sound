import 'dart:async';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:typed_data' show Uint8List;

import 'method_channel_flutter_sound_player.dart';
import 'flutter_sound_platform_interface.dart';

abstract class FlutterSoundPlayerCallback
{

  void updateProgress({Duration duration, Duration position,}) ;
  void pause(int state);
  void resume(int state);
  void skipBackward(int state);
  void skipForward(int state);
  void updatePlaybackState(int state);
  void needSomeFood(int ln);
  void audioPlayerFinished(int state);
}

/// The interface that implementations of flutter_soundPlayer must implement.
///
/// Platform implementations should extend this class rather than implement it as `url_launcher`
/// does not consider newly added methods to be breaking changes. Extending this class
/// (using `extends`) ensures that the subclass will get the default implementation, while
/// platform implementations that `implements` this interface will be broken by newly added
/// [FlutterSoundPlayerPlatform] methods.



abstract class FlutterSoundPlayerPlatform extends PlatformInterface {
  /// Constructs a UrlLauncherPlatform.
  FlutterSoundPlayerPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterSoundPlayerPlatform _instance = MethodChannelFlutterSoundPlayer();

  /// The default instance of [FlutterSoundPlayerPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterSoundPlayer].
  static FlutterSoundPlayerPlatform get instance => _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [MethodChannelFlutterSoundPlayer] when they register themselves.
  static set instance(FlutterSoundPlayerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }


  void openSession(FlutterSoundPlayerCallback aSession)
  {
    throw UnimplementedError('invokeMethod() has not been implemented.');
  }

  void closeSession(FlutterSoundPlayerCallback aSession)
  {
    throw UnimplementedError('invokeMethod() has not been implemented.');
  }


  Future<bool> initializeMediaPlayer(FlutterSoundPlayerCallback callback, {AudioFocus focus, SessionCategory category, SessionMode mode, int audioFlags, AudioDevice device, bool withUI,})
  {
    throw UnimplementedError('invokeMethod() has not been implemented.');
  }

  Future<int> setAudioFocus(FlutterSoundPlayerCallback callback, {AudioFocus focus, SessionCategory category, SessionMode mode, int audioFlags, AudioDevice device,} )
  {
    throw UnimplementedError('invokeMethod() has not been implemented.');
  }

  Future<int> releaseMediaPlayer(FlutterSoundPlayerCallback callback, )
  {
    throw UnimplementedError('invokeMethod() has not been implemented.');
  }

  Future<int> getPlayerState(FlutterSoundPlayerCallback callback, )
  {
    throw UnimplementedError('invokeMethod() has not been implemented.');
  }

  Future<Map<String, Duration>> getProgress(FlutterSoundPlayerCallback callback, )
  {
    throw UnimplementedError('invokeMethod() has not been implemented.');
  }

  Future<bool> isDecoderSupported(FlutterSoundPlayerCallback callback, {Codec codec} )
  {
    throw UnimplementedError('invokeMethod() has not been implemented.');
  }

  Future<int> setSubscriptionDuration(FlutterSoundPlayerCallback callback, {Duration duration})
  {
    throw UnimplementedError('invokeMethod() has not been implemented.');
  }

  Future<Map<dynamic, dynamic>> startPlayer(FlutterSoundPlayerCallback callback, {Codec codec, Uint8List fromDataBuffer, String  fromURI, int numChannels, int sampleRate})
  {
    throw UnimplementedError('invokeMethod() has not been implemented.');
  }

  Future<int> feed(FlutterSoundPlayerCallback callback, {Uint8List data, })
  {
    throw UnimplementedError('invokeMethod() has not been implemented.');
  }

  Future<Map<dynamic, dynamic>> startPlayerFromTrack(FlutterSoundPlayerCallback callback, {Duration progress, Duration duration, Map<String, dynamic> track, bool canPause, bool canSkipForward, bool canSkipBackward, bool defaultPauseResume, bool removeUIWhenStopped })
  {
    throw UnimplementedError('invokeMethod() has not been implemented.');
  }

  Future<int> nowPlaying(FlutterSoundPlayerCallback callback, {Duration progress, Duration duration, Map<String, dynamic> track, bool canPause, bool canSkipForward, bool canSkipBackward, bool defaultPauseResume,})
  {
    throw UnimplementedError('invokeMethod() has not been implemented.');
  }

  Future<int> stopPlayer(FlutterSoundPlayerCallback callback,  )
  {
    throw UnimplementedError('invokeMethod() has not been implemented.');
  }

  Future<int> pausePlayer(FlutterSoundPlayerCallback callback,  )
  {
    throw UnimplementedError('invokeMethod() has not been implemented.');
  }

  Future<int> resumePlayer(FlutterSoundPlayerCallback callback,  )
  {
    throw UnimplementedError('invokeMethod() has not been implemented.');
  }

  Future<int> seekToPlayer(FlutterSoundPlayerCallback callback, {Duration duration})
  {
    throw UnimplementedError('invokeMethod() has not been implemented.');
  }

  Future<int> setVolume(FlutterSoundPlayerCallback callback, {double volume})
  {
    throw UnimplementedError('invokeMethod() has not been implemented.');
  }

  Future<int> setUIProgressBar(FlutterSoundPlayerCallback callback, {Duration duration, Duration progress,})
  {
    throw UnimplementedError('invokeMethod() has not been implemented.');
  }

  Future<String> getResourcePath(FlutterSoundPlayerCallback callback, )
  {
    throw UnimplementedError('invokeMethod() has not been implemented.');
  }

}
