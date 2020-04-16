/*
 * This file is part of Flutter-Sound (Flauto).
 *
 *   Flutter-Sound (Flauto) is free software: you can redistribute it and/or modify
 *   it under the terms of the Lesser GNU General Public License
 *   version 3 (LGPL3) as published by the Free Software Foundation.
 *
 *   Flutter-Sound (Flauto) is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the Lesser GNU General Public License
 *   along with Flutter-Sound (Flauto).  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:io' show Platform;
import 'dart:typed_data' show Uint8List;

import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'src/flauto.dart';
import 'src/flutter_player_plugin.dart';
import 'src/playback_disposition.dart';

enum PlayerState {
  IS_STOPPED,

  /// Player is stopped
  IS_PLAYING,
  IS_PAUSED,
}

enum IOSSessionCategory {
  AMBIENT,
  MULTI_ROUTE,
  PLAY_AND_RECORD,
  PLAYBACK,
  RECORD,
  SOLO_AMBIENT,
}

final List<String> iosSessionCategory = [
  'AVAudioSessionCategoryAmbient',
  'AVAudioSessionCategoryMultiRoute',
  'AVAudioSessionCategoryPlayAndRecord',
  'AVAudioSessionCategoryPlayback',
  'AVAudioSessionCategoryRecord',
  'AVAudioSessionCategorySoloAmbient',
];

enum IOSSessionMode {
  DEFAULT,
  GAME_CHAT,
  MEASUREMENT,
  MOVIE_PLAYBACK,
  SPOKEN_AUDIO,
  VIDEO_CHAT,
  VIDEO_RECORDING,
  VOICE_CHAT,
  VOICE_PROMPT,
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
const int ANDROID_AUDIOFOCUS_GAIN = 1;
const int ANDROID_AUDIOFOCUS_GAIN_TRANSIENT = 2;
const int ANDROID_AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK = 3;
const int ANDROID_AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE = 4;

// Options for setSessionCategory on iOS
const int IOS_MIX_WITH_OTHERS = 0x1;
const int IOS_DUCK_OTHERS = 0x2;
const int IOS_INTERRUPT_SPOKEN_AUDIO_AND_MIX_WITH_OTHERS = 0x11;
const int IOS_ALLOW_BLUETOOTH = 0x4;
const int IOS_ALLOW_BLUETOOTH_A2DP = 0x20;
const int IOS_ALLOW_AIR_PLAY = 0x40;
const int IOS_DEFAULT_TO_SPEAKER = 0x8;

typedef void TWhenFinished();
typedef void TwhenPaused(bool paused);
typedef void TonSkip();
typedef void TupdateProgress(int current, int max);

FlautoPlayerPlugin flautoPlayerPlugin; // Singleton, lazy initialized
List<FlutterSoundPlayer> slots = [];

/// Return the file extension for the given path.
/// path can be null. We return null in this case.
String fileExtension(String path) {
  if (path == null) return null;
  var r = p.extension(path);
  return r;
}

class FlutterSoundPlayer {
  bool isInited = false;
  PlayerState playerState = PlayerState.IS_STOPPED;
  StreamController<PlaybackDisposition> _playerController;
  TWhenFinished audioPlayerFinishedPlaying; // User callback "whenFinished:"
  TwhenPaused whenPaused; // User callback "whenPaused:"
  int slotNo;

  Stream<PlaybackDisposition> get dispositionStream =>
      _playerController != null ? _playerController.stream : null;

  bool get isPlaying => playerState == PlayerState.IS_PLAYING;

  bool get isPaused => playerState == PlayerState.IS_PAUSED;

  bool get isStopped => playerState == PlayerState.IS_STOPPED;

  FlutterSoundPlayer();

  FlautoPlayerPlugin getPlugin() => flautoPlayerPlugin;

  Future<dynamic> invokeMethod(
      String methodName, Map<String, dynamic> call) async {
    call['slotNo'] = slotNo;
    return getPlugin().invokeMethod(methodName, call);
  }

  Future<FlutterSoundPlayer> initialize() async {
    if (!isInited) {
      isInited = true;

      if (flautoPlayerPlugin == null) {
        flautoPlayerPlugin = FlautoPlayerPlugin(); // The lazy singleton
      }
      slotNo = getPlugin().lookupEmptySlot(this);
      await invokeMethod('initializeMediaPlayer', <String, dynamic>{});
    }
    return this;
  }

  Future<void> release() async {
    if (isInited) {
      isInited = false;
      await stopPlayer();
      removePlayerCallback(); // playerController is closed by this function
      await invokeMethod('releaseMediaPlayer', <String, dynamic>{});
      await _playerController?.close();

      getPlugin().freeSlot(slotNo);
      slotNo = null;
    }
  }

  void updateProgress(Map call) {
    var arg = call['arg'] as String;
    Map<String, dynamic> result = jsonDecode(arg) as Map<String, dynamic>;
    _playerController?.add(PlaybackDisposition.fromJSON(result));
  }

  void audioPlayerFinished(PlaybackDisposition status) {
    // if we have finished then position should be at the end.
    status.position = status.duration;
    _playerController?.add(status);

    playerState = PlayerState.IS_STOPPED;
    if (audioPlayerFinishedPlaying != null) {
      audioPlayerFinishedPlaying();
      audioPlayerFinishedPlaying = null;
    }
    removePlayerCallback(); // playerController is closed by this function
  }

  void pause(Map call) {
    if (whenPaused != null) whenPaused(true);
  }

  void resume(Map call) {
    if (whenPaused != null) whenPaused(false);
  }

  /// Returns true if the specified decoder is supported by flutter_sound on this platform
  Future<bool> isDecoderSupported(Codec codec) async {
    bool result;
    await initialize();
    // For decoding ogg/opus on ios, we need to support two steps :
    // - remux OGG file format to CAF file format (with ffmpeg)
    // - decode CAF/OPPUS (with native Apple AVFoundation)
    if ((codec == Codec.CODEC_OPUS) && (Platform.isIOS)) {
      //if (!await isFFmpegSupported( ))
      //result = false;
      //else
      result = await invokeMethod('isDecoderSupported',
          <String, dynamic>{'codec': Codec.CODEC_CAF_OPUS.index}) as bool;
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
      IOSSessionCategory category, IOSSessionMode mode, int options) async {
    await initialize();
    if (!Platform.isIOS) return false;
    bool r = await invokeMethod('iosSetCategory', <String, dynamic>{
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
    await initialize();
    if (!Platform.isAndroid) return false;
    bool r = await invokeMethod('androidAudioFocusRequest',
        <String, dynamic>{'focusGain': focusGain}) as bool;

    return r;
  }

  ///  The caller can manage his audio focus with this function
  Future<bool> setActive(bool enabled) async {
    await initialize();
    bool r =
        await invokeMethod('setActive', <String, dynamic>{'enabled': enabled})
            as bool;

    return r;
  }

  Future<String> setSubscriptionDuration(double sec) async {
    await initialize();
    String r = await invokeMethod('setSubscriptionDuration', <String, dynamic>{
      'sec': sec,
    }) as String;
    return r;
  }

  void setPlayerCallback() {
    if (_playerController == null) {
      _playerController = StreamController.broadcast();
    }
  }

  void removePlayerCallback() {
    if (_playerController != null) {
      _playerController
        ..add(null)
        ..close();
      _playerController = null;
    }
  }

  Future<String> _startPlayer(
    String method, {
    Codec codec,
    String path,
    Uint8List dataBuffer,
    void Function() whenFinished,
  }) async {
    String result;
    await stopPlayer(); // Just in case
    try {
      audioPlayerFinishedPlaying = whenFinished;

      // If we want to play OGG/OPUS on iOS, we remux the OGG file format to a specific Apple CAF envelope before starting the player.
      // We use FFmpeg for that task.
      if ((Platform.isIOS) &&
          ((codec == Codec.CODEC_OPUS) || (fileExtension(path) == '.opus'))) {
        var tempDir = await getTemporaryDirectory();
        var fout = File('${tempDir.path}/$slotNo-flutter_sound-tmp.caf');
        if (fout.existsSync()) {
          // delete the old temporary file if it exists
          await fout.delete();
        }
        // The following ffmpeg instruction
        // does not decode and re-encode the file.
        // It just remux the OPUS data into an Apple CAF envelope.
        // It is probably very fast
        // and the user will not notice any delay,
        // even with a very large data.

        // This is the price to pay for the Apple stupidity.
        var rc = await flutterSoundHelper.executeFFmpegWithArguments([
          '-loglevel',
          'error',
          '-y',
          '-i',
          path,
          '-c:a',
          'copy',
          fout.path,
        ]); // remux OGG to CAF
        if (rc != 0) return null;
        // Now we can play Apple CAF/OPUS
        result = await invokeMethod(
            'startPlayer', <String, dynamic>{'path': fout.path}) as String;
      } else {
        // build the argument map
        var args = <String, dynamic>{};
        if (path != null) args['path'] = path;
        // Flutter cannot transfer an enum to a native plugin. We use an integer instead
        if (codec != null) args['codec'] = codec.index;
        if (dataBuffer != null) args['dataBuffer'] = dataBuffer;

        result = await invokeMethod(method, args) as String;
      }

      if (result != null) {
        playerState = PlayerState.IS_PLAYING;
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
  }) {
    initialize();
    return _startPlayer('startPlayer',
        path: uri, codec: codec, whenFinished: whenFinished);
  }

  Future<String> startPlayerFromBuffer(
    Uint8List dataBuffer, {
    Codec codec,
    TWhenFinished whenFinished,
  }) async {
    await initialize();
    // If we want to play OGG/OPUS on iOS, we need to remux the OGG file format to a specific Apple CAF envelope before starting the player.
    // We write the data in a temporary file before calling ffmpeg.
    if ((codec == Codec.CODEC_OPUS) && (Platform.isIOS)) {
      await stopPlayer();
      var tempDir = await getTemporaryDirectory();
      File inputFile = File('${tempDir.path}/$slotNo-flutter_sound-tmp.opus');

      if (inputFile.existsSync()) {
        await inputFile.delete();
      }
      inputFile.writeAsBytesSync(
          dataBuffer); // Write the user buffer into the temporary file

      // Now we can play the temporary file
      return await _startPlayer('startPlayer',
          path: inputFile.path, codec: codec, whenFinished: whenFinished);
      // And play something that Apple will be happy with.
    } else {
      return await _startPlayer('startPlayerFromBuffer',
          dataBuffer: dataBuffer, codec: codec, whenFinished: whenFinished);
    }
  }

  Future<String> stopPlayer() async {
    playerState = PlayerState.IS_STOPPED;
    audioPlayerFinishedPlaying = null;

    try {
      removePlayerCallback(); // playerController is closed by this function
      String result =
          await invokeMethod('stopPlayer', <String, dynamic>{}) as String;
      return result;
    } catch (e) {
      print(e);
      rethrow;
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
    if (playerState != PlayerState.IS_PLAYING) {
      await _stopPlayerwithCallback(); // To recover a clean state
      throw PlayerRunningException(
          'Player is not playing.'); // I am not sure that it is good to throw an exception here
    }
    playerState = PlayerState.IS_PAUSED;

    String r = await invokeMethod('pausePlayer', <String, dynamic>{}) as String;
    return r;
  }

  Future<String> resumePlayer() async {
    if (playerState != PlayerState.IS_PAUSED) {
      await _stopPlayerwithCallback(); // To recover a clean state
      throw PlayerRunningException(
          'Player is not paused.'); // I am not sure that it is good to throw an exception here
    }
    playerState = PlayerState.IS_PLAYING;
    String r =
        await invokeMethod('resumePlayer', <String, dynamic>{}) as String;
    return r;
  }

  Future<String> seekToPlayer(int milliSecs) async {
    await initialize();
    String r = await invokeMethod('seekToPlayer', <String, dynamic>{
      'sec': milliSecs,
    }) as String;
    return r;
  }

  Future<String> setVolume(double volume) async {
    await initialize();
    var indexedVolume = Platform.isIOS ? volume * 100 : volume;
    if (volume < 0.0 || volume > 1.0) {
      throw RangeError('Value of volume should be between 0.0 and 1.0.');
    }

    String r = await invokeMethod('setVolume', <String, dynamic>{
      'volume': indexedVolume,
    }) as String;
    return r;
  }
}

class PlayerRunningException implements Exception {
  final String message;

  PlayerRunningException(this.message);
}
