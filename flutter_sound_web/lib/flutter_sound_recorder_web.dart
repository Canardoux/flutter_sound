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

@JS()
library flutter_sound;

import 'dart:async';
import 'dart:html' as html;

import 'package:meta/meta.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_platform_interface.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_recorder_platform_interface.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'dart:typed_data';

import 'package:js/js.dart';

//========================================  JS  ===============================================================

@JS('newRecorderInstance')
external FlutterSoundRecorder newRecorderInstance(FlutterSoundRecorderCallback callback);

@JS('FlutterSoundRecorder')
class FlutterSoundRecorder
{
        @JS('newInstance')
        external static FlutterSoundRecorder newInstance(FlutterSoundRecorderCallback callback);

        @JS('startRecorder')
        external void startRecorder();

        @JS('releaseMediaPlayer')
        external void releaseMediaPlayer();

}

//============================================================================================================================

/// The web implementation of [FlutterSoundRecorderPlatform].
///
/// This class implements the `package:FlutterSoundPlayerPlatform` functionality for the web.
class FlutterSoundRecorderWeb extends FlutterSoundRecorderPlatform //implements FlutterSoundRecorderCallback
{

        /// Registers this class as the default instance of [FlutterSoundRecorderPlatform].
        static void registerWith(Registrar registrar)
        {
                FlutterSoundRecorderPlatform.instance = FlutterSoundRecorderWeb();
        }



//============================================ Session manager ===================================================================


        List<FlutterSoundRecorder> _slots = [];
/*
        int findWebSession(FlutterSoundRecorder aSession)
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

        void openWebSession(FlutterSoundRecorder aSession)
        {
                assert(findWebSession(aSession) == -1);

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

        void closeWebSession(FlutterSoundRecorder aSession)
        {
                _slots[findWebSession(aSession)] = null;
        }
*/
        FlutterSoundRecorder getWebSession(FlutterSoundRecorderCallback callback)
        {
                return _slots[findSession(callback)];
        }


//=======================================================  Callback  ==============================================================
/*
        @override
        void updateRecorderProgress({Duration duration, double dbPeakLevel})
        {

        }

        @override
        void recordingData({Uint8List data} )
        {

        }
*/

//================================================================================================================


        //
        // /*ctor */ MethodChannelFlutterSoundRecorder()
        // {
        //         _setCallback();
        // }
        //
        // void _setCallback()
        // {
        // }
        //

        // Future<dynamic> channelMethodCallHandler(MethodCall call) {
                // FlutterSoundRecorderCallback aRecorder = _slots[call.arguments['slotNo'] as int];
                //
                // switch (call.method) {
                //         case "updateRecorderProgress":
                //                 {
                //                         aRecorder.updateRecorderProgress(duration: Duration(milliseconds: call.arguments ['duration']), dbPeakLevel: call.arguments['dbPeakLevel']);
                //                 }
                //                 break;
                //
                //         case "recordingData":
                //                 {
                //                         aRecorder.recordingData(data: call.arguments['recordingData'] );
                //                 }
                //                 break;
                //
                //         default:
                //                 throw ArgumentError('Unknown method ${call.method}');
                // }
                //
        //         return null;
        // }


        @override
        Future<void> initializeFlautoRecorder(FlutterSoundRecorderCallback callback, {AudioFocus focus, SessionCategory category, SessionMode mode, int audioFlags, AudioDevice device}) async
        {
                int slotno = findSession(callback);
                if (slotno < _slots.length)
                {
                        assert (_slots[slotno] == null);
                        _slots[slotno] = newRecorderInstance(callback);
                } else
                {
                        assert(slotno == _slots.length);
                        _slots.add( newRecorderInstance(callback));
                }
                return true;
                // return invokeMethodVoid( callback, 'initializeFlautoRecorder', {'focus': focus.index, 'category': category.index, 'mode': mode.index, 'audioFlags': audioFlags, 'device': device.index ,},) ;
        }


        @override
        Future<void> releaseFlautoRecorder(FlutterSoundRecorderCallback callback, ) async
        {
                int slotno = findSession(callback);
                _slots[slotno].releaseMediaPlayer();
                _slots[slotno] = null;
                // return invokeMethodVoid( callback, 'releaseFlautoRecorder',  Map<String, dynamic>(),);
        }

        @override
        Future<void> setAudioFocus(FlutterSoundRecorderCallback callback, {AudioFocus focus, SessionCategory category, SessionMode mode, int audioFlags, AudioDevice device,} ) async
        {
                // return invokeMethodVoid( callback, 'setAudioFocus', {'focus': focus.index, 'category': category.index, 'mode': mode.index, 'audioFlags': audioFlags, 'device': device.index ,},);
        }

        @override
        Future<bool> isEncoderSupported(FlutterSoundRecorderCallback callback, {Codec codec,}) async
        {
                // return invokeMethodBool( callback, 'isEncoderSupported', {'codec': codec.index,},) as Future<bool>;
                return true;
        }

        @override
        Future<void> setSubscriptionDuration(FlutterSoundRecorderCallback callback, {Duration duration,}) async
        {
                // return invokeMethodVoid( callback, 'setSubscriptionDuration', {'duration': duration.inMilliseconds},);
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
            }) async
        {
                // return invokeMethodVoid( callback, 'startRecorder',
                //         {
                //                 'path': path,
                //                 'sampleRate': sampleRate,
                //                 'numChannels': numChannels,
                //                 'bitRate': bitRate,
                //                 'codec': codec.index,
                //                 'toStream': toStream ? 1 : 0,
                //                 'audioSource': audioSource.index,
                //         },);
                newRecorderInstance(null).startRecorder();
        }

        @override
        Future<void> stopRecorder(FlutterSoundRecorderCallback callback,  ) async
        {
                // return invokeMethodVoid( callback, 'stopRecorder',  Map<String, dynamic>(),) ;
        }

        @override
        Future<void> pauseRecorder(FlutterSoundRecorderCallback callback,  ) async
        {
                // return invokeMethodVoid( callback, 'pauseRecorder',  Map<String, dynamic>(),) ;
        }

        @override
        Future<void> resumeRecorder(FlutterSoundRecorderCallback callback, ) async
        {
                // return invokeMethodVoid( callback, 'resumeRecorder', Map<String, dynamic>(),) ;
        }

}
