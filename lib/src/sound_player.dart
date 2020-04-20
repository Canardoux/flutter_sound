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
import 'package:uuid/uuid.dart';

import 'android/android_audio_focus_gain.dart';
import 'codec.dart';
import 'ios/ios_session_category.dart';
import 'ios/ios_session_category_option.dart';
import 'ios/ios_session_mode.dart';
import 'playback_disposition.dart';
import 'plugins/base_plugin.dart';
import 'plugins/sound_player_plugin.dart';
import 'plugins/sound_player_track_plugin.dart';
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

typedef PlayerEvent = void Function();

/// TODO should we be passing an object that contains
/// information such as the position in the track when
/// it was paused?
typedef PlayerEventWithCause = void Function({bool wasUser});
typedef TupdateProgress = void Function(int current, int max);

/// Provides the ability to playback audio from
/// a variety of sources including:
/// File
/// Buffer
/// Assets
/// URL.
class SoundPlayer {
  PlayerEvent _onSkipForward;
  PlayerEvent _onSkipBackward;
  PlayerEvent _onFinished;
  PlayerEventWithCause _onPaused;
  PlayerEventWithCause _onResumed;
  PlayerEventWithCause _onStarted;
  PlayerEventWithCause _onStopped;
  final bool _showOSUI;

  /// The title of this track
  String trackTitle;

  /// The name of the author of this track
  String trackAuthor;

  /// The URL that points to the album art of the track
  String albumArtUrl;

  /// The asset that points to the album art of the track
  String albumArtAsset;

  bool _initialized = false;

  /// If the user calls seekTo before starting the track
  /// we cache the value until we start the player and
  /// then we apply the seek offset.
  Duration _seekTo;

  /// The audio for a stream can either be sourced
  /// by a URI or from a databuffer.
  /// The URI could be a remote resource (HTTP)
  /// or a local file or asset.
  String _uri;
  Uint8List _dataBuffer;

  /// The codec we will be using to do the playback
  /// This may not be the original codec that was passed in
  /// as when preparing the stream we may have to transform
  /// the codec into one that is supported.
  Codec _codec;

  /// class to communicate with the plugin.
  /// This allows us to hide public methods
  /// from the public api.
  SoundPlayerProxy _proxy;

  /// The showOSUI passed to the constructor controls which
  /// plugin we use for the life of this SoundPlayer.
  BasePlugin _activePlugin;

  final List<TempMediaFile> _tempMediaFiles = [];

  ///
  PlayerState playerState = PlayerState.isStopped;
  StreamController<PlaybackDisposition> _playerController =
      StreamController<PlaybackDisposition>();

  /// The [uri] of the file to download and playback
  /// The [codec] of the file the [uri] points to. The default
  /// value is [Codec.fromExtension].
  /// If the default [Codec.fromExtension] is used then
  /// [SoundPlayer] will use the files extension to guess the codec.
  /// If the file extension doesn't match a known codec then
  /// [SoundPlayer] will throw an [CodecNotSupportedException] in which
  /// case you need pass one of the known codecs.
  ///
  /// If [showOSUI] is [true] then we will displays the OS's builtin
  /// audio player allowing you to control the audio from the lock screen.
  /// By default [showOSUI] is false.
  SoundPlayer.fromPath(this._uri,
      {Codec codec = Codec.fromExtension, bool showOSUI = false})
      : _showOSUI = showOSUI {
    if (codec == null || codec == Codec.fromExtension) {
      codec = CodecHelper.determineCodec(_uri);
      throw CodecNotSupportedException(
          "The uri's extension does not match any of the supported extensions. "
          'You must pass in a codec.');
    }
    _internal(codec);
  }

  /// Create a audio play from an in memory buffer.
  /// The [dataBuffer] contains the media to be played.
  /// The [codec] of the file the [dataBuffer] points to.
  /// You MUST pass a codec.
  /// If [showOSUI] is [true] then we will displays the OS's builtin
  /// audio player allowing you to control the audio from the lock screen.
  /// By default [showOSUI] is false.
  SoundPlayer.fromBuffer(Uint8List dataBuffer,
      {@required Codec codec, bool showOSUI = false})
      : _dataBuffer = dataBuffer,
        _showOSUI = showOSUI {
    if (codec == null) {
      throw CodecNotSupportedException('You must pass in a codec.');
    }
    _internal(codec);
  }

  void _internal(Codec codec) {
    _codec = codec;
    _proxy = SoundPlayerProxy(this);

    if (_showOSUI == true) {
      _activePlugin = SoundPlayerTrackPlugin();
    } else {
      _activePlugin = SoundPlayerPlugin();
    }

    _activePlugin.register(_proxy);

    print('regisetered $_proxy');
  }

  /// internal method
  Future<SoundPlayer> _initialize() async {
    if (!_initialized) {
      _initialized = true;
      print('initialise called $_proxy');

      await _invokeMethod('initializeMediaPlayer', <String, dynamic>{});
    }
    return this;
  }

  /// call this method once you are down with the player
  /// so that it can release all of the attached resources.
  Future<void> release() async {
    print('releasing $_proxy');
    if (_initialized) {
      _initialized = false;
      // Stop the player playback before releasing
      await stop();
      closeDispositionStream(); // playerController is closed by this function

      await _invokeMethod('releaseMediaPlayer', <String, dynamic>{});
      _activePlugin.release(_proxy);
      // SoundPlayerTrackPlugin().release(_proxy);

      _deleteTempFiles();
    }
  }

  /// Does any preparatory work required on a stream before it can be played.
  /// This includes converting databuffers to paths and
  /// any re-encoding required.
  ///
  /// Returns the path to be played.
  Future<String> _prepareStream() async {
    var path = _uri;

    if (_dataBuffer != null) {
      var tempMediaFile = TempMediaFile.fromBuffer(_dataBuffer);
      _tempMediaFiles.add(tempMediaFile);

      /// clear the buffer so we won't do this again.
      _dataBuffer = null;
      path = tempMediaFile.path;
    }

    // If we want to play OGG/OPUS on iOS, we remux the OGG file format to a specific Apple CAF envelope before starting the player.
    // We use FFmpeg for that task.
    if ((Platform.isIOS) &&
        ((_codec == Codec.opus) || (fm.fileExtension(path) == '.opus'))) {
      var tempMediaFile =
          TempMediaFile(await CodecConversions.opusToCafOpus(path));
      _tempMediaFiles.add(tempMediaFile);
      path = tempMediaFile.path;
      // update the codec so we won't reencode again.
      _codec = Codec.cafOpus;
    }

    /// set the uri so next time we come in here we will return the
    /// correct path.
    _uri = path;
    return path;
  }

  /// Starts playback.

  Future<void> play() async {
    _initialize();

    if (!isStopped) {
      throw PlayerInvalidStateException("The player must not be running.");
    }

    // Check the current codec is supported on this platform
    if (!await isSupported(_codec)) {
      throw PlayerInvalidStateException(
          'The selected codec is not supported on '
          'this platform.');
    }

    var path = await _prepareStream();

    _applyHush();

    if (_showOSUI) {
      await _startPlayerOnOSUI(path);
    } else {
      // build the argument map
      var args = <String, dynamic>{};
      args['path'] = path;
      // Flutter cannot transfer an enum to a native plugin.
      // We use an integer instead
      args['codec'] = _codec.index;
      await _invokeMethod('startPlayer', args);
      playerState = PlayerState.isPlaying;
    }

    /// If the user called seekTo before starting the player
    /// we immediate do a seek.
    /// TODO: does this cause any audio glitch (i.e starts playing)
    /// and then seeks.
    /// If so we may need to modify the plugin so we pass in a seekTo
    /// argument.
    if (_seekTo != null) {
      await seekTo(_seekTo);
      _seekTo = null;
    }

    playerState = PlayerState.isPlaying;
    if (_onStarted != null) _onStarted(wasUser: false);
  }

  /// Plays the given [track]. [canSkipForward] and [canSkipBackward] must be
  /// passed to provide information on whether the user can skip to the next
  /// or to the previous song in the lock screen controls.
  ///
  /// This method should only be used if the player has been initialize
  /// with the audio player specific features.
  Future<void> _startPlayerOnOSUI(String path) async {
    final trackMap = <String, dynamic>{
      "path": path,
      "title": trackTitle,
      "author": trackAuthor,
      "albumArtUrl": albumArtUrl,
      "albumArtAsset": albumArtAsset,
      // TODO is this necessary if we arn't passing a buffer?
      "bufferCodecIndex": _codec?.index,
    };

    await _invokeMethod('startPlayerFromTrack', <String, dynamic>{
      'track': trackMap,
      // TODO: is this a valid association?
      // A more direct flag might be appropriate in that
      // I may want the user to be able to pause but I don't
      // need to be notified.
      'canPause': _onPaused != null,
      'canSkipForward': _onSkipForward != null,
      'canSkipBackward': _onSkipBackward != null,
    }) as String;
  }

  /// Stops playback.
  Future<void> stop() async {
    if (isStopped) {
      print("stop() was called when the player wasn't playing. Ignored");
    } else {
      try {
        closeDispositionStream(); // playerController is closed by this function
        await _invokeMethod('stopPlayer', <String, dynamic>{}) as String;

        playerState = PlayerState.isStopped;
        if (_onStopped != null) _onStopped(wasUser: false);
      } on Object catch (e) {
        print(e);
        rethrow;
      }
    }
  }

  /// Pauses playback.
  /// If you call this and the audio is not playing
  /// a [PlayerInvalidStateException] will be thrown.
  Future<void> pause() async {
    if (playerState != PlayerState.isPlaying) {
      throw PlayerInvalidStateException('Player is not playing.');
    }
    playerState = PlayerState.isPaused;

    await _invokeMethod('pausePlayer', <String, dynamic>{}) as String;

    if (_onPaused != null) _onPaused(wasUser: false);
  }

  /// Resumes playback.
  /// If you call this when audio is not paused
  /// then a [PlayerInvalidStateException] will be thrown.
  Future<void> resume() async {
    if (playerState != PlayerState.isPaused) {
      throw PlayerInvalidStateException('Player is not paused.');
    }
    playerState = PlayerState.isPlaying;
    await _invokeMethod('resumePlayer', <String, dynamic>{}) as String;

    if (_onResumed != null) _onResumed(wasUser: false);
  }

  /// Moves the current playback position to the given offset in the
  /// recording.
  /// [position] is the position in the recording to set the playback
  /// location from.
  /// You may call this before [play] or whilst the audio is playing.
  /// If you call [seekTo] before calling [play] then when you call
  /// [play] we will start playing the recording from the [position]
  /// passed to [seekTo].
  Future<void> seekTo(Duration position) async {
    await _initialize();

    if (!isPlaying) {
      _seekTo = position;
    } else {
      await _invokeMethod('seekToPlayer', <String, dynamic>{
        'sec': position.inMilliseconds,
      }) as String;
    }
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

  ///  The caller can manage his audio focus with this function
  /// Depending on your configuration this will either make
  /// this player the loudest stream or it will silence all other stream.
  Future<void> setActive({bool enabled}) async {
    await _initialize();
    await _invokeMethod('setActive', <String, dynamic>{'enabled': enabled});
  }

  /// TODO does this need to be exposed?
  /// The simple action of stopping the playback may be sufficient
  /// Given the user has to call stop
  void closeDispositionStream() {
    if (_playerController != null) {
      _playerController..close();
      _playerController = null;
    }
  }

  Future<void> _setSubscriptionDuration(Duration interval) async {
    assert(interval.inMilliseconds > 0);
    await _initialize();
    await _invokeMethod('setSubscriptionDuration', <String, dynamic>{
      /// we need to use milliseconds as if we use seconds we end
      /// up rounding down to zero.
      'sec': (interval.inMilliseconds).toDouble() / 1000,
    }) as String;
  }

  // TODO implement these methods so a user
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
  Stream<PlaybackDisposition> dispositionStream(
      {Duration interval = const Duration(milliseconds: 100)}) {
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
    // we only send dispositions whilst playing.
    if (isPlaying) {
      var result = jsonDecode(jsonArgs) as Map<String, dynamic>;
      _playerController?.add(PlaybackDisposition.fromJSON(result));
    }
  }

  /// internal method.
  /// Called by the Platform plugin to notify us that
  /// audio has finished playing to the end.
  void _audioPlayerFinished(PlaybackDisposition status) {
    // if we have finished then position should be at the end.
    status.position = status.duration;
    _playerController?.add(status);

    playerState = PlayerState.isStopped;
    if (_onFinished != null) _onFinished();
  }

  /// delete any tempoary media files we created whilst recording.
  void _deleteTempFiles() {
    for (var tmp in _tempMediaFiles) {
      tmp.delete();
    }
    _tempMediaFiles.clear();
  }

  /// Instructs the OS to reduce the volume of other audio
  /// whilst we play this audio file.
  /// The exact effect of this is OS dependant.
  /// The effect is only applied when we start the audio play.
  /// Changing this value whilst audio is play will have no affect.
  bool hushOthers = false;

  /// Apply/Remoe the hush other setting.
  void _applyHush() async {
    if (hushOthers) {
      if (Platform.isIOS) {
        await iosSetCategory(
            IOSSessionCategory.playAndRecord,
            IOSSessionMode.defaultMode,
            IOSSessionCategoryOption.iosDuckOthers |
                IOSSessionCategoryOption.iosDefaultToSpeaker);
      } else if (Platform.isAndroid) {
        await androidAudioFocusRequest(AndroidAudioFocusGain.transientMayDuck);
      }
    } else {
      if (Platform.isIOS) {
        await iosSetCategory(
            IOSSessionCategory.playAndRecord,
            IOSSessionMode.defaultMode,
            IOSSessionCategoryOption.iosDefaultToSpeaker);
      } else if (Platform.isAndroid) {
        await androidAudioFocusRequest(AndroidAudioFocusGain.defaultGain);
      }
    }
  }

  /// handles a pause coming up from the player
  void _onSystemPaused() {
    if (_onPaused != null) _onPaused(wasUser: true);
  }

  /// handles a resume coming up from the player
  void _onSystemResumed() {
    if (_onResumed != null) _onResumed(wasUser: true);
  }

  /// handles a skip forward coming up from the player
  void _onSystemSkipForward() {
    if (_onSkipForward != null) _onSkipForward();
  }

  /// handles a skip forward coming up from the player
  void _onSystemSkipBackwards() {
    if (_onSkipBackward != null) _onSkipBackward();
  }

  /// Pass a callback if you want to be notified
  /// when the user attempts to skip forward to the
  /// next track.
  /// This is only meaningful if you have set
  /// [showOSUI] which has a 'skip' button.
  /// The SoundPlayer essentially ignores this event
  /// as the SoundPlayer has no concept of an Album.
  ///
  /// It is up to you to create a new SoundPlayer with the
  /// next track and start it playing.
  ///
  // ignore: avoid_setters_without_getters
  set onSkipForward(PlayerEvent onSkipForward) {
    _onSkipForward = onSkipForward;
  }

  /// Pass a callback if you want to be notified
  /// when the user attempts to skip backward to the
  /// prior track.
  /// This is only meaningful if you have set
  /// [showOSUI] which has a 'skip' button.
  /// The SoundPlayer essentially ignores this event
  /// as the SoundPlayer has no concept of an Album.
  ///
  ///
  // ignore: avoid_setters_without_getters
  set onSkipBackward(PlayerEvent onSkipBackward) {
    _onSkipBackward = onSkipBackward;
  }

  /// Pass a callback if you want to be notified when
  /// a track finishes to completion.
  /// see [onStopped] for events when the user or system stops playback.
  // ignore: avoid_setters_without_getters
  set onFinished(PlayerEvent onFinished) {
    _onFinished = onFinished;
  }

  ///
  /// Pass a callback if you want to be notified when
  /// playback is paused.
  /// The [wasUser] argument in the callback will
  /// be true if the user clicked the pause button
  /// on the OS UI.  This will only ever happen if you
  /// called [showOSUI].
  ///
  /// [wasUser] will be false if you paused the audio
  /// via a call to [pause].
  // ignore: avoid_setters_without_getters
  set onPaused(PlayerEventWithCause onPaused) {
    _onPaused = onPaused;
  }

  ///
  /// Pass a callback if you want to be notified when
  /// playback is resumed.
  /// The [wasUser] argument in the callback will
  /// be true if the user clicked the resume button
  /// on the OS UI.  This will only ever happen if you
  /// called [showOSUI].
  ///
  /// [wasUser] will be false if you resumed the audio
  /// via a call to [resume].
  // ignore: avoid_setters_without_getters
  set onResumed(PlayerEventWithCause onResumed) {
    _onResumed = onResumed;
  }

  /// Pass a callback if you want to be notified
  /// that audio has started playing.
  ///
  /// If the player has to download or transcribe
  /// the audio then this method won't return
  /// util the audio actually starts to play.
  ///
  /// This can occur if you called [play]
  /// or the user click the start button on the
  /// OS UI. To show the OS UI you must have called
  /// [showOSUI].
  // ignore: avoid_setters_without_getters
  set onStarted(PlayerEventWithCause onStarted) {
    _onStarted = onStarted;
  }

  /// Pass a callback if you want to be notified
  /// that audio has stopped playing.
  /// This is different from [onFinished] which
  /// is called when the auido plays to completion.
  ///
  /// [onStoppped]  can occur if you called [stop]
  /// or the user click the stop button on the
  /// OS UI. To show the OS UI you must have called
  /// [showOSUI].
  // ignore: avoid_setters_without_getters
  set onStopped(PlayerEventWithCause onStopped) {
    _onStopped = onStopped;
  }

  /// Returns true if the specified decoder is supported
  ///  by flutter_sound on this platform
  Future<bool> isSupported(Codec codec) async {
    bool result;
    await _initialize();
    // For decoding ogg/opus on ios, we need to support two steps :
    // - remux OGG file format to CAF file format (with ffmpeg)
    // - decode CAF/OPPUS (with native Apple AVFoundation)
    if ((codec == Codec.opus) && (Platform.isIOS)) {
      codec = Codec.cafOpus;
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

  Future<dynamic> _invokeMethod(
      String methodName, Map<String, dynamic> args) async {
    return await _activePlugin.invokeMethod(_proxy, methodName, args);
  }
}

/// Class exists to hide internal methods from the public api
class SoundPlayerProxy implements Proxy {
  final Uuid _uuid = Uuid();
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
  void onSystemPaused() => _player._onSystemPaused();

  /// The OS has sent us a signal that the audio has been resumed.
  void onSystemResumed() => _player._onSystemResumed();

  String toString() => 'Proxy: ${_uuid.hashCode}';

  /// The OS track UI skip forward button has been tapped.
  void skipForward() => _player._onSystemSkipForward();

  /// The OS track UI skip backwards button has been tapped.
  void skipBackward() => _player._onSystemSkipBackwards();
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
