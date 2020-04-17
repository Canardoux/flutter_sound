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

import 'package:flutter/foundation.dart';

import 'codec.dart';
import 'ios/ios_session_category.dart';
import 'ios/ios_session_mode.dart';
import 'playback_disposition.dart';
import 'plugins/base_plugin.dart';
import 'plugins/sound_player_plugin.dart';
import 'track.dart';
import 'util/codec_conversions.dart';
import 'util/file_management.dart' as fm;
import 'util/temp_media_file.dart';

///
enum PlayerState {
  ///
  isStopped,

  /// Player is stopped
  isPlaying,

  ///
  isPaused,
}

typedef TWhenFinished = void Function();
typedef TwhenPaused = void Function(bool paused);
typedef TonSkip = void Function();
typedef TupdateProgress = void Function(int current, int max);

/// Provides the ability to playback audio from
/// a variety of sources including:
/// File
/// Buffer
/// Assets
/// URL.
class SoundPlayer {
  ///
  TonSkip onSkipForward; // User callback "whenPaused:"
  ///
  TonSkip onSkipBackward; // User callback "whenPaused:"

  bool _isInited = false;

  /// class to communicate with the plugin.
  /// This allows us to hide public methods
  /// from the public api.
  SoundPlayerProxy _connector;

  final List<TempMediaFile> _tempMediaFiles = [];

  ///
  PlayerState playerState = PlayerState.isStopped;
  StreamController<PlaybackDisposition> _playerController;

  /// User callback "whenFinished:"
  TWhenFinished _whenFinished;

  /// User callback "whenPaused:"
  TwhenPaused whenPaused;

  /// Create a
  SoundPlayer() {
    _connector = SoundPlayerProxy(this);
    SoundPlayerPlugin().register(_connector);
  }

  Future<dynamic> _invokeMethod(
      String methodName, Map<String, dynamic> args) async {
    return await SoundPlayerPlugin().invokeMethod(_connector, methodName, args);
  }

  /// internal method
  Future<SoundPlayer> _initialize() async {
    if (!_isInited) {
      _isInited = true;

      await _invokeMethod('initializeMediaPlayer', <String, dynamic>{});

      /// TODO I think this is unnecessary.
      onSkipBackward = null;
      onSkipForward = null;
    }
    return this;
  }

  /// call this method once you are down with the player
  /// so that it can release all of the attached resources.
  Future<void> release() async {
    if (_isInited) {
      _isInited = false;
      // Stop the player playback before releasing
      await stopPlayer();
      closeDispositionStream(); // playerController is closed by this function
      onSkipBackward = null;
      onSkipForward = null;

      await _invokeMethod('releaseMediaPlayer', <String, dynamic>{});
      SoundPlayerPlugin().release(_connector);
    }
  }

  /// TODO implement these methods so a user
  /// can perform a skip from the api.
  void skipForward(Map call) {
    throw NotImplementedException('skipForward is not currently supported');
  }

  /// TODO implement these methods so a user
  /// can perform a skip from the api.
  void skipBackward(Map call) {
    throw NotImplementedException('skipForward is not currently supported');
  }

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

  void _updateProgress(String jsonArgs) {
    var result = jsonDecode(jsonArgs) as Map<String, dynamic>;
    _playerController?.add(PlaybackDisposition.fromJSON(result));
  }

  /// internal method.
  /// Called by the Platform plug to notify us that
  /// audio has finished playing.
  void _audioPlayerFinished(PlaybackDisposition status) {
    // if we have finished then position should be at the end.
    status.position = status.duration;
    _playerController?.add(status);

    playerState = PlayerState.isStopped;
    if (_whenFinished != null) {
      _whenFinished();
      _whenFinished = null;
    }

    _deleteTempFiles();
    closeDispositionStream(); // playerController is closed by this function
  }

  /// delete any tempoary media files we created whilst recording.
  void _deleteTempFiles() {
    for (var tmp in _tempMediaFiles) {
      tmp.delete();
    }
    _tempMediaFiles.clear();
  }

  /// handles a pause coming up from the player
  void _onPaused() {
    if (whenPaused != null) whenPaused(true);
  }

  /// handles a resume coming up from the player
  void _onResumed() {
    if (whenPaused != null) whenPaused(false);
  }

  /// Returns true if the specified decoder is supported
  ///  by flutter_sound on this platform
  Future<bool> isSupported(Codec codec) async {
    bool result;
    await _initialize();
    // For decoding ogg/opus on ios, we need to support two steps :
    // - remux OGG file format to CAF file format (with ffmpeg)
    // - decode CAF/OPPUS (with native Apple AVFoundation)
    if ((codec == Codec.codecOpus) && (Platform.isIOS)) {
      codec = Codec.codecCafOpus;
    }
    result = await _invokeMethod(
        'isDecoderSupported', <String, dynamic>{'codec': codec.index}) as bool;
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
  ///
  /// TODO
  /// Is this in the correct spot if it is only called once?
  /// Should we have a configuration object that sets
  /// up global options?
  Future<bool> iosSetCategory(
      IOSSessionCategory category, IOSSessionMode mode, int options) async {
    await _initialize();
    if (!Platform.isIOS) return false;
    var r = await _invokeMethod('iosSetCategory', <String, dynamic>{
      'category': iosSessionCategory[category.index],
      'mode': iosSessionMode[mode.index],
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
  ///
  /// TODO
  /// Is this in the correct spot if it is only called once?
  /// Should we have a configuration object that sets
  /// up global options?
  Future<bool> androidAudioFocusRequest(int focusGain) async {
    await _initialize();
    if (!Platform.isAndroid) return false;
    var r = await _invokeMethod('androidAudioFocusRequest',
        <String, dynamic>{'focusGain': focusGain}) as bool;

    return r;
  }

  ///  The caller can manage his audio focus with this function
  /// TODO
  /// Is this in the correct spot if it is only called once?
  /// Should we have a configuration object that sets
  /// up global options?
  Future<bool> setActive({bool enabled}) async {
    await _initialize();
    var r =
        await _invokeMethod('setActive', <String, dynamic>{'enabled': enabled})
            as bool;

    return r;
  }

  /// TODO does this need to be exposed?
  /// The simple action of stopping the playback may be sufficient
  /// Given the user has to call stop
  void closeDispositionStream() {
    if (_playerController != null) {
      _playerController
        ..add(null)
        ..close();
      _playerController = null;
    }
  }

  /// Starts playback of the give URL
  /// The [uri] of the file to download and playback
  /// The [codec] of the file the [uri] points to.
  /// If passed the [whenFinished] callback will be called
  /// once the playback completes.
  /// If you set [showTrack] to true then the builtin
  /// OS audio controls will be displayed.

  Future<void> startPlayer(
    String uri, {
    Codec codec,
    TWhenFinished whenFinished,
  }) async {
    await _startPlayer(
      path: uri,
      codec: codec,
      whenFinished: whenFinished,
    );
  }

  /// Starts plaback from a buffer.
  /// The [dataBuffer] that containes the media.
  /// The [codec] that the media is encoded with.
  /// If you pass [whenFinished] you method will be called
  /// when playback completes.

  Future<void> startPlayerFromBuffer(
    Uint8List dataBuffer, {
    Codec codec,
    TWhenFinished whenFinished,
  }) async {
    assert(_tempMediaFiles.isEmpty);
    var tempMediaFile = TempMediaFile.fromBuffer(dataBuffer);
    _tempMediaFiles.add(tempMediaFile);

    await _startPlayer(
      path: tempMediaFile.path,
      codec: codec,
      whenFinished: whenFinished,
    );
  }

  Future<void> _startPlayer({
    @required String path,
    Codec codec = Codec.defaultCodec,
    void Function() whenFinished,
    void Function(bool) whenPaused,
    bool showTrack = false,
    TonSkip onSkipForward,
    TonSkip onSkipBackward,
  }) async {
    await _initialize();

    if (!isStopped) {
      throw PlayerInvalidStateException("The player must not be running.");
    }

    // Check the current codec is supported on this platform
    if (!await isSupported(codec)) {
      throw PlayerInvalidStateException(
          'The selected codec is not supported on '
          'this platform.');
    }

    _whenFinished = whenFinished;

    // If we want to play OGG/OPUS on iOS, we remux the OGG file format to a specific Apple CAF envelope before starting the player.
    // We use FFmpeg for that task.
    if ((Platform.isIOS) &&
        ((codec == Codec.codecOpus) || (fm.fileExtension(path) == '.opus'))) {
      var tempMediaFile =
          TempMediaFile(await CodecConversions.opusToCafOpus(path));
      _tempMediaFiles.add(tempMediaFile);
      path = tempMediaFile.path;
    }

    // build the argument map
    var args = <String, dynamic>{};
    args['path'] = path;
    // Flutter cannot transfer an enum to a native plugin.
    // We use an integer instead
    args['codec'] = codec.index;

    await _invokeMethod('startPlayer', args);
    playerState = PlayerState.isPlaying;
  }

  /// Plays the given [track]. [canSkipForward] and [canSkipBackward] must be
  /// passed to provide information on whether the user can skip to the next
  /// or to the previous song in the lock screen controls.
  ///
  /// This method should only be used if the player has been initialize
  /// with the audio player specific features.
  Future<void> startPlayerFromTrack(
    Track track, {
    TWhenFinished whenFinished,
    TwhenPaused whenPaused,
    TonSkip onSkipForward,
    TonSkip onSkipBackward,
  }) async {
    assert(_tempMediaFiles.isEmpty);
    final trackMap = await track.toMap();

    _whenFinished = whenFinished;
    this.whenPaused = whenPaused;
    this.onSkipForward = onSkipForward;
    this.onSkipBackward = onSkipBackward;
    await _invokeMethod('startPlayerFromTrack', <String, dynamic>{
      'track': trackMap,
      'canPause': whenPaused != null,
      'canSkipForward': onSkipForward != null,
      'canSkipBackward': onSkipBackward != null,
    }) as String;

    playerState = PlayerState.isPlaying;
  }

  /// Stops playback.
  Future<void> stopPlayer() async {
    playerState = PlayerState.isStopped;

    try {
      closeDispositionStream(); // playerController is closed by this function
      await _invokeMethod('stopPlayer', <String, dynamic>{}) as String;

      if (_whenFinished != null) _whenFinished();
      _deleteTempFiles();
    } on Object catch (e) {
      print(e);
      rethrow;
    }
  }

  /// Pauses playback.
  /// If you call this and the audio is not playing
  /// a [PlayerInvalidStateException] will be thrown.
  Future<void> pausePlayer() async {
    if (playerState != PlayerState.isPlaying) {
      throw PlayerInvalidStateException('Player is not playing.');
    }
    playerState = PlayerState.isPaused;

    return await _invokeMethod('pausePlayer', <String, dynamic>{}) as String;
  }

  /// Resumes playback.
  /// If you call this when audio is not paused
  /// then a [PlayerInvalidStateException] will be thrown.
  Future<void> resumePlayer() async {
    if (playerState != PlayerState.isPaused) {
      throw PlayerInvalidStateException('Player is not paused.');
    }
    playerState = PlayerState.isPlaying;
    return await _invokeMethod('resumePlayer', <String, dynamic>{}) as String;
  }

  /// Moves the current playback position to the given offset in the
  /// recording.
  /// [offset] is the position in the recording to set the playback
  /// location from.
  /// TODO: can you call this before calling startPlayer?
  Future<void> seekToPlayer(Duration offset) async {
    await _initialize();
    await _invokeMethod('seekToPlayer', <String, dynamic>{
      'sec': offset.inMilliseconds,
    }) as String;
  }

  /// Sets the playback volume
  /// The [volume] must be in the range 0.0 to 1.0.
  Future<void> setVolume(double volume) async {
    await _initialize();
    var indexedVolume = Platform.isIOS ? volume * 100 : volume;
    if (volume < 0.0 || volume > 1.0) {
      throw RangeError('Value of volume should be between 0.0 and 1.0.');
    }

    await _invokeMethod('setVolume', <String, dynamic>{
      'volume': indexedVolume,
    }) as String;
  }

  Future<void> _setSubscriptionDuration(Duration interval) async {
    await _initialize();
    await _invokeMethod('setSubscriptionDuration', <String, dynamic>{
      'sec': interval.inSeconds.toDouble(),
    }) as String;
  }
}

/// Class exists to hide internal methods from the public api
class SoundPlayerProxy implements Proxy {
  final SoundPlayer _player;

  ///
  SoundPlayerProxy(this._player);

  ///
  void updateProgress(String jsonArgs) {
    _player._updateProgress(jsonArgs);
  }

  ///
  void audioPlayerFinished(PlaybackDisposition status) =>
      _player._audioPlayerFinished(status);

  /// The OS has sent us a signal that the audio has been paused.
  void onPaused() => _player._onPaused();

  /// The OS has sent us a signal that the audio has been resumed.
  void onResume() => _player._onResumed();
}

/// The player was in an unexpected state when you tried
/// to change it state.
/// e.g. you tried to pause when the player was stopped.
class PlayerInvalidStateException implements Exception {
  final String _message;

  ///
  PlayerInvalidStateException(this._message);

  String toString() => _message;
}

/// Thrown if the user tries to call an api method which
/// is currently not implemented.
class NotImplementedException implements Exception {
  final String _message;

  ///
  NotImplementedException(this._message);

  String toString() => _message;
}
