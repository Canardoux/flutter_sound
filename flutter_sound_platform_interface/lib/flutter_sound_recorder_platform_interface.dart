

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

import 'package:logger/logger.dart' show Level , Logger;
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
  voiceDownlink, // (it does not work, at least on Android. Probably problems with the authorization )
  camCorder,
  remote_submix,
  unprocessed,
  voice_call,
  voice_communication,
  voice_performance,
  voice_recognition,
  voiceUpLink,// (it does not work, at least on Android. Probably problems with the authorization )
  bluetoothHFP,
  headsetMic,
  lineIn,
}


abstract class FlutterSoundRecorderCallback
{
  void updateRecorderProgress({int? duration, double? dbPeakLevel});
  void recordingData({Uint8List? data} );
  void startRecorderCompleted(int? state, bool? success);
  void pauseRecorderCompleted(int? state, bool? success);
  void resumeRecorderCompleted(int? state, bool? success);
  void stopRecorderCompleted(int? state, bool? success, String? url);
  void openRecorderCompleted(int? state, bool? success);
  void closeRecorderCompleted(int? state, bool? success);
  void log(Level logLevel, String msg);

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



  List<FlutterSoundRecorderCallback?> _slots = [];

  @override
  int findSession(FlutterSoundRecorderCallback aSession)
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

  @override
  void openSession(FlutterSoundRecorderCallback aSession)
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

  @override
  void closeSession(FlutterSoundRecorderCallback aSession)
  {
    _slots[findSession(aSession)] = null;
  }

  FlutterSoundRecorderCallback? getSession(int slotno)
  {
    return _slots[slotno];
  }



  Future<void>?   setLogLevel(FlutterSoundRecorderCallback callback, Level loglevel)
  {
    throw UnimplementedError('setLogLeve() has not been implemented.');
  }


  Future<void>?   resetPlugin(FlutterSoundRecorderCallback callback,)
  {
    throw UnimplementedError('resetPlugin() has not been implemented.');
  }


  Future<void> openRecorder(FlutterSoundRecorderCallback callback, {required Level logLevel, AudioFocus? focus, SessionCategory? category, SessionMode? mode, int? audioFlags, AudioDevice? device})
  {
    throw UnimplementedError('openRecorder() has not been implemented.');
  }

  Future<void> closeRecorder(FlutterSoundRecorderCallback callback, )
  {
    throw UnimplementedError('closeRecorder() has not been implemented.');
  }

  Future<void> setAudioFocus(FlutterSoundRecorderCallback callback, {AudioFocus? focus, SessionCategory? category, SessionMode? mode, int? audioFlags, AudioDevice? device,} )
  {
    throw UnimplementedError('setAudioFocus() has not been implemented.');
  }

  Future<bool> isEncoderSupported(FlutterSoundRecorderCallback callback, {required Codec codec ,})
  {
    throw UnimplementedError('isEncoderSupported() has not been implemented.');
  }

  Future<void> setSubscriptionDuration(FlutterSoundRecorderCallback callback, { Duration? duration,})
  {
    throw UnimplementedError('setSubscriptionDuration() has not been implemented.');
  }

  Future<void> startRecorder(FlutterSoundRecorderCallback callback,
  {
  String? path,
  int? sampleRate,
  int? numChannels,
  int? bitRate,
  Codec? codec,
  bool? toStream,
  AudioSource? audioSource,
  })
  {
    throw UnimplementedError('startRecorder() has not been implemented.');
  }

  Future<void> stopRecorder(FlutterSoundRecorderCallback callback, )
  {
    throw UnimplementedError('stopRecorder() has not been implemented.');
  }

  Future<void> pauseRecorder(FlutterSoundRecorderCallback callback, )
  {
    throw UnimplementedError('pauseRecorder() has not been implemented.');
  }

  Future<void> resumeRecorder(FlutterSoundRecorderCallback callback, )
  {
    throw UnimplementedError('resumeRecorder() has not been implemented.');
  }

  Future<bool?> deleteRecord(FlutterSoundRecorderCallback callback, String path)
  {
    throw UnimplementedError('deleteRecord() has not been implemented.');
  }

  Future<String?> getRecordURL(FlutterSoundRecorderCallback callback, String path )
  {
    throw UnimplementedError('getRecordURL() has not been implemented.');
  }


}