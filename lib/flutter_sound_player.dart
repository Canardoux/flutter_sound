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

import 'package:flutter/services.dart';
import 'package:flutter_sound/android_encoder.dart';
import 'package:flutter_sound/ios_quality.dart';
import 'package:flutter_sound/flauto.dart';
import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

enum t_PLAYER_STATE {
  IS_STOPPED,
  IS_PLAYING,
  IS_PAUSED,
}

enum t_IOS_SESSION_CATEGORY {
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

enum t_IOS_SESSION_MODE {
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

typedef void t_whenFinished();
typedef void t_whenPaused(bool paused);
typedef void t_onSkip();
typedef void t_updateProgress(int current, int max);

FlautoPlayerPlugin flautoPlayerPlugin; // Singleton, lazy initialized
List<FlutterSoundPlayer> slots = [];

class FlautoPlayerPlugin {
  MethodChannel channel;

  FlautoPlayerPlugin() {
    setCallback();
  }

  void setCallback() {
    channel = const MethodChannel('xyz.canardoux.flauto_player');
    channel.setMethodCallHandler((MethodCall call) {
      // This lambda function is necessary because channelMethodCallHandler is a virtual function (polymorphism)
      return channelMethodCallHandler(call);
    });
  }

  int lookupEmptySlot(FlutterSoundPlayer aPlayer) {
    for (int i = 0; i < slots.length; ++i) {
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
    return getChannel().invokeMethod(methodName, call);
  }

  Future<dynamic> channelMethodCallHandler(MethodCall call) // This procedure is superCharged in "flauto"
  {
    int slotNo = call.arguments['slotNo'];
    FlutterSoundPlayer aPlayer = slots[slotNo];
    switch (call.method) {
      case "updateProgress":
        {
          aPlayer.updateProgress(call.arguments);
        }
        break;

      case "audioPlayerFinishedPlaying":
        {
          aPlayer.audioPlayerFinished(call.arguments);
        }
        break;

      case 'pause':
        {
          aPlayer.pause(call.arguments);
        }
        break;

      case 'resume':
        {
          aPlayer.resume(call.arguments);
        }
        break;

/*
                        case 'skipForward':
                                {
                                        aPlayer.skipBackward( call.arguments );
                                }
                                break;

                        case 'skipBackward':
                                {}
                                break;
*/
      default:
        throw new ArgumentError('Unknown method ${call.method}');
    }
    return null;
  }
}

/// Return the file extension for the given path.
/// path can be null. We return null in this case.
String fileExtension(String path) {
  if (path == null) return null;
  String r = p.extension(path);
  return r;
}

class FlutterSoundPlayer {
  bool isInited = false;
  t_PLAYER_STATE playerState = t_PLAYER_STATE.IS_STOPPED;
  StreamController<PlayStatus> playerController;
  t_whenFinished audioPlayerFinishedPlaying; // User callback "whenFinished:"
  t_whenPaused whenPause; // User callback "whenPaused:"
  t_updateProgress onUpdateProgress;
  int slotNo = null;

  Stream<PlayStatus> get onPlayerStateChanged => playerController != null ? playerController.stream : null;

  bool get isPlaying => playerState == t_PLAYER_STATE.IS_PLAYING;

  bool get isPaused => playerState == t_PLAYER_STATE.IS_PAUSED;

  bool get isStopped => playerState == t_PLAYER_STATE.IS_STOPPED;

  FlutterSoundPlayer() {
  }

  FlautoPlayerPlugin getPlugin() => flautoPlayerPlugin;

  Future<dynamic> invokeMethod(String methodName, Map<String, dynamic> call) async {
    call['slotNo'] = slotNo;
    return getPlugin().invokeMethod(methodName, call);
  }

  Future<FlutterSoundPlayer> initialize() async {
    if (!isInited) {
      isInited = true;
      if (flautoPlayerPlugin == null) flautoPlayerPlugin = FlautoPlayerPlugin(); // The lazy singleton
      slotNo = getPlugin().lookupEmptySlot(this);
      await invokeMethod('initializeMediaPlayer', {});
    }
    return this;
  }

  Future<void> release() async {
    isInited = false;
    await stopPlayer();
    _removePlayerCallback();
    await invokeMethod('releaseMediaPlayer', {});
    getPlugin().freeSlot(slotNo);
    slotNo = null;
  }

  void updateProgress(Map call) {
    String arg = call['arg'];
    Map<String, dynamic> result = jsonDecode(arg);
    if (playerController != null) playerController.add(new PlayStatus.fromJSON(result));
  }

  void audioPlayerFinished(Map call) {
    String arg = call['arg'];

    Map<String, dynamic> result = jsonDecode(arg);
    PlayStatus status = new PlayStatus.fromJSON(result);
    if (status.currentPosition != status.duration) {
      status.currentPosition = status.duration;
    }
    if (playerController != null) playerController.add(status);

    playerState = t_PLAYER_STATE.IS_STOPPED;
    _removePlayerCallback();
    if (audioPlayerFinishedPlaying != null) audioPlayerFinishedPlaying();
  }

  void pause(Map call) {
    if (whenPause != null) whenPause(true);
  }

  void resume(Map call) {
    if (whenPause != null) whenPause(false);
  }
/*
        void skipBackward( Map call)
        {
                if (onSkipBackward != null) onSkipBackward( );
        }
*/

  /// Returns true if the specified decoder is supported by flutter_sound on this platform
  Future<bool> isDecoderSupported(t_CODEC codec) async {
    bool result;
    // For decoding ogg/opus on ios, we need to support two steps :
    // - remux OGG file format to CAF file format (with ffmpeg)
    // - decode CAF/OPPUS (with native Apple AVFoundation)
    if ((codec == t_CODEC.CODEC_OPUS) && (Platform.isIOS)) {
      //if (!await isFFmpegSupported( ))
      //result = false;
      //else
      result = await invokeMethod('isDecoderSupported', <String, dynamic>{'codec': t_CODEC.CODEC_CAF_OPUS.index});
    } else
      result = await invokeMethod('isDecoderSupported', <String, dynamic>{'codec': codec.index});
    return result;
  }

  /// For iOS only.
  /// If this function is not called, everything is managed by default by flutter_sound.
  /// If this function is called, it is probably called just once when the app starts.
  /// After calling this function, the caller is responsible for using correctly setActive
  ///    probably before startRecorder or startPlayer, and stopPlayer and stopRecorder
  Future<bool> iosSetCategory(t_IOS_SESSION_CATEGORY category, t_IOS_SESSION_MODE mode, int options) async {
    if (!Platform.isIOS) return false;
    bool r = await invokeMethod('iosSetCategory', <String, dynamic>{'category': iosSessionCategory[category.index], 'mode': iosSessionMode[mode.index], 'options': options});
    return r;
  }

  /// For Android only.
  /// If this function is not called, everything is managed by default by flutter_sound.
  /// If this function is called, it is probably called just once when the app starts.
  /// After calling this function, the caller is responsible for using correctly setActive
  ///    probably before startRecorder or startPlayer, and stopPlayer and stopRecorder
  Future<bool> androidAudioFocusRequest(int focusGain) async {
    if (!Platform.isAndroid) return false;
    bool r = await invokeMethod('androidAudioFocusRequest', <String, dynamic>{'focusGain': focusGain});
    return r;
  }

  ///  The caller can manage his audio focus with this function
  Future<bool> setActive(bool enabled) async {
    bool r = await invokeMethod('setActive', <String, dynamic>{'enabled': enabled});
    return r;
  }

  Future<String> setSubscriptionDuration(double sec) async {
    String r = await invokeMethod('setSubscriptionDuration', <String, dynamic>{
      'sec': sec,
    });
    return r;
  }

  Future<void> setPlayerCallback() async {
    if (playerController == null) {
      playerController = new StreamController.broadcast();
    }
  }

  void _removePlayerCallback() {
    if (playerController != null) {
      playerController
        ..add(null)
        ..close();
      playerController = null;
    }
  }

  Future<String> _startPlayer(String method, Map<String, dynamic> what) async {
    String result;
    await stopPlayer(); // Just in case
    try {
      t_CODEC codec = what['codec'];
      String path = what['path']; // can be null
      if (codec != null) what['codec'] = codec.index; // Flutter cannot transfer an enum to a native plugin. We use an integer instead

      // If we want to play OGG/OPUS on iOS, we remux the OGG file format to a specific Apple CAF envelope before starting the player.
      // We use FFmpeg for that task.
      if ((Platform.isIOS) && ((codec == t_CODEC.CODEC_OPUS) || (fileExtension(path) == '.opus'))) {
        Directory tempDir = await getTemporaryDirectory();
        File fout = File('${tempDir.path}/$slotNo-flutter_sound-tmp.caf');
        if (fout.existsSync()) // delete the old temporary file if it exists
          await fout.delete();
        // The following ffmpeg instruction does not decode and re-encode the file. It just remux the OPUS data into an Apple CAF envelope.
        // It is probably very fast and the user will not notice any delay, even with a very large data.
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
        audioPlayerFinishedPlaying = what['whenFinished'];
        what['whenFinished'] = null; // We must remove this parameter because _channel.invokeMethod() does not like it
        result = await invokeMethod('startPlayer', {'path': fout.path});
      } else {
        audioPlayerFinishedPlaying = what['whenFinished'];
        what['whenFinished'] = null; // We must remove this parameter because _channel.invokeMethod() does not like it
        result = await invokeMethod(method, what);
      }

      if (result != null) {
        print('startPlayer result: $result');
        setPlayerCallback();

        playerState = t_PLAYER_STATE.IS_PLAYING;
      }

      return result;
    } catch (err) {
      audioPlayerFinishedPlaying = null;
      throw Exception(err);
    }
  }

  Future<String> startPlayer(
    String uri, {
    t_CODEC codec,
    whenFinished(),
  }) =>
      _startPlayer('startPlayer', {
        'path': uri,
        'codec': codec,
        'whenFinished': whenFinished,
      });

  Future<String> startPlayerFromBuffer(
    Uint8List dataBuffer, {
    t_CODEC codec,
    whenFinished(),
  }) async {
    // If we want to play OGG/OPUS on iOS, we need to remux the OGG file format to a specific Apple CAF envelope before starting the player.
    // We write the data in a temporary file before calling ffmpeg.
    if ((codec == t_CODEC.CODEC_OPUS) && (Platform.isIOS)) {
      await stopPlayer();
      Directory tempDir = await getTemporaryDirectory();
      File inputFile = File('${tempDir.path}/$slotNo-flutter_sound-tmp.opus');
      if (inputFile.existsSync()) await inputFile.delete();
      inputFile.writeAsBytesSync(dataBuffer); // Write the user buffer into the temporary file
      // Now we can play the temporary file
      return await _startPlayer('startPlayer', {
        'path': inputFile.path,
        'codec': codec,
        'whenFinished': whenFinished,
      }); // And play something that Apple will be happy with.
    } else
      return await _startPlayer('startPlayerFromBuffer', {
        'dataBuffer': dataBuffer,
        'codec': codec,
        'whenFinished': whenFinished,
      });
  }

  Future<String> stopPlayer() async {
    playerState = t_PLAYER_STATE.IS_STOPPED;
    audioPlayerFinishedPlaying = null;

    try {
      String result = await invokeMethod('stopPlayer', {});
      return result;
    } catch (e) {}
    return null;
  }

  Future<String> _stopPlayerwithCallback() async {
    if (audioPlayerFinishedPlaying != null) {
      audioPlayerFinishedPlaying();
      audioPlayerFinishedPlaying = null;
    }

    return stopPlayer();
  }

  Future<String> pausePlayer() async {
    if (playerState != t_PLAYER_STATE.IS_PLAYING) {
      _stopPlayerwithCallback(); // To recover a clean state
      throw PlayerRunningException('Player is not playing.'); // I am not sure that it is good to throw an exception here
    }
    playerState = t_PLAYER_STATE.IS_PAUSED;

    String r = await invokeMethod('pausePlayer', {});
    return r;
  }

  Future<String> resumePlayer() async {
    if (playerState != t_PLAYER_STATE.IS_PAUSED) {
      _stopPlayerwithCallback(); // To recover a clean state
      throw PlayerRunningException('Player is not paused.'); // I am not sure that it is good to throw an exception here
    }
    playerState = t_PLAYER_STATE.IS_PLAYING;
    String r = await invokeMethod('resumePlayer', {});
    return r;
  }

  Future<String> seekToPlayer(int milliSecs) async {
    String r = await invokeMethod('seekToPlayer', <String, dynamic>{
      'sec': milliSecs,
    });
    return r;
  }

  Future<String> setVolume(double volume) async {
    double indexedVolume = Platform.isIOS ? volume * 100 : volume;
    if (volume < 0.0 || volume > 1.0) {
      throw RangeError('Value of volume should be between 0.0 and 1.0.');
    }

    String r = await invokeMethod('setVolume', <String, dynamic>{
      'volume': indexedVolume,
    });
    return r;
  }
}

class PlayStatus {
  final double duration;
  double currentPosition;

  PlayStatus.fromJSON(Map<String, dynamic> json)
      : duration = double.parse(json['duration']),
        currentPosition = double.parse(json['current_position']);

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
