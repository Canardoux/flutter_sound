/*
 * Copyright 2018, 2019, 2020 Dooboolab.
 *
 * This file is part of Flutter-Sound.
 *
 * Flutter-Sound is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3, as published by
 * the Free Software Foundation.
 *
 * Flutter-Sound is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
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

enum PlayerState {
  /// Player is stopped
  isStopped,
  /// Player is playing
  isPlaying,
  /// Player is paused
  isPaused,
}

/// Used by [AudioPlayer.audioFocus]
/// to control the focus mode.
enum AudioFocus {
  requestFocus,

  /// request focus and allow other audio
  /// to continue playing at their current volume.
  requestFocusAndKeepOthers,

  /// request focus and stop other audio playing
  requestFocusAndStopOthers,

  /// request focus and reduce the volume of other players
  /// In the Android world this is know as 'Duck Others'.
  requestFocusAndDuckOthers,

  requestFocusAndInterruptSpokenAudioAndMixWithOthers,

  requestFocusTransient,
  requestFocusTransientExclusive,


  /// relinquish the audio focus.
  abandonFocus,

  doNotRequestFocus,
}

// Audio Flags
// -----------
const outputToSpeaker = 1;
const allowHeadset = 2;
const allowEarPiece = 4;
const allowBlueTooth = 8;
const allowAirPlay = 16;
const allowBlueToothA2DP = 32;


enum SessionCategory {
  ambient,
  multiRoute,
  playAndRecord,
  playback,
  record,
  soloAmbient,
}

final List<String> iosSessionCategory = [
  'AVAudioSessionCategoryAmbient',
  'AVAudioSessionCategoryMultiRoute',
  'AVAudioSessionCategoryPlayAndRecord',
  'AVAudioSessionCategoryPlayback',
  'AVAudioSessionCategoryRecord',
  'AVAudioSessionCategorySoloAmbient',
];

enum SessionMode {
  defaultSessionMode,
  gameChat,
  measurement,
  moviePlayback,
  spokenAudio,
  videoChat,
  videoRecording,
  voiceChat,
  voicePrompt,
}

final List<String> iosSessionMode = [
  'AVAudioSessionModeDefault',
  'AVAudioSessionModeGameChat',
  'AVAudioSessionModeMeasurement',
  'AVAudioSessionModeMoviePlayback',
  'AVAudioSessionModeSpokenAudio',
  'AVAudioSessionModeVideoChat',
  'AVAudioSessionModeVideoRecording',
  'AVAudioSessionModeVoiceChat',
  'AVAudioSessionModeVoicePrompt',
];

// Values for AUDIO_FOCUS_GAIN on Android
enum AndroidFocusGain {
  defaultFocusGain,
  audioFocusGain,
  audioFocusGainTransient,
  audioFocusGainTransientMayDuck,
  audioFocusGainTransientExclusive,
}

// Options for setSessionCategory on iOS
const int iosMixWithOthers = 0x1;
const int iosDuckOthers = 0x2;
const int iosInterruptSpokenAudioAndMixWithOthers = 0x11;
const int iosAllowBluetooth = 0x4;
const int iosAllowBluetoothA2DP = 0x20;
const int iosAllowAirplay = 0x40;
const int iosDefaultToSpeaker = 0x8;

typedef void TWhenFinished();
typedef void TonPaused(bool paused);
typedef void TonSkip();
typedef void TupdateProgress(int current, int max);

FlautoPlayerPlugin flautoPlayerPlugin; // Singleton, lazy initialized
List<FlutterSoundPlayer> slots = [];

class FlautoPlayerPlugin {
  MethodChannel channel;

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

  int _lookupEmptySlot(FlutterSoundPlayer aPlayer) {
    for (var i = 0; i < slots.length; ++i) {
      if (slots[i] == null) {
        slots[i] = aPlayer;
        return i;
      }
    }
    slots.add(aPlayer);
    return slots.length - 1;
  }

  void freeSlot(int slotNo) {
    slots[slotNo] = null;
  }

  MethodChannel getChannel() => channel;

  Future<dynamic> invokeMethod(String methodName, Map<String, dynamic> call) {
    return getChannel().invokeMethod<dynamic>(methodName, call);
  }

  Future<dynamic> channelMethodCallHandler(MethodCall call) {
    int slotNo = call.arguments['slotNo'] as int;
    var aPlayer = slots[slotNo];

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

enum Initialized {
  notInitialized,
  initializationInProgress,
  fullyInitialized,
  fullyInitializedWithUI,
}

class FlutterSoundPlayer {
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
  ];

  Initialized isInited = Initialized.notInitialized;
  PlayerState playerState = PlayerState.isStopped;
  StreamController<PlaybackDisposition> playerController;
  TWhenFinished audioPlayerFinishedPlaying; // User callback "whenFinished:"
  //TonPaused whenPause; // User callback "whenPaused:"
  TupdateProgress onUpdateProgress;
  int slotNo;

  Stream<PlaybackDisposition> get onProgress =>
      playerController != null ? playerController.stream : null;

  bool get isPlaying => playerState == PlayerState.isPlaying;

  bool get isPaused => playerState == PlayerState.isPaused;

  bool get isStopped => playerState == PlayerState.isStopped;

  FlutterSoundPlayer();

  FlautoPlayerPlugin getPlugin() => flautoPlayerPlugin;

  Future<dynamic> invokeMethod(
      String methodName, Map<String, dynamic> call) async {
    call['slotNo'] = slotNo;
    return getPlugin().invokeMethod(methodName, call);
  }

  Future<FlutterSoundPlayer> openAudioSession( { AudioFocus focus = AudioFocus.requestFocusAndStopOthers, int audioFlags = outputToSpeaker}) async {
    if (isInited == Initialized.fullyInitialized || isInited == Initialized.fullyInitializedWithUI) {
      return this;
    }
    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }

    isInited = Initialized.initializationInProgress;

    if (flautoPlayerPlugin == null) {
      flautoPlayerPlugin = FlautoPlayerPlugin(); // The lazy singleton
    }
    slotNo = getPlugin()._lookupEmptySlot(this);

    await invokeMethod('initializeMediaPlayer', <String, dynamic>{'focus': focus.index, 'audioFlags': audioFlags,});
    isInited = Initialized.fullyInitialized;
    return this;
  }

  Future<FlutterSoundPlayer> openAudioSessionWithUI( { AudioFocus focus = AudioFocus.requestFocusAndStopOthers, int audioFlags = outputToSpeaker}) async {
    if (isInited == Initialized.fullyInitializedWithUI) {
      return this;
    }
    if (isInited == Initialized.initializationInProgress || isInited == Initialized.fullyInitialized) {
      throw (_InitializationInProgress());
    }

    isInited = Initialized.initializationInProgress;

    if (flautoPlayerPlugin == null) {
      flautoPlayerPlugin = FlautoPlayerPlugin(); // The lazy singleton
    }
    slotNo = getPlugin()._lookupEmptySlot(this);

    try {
      await invokeMethod('initializeMediaPlayerWithUI', <String, dynamic>{'focus': focus.index, 'audioFlags': audioFlags,});

      // Add the method call handler
      //getChannel( ).setMethodCallHandler( channelMethodCallHandler );
    } catch (err) {
      rethrow;
    }
    isInited = Initialized.fullyInitializedWithUI;
    return this;
  }

  Future<void> setAudioFocus( { AudioFocus focus = AudioFocus.requestFocusAndStopOthers, int audioFlags = outputToSpeaker}) async {
    await openAudioSession(focus:focus, audioFlags: audioFlags);
    await invokeMethod('setAudioFocus', <String, dynamic>{'focus':focus, 'audioFlags':audioFlags});
  }



  Future<void> closeAudioSession() async {
    if (isInited == Initialized.notInitialized) {
      return this;
    }
    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    isInited = Initialized.initializationInProgress;

    await stopPlayer();
    _removePlayerCallback(); // playerController is closed by this function
    await invokeMethod('releaseMediaPlayer', <String, dynamic>{});
    await playerController?.close();

    getPlugin().freeSlot(slotNo);
    slotNo = null;
    isInited = Initialized.notInitialized;
  }

  void _updateProgress(Map call) {
    //String arg = call['arg'] as String;
    //Map<String, dynamic> result = jsonDecode(arg) as Map<String, dynamic>;
    //if (playerController != null) {
      //playerController.add(PlayStatus.fromJSON(result));
   // }
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
    _removePlayerCallback();

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
    await openAudioSession();
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

  /// For iOS only.
  /// If this function is not called,
  /// everything is managed by default by flutter_sound.
  /// If this function is called,
  /// it is probably called just once when the app starts.
  /// After calling this function,
  /// the caller is responsible for using correctly setActive
  ///    probably before startRecorder or startPlayer, and stopPlayer and stopRecorder
  Future<bool> iosSetCategory(
      SessionCategory category, SessionMode mode, int options) async {
    await openAudioSession();
    if (!Platform.isIOS) return false;
    var r = await invokeMethod('iosSetCategory', <String, dynamic>{
      'category': iosSessionCategory[category.index],
      'mode': iosSessionMode[mode.index],
      'options': options
    }) as bool;

    return r;
  }

  /// For Android only.
  /// If this function is not called, everything is managed by default by flutter_sound.
  /// If this function is called, it is probably called just once when the app starts.
  /// After calling this function, the caller is responsible for using correctly setActive
  ///    probably before startRecorder or startPlayer, and stopPlayer and stopRecorder
  Future<bool> androidAudioFocusRequest(int focusGain) async {
    await openAudioSession();
    if (!Platform.isAndroid) return false;
    var r = await invokeMethod('androidAudioFocusRequest',
        <String, dynamic>{'focusGain': focusGain}) as bool;

    return r;
  }

  Future<String> setSubscriptionDuration(double sec) async {
    await openAudioSession();
    String r = await invokeMethod('setSubscriptionDuration', <String, dynamic>{
      'sec': sec,
    }) as String;
    return r;
  }

  void setPlayerCallback() {
    if (playerController == null) {
      playerController = StreamController.broadcast();
    }
  }

  void _removePlayerCallback() {
    if (playerController != null) {
      playerController
        //..add(null)
        ..close();
      playerController = null;
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
    await openAudioSession();
    if (isInited != Initialized.fullyInitialized)
      throw(Exception('Not initialized'));
    await stopPlayer(); // Just in case
    bool result = true;
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
      result = await invokeMethod('startPlayer', {'codec':codec.index, 'fromDataBuffer': fromDataBuffer, 'fromURI': fromURI,} as Map<String, dynamic>) as bool;

      if (result ) {
        setPlayerCallback();

        playerState = PlayerState.isPlaying;
      }

    } catch (err) {
      audioPlayerFinishedPlaying = null;
      throw Exception(err);
    }
    return result;
  }


  Future<void> startPlayerFromTrack( Track track,
              {
                Codec codec = Codec.aacADTS,
                TonSkip onSkipForward,
                TonSkip onSkipBackward,
                TonPaused onPaused,
                TWhenFinished whenFinished = null,
              }) async {
    await openAudioSessionWithUI();
    if (isInited != Initialized.fullyInitializedWithUI)
      throw(Exception('Not initialized'));

    await stopPlayer(); // Just in case
    bool result = true;
    audioPlayerFinishedPlaying = whenFinished;
    this.onSkipForward = onSkipForward;
    this.onSkipBackward = onSkipBackward;
    this.onPaused = onPaused;
    Map<String, dynamic> trackDico = track.toMap();
    result = await invokeMethod('startPlayerFromTrack', {
          'codec': codec.index,
          'track': trackDico,
          'canPause': onPaused != null,
          'canSkipForward': onSkipForward != null,
          'canSkipBackward': onSkipBackward != null,
    } as Map<String, dynamic>) as bool;

  }


    Future<String> stopPlayer() async {
    playerState = PlayerState.isStopped;
    audioPlayerFinishedPlaying = null;

    try {
      _removePlayerCallback(); // playerController is closed by this function
      String result =
          await invokeMethod('stopPlayer', <String, dynamic>{}) as String;
      return result;
    } catch (e) {
      print(e);
      return null; // stopPlayer() can always be called safely without getting errors
    }
  }

  Future<String> _stopPlayerwithCallback() async {
    if (audioPlayerFinishedPlaying != null) {
      audioPlayerFinishedPlaying();
      audioPlayerFinishedPlaying = null;
    }
    return stopPlayer();
  }

  Future<String> pausePlayer() async {
    if (playerState != PlayerState.isPlaying) {
      await _stopPlayerwithCallback(); // To recover a clean state
      throw PlayerRunningException(
          'Player is not playing.'); // I am not sure that it is good to throw an exception here
    }
    playerState = PlayerState.isPaused;

    String r = await invokeMethod('pausePlayer', <String, dynamic>{}) as String;
    return r;
  }

  Future<String> resumePlayer() async {
    if (playerState != PlayerState.isPaused) {
      await _stopPlayerwithCallback(); // To recover a clean state
      throw PlayerRunningException(
          'Player is not paused.'); // I am not sure that it is good to throw an exception here
    }
    playerState = PlayerState.isPlaying;
    String r =
        await invokeMethod('resumePlayer', <String, dynamic>{}) as String;
    return r;
  }

  Future<String> seekToPlayer(int milliSecs) async {
    await openAudioSession();
    String r = await invokeMethod('seekToPlayer', <String, dynamic>{
      'sec': milliSecs,
    }) as String;
    return r;
  }

  Future<String> setVolume(double volume) async {
    await openAudioSession();
    var indexedVolume = Platform.isIOS ? volume * 100 : volume;
    if (volume < 0.0 || volume > 1.0) {
      throw RangeError('Value of volume should be between 0.0 and 1.0.');
    }

    String r = await invokeMethod('setVolume', <String, dynamic>{
      'volume': indexedVolume,
    }) as String;
    return r;
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

/*
class PlayStatus {
  final double duration;
  double currentPosition;

  /// A convenience ctor. If you are using a stream builder
  /// you can use this to set initialData with both duration
  /// and postion as 0.
  PlayStatus.zero()
      : duration = 0,
        currentPosition = 0;

  PlayStatus.fromJSON(Map<String, dynamic> json)
      : duration = double.parse(json['duration'] as String),
        currentPosition = double.parse(json['current_position'] as String);

  @override
  String toString() {
    return 'duration: $duration, '
        'currentPosition: $currentPosition';
  }
}
*/

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
  PlaybackDisposition(this.position, this.duration);

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
    print('An initialization is currently already in progress.');
  }
}


/// The track to play in the audio player
class Track {
  /// The title of this track
  final String trackTitle;

  /// The buffer containing the audio file to play
  Uint8List dataBuffer;

  /// The name of the author of this track
  final String trackAuthor;

  /// The path that points to the track audio file
  String trackPath;

  /// The URL that points to the album art of the track
  final String albumArtUrl;

  /// The asset that points to the album art of the track
  final String albumArtAsset;

  /// The file that points to the album art of the track
  final String albumArtFile;

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
