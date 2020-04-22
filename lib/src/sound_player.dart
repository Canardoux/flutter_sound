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
import 'dart:io';

import 'android/android_audio_focus_gain.dart';

import 'codec.dart';
import 'ios/ios_session_category.dart';
import 'ios/ios_session_category_option.dart';
import 'ios/ios_session_mode.dart';
import 'playback_disposition.dart';
import 'plugins/base_plugin.dart';
import 'plugins/player_base_plugin.dart';
import 'plugins/sound_player_plugin.dart';
import 'plugins/sound_player_track_plugin.dart';
import 'track.dart' as t;

/// An api for playing audio.
///
/// A [SoundPlayer] establishes an audio session and allows
/// you to play multiple audio files within the session.
///
/// [SoundPlayer] can either be used headless ([SoundPlayer.noUI] or
/// use the OSs' built in Media Player [SoundPlayer.withIU].
///
/// You can use the headless mode to build you own UI for playing sound
/// or use Flutter Sounds own [SoundPlayerUI] widget.
///
/// Once you have finished using a [SoundPlayer] you MUST call
/// [SoundPlayer.release] to free up any resources.
///
class SoundPlayer implements SlotEntry {
  PlayerEvent _onSkipForward;
  PlayerEvent _onSkipBackward;
  PlayerEvent _onFinished;
  PlayerEventWithCause _onPaused;
  PlayerEventWithCause _onResumed;
  PlayerEventWithCause _onStarted;
  PlayerEventWithCause _onStopped;

  ///
  bool canPause;

  ///
  bool canSkipForward;

  ///
  bool canSkipBackward;

  bool _initialized = false;

  /// If the user calls seekTo before starting the track
  /// we cache the value until we start the player and
  /// then we apply the seek offset.
  Duration _seekTo;

  final PlayerBasePlugin _plugin;

  /// The track that we are currently playing.
  t.Track _track;

  ///
  PlayerState playerState = PlayerState.isStopped;

  StreamController<PlaybackDisposition> _playerController =
      StreamController<PlaybackDisposition>();

  /// Create a [SoundPlayer] that displays the OS' audio UI.
  SoundPlayer.withUI({
    this.canPause = true,
    this.canSkipBackward = false,
    this.canSkipForward = false,
  }) : _plugin = SoundPlayerTrackPlugin();

  /// Create an [SoundPlayer] that does not have a UI.
  /// You can use this version to simply playback audio without
  /// a UI or to build your own UI as [Playbar] does.
  SoundPlayer.noUI() : _plugin = SoundPlayerPlugin() {
    canPause = false;
    canSkipBackward = false;
    canSkipForward = false;
  }

  /// Create a audio play from an in memory buffer.
  /// The [dataBuffer] contains the media to be played.
  /// The [codec] of the file the [dataBuffer] points to.
  /// You MUST pass a codec.
  // SoundPlayer.fromBuffer(Uint8List dataBuffer, {@required Codec codec})
  //     : _dataBuffer = dataBuffer {
  //   if (codec == null) {
  //     throw CodecNotSupportedException('You must pass in a codec.');
  //   }
  //   _codec = codec;
  // }

  /// internal method implements lazy initialisation.
  /// This allows us to delay selecting the plugin
  /// until the users try to start playing.
  /// This helps with the [Track] implementation
  /// which wraps a SoundPlayer.
  Future _initialize() async {
    if (!_initialized) {
      _initialized = true;

      _plugin.initialise(this);
    }
  }

  /// call this method once you are down with the player
  /// so that it can release all of the attached resources.
  Future<void> release() async {
    if (_initialized) {
      _initialized = false;
      // Stop the player playback before releasing
      await stop();
      closeDispositionStream(); // playerController is closed by this function

      await t.trackRelease(_track);
      await _plugin.release(this);
    }
  }

  /// Starts playback.
  /// The [uri] of the file to download and playback
  /// The [codec] of the file the [uri] points to. The default
  /// value is [Codec.fromExtension].
  /// If the default [Codec.fromExtension] is used then
  /// [QuickPlay] will use the files extension to guess the codec.
  /// If the file extension doesn't match a known codec then
  /// [QuickPlay] will throw an [CodecNotSupportedException] in which
  /// case you need pass one of the known codecs.
  ///
  ///
  Future<void> play(t.Track track) async {
    _initialize();
    _track = track;

    if (!isStopped) {
      throw PlayerInvalidStateException("The player must not be running.");
    }

    // Check the current codec is supported on this platform
    if (!await isSupported(track.codec)) {
      throw PlayerInvalidStateException(
          'The selected codec is not supported on '
          'this platform.');
    }

    t.prepareStream(track);

    _applyHush();
    await _plugin.play(this, track);
    playerState = PlayerState.isPlaying;

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

  /// Stops playback.
  Future<void> stop() async {
    if (isStopped) {
      print("stop() was called when the player wasn't playing. Ignored");
    } else {
      try {
        closeDispositionStream(); // playerController is closed by this function
        await _plugin.stop(this);
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
    await _plugin.pause(this);

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

    await _plugin.resume(this);

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
    if (!isPlaying) {
      _seekTo = position;
    } else {
      await _initialize();
      await _plugin.seekToPlayer(this, position);
    }
  }

  /// Sets the playback volume
  /// The [volume] must be in the range 0.0 to 1.0.
  Future<void> setVolume(double volume) async {
    await _initialize();
    await _plugin.setVolume(this, volume);
  }

  /// TODO does this need to be exposed?
  /// The simple action of stopping the playback may be sufficient
  /// Given the user has to call stop
  void closeDispositionStream() {
    if (_playerController != null) {
      _playerController.close();
      _playerController = null;
    }
  }

  Future<void> _setSubscriptionDuration(Duration interval) async {
    assert(interval.inMilliseconds > 0);
    await _initialize();
    await _plugin.setSubscriptionDuration(this, interval);
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

  ///
  void _updateProgress(PlaybackDisposition disposition) {
    // we only send dispositions whilst playing.
    if (isPlaying) {
      _playerController?.add(disposition);
    }
  }

  /// internal method.
  /// Called by the Platform plugin to notify us that
  /// audio has finished playing to the end.
  void _audioPlayerFinished(PlaybackDisposition status) {
    // if we have finished then position should be at the end.
    var finalPosition = PlaybackDisposition(status.duration, status.duration);

    _playerController?.add(finalPosition);

    playerState = PlayerState.isStopped;
    if (_onFinished != null) _onFinished();
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
        await androidFocusRequest(AndroidAudioFocusGain.transientMayDuck);
      }
    } else {
      if (Platform.isIOS) {
        await iosSetCategory(
            IOSSessionCategory.playAndRecord,
            IOSSessionMode.defaultMode,
            IOSSessionCategoryOption.iosDefaultToSpeaker);
      } else if (Platform.isAndroid) {
        await androidFocusRequest(AndroidAudioFocusGain.defaultGain);
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
  void _onSystemSkipBackward() {
    if (_onSkipBackward != null) _onSkipBackward();
  }

  /// Pass a callback if you want to be notified
  /// when the user attempts to skip forward to the
  /// next track.
  /// This is only meaningful if you have used
  /// [SoundPlayer.withUI] which has a 'skip' button.
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
  /// on the OS UI.  To show the OS UI you must have called
  /// [SoundPlayer.withUI].
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
  /// on the OS UI.  To show the OS UI you must have called
  /// [SoundPlayer.withUI].
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
  /// [SoundPlayer.withUI].
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
  /// OSs' UI. To show the OS UI you must have called
  /// [SoundPlayer.withUI].
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
    if ((codec == Codec.opusOGG) && (Platform.isIOS)) {
      codec = Codec.cafOpus;
    }
    result = await _plugin.isSupported(this, codec);
    return result;
  }

  /// For iOS only.
  /// If this function is not called,
  /// everything is managed by default by flutter_sound.
  /// If this function is called,
  /// it is probably called just once when the app starts.
  ///
  /// NOTE: in reality it is being called everytime we start
  /// playing audio which from my reading appears to be correct.
  ///
  /// After calling this function,
  /// the caller is responsible for using [requestAudioFocus]
  /// and [abandonAudioFocus]
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
    return await _plugin.iosSetCategory(this, category, mode, options);
  }

  /// Reliquences the foreground audio.
  ///  The caller can manage his audio focus with this function
  /// Depending on your configuration this will either make
  /// this player the loudest stream or it will silence all other stream.
  Future<void> abandonAudioFocus({bool enabled}) async {
    await _initialize();
    await _plugin.abandonAudioFocus(this);
  }

  ///  The caller can manage his audio focus with this function
  /// Depending on your configuration this will either make
  /// this player the loudest stream or it will silence all other stream.
  Future<void> requestAudioFocus() async {
    await _initialize();
    await _plugin.requestAudioFocus(this);
  }

  /// For Android only.
  /// If this function is not called, everything is
  ///  managed by default by flutter_sound.
  /// If this function is called, it is probably called
  ///  just once when the app starts.
  /// After calling this function, the caller is responsible
  ///  for using correctly requestFocus
  ///    probably before startRecorder or startPlayer
  /// and stopPlayer and stopRecorder
  ///
  /// Unlike [requestFocus] this method allows us to set the gain.
  ///

  Future<bool> androidFocusRequest(int focusGain) async {
    await _initialize();
    return await _plugin.androidFocusRequest(this, focusGain);
  }
}

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
typedef UpdatePlayerProgress = void Function(int current, int max);

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

/// Forwarders so we can hide methods from the public api.

void updateProgress(SoundPlayer player, PlaybackDisposition disposition) =>
    player._updateProgress(disposition);

///
void audioPlayerFinished(SoundPlayer player, PlaybackDisposition status) =>
    player._audioPlayerFinished(status);

/// handles a pause coming up from the player
void onSystemPaused(SoundPlayer player) => player._onSystemPaused();

/// handles a resume coming up from the player
void onSystemResumed(SoundPlayer player) => player._onSystemResumed();

/// handles a skip forward coming up from the player
void onSystemSkipForward(SoundPlayer player) => player._onSystemSkipForward();

/// handles a skip forward coming up from the player
void onSystemSkipBackward(SoundPlayer player) => player._onSystemSkipBackward();
