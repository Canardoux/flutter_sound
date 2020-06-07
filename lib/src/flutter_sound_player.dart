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
typedef void TupdateProgress(int current, int max);

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

    switch (call.method) {
      case "updateProgress":
        {
          aPlayer._updateProgress(call.arguments as Map);
        }
        break;

      case "audioPlayerFinishedPlaying":
        {
          aPlayer.audioPlayerFinished(call.arguments as Map);
        }
        break;

      case 'pause': // Pause/Resume
        {
          aPlayer.pause(call.arguments as Map);
        }
        break;

      case 'skipForward':
        {
          aPlayer.skipForward(call.arguments as Map);
        }
        break;

      case 'skipBackward':
        {
          aPlayer.skipBackward(call.arguments as Map);
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
class FlutterSoundPlayer extends Session {
  TonSkip onSkipForward; // User callback "onPaused:"
  TonSkip onSkipBackward; // User callback "onPaused:"
  TonPaused onPaused; // user callback "whenPause:"

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
  //StreamController<PlaybackDisposition> playerController;
  // The stream source
  StreamController<PlaybackDisposition> _playerController ;//= StreamController<PlaybackDisposition>.broadcast();


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
  /// Note: all calls to [dispositionStream] agains this player will
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
  TupdateProgress onUpdateProgress;


  bool get isPlaying => playerState == PlayerState.isPlaying;

  bool get isPaused => playerState == PlayerState.isPaused;

  bool get isStopped => playerState == PlayerState.isStopped;

  FlutterSoundPlayer();

  FlautoPlugin getPlugin() => flautoPlayerPlugin;

  Future<FlutterSoundPlayer> openAudioSession( {
                                                 AudioFocus focus = AudioFocus.requestFocusTransient,
                                                 SessionCategory category = SessionCategory.playAndRecord,
                                                 SessionMode mode = SessionMode.modeDefault,
                                                 AudioDevice device = AudioDevice.speaker}) async {
    if (isInited == Initialized.fullyInitialized || isInited == Initialized.fullyInitializedWithUI) {
      await closeAudioSession();
    }
    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }

    isInited = Initialized.initializationInProgress;

    if (flautoPlayerPlugin == null) {
      flautoPlayerPlugin = FlautoPlayerPlugin(); // The lazy singleton
    }

    openSession();
    setPlayerCallback();

    await invokeMethod('initializeMediaPlayer', <String, dynamic>{'focus': focus.index, 'category': category.index, 'mode': mode.index, 'device': device.index,});
    isInited = Initialized.fullyInitialized;
    return this;
  }

  Future<FlutterSoundPlayer> openAudioSessionWithUI( {
                                                       AudioFocus focus = AudioFocus.requestFocusTransient,
                                                       SessionCategory category = SessionCategory.playAndRecord,
                                                       SessionMode mode = SessionMode.modeDefault,
                                                       AudioDevice device = AudioDevice.speaker}) async {
    if (isInited == Initialized.fullyInitializedWithUI || isInited == Initialized.fullyInitialized) {
      await closeAudioSession();
    }
    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }

    isInited = Initialized.initializationInProgress;

    if (flautoPlayerPlugin == null) {
      flautoPlayerPlugin = FlautoPlayerPlugin(); // The lazy singleton
    }
    openSession();
    setPlayerCallback();

    try {
      await invokeMethod('initializeMediaPlayerWithUI', <String, dynamic>{'focus': focus.index, 'category': category.index, 'mode': mode.index, 'device': device.index,});

      // Add the method call handler
      //getChannel( ).setMethodCallHandler( channelMethodCallHandler );
    } catch (err) {
      rethrow;
    }
    isInited = Initialized.fullyInitializedWithUI;
    return this;
  }



  Future<void> setAudioFocus( {
                                AudioFocus focus = AudioFocus.requestFocusTransient,
                                SessionCategory category = SessionCategory.playAndRecord,
                                SessionMode mode = SessionMode.modeDefault,
                                AudioDevice device = AudioDevice.speaker}) async {

    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (isInited != Initialized.fullyInitializedWithUI && isInited != Initialized.fullyInitialized) {
      throw (_notOpen());
    }

    await invokeMethod('setAudioFocus', <String, dynamic>{'focus':focus.index, 'category': category.index, 'mode': mode.index, 'device':device.index});
  }



  Future<void> closeAudioSession() async {
    if (isInited == Initialized.notInitialized) {
      return this;
    }
    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }

    await stopPlayer();
    isInited = Initialized.initializationInProgress;

    //_removePlayerCallback(); // playerController is closed by this function
    await invokeMethod('releaseMediaPlayer', <String, dynamic>{});
    _removePlayerCallback();
    closeSession();
    isInited = Initialized.notInitialized;
  }

  void _updateProgress(Map call) {
    int duration = call['duration'] as int;
    int position = call['position'] as int;
    //print('position=$position');
    _playerController.add(PlaybackDisposition(position: Duration(milliseconds: position), duration: Duration(milliseconds: duration),) );
  }

  void audioPlayerFinished(Map call) {
    String args = call['arg'] as String;
    //Map<String, dynamic> result = jsonDecode(args) as Map<String, dynamic>;
    //PlayStatus status = PlayStatus.fromJSON(result);

    //if (status.currentPosition != status.duration) {
      //status.currentPosition = status.duration;
    //}
    //if (playerController != null) playerController.add(status);

    playerState = PlayerState.isStopped;
    //_removePlayerCallback();

    if (audioPlayerFinishedPlaying != null) audioPlayerFinishedPlaying();
  }



  void skipForward(Map call) {
    if (onSkipForward != null) onSkipForward();
  }

  void skipBackward(Map call) {
    if (onSkipBackward != null) onSkipBackward();
  }

  void pause(Map call) {
    bool b = call['arg'] as bool;
    if (onPaused != null) {
      // Probably always true
      onPaused(b);
    } else {
      if (b)
        pausePlayer();
      else
        resumePlayer();
    }
  }

  bool needToConvert(Codec codec) {
    if (codec == null) return false;
    Codec convert = (Platform.isIOS)
        ? tabIosConvert[codec.index]
        : tabAndroidConvert[codec.index];
    return (convert != Codec.defaultCodec);
  }

  /// Returns true if the specified decoder is supported by flutter_sound on this platform
  Future<bool> isDecoderSupported(Codec codec) async {
    bool result;

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
    return result;
  }

  /// For Android only.
  /// If this function is not called, everything is managed by default by flutter_sound.
  /// If this function is called, it is probably called just once when the app starts.
  /// After calling this function, the caller is responsible for using correctly setActive
  ///    probably before startRecorder or startPlayer, and stopPlayer and stopRecorder
  Future<bool> androidAudioFocusRequest(int focusGain) async {

    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (isInited != Initialized.fullyInitializedWithUI && isInited != Initialized.fullyInitialized) {
      throw (_notOpen());
    }
    if (!Platform.isAndroid) return false;
    var r = await invokeMethod('androidAudioFocusRequest',
        <String, dynamic>{'focusGain': focusGain}) as bool;

    return r;
  }

  Future<void> setSubscriptionDuration(Duration duration) async {

    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (isInited != Initialized.fullyInitializedWithUI && isInited != Initialized.fullyInitialized) {
      throw (_notOpen());
    }
    await invokeMethod('setSubscriptionDuration', <String, dynamic>{
      'milliSec': duration.inMilliseconds,
    }) ;
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
  }


  Future<void> startPlayer(
   {
     String fromURI = null,
     Uint8List fromDataBuffer = null,
     Codec codec = Codec.aacADTS,
     TWhenFinished whenFinished = null,
  }) async {
    if (isInited == Initialized.fullyInitializedWithUI) {
      final track = Track(trackPath: fromURI, dataBuffer: fromDataBuffer, codec: codec);
      return startPlayerFromTrack(track, whenFinished: whenFinished);
    }

    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (isInited != Initialized.fullyInitializedWithUI && isInited != Initialized.fullyInitialized) {
      throw (_notOpen());
    }
    await stopPlayer(); // Just in case
    //bool result = true;
    try {
      if (needToConvert(codec)) {

        if (fromDataBuffer != null) {
          var tempDir = await getTemporaryDirectory();
          File inputFile = File('${tempDir.path}/$slotNo-flutter_sound-tmp');

          if (inputFile.existsSync()) {
            await inputFile.delete();
          }
          inputFile.writeAsBytesSync(
                      fromDataBuffer); // Write the user buffer into the temporary file
          fromDataBuffer = null;
          fromURI = inputFile.path;
        }
        Map<String, dynamic> what = {'codec': codec, 'path': fromURI, 'fromDataBuffer': fromDataBuffer,} as Map<String, dynamic>;
        await _convertAudio(what);
        codec = what['codec'] as Codec;
        fromURI =  what['path'] as String;
        //fromDataBuffer = what['fromDataBuffer'] as Uint8List;
      }

      audioPlayerFinishedPlaying = whenFinished;
      await invokeMethod('startPlayer', {'codec':codec.index, 'fromDataBuffer': fromDataBuffer, 'fromURI': fromURI,} as Map<String, dynamic>);
      //setPlayerCallback();

      playerState = PlayerState.isPlaying;

    } catch (err) {
      audioPlayerFinishedPlaying = null;
      throw Exception(err);
    }
  }


  Future<void> startPlayerFromTrack( Track track,
              {
                TonSkip onSkipForward,
                TonSkip onSkipBackward,
                TonPaused onPaused,
                TWhenFinished whenFinished = null,
              }) async {

    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (isInited != Initialized.fullyInitializedWithUI ) {
      throw (_notOpen());
    }

    await stopPlayer(); // Just in case
    audioPlayerFinishedPlaying = whenFinished;
    this.onSkipForward = onSkipForward;
    this.onSkipBackward = onSkipBackward;
    this.onPaused = onPaused;
    Map<String, dynamic> trackDico = track.toMap();
    await invokeMethod('startPlayerFromTrack',  <String, dynamic>{
          'track': trackDico,
          'canPause': onPaused != null,
          'canSkipForward': onSkipForward != null,
          'canSkipBackward': onSkipBackward != null,
    } );
    //setPlayerCallback();
    playerState = PlayerState.isPlaying;
  }


    Future<void> stopPlayer() async {
      if (isInited == Initialized.initializationInProgress) {
        throw (_InitializationInProgress());
      }
      if (isInited != Initialized.fullyInitializedWithUI && isInited != Initialized.fullyInitialized) {
        throw (_notOpen());
      }
      playerState = PlayerState.isStopped;

    audioPlayerFinishedPlaying = null;

    try {
      //_removePlayerCallback(); // playerController is closed by this function
      await invokeMethod('stopPlayer', <String, dynamic>{}) as String;
    } catch (e) {
      print(e);
    }
  }

  Future<void> _stopPlayerwithCallback() async {
    if (audioPlayerFinishedPlaying != null) {
      audioPlayerFinishedPlaying();
      audioPlayerFinishedPlaying = null;
    }
    stopPlayer();
  }

  Future<void> pausePlayer() async {
    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (isInited != Initialized.fullyInitializedWithUI && isInited != Initialized.fullyInitialized) {
      throw (_notOpen());
    }

    if (playerState != PlayerState.isPlaying) {
      await _stopPlayerwithCallback(); // To recover a clean state
      throw PlayerRunningException(
          'Player is not playing.'); // I am not sure that it is good to throw an exception here
    }
    playerState = PlayerState.isPaused;

    await invokeMethod('pausePlayer', <String, dynamic>{}) as String;
  }

  Future<void> resumePlayer() async {
    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (isInited != Initialized.fullyInitializedWithUI && isInited != Initialized.fullyInitialized) {
      throw (_notOpen());
    }

    if (playerState != PlayerState.isPaused) {
      await _stopPlayerwithCallback(); // To recover a clean state
      throw PlayerRunningException(
          'Player is not paused.'); // I am not sure that it is good to throw an exception here
    }
    playerState = PlayerState.isPlaying;
    await invokeMethod('resumePlayer', <String, dynamic>{}) as String;
  }

  Future<void> seekToPlayer(Duration duration) async {

    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (isInited != Initialized.fullyInitializedWithUI && isInited != Initialized.fullyInitialized) {
      throw (_notOpen());
    }
    await invokeMethod('seekToPlayer', <String, dynamic>{
      'duration': duration.inMilliseconds,
    });
  }

  Future<void> setVolume(double volume) async {

    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (isInited != Initialized.fullyInitializedWithUI && isInited != Initialized.fullyInitialized) {
      throw (_notOpen());
    }
    var indexedVolume = Platform.isIOS ? volume * 100 : volume;
    if (volume < 0.0 || volume > 1.0) {
      throw RangeError('Value of volume should be between 0.0 and 1.0.');
    }

    String r = await invokeMethod('setVolume', <String, dynamic>{
      'volume': indexedVolume,
    }) as String;
  }

  Future<String> getResourcePath() async {
    // iOS : /Volumes/Macos-Ext/Users/larpoux/Library/Developer/CoreSimulator/Devices/DC01AED0-124F-4589-B2FD-DC1D56A967DF/data/Containers/Bundle/Application/7FF3AF75-FD79-4C9C-A76D-0CFB09CB6BC5/Runner.app
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
    assert(trackPath != null || dataBuffer != null,
    'You should provide a path or a buffer for the audio content to play.');
    assert(
    (trackPath != null && dataBuffer == null) ||
    (trackPath == null && dataBuffer != null),
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
