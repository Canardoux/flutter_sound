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

import 'flutter_sound_platform_interface.dart';
import 'flutter_sound_recorder_platform_interface.dart';

const MethodChannel _channel = MethodChannel('com.dooboolab.flutter_sound_recorder');



/// An implementation of [UrlLauncherPlatform] that uses method channels.
class MethodChannelFlutterSoundRecorder extends FlutterSoundRecorderPlatform
{

  /*ctor */ MethodChannelFlutterSoundRecorder()
  {
    _setCallback();
  }

  void _setCallback()
  {
    //channel = const MethodChannel('com.dooboolab.flutter_sound_recorder');
    _channel.setMethodCallHandler((MethodCall call)
    {
      return channelMethodCallHandler(call);
    });
  }



Future<dynamic> channelMethodCallHandler(MethodCall call) {
    FlutterSoundRecorderCallback aRecorder = getSession(call.arguments['slotNo'] as int);
    bool success = call.arguments['success'] as bool;

    switch (call.method) {
      case "updateRecorderProgress":
        {
          aRecorder.updateRecorderProgress(duration:call.arguments ['duration'], dbPeakLevel: call.arguments['dbPeakLevel']);
        }
        break;

        case "recordingData":
        {
          aRecorder.recordingData(data: call.arguments['recordingData'] );
        }
        break;

        case "startRecorderCompleted":
        {
          aRecorder.startRecorderCompleted(call.arguments['state'], success );
        }
        break;

        case "stopRecorderCompleted":
        {
          aRecorder.stopRecorderCompleted(call.arguments['state'] , success, call.arguments['arg']);
        }
        break;

        case "pauseRecorderCompleted":
        {
          aRecorder.pauseRecorderCompleted(call.arguments['state'] , success);
        }
        break;

        case "resumeRecorderCompleted":
        {
          aRecorder.resumeRecorderCompleted(call.arguments['state'] , success);
        }
        break;

        case "openRecorderCompleted":
        {
          aRecorder.openRecorderCompleted(call.arguments['state'], success );
        }
        break;

       case "closeRecorderCompleted":
        {
          aRecorder.closeRecorderCompleted(call.arguments['state'], success );
        }
        break;

    

      default:
        throw ArgumentError('Unknown method ${call.method}');
    }

    return null;
  }



  Future<void> invokeMethodVoid (FlutterSoundRecorderCallback callback,  String methodName, Map<String, dynamic> call)
  {
    call['slotNo'] = findSession(callback);
    return _channel.invokeMethod(methodName, call);
  }


  Future<int> invokeMethodInt (FlutterSoundRecorderCallback callback,  String methodName, Map<String, dynamic> call)
  {
    call['slotNo'] = findSession(callback);
    return _channel.invokeMethod(methodName, call);
  }


  Future<bool> invokeMethodBool (FlutterSoundRecorderCallback callback,  String methodName, Map<String, dynamic> call)
  {
    call['slotNo'] = findSession(callback);
    return _channel.invokeMethod(methodName, call);
  }

  Future<String> invokeMethodString (FlutterSoundRecorderCallback callback, String methodName, Map<String, dynamic> call)
  {
    call['slotNo'] = findSession(callback);
    return _channel.invokeMethod(methodName, call);
  }



  @override
  Future<void>   resetPlugin(FlutterSoundRecorderCallback callback,)
  {
    return _channel.invokeMethod('resetPlugin', );
  }



@override
  Future<void> openRecorder(FlutterSoundRecorderCallback callback, {AudioFocus focus, SessionCategory category, SessionMode mode, int audioFlags, AudioDevice device})
  {
    return invokeMethodVoid( callback, 'openRecorder', {'focus': focus.index, 'category': category.index, 'mode': mode.index, 'audioFlags': audioFlags, 'device': device.index ,},) ;
  }


  @override
  Future<void> closeRecorder(FlutterSoundRecorderCallback callback, )
  {
    return invokeMethodVoid( callback, 'closeRecorder',  Map<String, dynamic>(),);
  }

  @override
  Future<void> setAudioFocus(FlutterSoundRecorderCallback callback, {AudioFocus focus, SessionCategory category, SessionMode mode, int audioFlags, AudioDevice device,} )
  {
    return invokeMethodVoid( callback, 'setAudioFocus', {'focus': focus.index, 'category': category.index, 'mode': mode.index, 'audioFlags': audioFlags, 'device': device.index ,},);
  }

  @override
  Future<bool> isEncoderSupported(FlutterSoundRecorderCallback callback, {Codec codec,})
  {
    return invokeMethodBool( callback, 'isEncoderSupported', {'codec': codec.index,},) as Future<bool>;
  }

  @override
  Future<void> setSubscriptionDuration(FlutterSoundRecorderCallback callback, {Duration duration,})
  {
    return invokeMethodVoid( callback, 'setSubscriptionDuration', {'duration': duration.inMilliseconds},);
  }

  @override
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
    return invokeMethodVoid( callback, 'startRecorder',
        {
                  'path': path,
                  'sampleRate': sampleRate,
                  'numChannels': numChannels,
                  'bitRate': bitRate,
                  'codec': codec.index,
                  'toStream': toStream ? 1 : 0,
                  'audioSource': audioSource.index,
        },);
  }

  @override
  Future<void> stopRecorder(FlutterSoundRecorderCallback callback,  )
  {
    return invokeMethodVoid( callback, 'stopRecorder',  Map<String, dynamic>(),) ;
  }

  @override
  Future<void> pauseRecorder(FlutterSoundRecorderCallback callback,  )
  {
    return invokeMethodVoid( callback, 'pauseRecorder',  Map<String, dynamic>(),) ;
  }

  @override
  Future<void> resumeRecorder(FlutterSoundRecorderCallback callback, )
  {
    return invokeMethodVoid( callback, 'resumeRecorder', Map<String, dynamic>(),) ;
  }


  @override
  Future<bool> deleteRecord(FlutterSoundRecorderCallback callback, String path)
  {
    return invokeMethodBool( callback, 'deleteRecord', {'path': path});
  }

  @override
  Future<String> getRecordURL(FlutterSoundRecorderCallback callback, String path )
  {
    return invokeMethodString( callback, 'getRecordURL', {'path': path});
  }



}