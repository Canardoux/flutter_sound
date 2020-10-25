@JS()
library flutter_sound;

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data' show Uint8List;

import 'package:meta/meta.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_platform_interface.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_player_platform_interface.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:js/js.dart';

@JS('playAudioFromBuffer3')
external playAudioFromBuffer3(Uint8List buffer);

//@JS('playAudioFromURL')
//external playAudioFromURL(String url);

@JS('newInstance')
external Toto newInstance();

@JS('v')
class Toto
{
        //@JS('constructor')
        /* ctor */ //external Toto();
        @JS('newInstance')
        external static Toto newInstance();
        @JS('playAudioFromURL')
        external void playAudioFromURL(String text);
        @JS('playAudioFromBuffer')
        external void playAudioFromBuffer(Uint8List buffer);

}

/// The web implementation of [FlutterSoundPlatform].
///
/// This class implements the `package:flutter_sound_player` functionality for the web.
///

class FlutterSoundPlayerWeb extends FlutterSoundPlayerPlatform
{


        static List<String> defaultExtensions  =
        [
                "flutter_sound.aac", // defaultCodec
                "flutter_sound.aac", // aacADTS
                "flutter_sound.opus", // opusOGG
                "flutter_sound_opus.caf", // opusCAF
                "flutter_sound.mp3", // mp3
                "flutter_sound.ogg", // vorbisOGG
                "flutter_sound.pcm", // pcm16
                "flutter_sound.wav", // pcm16WAV
                "flutter_sound.aiff", // pcm16AIFF
                "flutter_sound_pcm.caf", // pcm16CAF
                "flutter_sound.flac", // flac
                "flutter_sound.mp4", // aacMP4
                "flutter_sound.amr", // amrNB
                "flutter_sound.amr", // amrWB
                "flutter_sound.pcm", // pcm8
                "flutter_sound.pcm", // pcmFloat32
        ];


        List<FlutterSoundPlayerCallback> _slots = [];

        /// Registers this class as the default instance of [FlutterSoundPlatform].
        static void registerWith(Registrar registrar)
        {
                FlutterSoundPlayerPlatform.instance = FlutterSoundPlayerWeb();
        }


        // /* ctor */ MethodChannelFlutterSoundPlayer()
        // {
        //         setCallback();
        // }
        //
        // void setCallback()
        // {
        //         //_channel = const MethodChannel('com.dooboolab.flutter_sound_player');
        //         // _channel.setMethodCallHandler((MethodCall call)
        //         // {
        //         //         return channelMethodCallHandler(call);
        //         // });
        // }



        // Future<dynamic> channelMethodCallHandler(MethodCall call)
        // {
        //         // FlutterSoundPlayerCallback aPlayer = _slots[call.arguments['slotNo'] as int];
                // Map arg = call.arguments ;
                //
                // switch (call.method)
                // {
                //           case "updateProgress":
                //           {
                //                   aPlayer.updateProgress(duration: Duration(milliseconds: arg['duration']), position: Duration(milliseconds: arg['position']));
                //           }
                //           break;
                //
                //           case "audioPlayerFinishedPlaying":
                //           {
                //                   print('FS:---> channelMethodCallHandler : ${call.method}');
                //                   aPlayer.audioPlayerFinished(arg['arg']);
                //                   print('FS:<--- channelMethodCallHandler : ${call.method}');
                //           }
                //           break;
                //
                //           case 'pause': // Pause/Resume
                //           {
                //                   print('FS:---> channelMethodCallHandler : ${call.method}');
                //                   aPlayer.pause(arg['arg']);
                //                   print('FS:<--- channelMethodCallHandler : ${call.method}');
                //           }
                //           break;
                //
                //           case 'resume': // Pause/Resume
                //           {
                //                   print('FS:---> channelMethodCallHandler : ${call.method}');
                //                   aPlayer.resume(arg['arg']);
                //                   print('FS:<--- channelMethodCallHandler : ${call.method}');
                //           }
                //           break;
                //
                //
                //           case 'skipForward':
                //           {
                //                   print('FS:---> channelMethodCallHandler : ${call.method}');
                //                   aPlayer.skipForward(arg['arg']);
                //                   print('FS:<--- channelMethodCallHandler : ${call.method}');
                //           }
                //           break;
                //
                //           case 'skipBackward':
                //           {
                //                   print('FS:---> channelMethodCallHandler : ${call.method}');
                //                   aPlayer.skipBackward(arg['arg']);
                //                   print('FS:<--- channelMethodCallHandler : ${call.method}');
                //                 }
                //           break;
                //
                //         case 'updatePlaybackState':
                //           {
                //                   print('FS:---> channelMethodCallHandler : ${call.method}');
                //                   aPlayer.updatePlaybackState(arg['arg']);
                //                   print('FS:<--- channelMethodCallHandler : ${call.method}');
                //                 }
                //           break;
                //
                //         case 'openAudioSessionCompleted':
                //           {
                //                   print('FS:---> channelMethodCallHandler : ${call.method}');
                //                   bool success = arg['arg'] as bool;
                //                   openAudioSessionCompleter.complete(success );
                //                   print('FS:<--- channelMethodCallHandler : ${call.method}');
                //                 }
                //           break;
                //
                //         case 'startPlayerCompleted':
                //           {
                //                   print('FS:---> channelMethodCallHandler : ${call.method}');
                //                   //int duration =  arg['duration'] as int;
                //                   //Duration d = Duration(milliseconds: duration);
                //                   startPlayerCompleter.complete(arg ) ;
                //                   print('FS:<--- channelMethodCallHandler : ${call.method}');
                //                 }
                //           break;
                //
                //         case 'needSomeFood':
                //           {
                //                   aPlayer.needSomeFood(arg['arg']);
                //           }
                //           break;
                //
                //
                //         default:
                //                   throw ArgumentError('Unknown method ${call.method}');
                //       }

                //       return null;
                // }


//===============================================================================================================================


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

        @override
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

        @override
        void closeSession(FlutterSoundPlayerCallback aSession)
        {
                _slots[findSession(aSession)] = null;
        }

        @override
        Future<bool> initializeMediaPlayer(FlutterSoundPlayerCallback callback, {AudioFocus focus, SessionCategory category, SessionMode mode, int audioFlags, AudioDevice device, bool withUI}) async
        {
                // openAudioSessionCompleter = new Completer<bool>();
                // await invokeMethod( callback, 'initializeMediaPlayer', {'focus': focus.index, 'category': category.index, 'mode': mode.index, 'audioFlags': audioFlags, 'device': device.index, 'withUI': withUI ? 1 : 0 ,},) ;
                // return  openAudioSessionCompleter.future ;
                return true;
        }

        @override
        Future<int> setAudioFocus(FlutterSoundPlayerCallback callback, {AudioFocus focus, SessionCategory category, SessionMode mode, int audioFlags, AudioDevice device,} ) async
        {
                // return invokeMethod( callback, 'setAudioFocus', {'focus': focus.index, 'category': category.index, 'mode': mode.index, 'audioFlags': audioFlags, 'device': device.index ,},);
                return 0;
        }

        @override
        Future<int> releaseMediaPlayer(FlutterSoundPlayerCallback callback, ) async
        {
                // return invokeMethod( callback, 'releaseMediaPlayer',  Map<String, dynamic>(),);
                return 0;
        }

        @override
        Future<int> getPlayerState(FlutterSoundPlayerCallback callback, ) async
        {
                // return invokeMethod( callback, 'getPlayerState',  Map<String, dynamic>(),);
                return 0;
        }
        @override
        Future<Map<String, Duration>> getProgress(FlutterSoundPlayerCallback callback, ) async
        {
                // Map<String, int> m = await invokeMethod( callback, 'getPlayerState', null,) as Map;
                // Map<String, Duration> r = {'duration': Duration(milliseconds: m['duration']), 'progress': Duration(milliseconds: m['progress']),};
                // return r;
                return null;
        }

        @override
        Future<bool> isDecoderSupported(FlutterSoundPlayerCallback callback, { Codec codec,}) async
        {
                // return invokeMethodBool( callback, 'isDecoderSupported', {'codec': codec.index,},) as Future<bool>;
                return true;
        }


        @override
        Future<int> setSubscriptionDuration(FlutterSoundPlayerCallback callback, { Duration duration,}) async
        {
                //return invokeMethod( callback, 'setSubscriptionDuration', {'duration': duration.inMilliseconds},);
                return 0;
        }

        @override
        Future<Map> startPlayer(FlutterSoundPlayerCallback callback,  {Codec codec, Uint8List fromDataBuffer, String  fromURI, int numChannels, int sampleRate}) async
        {
                // startPlayerCompleter = new Completer<Map>();
                // await invokeMethod( callback, 'startPlayer', {'codec': codec.index, 'fromDataBuffer': fromDataBuffer, 'fromURI': fromURI, 'numChannels': numChannels, 'sampleRate': sampleRate},) ;
                // return  startPlayerCompleter.future ;
                // String s = "https://file-examples-com.github.io/uploads/2017/11/file_example_MP3_700KB.mp3";
                if (codec == null)
                        codec = Codec.defaultCodec;
                if (fromDataBuffer != null)
                {
                        if (fromURI != null)
                        {
                                throw Exception("You may not specify both 'fromURI' and 'fromDataBuffer' parameters");
                        }
                        //js.context.callMethod('playAudioFromBuffer', [fromDataBuffer]);
                        //playAudioFromBuffer(fromDataBuffer);
                        Toto toto = Toto.newInstance();
                        toto.playAudioFromBuffer(fromDataBuffer);
                        //playAudioFromBuffer3(fromDataBuffer);
                        return null;
                        //Directory tempDir = await getTemporaryDirectory();
                        /*
                        String path = defaultExtensions[codec.index];
                        File filOut = File(path);
                        IOSink sink = filOut.openWrite();
                        sink.add(fromDataBuffer.toList());
                        fromURI = path;
                         */
                }
                //js.context.callMethod('playAudioFromURL', [fromURI]);
                newInstance().playAudioFromURL(fromURI);
                Map<String, dynamic> r = new Map<String, dynamic>();
                r['duration'] = 0;
                r['state'] = 1;
                return r;
        }

        @override
        Future<int> feed(FlutterSoundPlayerCallback callback, {Uint8List data, }) async
        {
                // return invokeMethod( callback, 'feed', {'data': data, },) ;
                return 0;
        }

        @override
        Future<Map> startPlayerFromTrack(FlutterSoundPlayerCallback callback, {Duration progress, Duration duration, Map<String, dynamic> track, bool canPause, bool canSkipForward, bool canSkipBackward, bool defaultPauseResume, bool removeUIWhenStopped }) async
        {
                // startPlayerCompleter = new Completer<Map>();
                // await invokeMethod( callback, 'startPlayerFromTrack', {'progress': progress, 'duration': duration, 'track': track, 'canPause': canPause, 'canSkipForward': canSkipForward, 'canSkipBackward': canSkipBackward,
                //   'defaultPauseResume': defaultPauseResume, 'removeUIWhenStopped': removeUIWhenStopped,},);
                // return  startPlayerCompleter.future ;
                //
                return null;
          }

        @override
        Future<int> nowPlaying(FlutterSoundPlayerCallback callback,  {Duration progress, Duration duration, Map<String, dynamic> track, bool canPause, bool canSkipForward, bool canSkipBackward, bool defaultPauseResume, }) async
        {
              //   return invokeMethod( callback, 'nowPlaying', {'progress': progress.inMilliseconds, 'duration': duration.inMilliseconds, 'track': track, 'canPause': canPause, 'canSkipForward': canSkipForward, 'canSkipBackward': canSkipBackward,
              //     'defaultPauseResume': defaultPauseResume,},);
              //
                return 0;
        }

        @override
        Future<int> stopPlayer(FlutterSoundPlayerCallback callback,  ) async
        {
                // return invokeMethod( callback, 'stopPlayer',  Map<String, dynamic>(),) ;
                return 0;
        }

        @override
        Future<int> pausePlayer(FlutterSoundPlayerCallback callback,  ) async
        {
                // return invokeMethod( callback, 'pausePlayer',  Map<String, dynamic>(),) ;
                return 0;
        }

        @override
        Future<int> resumePlayer(FlutterSoundPlayerCallback callback,  ) async
        {
                // return invokeMethod( callback, 'resumePlayer',  Map<String, dynamic>(),) ;
                return 0;
        }

        @override
        Future<int> seekToPlayer(FlutterSoundPlayerCallback callback,  {Duration duration}) async
        {
                // return invokeMethod( callback, 'seekToPlayer', {'duration': duration.inMilliseconds,},) ;
                return 0;
        }

        Future<int> setVolume(FlutterSoundPlayerCallback callback,  {double volume}) async
        {
                // return invokeMethod( callback, 'setVolume', {'volume': volume,}) ;
                return 0;
        }

        @override
        Future<int> setUIProgressBar(FlutterSoundPlayerCallback callback, {Duration duration, Duration progress,}) async
        {
                // return invokeMethod( callback, 'setUIProgressBar', {'duration': duration.inMilliseconds, 'progress': progress,}) ;
                return 0;
        }

        Future<String> getResourcePath(FlutterSoundPlayerCallback callback, ) async
        {
                // return invokeMethodString( callback, 'getResourcePath',  Map<String, dynamic>(),) ;
                return null;
        }

 }
