/*
 * Copyright 2018, 2019, 2020, 2021 Dooboolab.
 *
 * This file is part of Flutter-Sound.
 *
 * Flutter-Sound is free software: you can redistribute it and/or modify
 * it under the terms of the Mozilla Public License version 2 (MPL2.0),
 * as published by the Mozilla organization.
 *
 * Flutter-Sound is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * MPL General Public License for more details.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */


import 'dart:async';

import 'package:flutter/services.dart';
import 'package:logger/logger.dart' show Level , Logger;
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
      return channelMethodCallHandler(call)!;
    });
  }


  Future<dynamic>? channelMethodCallHandler(MethodCall call)
  {
    FlutterSoundPlayerCallback aPlayer = getSession(call.arguments!['slotNo'] as int);
    Map arg = call.arguments ;

    bool success = call.arguments['success'] != null ? call.arguments['success'] as bool : false;
    if (arg['state'] != null)
      aPlayer.updatePlaybackState(arg['state']);

    switch (call.method)
    {
      case "updateProgress":
        {
          aPlayer.updateProgress(duration:  arg['duration'], position:  arg['position']);
        }
        break;

      case "needSomeFood":
        {
          aPlayer.needSomeFood(arg['arg']);
        }
        break;

      case "audioPlayerFinishedPlaying":
        {
          aPlayer.audioPlayerFinished(arg['arg']);
        }
        break;


      case 'updatePlaybackState':
        {
          aPlayer.updatePlaybackState(arg['arg']);
        }
        break;


      case 'openPlayerCompleted':
        {
          aPlayer.openPlayerCompleted(call.arguments['state'] , success);
        }
        break;




      case 'startPlayerCompleted':
        {
          int duration = arg['duration'] as int;
          aPlayer.startPlayerCompleted(call.arguments['state'], success, duration);
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

      case "log":
        {
          aPlayer.log(Level.values[call.arguments['level']], call.arguments['msg']);
        }
        break;


      default:
        throw ArgumentError('Unknown method ${call.method}');
    }

    return null;
  }


//===============================================================================================================================



  Future<int> invokeMethod (FlutterSoundPlayerCallback callback,  String methodName, Map<String, dynamic> call) async
  {
    call['slotNo'] = findSession(callback);
    return await _channel.invokeMethod(methodName, call) as int;
  }


  Future<String> invokeMethodString (FlutterSoundPlayerCallback callback, String methodName, Map<String, dynamic> call) async
  {
    call['slotNo'] = findSession(callback);
    return await _channel.invokeMethod(methodName, call) as String;
  }


  Future<bool> invokeMethodBool (FlutterSoundPlayerCallback callback, String methodName, Map<String, dynamic> call) async
  {
    call['slotNo'] = findSession(callback);
    return await _channel.invokeMethod(methodName, call) as bool;
  }


Future<Map> invokeMethodMap (FlutterSoundPlayerCallback callback, String methodName, Map<String, dynamic> call) async
{
  call['slotNo'] = findSession(callback);
  var r = await _channel.invokeMethod(methodName, call);
  return r ;
}



@override
  Future<void>?   setLogLevel(FlutterSoundPlayerCallback callback, Level logLevel)
  {
    invokeMethod( callback, 'setLogLevel', {'logLevel': logLevel.index,});
  }


  @override
  Future<void>?   resetPlugin(FlutterSoundPlayerCallback callback,)
  {
    return _channel.invokeMethod('resetPlugin', );
  }


  @override
  Future<int> openPlayer(FlutterSoundPlayerCallback callback, {required Level logLevel, bool voiceProcessing=false})
  {
    return  invokeMethod( callback, 'openPlayer', {'logLevel': logLevel.index, 'voiceProcessing': voiceProcessing},) ;
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
    var m2 = await invokeMethodMap( callback, 'getProgress', Map<String, dynamic>(),) ;
    Map<String, Duration> r = {'duration': Duration(milliseconds: m2['duration']! ), 'progress': Duration(milliseconds: m2['position']! ),};
    return r;
  }

  @override
  Future<bool> isDecoderSupported(FlutterSoundPlayerCallback callback, { Codec codec = Codec.defaultCodec,})
  {
    return invokeMethodBool( callback, 'isDecoderSupported', {'codec': codec.index,},) as Future<bool>;
  }


  @override
  Future<int> setSubscriptionDuration(FlutterSoundPlayerCallback callback, { Duration? duration,})
  {
    return invokeMethod( callback, 'setSubscriptionDuration', {'duration': duration!.inMilliseconds},);
  }

  @override
  Future<int> startPlayer(FlutterSoundPlayerCallback callback,  {Codec? codec, Uint8List? fromDataBuffer, String?  fromURI, int? numChannels, int? sampleRate})
  {
     return  invokeMethod( callback, 'startPlayer', {'codec': codec!.index, 'fromDataBuffer': fromDataBuffer, 'fromURI': fromURI, 'numChannels': numChannels, 'sampleRate': sampleRate},) ;
  }

  @override
  Future<int> startPlayerFromMic(FlutterSoundPlayerCallback callback, {int? numChannels, int? sampleRate})
  {
    return  invokeMethod( callback, 'startPlayerFromMic', { 'numChannels': numChannels, 'sampleRate': sampleRate, },) ;
  }


  @override
  Future<int> feed(FlutterSoundPlayerCallback callback, {Uint8List? data, })
  {
    return invokeMethod( callback, 'feed', {'data': data, },) ;
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
  Future<int> seekToPlayer(FlutterSoundPlayerCallback callback,  {Duration? duration})
  {
    return invokeMethod( callback, 'seekToPlayer', {'duration': duration!.inMilliseconds,},) ;
  }

  @override
  Future<int> setVolume(FlutterSoundPlayerCallback callback,  {double? volume})
  {
    return invokeMethod( callback, 'setVolume', {'volume': volume,}) ;
  }

  @override
  Future<int> setSpeed(FlutterSoundPlayerCallback callback,  {required double speed})
  {
    return invokeMethod( callback, 'setSpeed', {'speed': speed,}) ;
  }


  Future<String> getResourcePath(FlutterSoundPlayerCallback callback, )
  {
    return invokeMethodString( callback, 'getResourcePath',  Map<String, dynamic>(),) ;
  }

}