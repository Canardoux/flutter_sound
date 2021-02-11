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

  void updateProgress({int duration, int position,}) ;
  void pause(int state);
  void resume(int state);
  void skipBackward(int state);
  void skipForward(int state);
  void updatePlaybackState(int state);
  void needSomeFood(int ln);
  void audioPlayerFinished(int state);
  void startPlayerCompleted(int state, bool success, int duration);
  void pausePlayerCompleted(int state, bool success);
  void resumePlayerCompleted(int state, bool success);
  void stopPlayerCompleted(int state, bool success);
  void openPlayerCompleted(int state, bool success);
  void closePlayerCompleted(int state, bool success);

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


  List<FlutterSoundPlayerCallback> _slots = [];

  int findSession(FlutterSoundPlayerCallback aSession)
  {
    for (var i = 0; i < _slots.length; ++i)
    {
      if (_slots[i] == aSession)
      {
        return i;
      }
    }
    return -1;
  }

  void openSession(FlutterSoundPlayerCallback aSession)
  {
    assert(findSession(aSession) == -1);

    for (var i = 0; i < _slots.length; ++i)
    {
      if (_slots[i] == null)
      {
        _slots[i] = aSession;
        return;
      }
    }
    _slots.add(aSession);
  }

  void closeSession(FlutterSoundPlayerCallback aSession)
  {
    _slots[findSession(aSession)] = null;
  }

  FlutterSoundPlayerCallback getSession(int slotno)
  {
    return _slots[slotno];
  }

  //===================================================================================================================================================


  Future<void>   resetPlugin(FlutterSoundPlayerCallback callback,)
  {
    throw UnimplementedError('resetPlugin() has not been implemented.');
  }

  Future<int> openPlayer(FlutterSoundPlayerCallback callback, {AudioFocus focus, SessionCategory category, SessionMode mode, int audioFlags, AudioDevice device, bool withUI,})
  {
    throw UnimplementedError('openPlayer() has not been implemented.');
  }

  Future<int> setAudioFocus(FlutterSoundPlayerCallback callback, {AudioFocus focus, SessionCategory category, SessionMode mode, int audioFlags, AudioDevice device,} )
  {
    throw UnimplementedError('setAudioFocus() has not been implemented.');
  }

  Future<int> closePlayer(FlutterSoundPlayerCallback callback, )
  {
    throw UnimplementedError('closePlayer() has not been implemented.');
  }

  Future<int> getPlayerState(FlutterSoundPlayerCallback callback, )
  {
    throw UnimplementedError('getPlayerState() has not been implemented.');
  }

  Future<Map<String, Duration>> getProgress(FlutterSoundPlayerCallback callback, )
  {
    throw UnimplementedError('getProgress() has not been implemented.');
  }

  Future<bool> isDecoderSupported(FlutterSoundPlayerCallback callback, {Codec codec} )
  {
    throw UnimplementedError('isDecoderSupported() has not been implemented.');
  }

  Future<int> setSubscriptionDuration(FlutterSoundPlayerCallback callback, {Duration duration})
  {
    throw UnimplementedError('setSubscriptionDuration() has not been implemented.');
  }

  Future<int> startPlayer(FlutterSoundPlayerCallback callback, {Codec codec, Uint8List fromDataBuffer, String  fromURI, int numChannels, int sampleRate})
  {
    throw UnimplementedError('startPlayer() has not been implemented.');
  }

  Future<int> startPlayerFromMic(FlutterSoundPlayerCallback callback, {int numChannels, int sampleRate})
  {
    throw UnimplementedError('startPlayerFromMic() has not been implemented.');
  }

  Future<int> feed(FlutterSoundPlayerCallback callback, {Uint8List data, })
  {
    throw UnimplementedError('feed() has not been implemented.');
  }

  Future<int> startPlayerFromTrack(FlutterSoundPlayerCallback callback, {Duration progress, Duration duration, Map<String, dynamic> track, bool canPause, bool canSkipForward, bool canSkipBackward, bool defaultPauseResume, bool removeUIWhenStopped })
  {
    throw UnimplementedError('startPlayerFromTrack() has not been implemented.');
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
