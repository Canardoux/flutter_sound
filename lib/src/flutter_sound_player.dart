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
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:io' show Platform;
import 'dart:typed_data' show Uint8List;
import 'package:synchronized/synchronized.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound/src/session.dart';

enum PlayerState {
  /// Player is stopped
  isStopped,
  /// Player is playing
  isPlaying,
  /// Player is paused
  isPaused,
}

typedef void TWhenFinished();
typedef void TonPaused(bool paused);
typedef void TonSkip();
//typedef void TupdateProgress({position: Duration , duration: Duration});

FlautoPlayerPlugin flautoPlayerPlugin; // Singleton, lazy initialized

class FlautoPlayerPlugin extends FlautoPlugin{

  FlautoPlayerPlugin() {
    setCallback();
  }

  void setCallback() {
    channel = const MethodChannel('com.dooboolab.flutter_sound_player');
    channel.setMethodCallHandler((MethodCall call) {
      // This lambda function is necessary because
      // channelMethodCallHandler is a virtual function (polymorphism)
      return channelMethodCallHandler(call);
    });
  }



  Future<dynamic> channelMethodCallHandler(MethodCall call) {
    FlutterSoundPlayer aPlayer = getSession (call) as FlutterSoundPlayer;
    Map arg = call.arguments as Map;
    if (arg['playerStatus'] != null) {
      aPlayer.playerState = PlayerState.values[arg['playerStatus'] as int ];
    }

    switch (call.method) {
       case "updateProgress":
        {
          aPlayer._updateProgress(arg);
        }
        break;

      case "audioPlayerFinishedPlaying":
        {
          print('FS:---> channelMethodCallHandler : ${call.method}');
          aPlayer.audioPlayerFinished(arg);
          print('FS:<--- channelMethodCallHandler : ${call.method}');
        }
        break;

      case 'pause': // Pause/Resume
        {
          print('FS:---> channelMethodCallHandler : ${call.method}');
          aPlayer.pause(arg);
          print('FS:<--- channelMethodCallHandler : ${call.method}');
        }
        break;

      case 'skipForward':
        {
          print('FS:---> channelMethodCallHandler : ${call.method}');
          aPlayer.skipForward(arg);
          print('FS:<--- channelMethodCallHandler : ${call.method}');
        }
        break;

      case 'skipBackward':
        {
          print('FS:---> channelMethodCallHandler : ${call.method}');
          aPlayer.skipBackward(arg);
          print('FS:<--- channelMethodCallHandler : ${call.method}');
        }
        break;

      case 'updatePlaybackState':
        {
          print('FS:---> channelMethodCallHandler : ${call.method}');
          aPlayer.updatePlaybackState(arg);
          print('FS:<--- channelMethodCallHandler : ${call.method}');
        }
        break;

      case 'openAudioSessionCompleted':
        {
          print('FS:---> channelMethodCallHandler : ${call.method}');
          aPlayer.openSessionCompleted(arg);
          print('FS:<--- channelMethodCallHandler : ${call.method}');
        }
        break;

      case 'startPlayerCompleted':
        {
          print('FS:---> channelMethodCallHandler : ${call.method}');
          aPlayer.startPlayerCompleted(arg);
          print('FS:<--- channelMethodCallHandler : ${call.method}');
        }
        break;


      default:
        throw ArgumentError('Unknown method ${call.method}');
    }
    return null;
  }
}

/// Return the file extension for the given path.
/// path can be null. We return null in this case.
String fileExtension(String path) {
  if (path == null) return null;
  var r = p.extension(path);
  return r;
}
class FlutterSoundPlayer extends Session
{
  TonSkip onSkipForward; // User callback "onPaused:"
  TonSkip onSkipBackward; // User callback "onPaused:"
  TonPaused onPaused; // user callback "whenPause:"
  var lock = new Lock();

  Completer<FlutterSoundPlayer> openAudioSessionCompleter;
  Completer<Duration> startPlayerCompleter;


  static const List<Codec> tabAndroidConvert = [
    Codec.defaultCodec, // defaultCodec
    Codec.defaultCodec, // aacADTS
    Codec.defaultCodec, // opusOGG
    Codec.opusOGG, // opusCAF
    Codec.defaultCodec, // mp3
    Codec.defaultCodec, // vorbisOGG
    Codec.defaultCodec, // pcm16
    Codec.defaultCodec, // pcm16WAV
    Codec.pcm16WAV, // pcm16AIFF
    Codec.pcm16WAV, // pcm16CAF
    Codec.defaultCodec, // flac
    Codec.defaultCodec, // aacMP4
    Codec.defaultCodec, // amrNB
    Codec.defaultCodec, // amrWB
  ];

  static const List<Codec> tabIosConvert = [
    Codec.defaultCodec, // defaultCodec
    Codec.defaultCodec, // aacADTS
    Codec.opusCAF, // opusOGG
    Codec.defaultCodec, // opusCAF
    Codec.defaultCodec, // mp3
    Codec.defaultCodec, // vorbisOGG
    Codec.defaultCodec, // pcm16
    Codec.defaultCodec, // pcm16WAV
    Codec.defaultCodec, // pcm16AIFF
    Codec.defaultCodec, // pcm16CAF
    Codec.defaultCodec, // flac
    Codec.defaultCodec, // aacMP4
    Codec.defaultCodec, // amrNB
    Codec.defaultCodec, // amrWB
  ];

  PlayerState playerState = PlayerState.isStopped;
  // The stream source
  StreamController<PlaybackDisposition> _playerController ;


  Stream<PlaybackDisposition> get onProgress =>
              _playerController != null ? _playerController.stream : null;

  /// Provides a stream of dispositions which
  /// provide updated position and duration
  /// as the audio is played.
  /// The duration may start out as zero until the
  /// media becomes available.
  /// The [interval] dictates the minimum interval between events
  /// being sent to the stream.
  ///
  /// The minimum interval supported is 100ms.
  ///
  /// Note: the underlying stream has a minimum frequency of 100ms
  /// so multiples of 100ms will give you the most consistent timing
  /// source.
  ///
  /// Note: all calls to [dispositionStream] against this player will
  /// share a single interval which will controlled by the last
  /// call to this method.
  ///
  /// If you pause the audio then no updates will be sent to the
  /// stream.
  Stream<PlaybackDisposition> dispositionStream() {
    return _playerController != null ? _playerController.stream : null;
  }

  TWhenFinished audioPlayerFinishedPlaying; // User callback "whenFinished:"
  //TonPaused whenPause; // User callback "whenPaused:"
  //TupdateProgress onUpdateProgress;


  bool get isPlaying => playerState == PlayerState.isPlaying;

  bool get isPaused => playerState == PlayerState.isPaused;

  bool get isStopped => playerState == PlayerState.isStopped;

  FlutterSoundPlayer();

  FlautoPlugin getPlugin() => flautoPlayerPlugin;

    Future<FlutterSoundPlayer> openAudioSession( {
                                                 AudioFocus focus = AudioFocus.requestFocusAndKeepOthers,
                                                 SessionCategory category = SessionCategory.playAndRecord,
                                                 SessionMode mode = SessionMode.modeDefault,
                                                 AudioDevice device = AudioDevice.speaker,
                                                 int audioFlags = outputToSpeaker |  allowBlueToothA2DP  | allowAirPlay}) async {
      print('FS:---> openAudioSession ');
      await lock.synchronized(() async {
        if (isInited == Initialized.fullyInitialized || isInited == Initialized.fullyInitializedWithUI)
        {
          await closeAudioSession( );
        }
        if (isInited == Initialized.initializationInProgress)
        {
          throw (
                      _InitializationInProgress( )
          );
        }

        isInited = Initialized.initializationInProgress;

        if (flautoPlayerPlugin == null)
        {
          flautoPlayerPlugin = FlautoPlayerPlugin( ); // The lazy singleton
        }

        openSession( );
        setPlayerCallback( );

        openAudioSessionCompleter = new Completer<FlutterSoundPlayer>();
        int state = await invokeMethod( 'initializeMediaPlayer', <String, dynamic>{'focus': focus.index, 'category': category.index, 'mode': mode.index, 'audioFlags': audioFlags, 'device': device.index ,}) as int;
        playerState = PlayerState.values[state];

      });

      print('FS:<--- openAudioSession ');
      return openAudioSessionCompleter.future;
  }

  Future<FlutterSoundPlayer> openAudioSessionWithUI( {
                                                       AudioFocus focus = AudioFocus.requestFocusAndKeepOthers,
                                                       SessionCategory category = SessionCategory.playAndRecord,
                                                       SessionMode mode = SessionMode.modeDefault,
                                                       AudioDevice device = AudioDevice.speaker,
                                                       int audioFlags = outputToSpeaker |  allowBlueToothA2DP  | allowAirPlay}) async {
    print('FS:---> openAudioSessionWithUI ');
    await lock.synchronized(() async {
      if (isInited == Initialized.fullyInitializedWithUI || isInited == Initialized.fullyInitialized)
      {
        await closeAudioSession( );
      }
      if (isInited == Initialized.initializationWithUIInProgress ||isInited == Initialized.initializationInProgress )
      {
        throw (
                    _InitializationInProgress( )
        );
      }

      isInited = Initialized.initializationWithUIInProgress;

    if (flautoPlayerPlugin == null) {
      flautoPlayerPlugin = FlautoPlayerPlugin(); // The lazy singleton
    }
      openSession();
      setPlayerCallback();
      openAudioSessionCompleter = new Completer<FlutterSoundPlayer>();

      int state = await invokeMethod( 'initializeMediaPlayerWithUI', <String, dynamic>{'focus': focus.index, 'category': category.index, 'mode': mode.index, 'audioFlags': audioFlags, 'device': device.index, } ) as int;
      playerState = PlayerState.values[state];
     });


    print('FS:<--- openAudioSessionWithUI ');
    return openAudioSessionCompleter.future;
  }



  void openSessionCompleted(Map call) {
    print('FS:---> openSessionCompleted ');
    bool success = call['arg'] as bool;
    isInited = success ? (isInited == Initialized.initializationWithUIInProgress ? Initialized.fullyInitializedWithUI :   Initialized.fullyInitialized) : Initialized.notInitialized;
    openAudioSessionCompleter.complete(success ? this : null);
    //openAudioSessionCompleter = null;
    print('FS:<--- openSessionCompleted ');
  }


  Future<void> setAudioFocus( {
                                AudioFocus focus = AudioFocus.requestFocusAndKeepOthers,
                                SessionCategory category = SessionCategory.playback,
                                SessionMode mode = SessionMode.modeDefault,
                                AudioDevice device = AudioDevice.speaker,
                                int audioFlags = outputToSpeaker | allowBlueTooth | allowBlueToothA2DP | allowEarPiece,
  }) async {

    print('FS:---> setAudioFocus ');
    await lock.synchronized(() async {
      if (isInited == Initialized.initializationInProgress)
      {
        throw (
                    _InitializationInProgress( )
        );
      }
      if (isInited != Initialized.fullyInitializedWithUI && isInited != Initialized.fullyInitialized)
      {
        throw (
                    _notOpen( )
        );
      }

      int state = await invokeMethod( 'setAudioFocus', <String, dynamic>{'focus': focus, 'category': category.index, 'mode': mode.index, 'audioFlags': audioFlags, 'device': device.index,} ) as int;
      playerState = PlayerState.values[state];
    });
    print( 'FS:<--- setAudioFocus ' );
  }



  Future<void> closeAudioSession() async {
    print('FS:---> closeAudioSession ');
    await lock.synchronized(() async {
      if (isInited == Initialized.notInitialized)
      {
        return this;
      }
      // probably better not to throw an exception here
      //if (isInited == Initialized.initializationInProgress) {
      //throw (_InitializationInProgress());
      //}


      isInited = Initialized.initializationInProgress;
      await stop( );

      //_removePlayerCallback(); // playerController is closed by this function
      int state = await invokeMethod( 'releaseMediaPlayer', <String, dynamic>{} ) as int;
      playerState = PlayerState.values[state];
      _removePlayerCallback( );
      super.closeAudioSession( );
      isInited = Initialized.notInitialized;
    });
    print('FS:<--- closeAudioSession ');
  }

  Future<PlayerState> getPlayerState() async
  {
    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (isInited != Initialized.fullyInitializedWithUI && isInited != Initialized.fullyInitialized) {
      throw (_notOpen());
    }
    int state = await invokeMethod('getPlayerState', <String, dynamic>{}) as int;
    playerState = PlayerState.values[state];
    return playerState;
  }


  Future<Map<String, Duration>> getProgress() async
  {
      if (isInited == Initialized.initializationInProgress)
      {
        throw (
                    _InitializationInProgress( )
        );
      }
      if (isInited != Initialized.fullyInitializedWithUI && isInited != Initialized.fullyInitialized)
      {
        throw (
                    _notOpen( )
        );
      }
      Map m = await invokeMethod( 'getProgress', <String, dynamic>{} ) as Map;
      Map <String, Duration> r = { 'duration' : Duration(milliseconds: m['duration'] as int), 'progress': Duration(milliseconds: m['position'] as int) };
      return r;
  }

  void _updateProgress(Map call) {
    int duration = call['duration'] as int;
    int position = call['position'] as int;
    if (duration == 0 || position > 10000) // For debugging
      {
        print(duration);
      }
    if (duration < position)
      {
        print(' Duration = $duration,   Position = $position');
      } 
        _playerController.add(PlaybackDisposition(position: Duration(milliseconds: position), duration: Duration(milliseconds: duration),) );
  }

  void audioPlayerFinished(Map call) async {
    print('FS:---> audioPlayerFinished');
    await lock.synchronized(() async {
        //playerState = PlayerState.isStopped;
        int state = call['arg'] as int;
        assert (state != null);
        playerState = PlayerState.values[state];

        if (audioPlayerFinishedPlaying != null)
           audioPlayerFinishedPlaying( );
    });
    print('FS:<--- audioPlayerFinished');
    }



  Future<void> skipForward(Map call) async {
    print( 'FS:---> skipForward ' );
    await lock.synchronized(() async {
     int state = call['arg'] as int;
      assert (state != null);
      playerState = PlayerState.values[state];
      if (onSkipForward != null)
        onSkipForward( );
    });
    print( 'FS:<--- skipForward ' );
  }

  Future<void> skipBackward(Map call) async {
    print( 'FS:---> skipBackward ' );
    await lock.synchronized(() async {
      int state = call['arg'] as int;
      assert (state != null);
      playerState = PlayerState.values[state];

      if (onSkipBackward != null)
        onSkipBackward( );
     });
    print( 'FS:<--- skipBackward ' );
  }


  Future<void> updatePlaybackState(Map call) async {
    print( 'FS:---> updatePlaybackState ' );
      int state = call['arg'] as int;
      assert (state != null);
      playerState = PlayerState.values[state];
    print( 'FS:<--- updatePlaybackState ' );
  }


  Future<void> pause(Map call)  async {
    print( 'FS:---> pause ' );
    await lock.synchronized(() async {
      int state = call['arg'] as int;
      assert (state != null);
      playerState = PlayerState.values[state];

      bool b = (
                  playerState == PlayerState.isPaused
      );
      if (onPaused != null)
      {
        // Probably always true
        onPaused( !b );
      }
    });
    print('FS:<--- pause ');
  }

  bool needToConvert(Codec codec) {
    print('FS:---> needToConvert ');
    if (codec == null) return false;
    Codec convert = (Platform.isIOS)
        ? tabIosConvert[codec.index]
        : tabAndroidConvert[codec.index];
    print('FS:<--- needToConvert ');
    return (convert != Codec.defaultCodec);
  }

  /// Returns true if the specified decoder is supported by flutter_sound on this platform
  Future<bool> isDecoderSupported(Codec codec) async {
    bool result;
    print('FS:---> isDecoderSupported ');

    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (isInited != Initialized.fullyInitializedWithUI && isInited != Initialized.fullyInitialized) {
      throw (_notOpen());
    }
    // For decoding ogg/opus on ios, we need to support two steps :
    // - remux OGG file format to CAF file format (with ffmpeg)
    // - decode CAF/OPPUS (with native Apple AVFoundation)

    if (needToConvert(codec)) {
      if (!await flutterSoundHelper.isFFmpegAvailable()) return false;
      Codec convert = (Platform.isIOS)
          ? tabIosConvert[codec.index]
          : tabAndroidConvert[codec.index];
      result = await invokeMethod(
              'isDecoderSupported', <String, dynamic>{'codec': convert.index})
          as bool;
    } else {
      result = await invokeMethod(
              'isDecoderSupported', <String, dynamic>{'codec': codec.index})
          as bool;
    }
    print('FS:<--- isDecoderSupported ');
    return result;
  }


  Future<void> setSubscriptionDuration(Duration duration) async {

    print('FS:---> setSubscriptionDuration ');
    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (isInited != Initialized.fullyInitializedWithUI && isInited != Initialized.fullyInitialized) {
      throw (_notOpen());
    }
    int state = await invokeMethod('setSubscriptionDuration', <String, dynamic>{
      'milliSec': duration.inMilliseconds,
    }) as int ;
    playerState = PlayerState.values[state];
    print('FS:<---- setSubscriptionDuration ');
  }

  void setPlayerCallback() {
    if (_playerController == null) {
      _playerController = StreamController<PlaybackDisposition>.broadcast();
    }
  }

  void _removePlayerCallback() {
    if (_playerController != null) {
      _playerController
        //..add(null)
        ..close();
      _playerController = null;
    }
  }

  Future<void> _convertAudio(Map<String, dynamic> what) async {
     // If we want to play OGG/OPUS on iOS, we remux the OGG file format to a specific Apple CAF envelope before starting the player.
    // We use FFmpeg for that task.
    print('FS:---> _convertAudio ');
    var tempDir = await getTemporaryDirectory();
    Codec codec = what['codec'] as Codec;
    Codec convert = (Platform.isIOS)
        ? tabIosConvert[codec.index]
        : tabAndroidConvert[codec.index];
    String fout =
        '${tempDir.path}/$slotNo-flutter_sound-tmp2${ext[convert.index]}';
    String path = what['path'] as String;
    await flutterSoundHelper.convertFile(path, codec, fout, convert);

    // Now we can play Apple CAF/OPUS

    what['path'] = fout;
    what['codec'] = convert;
    print('FS:<--- _convertAudio ');
  }

  Future<void> _convert ( Map<String, dynamic> what) async
  {
    print('FS:---> _convert ');
    Codec codec = what['codec'] as Codec;
    if (needToConvert(codec)) {
      String fromURI = what['path'] as String;
      Uint8List fromDataBuffer = what['fromDataBuffer'] as Uint8List;

      if (fromDataBuffer != null) {
        var tempDir = await getTemporaryDirectory();
        File inputFile = File('${tempDir.path}/$slotNo-flutter_sound-tmp');

        if (inputFile.existsSync()) {
          await inputFile.delete();
        }
        inputFile.writeAsBytesSync(
                    fromDataBuffer); // Write the user buffer into the temporary file
        what['fromDataBuffer'] = null;
        what['path'] = inputFile.path;
      }
      //Map<String, dynamic> what = {'codec': codec, 'path': fromURI, 'fromDataBuffer': fromDataBuffer,} as Map<String, dynamic>;
      await _convertAudio(what);
      //codec = what['codec'] as Codec;
      //fromURI =  what['path'] as String;
      //if (playerState != PlayerState.isPlaying)
        //throw Exception('Player has been stopped');
    }
    print('FS:<--- _convert ');

  }

  Future<Duration> startPlayer(
   {
     String fromURI = null,
     Uint8List fromDataBuffer = null,
     Codec codec = Codec.aacADTS,
     TWhenFinished whenFinished = null,
  }) async {
     print('FS:---> startPlayer ');
     if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (isInited != Initialized.fullyInitializedWithUI && isInited != Initialized.fullyInitialized) {
      throw (_notOpen());
    }


    await lock.synchronized(() async {
        await stop( ); // Just in case

        //playerState = PlayerState.isPlaying;
        Map<String, dynamic> what = {'codec': codec, 'path': fromURI, 'fromDataBuffer': fromDataBuffer,} as Map<String, dynamic>;
        await _convert( what );
        codec = what['codec'] as Codec;
        fromURI = what['path'] as String;
        fromDataBuffer = what['fromDataBuffer'] as Uint8List;
        if (playerState != PlayerState.isStopped)
        {
          throw Exception( 'Player is not stopped' );
        }
        audioPlayerFinishedPlaying = ()
        {
          print('FS: !whenFinished()');
          whenFinished();
        };
        startPlayerCompleter = new Completer<Duration>();
        int state  = (await invokeMethod( 'startPlayer', {'codec': codec.index, 'fromDataBuffer': fromDataBuffer, 'fromURI': fromURI,} as Map<String, dynamic> )) as int;
        playerState = PlayerState.values[state];
   } );
    print('FS:<--- startPlayer ');
    return startPlayerCompleter.future;

  }





  void startPlayerCompleted(Map call) {
    print('FS:---> startPlayerCompleted ');
    int duration =  call['arg'] as int;
    if (startPlayerCompleter != null)
    {
      Duration d = Duration(milliseconds: duration);
      startPlayerCompleter.complete(d);
      //startPlayerCompleter = null;
    }
    print('FS:<--- startPlayerCompleted ');
  }


  Future<Duration> startPlayerFromTrack( Track track,
              {
                TonSkip onSkipForward = null,
                TonSkip onSkipBackward = null,
                TonPaused onPaused = null,
                TWhenFinished whenFinished = null,
                Duration progress = null,
                Duration duration = null,
                bool defaultPauseResume = null,
                bool removeUIWhenStopped = true,
              }) async {

     print('FS:---> startPlayerFromTrack ');
    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (isInited != Initialized.fullyInitializedWithUI ) {
      throw (_notOpen());
    }
    await lock.synchronized(() async {
      try
      {
        await stop( ); // Just in case
        audioPlayerFinishedPlaying = ()
        {
          whenFinished();
        };
        this.onSkipForward = onSkipForward;
        this.onSkipBackward = onSkipBackward;
        this.onPaused = onPaused;
        Map<String, dynamic> trackDico = track.toMap( );
        //playerState = PlayerState.isPlaying;
        Map<String, dynamic> what = {'codec': track.codec, 'path': track.trackPath, 'fromDataBuffer': track.dataBuffer,} as Map<String, dynamic>;
        await _convert( what );
        Codec codec = what['codec'] as Codec;
        trackDico['bufferCodecIndex'] = codec.index;
        trackDico['path'] = what['path'];
        trackDico['dataBuffer'] = what['fromDataBuffer'];
        int d = (
                    duration != null
        ) ? duration.inMilliseconds : null;
        int p = (
                    progress != null
        ) ? progress.inMilliseconds : null;

        if (defaultPauseResume == null)
          defaultPauseResume = (
                      onPaused == null
          );
        if (playerState != PlayerState.isStopped)
        {
          throw Exception( 'Player is not stopped' );
        }
        startPlayerCompleter = new Completer<Duration>();
        int state = await invokeMethod( 'startPlayerFromTrack', <String, dynamic>{
          'progress': p,
          'duration': d,
          'track': trackDico,
          'canPause': (
                      onPaused != null || defaultPauseResume
          ),
          'canSkipForward': (
                      onSkipForward != null
          ),
          'canSkipBackward': (
                      onSkipBackward != null
          ),
          'defaultPauseResume': defaultPauseResume,
          'removeUIWhenStopped': removeUIWhenStopped,
        }) as int;
        playerState = PlayerState.values[state];
      }
      catch (e)
      {
        rethrow;
      }
    });

     print('FS:<--- startPlayerFromTrack ');

     return startPlayerCompleter.future;

  }



  Future<void> nowPlaying( Track track,
              {
                Duration duration,
                Duration progress,
                TonSkip onSkipForward,
                TonSkip onSkipBackward,
                TonPaused onPaused,
                bool defaultPauseResume = null,

              }) async {
    print('FS:---> nowPlaying ');
    await lock.synchronized(() async {
      if (isInited == Initialized.initializationInProgress)
      {
        throw (
                    _InitializationInProgress( )
        );
      }
      if (isInited != Initialized.fullyInitializedWithUI)
      {
        throw (
                    _notOpen( )
        );
      }
      this.onSkipForward = onSkipForward;
      this.onSkipBackward = onSkipBackward;
      this.onPaused = onPaused;

      int d = (
                  duration != null
      ) ? duration.inMilliseconds : null;
      int p = (
                  progress != null
      ) ? progress.inMilliseconds : null;
      Map<String, dynamic> trackDico = (
                  track != null
      ) ? track.toMap( ) : null;
      if (defaultPauseResume == null)
        defaultPauseResume = (
                    onPaused == null
        );
      int state = await invokeMethod( 'nowPlaying', <String, dynamic>{
        'track': trackDico,
        'duration': d,
        'progress': p,
        'canPause': (
                    onPaused != null || defaultPauseResume
        ),
        'canSkipForward': (
                    onSkipForward != null
        ),
        'canSkipBackward': (
                    onSkipBackward != null
        ),
        'defaultPauseResume': defaultPauseResume,
      } ) as int;
      playerState = PlayerState.values[state];
      print( 'FS:<--- nowPlaying ' );
    });
  }

    Future<void> stopPlayer() async {
      print('FS:---> stopPlayer ');
      if (isInited == Initialized.initializationInProgress) {
        throw (_InitializationInProgress());
      }
      if (isInited != Initialized.fullyInitializedWithUI && isInited != Initialized.fullyInitialized) {
        throw (_notOpen());
      }
      //playerState = PlayerState.isStopped;

    // REALLY ? // audioPlayerFinishedPlaying = null;

      //await lock.synchronized(() async {
        try
        {
          //_removePlayerCallback(); // playerController is closed by this function
          await stop( );
        }
        catch (e)
        {
          print( e );
        }
      //});
      print('FS:<--- stopPlayer ');
    }

  Future<void> stop() async {
    print('FS:---> stop ');
    int state = await invokeMethod('stopPlayer', <String, dynamic>{}) as int;

    playerState = PlayerState.values[state];
    if (playerState != PlayerState.isStopped)
    {
      throw Exception( 'Player is not stopped' );
    }

    print('FS:<--- stop ');

  }


  Future<void> _stopPlayerwithCallback() async {
    print('FS:---> _stopPlayerwithCallback ');

    if (audioPlayerFinishedPlaying != null) {
      audioPlayerFinishedPlaying();
      // REALLY ? // audioPlayerFinishedPlaying = null;
    }
    stopPlayer();
    print('FS:<--- _stopPlayerwithCallback ');
  }

  Future<void> pausePlayer() async {
    print('FS:---> pausePlayer ');
    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (isInited != Initialized.fullyInitializedWithUI && isInited != Initialized.fullyInitialized) {
      throw (_notOpen());
    }
    await lock.synchronized(() async {
        playerState = PlayerState.values[await invokeMethod( 'pausePlayer', <String, dynamic>{} ) as int];
        if (playerState != PlayerState.isPaused)
        {
          //await _stopPlayerwithCallback( ); // To recover a clean state
          throw PlayerRunningException( 'Player is not paused.' ); // I am not sure that it is good to throw an exception here
        }
      });
    print('FS:<--- pausePlayer ');
  }

  Future<void> resumePlayer() async {
    print('FS:---> resumePlayer ');
    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (isInited != Initialized.fullyInitializedWithUI && isInited != Initialized.fullyInitialized) {
      throw (_notOpen());
    }
    await lock.synchronized(() async {
         int state = await invokeMethod( 'resumePlayer', <String, dynamic>{} ) as int;
        playerState = PlayerState.values[state];
        if (playerState != PlayerState.isPlaying)
        {
          //await _stopPlayerwithCallback( ); // To recover a clean state
          throw PlayerRunningException( 'Player is not resumed.' ); // I am not sure that it is good to throw an exception here
        }
    });
    print('FS:<--- resumePlayer ');
  }

  Future<void> seekToPlayer(Duration duration) async {

    print('FS:---> seekToPlayer ');
    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (isInited != Initialized.fullyInitializedWithUI && isInited != Initialized.fullyInitialized) {
      throw (_notOpen());
    }
    await lock.synchronized(() async {
        int state = await invokeMethod( 'seekToPlayer', <String, dynamic>{
          'duration': duration.inMilliseconds,
        } ) as int;
        playerState = PlayerState.values[state];
    });
    print('FS:<--- seekToPlayer ');
  }

  Future<void> setVolume(double volume) async {

    print('FS:---> setVolume ');
    await lock.synchronized(() async {
      if (isInited == Initialized.initializationInProgress)
      {
        throw (
                    _InitializationInProgress( )
        );
      }
      if (isInited != Initialized.fullyInitializedWithUI && isInited != Initialized.fullyInitialized)
      {
        throw (
                    _notOpen( )
        );
      }
      var indexedVolume = Platform.isIOS ? volume * 100 : volume;
      if (volume < 0.0 || volume > 1.0)
      {
        throw RangeError( 'Value of volume should be between 0.0 and 1.0.' );
      }

      int state = await invokeMethod( 'setVolume', <String, dynamic>{
        'volume': indexedVolume,
      } ) as int;
      playerState = PlayerState.values[state];
    });
    print('FS:<--- setVolume ');
  }

  Future<void> setUIProgressBar ( {
                                    Duration duration,
                                    Duration progress,
                                  }) async {
    int int_duration =  duration.inMilliseconds;
    int int_progress =  progress.inMilliseconds;
    print('FS:---> setUIProgressBar : duration=$int_duration  progress=$int_progress');
    await lock.synchronized(() async {
      int state = await invokeMethod( 'setUIProgressBar', <String, dynamic>{'duration': int_duration, 'progress': int_progress} ) as int;
      playerState = PlayerState.values[state];
    });
      print('FS:<--- setUIProgressBar ');
  }


  Future<String> getResourcePath() async {
    if (Platform.isIOS) {
      String s =
          await invokeMethod('getResourcePath', <String, dynamic>{}) as String;
      return s;
    } else
      return (await getApplicationDocumentsDirectory()).path;
  }
}

/// Used to stream data about the position of the
/// playback as playback proceeds.
class PlaybackDisposition {
  /// The duration of the media.
  final Duration duration;

  /// The current position within the media
  /// that we are playing.
  final Duration position;

  /// A convenience ctor. If you are using a stream builder
  /// you can use this to set initialData with both duration
  /// and postion as 0.
  PlaybackDisposition.zero()
              : position = Duration(seconds: 0),
                duration = Duration(seconds: 0);

  ///
  //PlaybackDisposition(this.position, this.duration);

  ///
  PlaybackDisposition(
               {
                this.position = Duration.zero,
                this.duration = Duration.zero,
              });



  @override
  String toString() {
    return 'duration: $duration, '
                'position: $position';
  }
}


class PlayerRunningException implements Exception {
  final String message;

  PlayerRunningException(this.message);
}

class _InitializationInProgress implements Exception {
  _InitializationInProgress() {
    print('An initialization of this audio session is currently already in progress.');
  }
}

class _notOpen implements Exception {
  _notOpen() {
    print('Audio session is not open');
  }
}


/// The track to play in the audio player
class Track {
  /// The title of this track
   String trackTitle;

  /// The buffer containing the audio file to play
  Uint8List dataBuffer;

  /// The name of the author of this track
   String trackAuthor;

  /// The path that points to the track audio file
  String trackPath;

  /// The URL that points to the album art of the track
   String albumArtUrl;

  /// The asset that points to the album art of the track
   String albumArtAsset;

  /// The file that points to the album art of the track
   String albumArtFile;

  /// The image that points to the album art of the track
  //final String albumArtImage;

  /// The codec of the audio file to play. If this parameter's value is null
  /// it will be set to [t_CODEC.DEFAULT].
  Codec codec;

  Track({
          this.trackPath,
          this.dataBuffer,
          this.trackTitle,
          this.trackAuthor,
          this.albumArtUrl,
          this.albumArtAsset,
          this.albumArtFile,
          this.codec = Codec.defaultCodec,
        }) {
    //codec = codec == null ? Codec.defaultCodec : codec;
    //assert(trackPath != null || dataBuffer != null,
    //'You should provide a path or a buffer for the audio content to play.');
    assert(
    (! (trackPath != null && dataBuffer != null) ),
    'You cannot provide both a path and a buffer.');
  }

  /// Convert this object to a [Map] containing the properties of this object
  /// as values.
  Map<String, dynamic> toMap() {
    final map = {
      "path": trackPath,
      "dataBuffer": dataBuffer,
      "title": trackTitle,
      "author": trackAuthor,
      "albumArtUrl": albumArtUrl,
      "albumArtAsset": albumArtAsset,
      "albumArtFile": albumArtFile,
      "bufferCodecIndex": codec?.index,
    };

    return map;
  }
}
