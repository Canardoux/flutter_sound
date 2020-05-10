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

      case 'pause':
        {
          aPlayer.pause(call.arguments as Map);
        }
        break;

      case 'resume':
        {
          aPlayer.resume(call.arguments as Map);
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
}

class FlutterSoundPlayer {
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
  StreamController<PlayStatus> playerController;
  TWhenFinished audioPlayerFinishedPlaying; // User callback "whenFinished:"
  TonPaused whenPause; // User callback "whenPaused:"
  TupdateProgress onUpdateProgress;
  int slotNo;

  Stream<PlayStatus> get onProgress =>
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

  Future<FlutterSoundPlayer> openAudioSession() async {
    if (isInited == Initialized.fullyInitialized) {
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
    await invokeMethod('initializeMediaPlayer', <String, dynamic>{});
    isInited = Initialized.fullyInitialized;
    return this;
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
    String arg = call['arg'] as String;
    Map<String, dynamic> result = jsonDecode(arg) as Map<String, dynamic>;
    if (playerController != null) {
      playerController.add(PlayStatus.fromJSON(result));
    }
  }

  void audioPlayerFinished(Map call) {
    String args = call['arg'] as String;
    Map<String, dynamic> result = jsonDecode(args) as Map<String, dynamic>;
    PlayStatus status = PlayStatus.fromJSON(result);

    if (status.currentPosition != status.duration) {
      status.currentPosition = status.duration;
    }
    if (playerController != null) playerController.add(status);

    playerState = PlayerState.isStopped;
    _removePlayerCallback();

    if (audioPlayerFinishedPlaying != null) audioPlayerFinishedPlaying();
  }

  void pause(Map call) {
    if (whenPause != null) whenPause(true);
  }

  void resume(Map call) {
    if (whenPause != null) whenPause(false);
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

  ///  The caller can manage his audio focus with this function
  Future<bool> setAudioFocus(bool enabled) async {
    await openAudioSession();
    var r =
        await invokeMethod('setActive', <String, dynamic>{'enabled': enabled})
            as bool;
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

  Future<String> _startPlayer(String method, Map<String, dynamic> what) async {
    String result;
    await stopPlayer(); // Just in case
    try {
      Codec codec = what['codec'] as Codec;
      if (needToConvert(codec)) {
        await _convertAudio(what);
      }
      //String path = what['path'] as String; // can be null
      codec =
          what['codec'] as Codec; // Could have been modified by convertAudio()

      // Flutter cannot transfer an enum to a native plugin.
      // We use an integer instead
      if (codec != null) {
        what['codec'] = codec.index;
      }
      audioPlayerFinishedPlaying = what['whenFinished'] as void Function();
      what['whenFinished'] =
          null; // We must remove this parameter because _channel.invokeMethod() does not like it
      result = await invokeMethod(method, what) as String;

      if (result != null) {
        print('startPlayer result: $result');
        setPlayerCallback();

        playerState = PlayerState.isPlaying;
      }

      return result;
    } catch (err) {
      audioPlayerFinishedPlaying = null;
      throw Exception(err);
    }
  }

  Future<String> startPlayer(
    String uri, {
    Codec codec,
    TWhenFinished whenFinished,
  }) async {
    await openAudioSession();
    return await _startPlayer('startPlayer', <String, dynamic>{
      'path': uri,
      'codec': codec,
      'whenFinished': whenFinished,
    });
  }

  Future<String> startPlayerFromBuffer(
    Uint8List dataBuffer, {
    Codec codec,
    TWhenFinished whenFinished,
  }) async {
    await openAudioSession();
    // If we want to play OGG/OPUS on iOS, we need to remux the OGG file format to a specific Apple CAF envelope before starting the player.
    // We write the data in a temporary file before calling ffmpeg.
    if (needToConvert(codec)) {
      await stopPlayer();
      var tempDir = await getTemporaryDirectory();
      File inputFile = File('${tempDir.path}/$slotNo-flutter_sound-tmp');

      if (inputFile.existsSync()) {
        await inputFile.delete();
      }
      inputFile.writeAsBytesSync(
          dataBuffer); // Write the user buffer into the temporary file

      // Now we can play the temporary file
      return await _startPlayer('startPlayer', <String, dynamic>{
        'path': inputFile.path,
        'codec': codec,
        'whenFinished': whenFinished,
      }); // And play something that Apple will be happy with.
    } else {
      return await _startPlayer('startPlayerFromBuffer', <String, dynamic>{
        'dataBuffer': dataBuffer,
        'codec': codec,
        'whenFinished': whenFinished,
      });
    }
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

class PlayerRunningException implements Exception {
  final String message;

  PlayerRunningException(this.message);
}

class _InitializationInProgress implements Exception {
  _InitializationInProgress() {
    print('An initialization is currently already in progress.');
  }
}
