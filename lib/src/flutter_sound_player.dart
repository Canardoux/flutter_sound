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
import 'dart:convert' hide Codec;
import 'dart:io';
import 'dart:typed_data' show Uint8List;

import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'codec.dart';
import 'flutter_sound_helper.dart';
import 'playback_disposition.dart';
import 'plugins/flutter_player_plugin.dart';

///
enum PlayerState {
  ///
  isStopped,

  /// Player is stopped
  isPlaying,

  ///
  isPaused,
}

///
enum IOSSessionCategory {
  ///
  ambient,

  ///
  multiRoute,

  ///
  playAndRecord,

  ///
  playback,

  ///
  record,

  ///
  soloAambient,
}

///
final List<String> iosSessionCategory = [
  'AVAudioSessionCategoryAmbient',
  'AVAudioSessionCategoryMultiRoute',
  'AVAudioSessionCategoryPlayAndRecord',
  'AVAudioSessionCategoryPlayback',
  'AVAudioSessionCategoryRecord',
  'AVAudioSessionCategorySoloAmbient',
];

///
enum IOSSessionMode {
  ///
  defaultMode,

  ///
  gameChat,

  ///
  measurement,

  ///
  moviePlayback,

  ///
  spokenAudio,

  ///
  videoChat,

  ///
  videoRecording,

  ///
  voiceChat,

  ///
  voicePrompt,
}
final List<String> _iosSessionMode = [
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

typedef TWhenFinished = void Function();
typedef TwhenPaused = void Function(bool paused);
typedef TonSkip = void Function();
typedef TupdateProgress = void Function(int current, int max);

FlautoPlayerPlugin _flautoPlayerPlugin; // Singleton, lazy initialized
/// Channel slots for communicating with native code.
List<PlayerPluginConnector> slots = [];

/// Return the file extension for the given path.
/// path can be null. We return null in this case.
String fileExtension(String path) {
  if (path == null) return null;
  var r = p.extension(path);
  return r;
}

/// Provides the ability to playback audio from
/// a variety of sources including:
/// File
/// Buffer
/// Assets
/// URL.
class FlutterSoundPlayer {
  bool _isInited = false;

  ///
  PlayerState playerState = PlayerState.isStopped;
  StreamController<PlaybackDisposition> _playerController;

  /// User callback "whenFinished:"
  TWhenFinished audioPlayerFinishedPlaying;

  /// User callback "whenPaused:"
  TwhenPaused whenPaused;

  ///
  int slotNo;

  /// Provides a stream of dispositions which
  /// provide updated position and duration
  /// as the audio is played.
  /// The duration may start out as zero until the
  /// media becomes available.
  /// The [interval] dictates the minimum interval between events
  /// been sent to the stream.
  /// In most case the interval will be adheared to fairly closely.
  /// If you pause the audio then no updates will be sent to the
  /// stream.
  Stream<PlaybackDisposition> dispositionStream(Duration interval) {
    _setSubscriptionDuration(interval);
    return _playerController != null ? _playerController.stream : null;
  }

  /// [true] if the player is currently playing audio
  bool get isPlaying => playerState == PlayerState.isPlaying;

  /// [true] if the player is playing but the audio is paused
  bool get isPaused => playerState == PlayerState.isPaused;

  /// [true] if the player is stopped.
  bool get isStopped => playerState == PlayerState.isStopped;

  /// internal method.
  FlautoPlayerPlugin getPlugin() => _flautoPlayerPlugin;

  /// internal method.
  Future<dynamic> invokeMethod(
      String methodName, Map<String, dynamic> call) async {
    call['slotNo'] = slotNo;
    return getPlugin().invokeMethod(methodName, call);
  }

  /// internal method
  Future<FlutterSoundPlayer> initialize() async {
    if (!_isInited) {
      _isInited = true;

      if (_flautoPlayerPlugin == null) {
        _flautoPlayerPlugin = FlautoPlayerPlugin(); // The lazy singleton
      }
      slotNo = getPlugin().lookupEmptySlot(PlayerPluginConnector(this));
      await invokeMethod('initializeMediaPlayer', <String, dynamic>{});
    }
    return this;
  }

  /// call this method once you are down with the player
  /// so that it can release all of the attached resources.
  Future<void> release() async {
    if (_isInited) {
      _isInited = false;
      await stopPlayer();
      removePlayerCallback(); // playerController is closed by this function
      await invokeMethod('releaseMediaPlayer', <String, dynamic>{});
      await _playerController?.close();

      getPlugin().freeSlot(slotNo);
      slotNo = null;
    }
  }

  void _updateProgress(Map call) {
    var arg = call['arg'] as String;
    var result = jsonDecode(arg) as Map<String, dynamic>;
    _playerController?.add(PlaybackDisposition.fromJSON(result));
  }

  /// internal method.
  void audioPlayerFinished(PlaybackDisposition status) {
    // if we have finished then position should be at the end.
    status.position = status.duration;
    _playerController?.add(status);

    playerState = PlayerState.isStopped;
    if (audioPlayerFinishedPlaying != null) {
      audioPlayerFinishedPlaying();
      audioPlayerFinishedPlaying = null;
    }
    removePlayerCallback(); // playerController is closed by this function
  }

  /// handles a pause coming up from the player
  void _pause(Map call) {
    if (whenPaused != null) whenPaused(true);
  }

  /// handles a resume coming up from the player
  void _resume(Map call) {
    if (whenPaused != null) whenPaused(false);
  }

  /// Returns true if the specified decoder is supported
  ///  by flutter_sound on this platform
  Future<bool> isDecoderSupported(Codec codec) async {
    bool result;
    await initialize();
    // For decoding ogg/opus on ios, we need to support two steps :
    // - remux OGG file format to CAF file format (with ffmpeg)
    // - decode CAF/OPPUS (with native Apple AVFoundation)
    if ((codec == Codec.codecOpus) && (Platform.isIOS)) {
      //if (!await isFFmpegSupported( ))
      //result = false;
      //else
      result = await invokeMethod('isDecoderSupported',
          <String, dynamic>{'codec': Codec.codecCafOpus.index}) as bool;
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
  ///    probably before startRecorder or startPlayer
  /// and stopPlayer and stopRecorder
  Future<bool> iosSetCategory(
      IOSSessionCategory category, IOSSessionMode mode, int options) async {
    await initialize();
    if (!Platform.isIOS) return false;
    var r = await invokeMethod('iosSetCategory', <String, dynamic>{
      'category': iosSessionCategory[category.index],
      'mode': _iosSessionMode[mode.index],
      'options': options
    }) as bool;

    return r;
  }

  /// For Android only.
  /// If this function is not called, everything is
  ///  managed by default by flutter_sound.
  /// If this function is called, it is probably called
  ///  just once when the app starts.
  /// After calling this function, the caller is responsible
  ///  for using correctly setActive
  ///    probably before startRecorder or startPlayer
  /// and stopPlayer and stopRecorder
  Future<bool> androidAudioFocusRequest(int focusGain) async {
    await initialize();
    if (!Platform.isAndroid) return false;
    var r = await invokeMethod('androidAudioFocusRequest',
        <String, dynamic>{'focusGain': focusGain}) as bool;

    return r;
  }

  ///  The caller can manage his audio focus with this function
  Future<bool> setActive(bool enabled) async {
    await initialize();
    var r =
        await invokeMethod('setActive', <String, dynamic>{'enabled': enabled})
            as bool;

    return r;
  }

  Future<String> _setSubscriptionDuration(Duration interval) async {
    await initialize();
    var r = await invokeMethod('setSubscriptionDuration', <String, dynamic>{
      'sec': interval.inSeconds.toDouble(),
    }) as String;
    return r;
  }

  ///
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
          ((codec == Codec.codecOpus) || (fileExtension(path) == '.opus'))) {
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
        var rc = await FlutterSoundHelper().executeFFmpegWithArguments([
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
        // Flutter cannot transfer an enum to a native plugin.
        // We use an integer instead
        if (codec != null) args['codec'] = codec.index;
        if (dataBuffer != null) args['dataBuffer'] = dataBuffer;

        result = await invokeMethod(method, args) as String;
      }

      if (result != null) {
        playerState = PlayerState.isPlaying;
      }

      return result;
    } on Object catch (err) {
      audioPlayerFinishedPlaying = null;
      throw Exception(err);
    }
  }

  /// Starts playback of the give URL
  /// The [uri] of the file to download and playback
  /// The [codec] of the file the [uri] points to.
  Future<String> startPlayer(
    String uri, {
    Codec codec,
    TWhenFinished whenFinished,
  }) async {
    await initialize();
    return _startPlayer('startPlayer',
        path: uri, codec: codec, whenFinished: whenFinished);
  }

  /// Starts plaback from a buffer.
  /// The [dataBuffer] that containes the media.
  /// The [codec] that the media is encoded with.
  /// If you pass [whenFinished] you method will be called
  /// when playback completes.
  Future<String> startPlayerFromBuffer(
    Uint8List dataBuffer, {
    Codec codec,
    TWhenFinished whenFinished,
  }) async {
    await initialize();
    // If we want to play OGG/OPUS on iOS, we need to remux the OGG file format to a specific Apple CAF envelope before starting the player.
    // We write the data in a temporary file before calling ffmpeg.
    if ((codec == Codec.codecOpus) && (Platform.isIOS)) {
      await stopPlayer();
      var tempDir = await getTemporaryDirectory();
      var inputFile = File('${tempDir.path}/$slotNo-flutter_sound-tmp.opus');

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

  /// Stops playback.
  /// TODO document what this method returns.
  Future<String> stopPlayer() async {
    playerState = PlayerState.isStopped;
    audioPlayerFinishedPlaying = null;

    try {
      removePlayerCallback(); // playerController is closed by this function
      var result =
          await invokeMethod('stopPlayer', <String, dynamic>{}) as String;
      return result;
    } on Object catch (e) {
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

  /// Pauses playback.
  /// TODO document what this method returns.
  /// You must only call this when audio is playing.
  Future<String> pausePlayer() async {
    if (playerState != PlayerState.isPlaying) {
      await _stopPlayerwithCallback(); // To recover a clean state

      // I am not sure that it is good to throw an exception here
      throw PlayerRunningException('Player is not playing.');
    }
    playerState = PlayerState.isPaused;

    return await invokeMethod('pausePlayer', <String, dynamic>{}) as String;
  }

  /// Resumes playback.
  /// TODO document what this method returns
  /// You must only call this when audio is paused.
  Future<String> resumePlayer() async {
    if (playerState != PlayerState.isPaused) {
      await _stopPlayerwithCallback(); // To recover a clean state
      // I am not sure that it is good to throw an exception here
      throw PlayerRunningException('Player is not paused.');
    }
    playerState = PlayerState.isPlaying;
    return await invokeMethod('resumePlayer', <String, dynamic>{}) as String;
  }

  /// Moves the current playback position to the given offset in the
  /// recording.
  /// [offset] is the position in the recording to set the playback
  /// location from.
  /// TODO: can you call this before calling startPlayer?
  Future<String> seekToPlayer(Duration offset) async {
    await initialize();
    return await invokeMethod('seekToPlayer', <String, dynamic>{
      'sec': offset.inMilliseconds,
    }) as String;
  }

  /// Sets the playback volume
  /// The [volume] must be in the range 0.0 to 1.0.
  Future<String> setVolume(double volume) async {
    await initialize();
    var indexedVolume = Platform.isIOS ? volume * 100 : volume;
    if (volume < 0.0 || volume > 1.0) {
      throw RangeError('Value of volume should be between 0.0 and 1.0.');
    }

    return await invokeMethod('setVolume', <String, dynamic>{
      'volume': indexedVolume,
    }) as String;
  }
}

/// Class exists to hide internal methods from the public api
class PlayerPluginConnector {
  final FlutterSoundPlayer _player;

  ///
  PlayerPluginConnector(this._player);

  ///
  void updateProgress(Map arguments) {
    _player._updateProgress(arguments);
  }

  ///
  void audioPlayerFinished(PlaybackDisposition status) =>
      _player.audioPlayerFinished(status);

  ///
  void pause(Map arguments) => _player._pause(arguments);

  ///
  void resume(Map arguments) => _player._resume(arguments);
}

/// The player was in an unexpected state when you tried
/// to change it state.
/// e.g. you tried to pause when the player was stopped.
class PlayerRunningException implements Exception {
  final String _message;

  ///
  PlayerRunningException(this._message);

  String toString() => _message;
}
