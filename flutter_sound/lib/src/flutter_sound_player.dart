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
import 'package:flutter_sound_platform_interface/flutter_sound_platform_interface.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_player_platform_interface.dart';
//export 'package:flutter_sound_platform_interface/flutter_sound_recorder_platform_interface.dart';

import 'package:flutter_sound_lite/src/food.dart';


import 'package:flutter/services.dart';
import 'package:flutter_sound_lite/flutter_sound.dart';

const BLOCK_SIZE = 4096;

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


/// Return the file extension for the given path.
/// path can be null. We return null in this case.
String fileExtension(String path) {
  if (path == null) return null;
  var r = p.extension(path);
  return r;
}

//--------------------------------------------------------------------------------------------------------------------------------------------

class FlutterSoundPlayer implements FlutterSoundPlayerCallback
{
  TonSkip onSkipForward; // User callback "onPaused:"
  TonSkip onSkipBackward; // User callback "onPaused:"
  TonPaused onPaused; // user callback "whenPause:"
  var lock = new Lock();
  StreamSubscription<Food> foodStreamSubscription ;
  StreamController <Food> foodStreamController;

  Completer<int> needSomeFoodCompleter;


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

  Initialized isInited = Initialized.notInitialized;

  PlayerState playerState = PlayerState.isStopped;
  // The stream source
  StreamController<PlaybackDisposition> _playerController ;

  StreamSink<Food> get foodSink => foodStreamController != null ? foodStreamController.sink : null;

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

    Future<FlutterSoundPlayer> openAudioSession( {
                                                 AudioFocus focus = AudioFocus.requestFocusAndKeepOthers,
                                                 SessionCategory category = SessionCategory.playAndRecord,
                                                 SessionMode mode = SessionMode.modeDefault,
                                                 AudioDevice device = AudioDevice.speaker,
                                                 int audioFlags = outputToSpeaker |  allowBlueToothA2DP  | allowAirPlay,
                                                 bool withUI = false,
                                              }) async
    {
      print('FS:---> openAudioSession ');
      await lock.synchronized(() async {
        if (isInited == Initialized.fullyInitialized )
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

        FlutterSoundPlayerPlatform.instance.openSession( this);
        setPlayerCallback( );
        bool success = await FlutterSoundPlayerPlatform.instance.initializeMediaPlayer(this, focus: focus, category: category, mode: mode, audioFlags: audioFlags, device: device, withUI: withUI );
        isInited = success ?  Initialized.fullyInitialized : Initialized.notInitialized;

      });

      print('FS:<--- openAudioSession ');
      return this;
    }

  @deprecated
  Future<FlutterSoundPlayer> openAudioSessionWithUI( {
                                                       AudioFocus focus = AudioFocus.requestFocusAndKeepOthers,
                                                       SessionCategory category = SessionCategory.playAndRecord,
                                                       SessionMode mode = SessionMode.modeDefault,
                                                       AudioDevice device = AudioDevice.speaker,
                                                       int audioFlags = outputToSpeaker |  allowBlueToothA2DP  | allowAirPlay})  {

    return openAudioSession(focus: focus, category: category, mode: mode, device: device, withUI: true) ;
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
      if ( isInited != Initialized.fullyInitialized)
      {
        throw (
                    _notOpen( )
        );
      }

      int state = await FlutterSoundPlayerPlatform.instance.setAudioFocus(this, focus: focus, category: category, mode: mode, audioFlags: audioFlags, device: device, ) ;
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
      int state = await FlutterSoundPlayerPlatform.instance.releaseMediaPlayer( this ) ;
      playerState = PlayerState.values[state];
      _removePlayerCallback( );
      FlutterSoundPlayerPlatform.instance.closeSession( this);
      isInited = Initialized.notInitialized;
    });
    print('FS:<--- closeAudioSession ');
  }

  Future<PlayerState> getPlayerState() async
  {
    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if ( isInited != Initialized.fullyInitialized) {
      throw (_notOpen());
    }
    int state = await FlutterSoundPlayerPlatform.instance.getPlayerState(this);
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
      if (isInited != Initialized.fullyInitialized)
      {
        throw (
                    _notOpen( )
        );
      }

      return FlutterSoundPlayerPlatform.instance.getProgress(this);
  }

  @override
  void updateProgress({Duration duration, Duration position,})
  {
    if (duration < position)
      {
        print(' Duration = $duration,   Position = $position');
      } 
      _playerController.add(PlaybackDisposition(position: position, duration: duration,), );
  }

  @override
  void audioPlayerFinished(int state) async {
    print('FS:---> audioPlayerFinished');
    await lock.synchronized(() async {
        //playerState = PlayerState.isStopped;
        //int state = call['arg'] as int;
        assert (state != null);
        playerState = PlayerState.values[state];

        if (audioPlayerFinishedPlaying != null)
           audioPlayerFinishedPlaying( );
    });
    print('FS:<--- audioPlayerFinished');
    }


  @override
  void skipForward(int state) async {
    print( 'FS:---> skipForward ' );
    await lock.synchronized(() async {
      assert (state != null);
      playerState = PlayerState.values[state];
      if (onSkipForward != null)
        onSkipForward( );
    });
    print( 'FS:<--- skipForward ' );
  }

  @override
  void skipBackward(int state) async {
    print( 'FS:---> skipBackward ' );
    await lock.synchronized(() async {
      assert (state != null);
      playerState = PlayerState.values[state];

      if (onSkipBackward != null)
        onSkipBackward( );
     });
    print( 'FS:<--- skipBackward ' );
  }


  @override
  void updatePlaybackState(int state) async {
    print( 'FS:---> updatePlaybackState ' );
      assert (state != null);
      playerState = PlayerState.values[state];
    print( 'FS:<--- updatePlaybackState ' );
  }


  @override
  void pause(int state)  async {
    print( 'FS:---> pause ' );
    await lock.synchronized(() async {
      assert (state != null);
      playerState = PlayerState.values[state];
      if (onPaused != null) // Probably always true
      {
        onPaused( true );
      }
    });
    print('FS:<--- pause ');
  }


  @override
  void resume(int state)  async {
    print( 'FS:---> pause ' );
    await lock.synchronized(() async {
      assert (state != null);
      playerState = PlayerState.values[state];
      if (onPaused != null) // Probably always true
      {
        onPaused( false );
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
    if (isInited != Initialized.fullyInitialized) {
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
      result = await FlutterSoundPlayerPlatform.instance.isDecoderSupported(this, codec: convert);
    } else {
      result = await FlutterSoundPlayerPlatform.instance.isDecoderSupported(this, codec: codec);
    }
    print('FS:<--- isDecoderSupported ');
    return result;
  }


  Future<void> setSubscriptionDuration(Duration duration) async {

    print('FS:---> setSubscriptionDuration ');
    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (isInited != Initialized.fullyInitialized) {
      throw (_notOpen());
    }
    int state = await FlutterSoundPlayerPlatform.instance.setSubscriptionDuration(this, duration: duration);
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
        '${tempDir.path}/flutter_sound-tmp2${ext[convert.index]}';
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
        File inputFile = File('${tempDir.path}/flutter_sound-tmp');

        if (inputFile.existsSync()) {
          await inputFile.delete();
        }
        inputFile.writeAsBytesSync(
                    fromDataBuffer); // Write the user buffer into the temporary file
        what['fromDataBuffer'] = null;
        what['path'] = inputFile.path;
      }
      await _convertAudio(what);
    }
    print('FS:<--- _convert ');

  }

  Future<Duration> startPlayer(
   {
     String fromURI = null,
     Uint8List fromDataBuffer = null,
     Codec codec = Codec.aacADTS,
     int sampleRate = 16000, // Used only with codec == Codec.pcm16
     int numChannels = 1, // Used only with codec == Codec.pcm16
     TWhenFinished whenFinished = null,
  }) async {
     print('FS:---> startPlayer ');
     if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (isInited != Initialized.fullyInitialized) {
      throw (_notOpen());
    }

     if (codec == Codec.pcm16 && fromURI != null) {
       Directory tempDir = await getTemporaryDirectory();
       String path =
           '${tempDir.path}/flutter_sound_tmp.wav';
       await flutterSoundHelper.pcmToWave(
         inputFile: fromURI,
         outputFile: path,
         numChannels: 1,
         //bitsPerSample: 16,
         sampleRate: sampleRate,
       );
       fromURI = path;
       codec = Codec.pcm16WAV;
     } else
     if (codec == Codec.pcm16 && fromDataBuffer != null) {
       fromDataBuffer = await flutterSoundHelper.pcmToWaveBuffer(inputBuffer: fromDataBuffer, sampleRate: sampleRate, numChannels: numChannels);
       codec = Codec.pcm16WAV;
     }

     Map retMap;
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
        retMap  = await FlutterSoundPlayerPlatform.instance.startPlayer(this, codec: codec, fromDataBuffer: fromDataBuffer, fromURI: fromURI,) ;
   } );
     Duration duration = Duration(milliseconds: retMap['duration'] as int);
     int state = retMap['state'] as int;
     playerState = PlayerState.values[state];
     print('FS:<--- startPlayer ');
     return duration;

  }

  void needSomeFood(int ln) {
      assert(ln >= 0);
      if (needSomeFoodCompleter != null)
      {
        needSomeFoodCompleter.complete(ln);
      }
  }



  Future<void> startPlayerFromStream ({
    Codec codec = Codec.pcm16,
    int numChannels = 1,
    int sampleRate = 16000,
  }) async
  {
    print('FS:---> startPlayerFromStream ');
    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if ( isInited != Initialized.fullyInitialized) {
      throw (_notOpen());
    }

      await lock.synchronized(() async {
      await stop( ); // Just in case
      foodStreamController = StreamController();
      foodStreamSubscription = foodStreamController.stream.listen((Food food)
      {
            foodStreamSubscription.pause(food.exec(this));
      }) ;
      Map retMap = await FlutterSoundPlayerPlatform.instance.startPlayer(this,
            codec: codec,
            fromDataBuffer: null,
            fromURI: null,
            numChannels: numChannels,
            sampleRate: sampleRate
           );
      int state = retMap['state'] as int;
      playerState = PlayerState.values[state];
    } );
    print('FS:<--- startPlayerFromStream ');
    }

    Future<void> feedFromStream(Uint8List buffer) async
    {
      int lnData = 0;
      int totalLength = buffer.length;
      while (totalLength > 0 && !isStopped)
      {
        int bsize = totalLength > BLOCK_SIZE ? BLOCK_SIZE : totalLength;
        int ln = await feed(buffer.sublist(lnData, lnData + bsize));
        lnData += ln;
        totalLength -= ln;
      }
    }

    Future<int> feed(Uint8List data) async {
      if (isInited == Initialized.initializationInProgress) {
        throw (_InitializationInProgress());
      }
      if ( isInited != Initialized.fullyInitialized )
      {
        throw (_notOpen());
      }
      if (isStopped)
        return 0;
      needSomeFoodCompleter = new Completer<int>();
      try
      {
        int ln = await FlutterSoundPlayerPlatform.instance.feed(this, data: data,);
        if (ln != 0)
        {
          needSomeFoodCompleter = null;
          return (ln);
        }
      } catch(e)
      {
        needSomeFoodCompleter = null;
        if (isStopped)
          return 0;
        rethrow;
      }

      if (needSomeFoodCompleter != null) {
        return needSomeFoodCompleter.future;
      }
      return 0;

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
    if (isInited != Initialized.fullyInitialized ) {
      throw (_notOpen());
    }
     Map retMap;
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

        if (defaultPauseResume == null)
          defaultPauseResume = (
                      onPaused == null
          );
        if (playerState != PlayerState.isStopped)
        {
          throw Exception( 'Player is not stopped' );
        }
          retMap = await FlutterSoundPlayerPlatform.instance.startPlayerFromTrack(this,
          progress: progress,
          duration: duration,
          track: trackDico,
          canPause: (
                      onPaused != null || defaultPauseResume
          ),
          canSkipForward: (
                      onSkipForward != null
          ),
          canSkipBackward: (
                      onSkipBackward != null
          ),
          defaultPauseResume: defaultPauseResume,
          removeUIWhenStopped: removeUIWhenStopped,);
      }
      catch (e)
      {
        rethrow;
      }
    });
     Duration d = Duration(milliseconds: retMap['duration'] as int);
     int state = retMap['state'] as int;
     playerState = PlayerState.values[state];

     print('FS:<--- startPlayerFromTrack ');

     return d;

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
      if (isInited != Initialized.fullyInitialized)
      {
        throw (
                    _notOpen( )
        );
      }
      this.onSkipForward = onSkipForward;
      this.onSkipBackward = onSkipBackward;
      this.onPaused = onPaused;

      Map<String, dynamic> trackDico = (
                  track != null
      ) ? track.toMap( ) : null;
      if (defaultPauseResume == null)
        defaultPauseResume = (
                    onPaused == null
        );
      int state = await FlutterSoundPlayerPlatform.instance.nowPlaying(this,
        track: trackDico,
        duration: duration,
        progress: progress,
        canPause: (
                    onPaused != null || defaultPauseResume
        ),
        canSkipForward: (
                    onSkipForward != null
        ),
        canSkipBackward: (
                    onSkipBackward != null
        ),
        defaultPauseResume: defaultPauseResume,
       ) ;
      playerState = PlayerState.values[state];
      print( 'FS:<--- nowPlaying ' );
    });
  }

    Future<void> stopPlayer() async {
      print('FS:---> stopPlayer ');
      if (isInited == Initialized.initializationInProgress) {
        throw (_InitializationInProgress());
      }
      if (isInited != Initialized.fullyInitialized) {
        throw (_notOpen());
      }

    // REALLY ? // audioPlayerFinishedPlaying = null;

      try
      {
        //_removePlayerCallback(); // playerController is closed by this function
        await stop( );
      }
      catch (e)
      {
        print( e );
      }
      print('FS:<--- stopPlayer ');
    }

  Future<void> stop() async {
    print('FS:---> stop ');
    if (foodStreamSubscription != null)
      {
        await foodStreamSubscription.cancel();
        foodStreamSubscription = null;
      }
    needSomeFoodCompleter = null;
    if (foodStreamController != null)
      {
        await foodStreamController.sink.close();
        //await foodStreamController.stream.drain<bool>();
        await foodStreamController.close();
        foodStreamController = null;
      }
    int state = await FlutterSoundPlayerPlatform.instance.stopPlayer(this);

    playerState = PlayerState.values[state];
    if (playerState != PlayerState.isStopped)
    {
      throw Exception( 'Player is not stopped' );
    }

    print('FS:<--- stop ');

  }


  Future<void> pausePlayer() async {
    print('FS:---> pausePlayer ');
    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (isInited != Initialized.fullyInitialized) {
      throw (_notOpen());
    }
    await lock.synchronized(() async {
        playerState = PlayerState.values[await FlutterSoundPlayerPlatform.instance.pausePlayer(this)];
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
    if (isInited != Initialized.fullyInitialized) {
      throw (_notOpen());
    }
    await lock.synchronized(() async {
         int state = await FlutterSoundPlayerPlatform.instance.resumePlayer(this);
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
    if (isInited != Initialized.fullyInitialized) {
      throw (_notOpen());
    }
    await lock.synchronized(() async
    {
        int state = await FlutterSoundPlayerPlatform.instance.seekToPlayer( this, duration: duration,);
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
      if (isInited != Initialized.fullyInitialized)
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

      int state = await FlutterSoundPlayerPlatform.instance.setVolume(this, volume: indexedVolume,);
      playerState = PlayerState.values[state];
    });
    print('FS:<--- setVolume ');
  }

  Future<void> setUIProgressBar ( {
                                    Duration duration,
                                    Duration progress,
                                  }) async {
    print('FS:---> setUIProgressBar : duration=$duration  progress=$progress');
    await lock.synchronized(() async {
      int state = await FlutterSoundPlayerPlatform.instance.setUIProgressBar( this, duration: duration, progress: progress);
      playerState = PlayerState.values[state];
    });
      print('FS:<--- setUIProgressBar ');
  }


  Future<String> getResourcePath() async {
    if (Platform.isIOS) {
      String s =
          await FlutterSoundPlayerPlatform.instance.getResourcePath(this);
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
