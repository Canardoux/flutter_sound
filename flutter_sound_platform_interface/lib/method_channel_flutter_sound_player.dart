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

import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:typed_data' show Uint8List;

import 'flutter_sound_player_platform_interface.dart';
import 'flutter_sound_platform_interface.dart';

const MethodChannel _channel = MethodChannel('com.dooboolab.flutter_sound_player');

/// An implementation of [FlutterSoundPlayerPlatform] that uses method channels.
class MethodChannelFlutterSoundPlayer extends FlutterSoundPlayerPlatform
{



  /* ctor */ MethodChannelFlutterSoundPlayer()
  {
    setCallback();
  }

  void setCallback()
  {
    //_channel = const MethodChannel('com.dooboolab.flutter_sound_player');
    _channel.setMethodCallHandler((MethodCall call)
    {
      return channelMethodCallHandler(call);
    });
  }


  Future<dynamic> channelMethodCallHandler(MethodCall call)
  {
    FlutterSoundPlayerCallback aPlayer = getSession(call.arguments['slotNo'] as int);
    Map arg = call.arguments ;
    bool success = call.arguments['success'] as bool;


    switch (call.method)
    {
      case "updateProgress":
        {
          aPlayer.updatePlaybackState(arg['state']);
          aPlayer.updateProgress(duration:  arg['duration'], position:  arg['position']);
        }
        break;

      case "audioPlayerFinishedPlaying":
        {
          print('FS:---> channelMethodCallHandler : ${call.method}');
          aPlayer.updatePlaybackState(arg['state']);
          aPlayer.audioPlayerFinished(arg['arg']);
          print('FS:<--- channelMethodCallHandler : ${call.method}');
        }
        break;

      case 'pause': // Pause/Resume
        {
          print('FS:---> channelMethodCallHandler : ${call.method}');
          aPlayer.pause(arg['arg']);
          print('FS:<--- channelMethodCallHandler : ${call.method}');
        }
        break;

        case 'resume': // Pause/Resume
        {
          print('FS:---> channelMethodCallHandler : ${call.method}');
          aPlayer.resume(arg['arg']);
          print('FS:<--- channelMethodCallHandler : ${call.method}');
        }
        break;


      case 'skipForward':
        {
          print('FS:---> channelMethodCallHandler : ${call.method}');
          aPlayer.skipForward(arg['arg']);
          print('FS:<--- channelMethodCallHandler : ${call.method}');
        }
        break;

      case 'skipBackward':
        {
          print('FS:---> channelMethodCallHandler : ${call.method}');
          aPlayer.skipBackward(arg['arg']);
          print('FS:<--- channelMethodCallHandler : ${call.method}');
        }
        break;

      case 'updatePlaybackState':
        {
          print('FS:---> channelMethodCallHandler : ${call.method}');
          aPlayer.updatePlaybackState(arg['arg']);
          print('FS:<--- channelMethodCallHandler : ${call.method}');
        }
        break;


      case 'openPlayerCompleted':
        {
          print('FS:---> channelMethodCallHandler : ${call.method}');
          aPlayer.openPlayerCompleted(call.arguments['state'] , success);
          print('FS:<--- channelMethodCallHandler : ${call.method}');
        }
        break;




      case 'startPlayerCompleted':
        {
          print('FS:---> channelMethodCallHandler : ${call.method}');
          int duration = arg['duration'] as int;
          aPlayer.updatePlaybackState(arg['state']);
          aPlayer.startPlayerCompleted(call.arguments['state'], success, duration);
          print('FS:<--- channelMethodCallHandler : ${call.method}');
        }
        break;


      case "stopPlayerCompleted":
        {
          aPlayer.stopPlayerCompleted(call.arguments['state'] , success);
        }
        break;

      case "pausePlayerCompleted":
        {
          aPlayer.pausePlayerCompleted(call.arguments['state'] , success);
        }
        break;

      case "resumePlayerCompleted":
        {
          aPlayer.resumePlayerCompleted(call.arguments['state'] , success);
        }
        break;

      case "closePlayerCompleted":
        {
          aPlayer.closePlayerCompleted(call.arguments['state'], success );
        }
        break;



      case 'needSomeFood':
        {
          aPlayer.updatePlaybackState(arg['state']);
          aPlayer.needSomeFood(arg['arg']);
        }
        break;


      default:
        throw ArgumentError('Unknown method ${call.method}');
    }

    return null;
  }


//===============================================================================================================================



  Future<int> invokeMethod (FlutterSoundPlayerCallback callback,  String methodName, Map<String, dynamic> call)
  {
    call['slotNo'] = findSession(callback);
    return _channel.invokeMethod(methodName, call);
  }


  Future<String> invokeMethodString (FlutterSoundPlayerCallback callback, String methodName, Map<String, dynamic> call)
  {
    call['slotNo'] = findSession(callback);
    return _channel.invokeMethod(methodName, call);
  }


  Future<bool> invokeMethodBool (FlutterSoundPlayerCallback callback, String methodName, Map<String, dynamic> call)
  {
    call['slotNo'] = findSession(callback);
    return _channel.invokeMethod(methodName, call);
  }



  @override
  Future<void>   resetPlugin(FlutterSoundPlayerCallback callback,)
  {
    return _channel.invokeMethod('resetPlugin', );
  }


  @override
  Future<int> openPlayer(FlutterSoundPlayerCallback callback, {AudioFocus focus, SessionCategory category, SessionMode mode, int audioFlags, AudioDevice device, bool withUI})
  {
    return  invokeMethod( callback, 'openPlayer', {'focus': focus.index, 'category': category.index, 'mode': mode.index, 'audioFlags': audioFlags, 'device': device.index, 'withUI': withUI ? 1 : 0 ,},) ;
  }

  @override
  Future<int> setAudioFocus(FlutterSoundPlayerCallback callback, {AudioFocus focus, SessionCategory category, SessionMode mode, int audioFlags, AudioDevice device,} )
  {
    return invokeMethod( callback, 'setAudioFocus', {'focus': focus.index, 'category': category.index, 'mode': mode.index, 'audioFlags': audioFlags, 'device': device.index ,},);
  }

  @override
  Future<int> closePlayer(FlutterSoundPlayerCallback callback, )
  {
    return invokeMethod( callback, 'closePlayer',  Map<String, dynamic>(),);
  }

  @override
  Future<int> getPlayerState(FlutterSoundPlayerCallback callback, )
  {
    return invokeMethod( callback, 'getPlayerState',  Map<String, dynamic>(),);
  }
  @override
  Future<Map<String, Duration>> getProgress(FlutterSoundPlayerCallback callback, ) async
  {
    Map<String, int> m = await invokeMethod( callback, 'getPlayerState', null,) as Map;
    Map<String, Duration> r = {'duration': Duration(milliseconds: m['duration']), 'progress': Duration(milliseconds: m['progress']),};
    return r;
  }

  @override
  Future<bool> isDecoderSupported(FlutterSoundPlayerCallback callback, { Codec codec,})
  {
    return invokeMethodBool( callback, 'isDecoderSupported', {'codec': codec.index,},) as Future<bool>;
  }


  @override
  Future<int> setSubscriptionDuration(FlutterSoundPlayerCallback callback, { Duration duration,})
  {
    return invokeMethod( callback, 'setSubscriptionDuration', {'duration': duration.inMilliseconds},);
  }

  @override
  Future<int> startPlayer(FlutterSoundPlayerCallback callback,  {Codec codec, Uint8List fromDataBuffer, String  fromURI, int numChannels, int sampleRate})
  {
     return  invokeMethod( callback, 'startPlayer', {'codec': codec.index, 'fromDataBuffer': fromDataBuffer, 'fromURI': fromURI, 'numChannels': numChannels, 'sampleRate': sampleRate},) ;
  }

  @override
  Future<int> startPlayerFromMic(FlutterSoundPlayerCallback callback, {int numChannels, int sampleRate})
  {
    return  invokeMethod( callback, 'startPlayerFromMic', { 'numChannels': numChannels, 'sampleRate': sampleRate, },) ;
  }


  @override
  Future<int> feed(FlutterSoundPlayerCallback callback, {Uint8List data, })
  {
    return invokeMethod( callback, 'feed', {'data': data, },) ;
  }

  @override
  Future<int> startPlayerFromTrack(FlutterSoundPlayerCallback callback, {Duration progress, Duration duration, Map<String, dynamic> track, bool canPause, bool canSkipForward, bool canSkipBackward, bool defaultPauseResume, bool removeUIWhenStopped })
  {
    return invokeMethod( callback, 'startPlayerFromTrack', {'progress': progress, 'duration': duration, 'track': track, 'canPause': canPause, 'canSkipForward': canSkipForward, 'canSkipBackward': canSkipBackward,
           'defaultPauseResume': defaultPauseResume, 'removeUIWhenStopped': removeUIWhenStopped,},);
  }

  @override
  Future<int> nowPlaying(FlutterSoundPlayerCallback callback,  {Duration progress, Duration duration, Map<String, dynamic> track, bool canPause, bool canSkipForward, bool canSkipBackward, bool defaultPauseResume, }) async
  {
    return invokeMethod( callback, 'nowPlaying', {'progress': progress.inMilliseconds, 'duration': duration.inMilliseconds, 'track': track, 'canPause': canPause, 'canSkipForward': canSkipForward, 'canSkipBackward': canSkipBackward,
      'defaultPauseResume': defaultPauseResume,},);
  }

  @override
  Future<int> stopPlayer(FlutterSoundPlayerCallback callback,  )
  {
    return invokeMethod( callback, 'stopPlayer',  Map<String, dynamic>(),) ;
  }

  @override
  Future<int> pausePlayer(FlutterSoundPlayerCallback callback,  )
  {
    return invokeMethod( callback, 'pausePlayer',  Map<String, dynamic>(),) ;
  }

  @override
  Future<int> resumePlayer(FlutterSoundPlayerCallback callback,  )
  {
    return invokeMethod( callback, 'resumePlayer',  Map<String, dynamic>(),) ;
  }

  @override
  Future<int> seekToPlayer(FlutterSoundPlayerCallback callback,  {Duration duration})
  {
    return invokeMethod( callback, 'seekToPlayer', {'duration': duration.inMilliseconds,},) ;
  }

  Future<int> setVolume(FlutterSoundPlayerCallback callback,  {double volume})
  {
    return invokeMethod( callback, 'setVolume', {'volume': volume,}) ;
  }

  @override
  Future<int> setUIProgressBar(FlutterSoundPlayerCallback callback, {Duration duration, Duration progress,})
  {
    return invokeMethod( callback, 'setUIProgressBar', {'duration': duration.inMilliseconds, 'progress': progress.inMilliseconds,}) ;

  }

  Future<String> getResourcePath(FlutterSoundPlayerCallback callback, )
  {
    return invokeMethodString( callback, 'getResourcePath',  Map<String, dynamic>(),) ;
  }

}