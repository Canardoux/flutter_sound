@JS()
library toto;
import 'dart:async';
import 'dart:html' as html;

import 'package:meta/meta.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_platform_interface.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_recorder_platform_interface.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:js/js.dart';

@JS('startRecorder')
external startJSRecorder();


/// The web implementation of [FlutterSoundRecorderPlatform].
///
/// This class implements the `package:FlutterSoundPlayerPlatform` functionality for the web.
class FlutterSoundRecorderWeb extends FlutterSoundRecorderPlatform
{
        List<FlutterSoundRecorderCallback> _slots = [];

        /// Registers this class as the default instance of [FlutterSoundRecorderPlatform].
        static void registerWith(Registrar registrar)
        {
                FlutterSoundRecorderPlatform.instance = FlutterSoundRecorderWeb();
        }

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


        @override
        Future<void> initializeFlautoRecorder(FlutterSoundRecorderCallback callback, {AudioFocus focus, SessionCategory category, SessionMode mode, int audioFlags, AudioDevice device}) async
        {
                // return invokeMethodVoid( callback, 'initializeFlautoRecorder', {'focus': focus.index, 'category': category.index, 'mode': mode.index, 'audioFlags': audioFlags, 'device': device.index ,},) ;
        }


        @override
        Future<void> releaseFlautoRecorder(FlutterSoundRecorderCallback callback, ) async
        {
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
                startJSRecorder();
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
