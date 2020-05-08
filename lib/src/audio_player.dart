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

import 'audio_focus.dart';
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
import 'util/ansi_color.dart';
import 'util/log.dart';

/// An api for playing audio.
///
/// A [AudioPlayer] establishes an audio session and allows
/// you to play multiple audio files within the session.
///
/// [AudioPlayer] can either be used headless ([AudioPlayer.noUI] or
/// use the OSs' built in Media Player [AudioPlayer.withIU].
///
/// You can use the headless mode to build you own UI for playing sound
/// or use Flutter Sounds own [SoundPlayerUI] widget.
///
/// Once you have finished using a [AudioPlayer] you MUST call
/// [AudioPlayer.release] to free up any resources.
///
class AudioPlayer implements SlotEntry {
  final PlayerBasePlugin _plugin;

  PlayerEvent _onSkipForward;
  PlayerEvent _onSkipBackward;
  OSPlayerStateEvent _onUpdatePlaybackState;
  PlayerEventWithCause _onPaused;
  PlayerEventWithCause _onResumed;
  PlayerEventWithCause _onStarted;
  PlayerEventWithCause _onStopped;

  /// When the [withUI] ctor is called this field
  /// controls whether the OSs' UI displays the pause button.
  /// If you change this value it won't take affect until the
  /// next call to [play].
  bool canPause;

  /// When the [withUI] ctor is called this field
  /// controls whether the OSs' UI displays the skip Forward button.
  /// If you change this value it won't take affect until the
  /// next call to [play].
  bool canSkipForward;

  /// When the [withUI] ctor is called this field
  /// controls whether the OSs' UI displays the skip back button.
  /// If you change this value it won't take affect until the
  /// next call to [play].
  bool canSkipBackward;

  /// If true then the media is being played in the background
  /// and will continue playing even if our app is paused.
  /// If false the audio will automatically be paused if
  /// the audio is placed into the back ground and resumed
  /// when your app becomes the foreground app.
  final bool _playInBackground;

  /// If the user calls seekTo before starting the track
  /// we cache the value until we start the player and
  /// then we apply the seek offset.
  Duration _seekTo;

  /// The track that we are currently playing.
  t.Track _track;

  ///
  PlayerState playerState = PlayerState.isStopped;

  ///
  /// Disposition stream components
  ///

  /// The stream source
  StreamController<PlaybackDisposition> _playerController =
      StreamController<PlaybackDisposition>.broadcast();

  /// last time we sent an update via the stream.
  DateTime _lastPositionDispositionUpdate = DateTime.now();

  /// The user requested interval of stream updates.
  Duration _positionDispostionInterval;

  /// The current playback position as last sent on the stream.
  Duration _currentPosition = Duration.zero;

  /// Used to flag that the player is ready to play.
  /// When this completion completes [_playerReady] is set
  /// to [true].
  Completer<bool> _playerReadyCompletion = Completer<bool>();

  /// Used to wait for the plugin to connect us to an OS MediaPlayer
  Future<bool> _playerReady;

  /// When we do a [_softRelease] we need to flag that the plugin
  /// needs to be re-initialized so we set this to true.
  /// Its also true on construction to force the initial initialisation.
  bool _pluginInitRequired = true;

  /// hack until we implement onConnect in the all the plugins.
  final bool _fakePlayerReady;

  /// Used to track when we have been paused when the app is paused.
  /// We should only resume playing if we wer playing when paused.
  bool _inSystemPause = false;

  /// Create a [AudioPlayer] that displays the OS' audio UI.
  ///
  /// if [canPause] is true than the user will be able to pause the track
  /// via the OSs' UI. Defaults to true.
  ///
  /// If [canSkipBackward] is true then the user will be able to click the skip
  /// back button on the OSs' UI. Given the [AudioPlayer] only deals with a
  /// single track at
  /// a time you will need to implement [onSkipBackward] for this action to
  /// have any affect. The [Album] class has the ability to manage mulitple
  /// tracks.
  ///
  /// If [canSkipForward] is true then the user will be able to click the skip
  /// forward button on the OSs' UI. Given the [AudioPlayer] only deals with a
  /// single track at a time you will need to implement [onSkipBackward] for
  /// this action to have any affect. The [Album] class has the ability to
  /// manage mulitple tracks.
  ///
  /// If [playInBackground] is true then the audio will play in the background
  /// which means that it will keep playing even if the app is sent to the
  /// background.
  ///
  /// {@tool sample}
  /// Once you have finished with the [AudioPlayer] you MUST
  /// call [AudioPlayer.release].
  ///
  /// ```dart
  /// var player = SoundPlayer.noUI();
  /// player.onStopped = () => player.release();
  /// player.play(track);
  /// ```
  /// The above example guarentees that the player will be released.
  /// {@end-tool}
  AudioPlayer.withUI({
    this.canPause = true,
    this.canSkipBackward = false,
    this.canSkipForward = false,
    bool playInBackground = false,
  })  : _fakePlayerReady = Platform.isIOS,
        _playInBackground = playInBackground,
        _plugin = SoundPlayerTrackPlugin() {
    _commonInit();
  }

  /// Create a [AudioPlayer] that does not have a UI.
  ///
  /// You can use this version to simply playback audio without
  /// a UI or to build your own UI as [Playbar] does.
  ///
  /// If [playInBackground] is true then the audio will play in the background
  /// which means that it will keep playing even if the app is sent to the
  /// background.
  ///
  /// {@tool sample}
  /// Once you have finished with the [AudioPlayer] you MUST
  /// call [AudioPlayer.release].
  /// ```dart
  /// var player = SoundPlayer.noUI();
  /// player.onStopped = () => player.release();
  /// player.play(track);
  /// ```
  /// The above example guarentees that the player will be released.
  /// {@end-tool}
  AudioPlayer.noUI({bool playInBackground = false})
      : _fakePlayerReady = true,
        _playInBackground = playInBackground,
        _plugin = SoundPlayerPlugin() {
    canPause = false;
    canSkipBackward = false;
    canSkipForward = false;
    _commonInit();
  }

  /// once off initialisation used by call ctors.
  void _commonInit() {
    _plugin.register(this);
    _plugin.onPlayerReady = _onPlayerReady;

    /// track the current position
    _playerController.stream.listen((playbackDisposition) {
      _currentPosition = playbackDisposition.position;
    });
  }

  /// initializes the plugin
  ///
  /// This will be called multiple times in the life cycle
  /// of a [AudioPlayer] as we release the plugin
  /// each time we stop the player.
  ///
  Future<R> _initializeAndRun<R>(Future<R> Function() run) async {
    if (_pluginInitRequired) {
      _pluginInitRequired = false;

      _playerReadyCompletion = Completer<bool>();

      /// we allow five seconds for the connect to complete or
      /// we timeout returning false.
      _playerReady = _playerReadyCompletion.future
          .timeout(Duration(seconds: 5), onTimeout: () => Future.value(false));

      /// The plugin will call [onPlayerReady] which completes
      /// the intialisation.
      await _plugin.initializePlayer(this);

      _setSubscriptionDuration(Duration(milliseconds: 100));

      /// hack until we implement [onPlayerReady] in the all the OS
      /// native plugins.
      if (_fakePlayerReady) _onPlayerReady(result: true);
    }
    return _playerReady.then((ready) {
      if (ready) {
        return run();
      } else {
        /// This can happen if you have a breakpoint in you code and
        /// you don't let the initialisation logic complete.
        throw PlayerInvalidStateException(
            "AudioPlayer initialisation timeout.");
      }
    });
  }

  /// Call this method once you are done with the player
  /// so that it can release all of the attached resources.
  /// await the [release] to ensure that all resources are released before
  /// you take future action.
  Future<void> release() async {
    if (!_plugin.isRegistered(this)) {
      throw PlayerInvalidStateException(
          "The player is no longer registered. Did you call release() twice?");
    }
    return _initializeAndRun(() async {
      _closeDispositionStream();
      await _softRelease();
      await _plugin.release(this);
    });
  }

  /// If the player is pushed into the
  /// background we want to release the plugin and
  /// any other temporary resources.
  /// The exception is if we are configured to continue
  /// playing in the backgroudn in which case
  /// this method won't be called.
  void _softRelease() async {
    // Stop the player playback before releasing

    if (isPlaying) {
      await _plugin.stop(this);
    }

    // release the android/ios resources but
    // leave the slot intact so we can resume.
    if (!_pluginInitRequired) {
      /// looks like this method is re-entrant when app is pausing
      /// so we need to protect ourselves from being called twice.
      _pluginInitRequired = true;

      _playerReady = null;

      /// the plugin is in an initialized state
      /// so we need to release it.
      await _plugin.releasePlayer(this);
    }

    if (_track != null) {
      t.trackRelease(_track);
    }
  }

  /// callback occurs when the OS MediaPlayer successfully connects:
  /// TODO: implement the onPlayerReady event from iOS.
  /// [result] true if the connection succeeded.
  void _onPlayerReady({bool result}) {
    _playerReadyCompletion.complete(result);
  }

  /// Starts playback.
  /// The [track] to play.
  Future<void> play(t.Track track) async {
    assert(track != null);

    if (!isStopped) {
      throw PlayerInvalidStateException("The player must not be running.");
    }

    var started = Completer<void>();

    _currentPosition = Duration.zero;

    return _initializeAndRun<void>(() async {
      _track = track;

      // Check the current codec is supported on this platform
      if (!await isSupported(track.codec)) {
        var exception = PlayerInvalidStateException(
            'The selected codec ${track.codec} is not supported on '
            'this platform.');
        started.completeError(exception);
        throw exception;
      }

      Log.d('calling prepare stream');
      t.prepareStream(track);

      // Not awaiting this may cause issues if someone immediately tries
      // to stop.
      // I think we need a completer to control transitions.
      Log.d('calling _plugin.play');
      _plugin.play(this, track).then<void>((_) {
        /// If the user called seekTo before starting the player
        /// we immediate do a seek.
        /// TODO: does this cause any audio glitch (i.e starts playing)
        /// and then seeks.
        /// If so we may need to modify the plugin so we pass in a seekTo
        /// argument.
        Log.d('calling seek');
        if (_seekTo != null) {
          seekTo(_seekTo);
          _seekTo = null;
        }

        // TODO: we should wait for the os to notify us that the start
        // has happened.
        playerState = PlayerState.isPlaying;

        Log.d('calling complete');
        started.complete();
        if (_onStarted != null) _onStarted(wasUser: false);
      });

      Log.d('*************play returning');
      return started.future;
    });
  }

  /// Stops playback.
  Future<void> stop() async {
    if (playerState == PlayerState.isStopped) {
      throw PlayerInvalidStateException('Player is not playing.');
    }

    return _initializeAndRun(() async {
      try {
        playerState = PlayerState.isStopped;
        if (_onStopped != null) _onStopped(wasUser: false);
      } on Object catch (e) {
        Log.d(e.toString());
        rethrow;
      }
    });
  }

  /// Pauses playback.
  /// If you call this and the audio is not playing
  /// a [PlayerInvalidStateException] will be thrown.
  Future<void> pause() async {
    if (playerState != PlayerState.isPlaying) {
      throw PlayerInvalidStateException('Player is not playing.');
    }

    return _initializeAndRun(() async {
      playerState = PlayerState.isPaused;
      await _plugin.pause(this);
      if (_onPaused != null) _onPaused(wasUser: false);
    });
  }

  /// Resumes playback.
  /// If you call this when audio is not paused
  /// then a [PlayerInvalidStateException] will be thrown.
  Future<void> resume() async {
    if (playerState != PlayerState.isPaused) {
      throw PlayerInvalidStateException('Player is not paused.');
    }

    return _initializeAndRun(() async {
      playerState = PlayerState.isPlaying;
      await _plugin.resume(this);
      if (_onResumed != null) _onResumed(wasUser: false);
    });
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
    return _initializeAndRun(() async {
      if (!isPlaying) {
        _seekTo = position;
      } else {
        await _plugin.seekToPlayer(this, position);
      }
    });
  }

  /// Rewinds the current track by the given interval
  Future<void> rewind(Duration interval) {
    _currentPosition -= interval;

    /// There may be a chance of a race condition if the underlying
    /// os code is in the middle of sending us a position update.
    return seekTo(_currentPosition);
  }

  /// Sets the playback volume
  /// The [volume] must be in the range 0.0 to 1.0.
  Future<void> setVolume(double volume) async {
    return _initializeAndRun(() async {
      await _plugin.setVolume(this, volume);
    });
  }

  /// [true] if the player is currently playing audio
  bool get isPlaying => playerState == PlayerState.isPlaying;

  /// [true] if the player is playing but the audio is paused
  bool get isPaused => playerState == PlayerState.isPaused;

  /// [true] if the player is stopped.
  bool get isStopped => playerState == PlayerState.isStopped;

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
  Stream<PlaybackDisposition> dispositionStream(
      {Duration interval = const Duration(milliseconds: 100)}) {
    _positionDispostionInterval = interval;
    return _playerController.stream;
  }

  /// TODO does this need to be exposed?
  /// The simple action of stopping the playback may be sufficient
  /// Given the user has to call stop
  void _closeDispositionStream() {
    if (_playerController != null) {
      _playerController.close();
      _playerController = null;
    }
  }

  /// Stream updates to users of [dispositionStream]
  /// We have a fixed frequency of 100ms coming up from the
  /// plugin so we need to modify the frequency based on what
  /// the user requested in the call to [dispositionStream].
  void _updateProgress(PlaybackDisposition disposition) {
    // we only send dispositions whilst playing.
    if (isPlaying) {
      if (DateTime.now().difference(_lastPositionDispositionUpdate) >
          _positionDispostionInterval) {
        _playerController?.add(disposition);
        _lastPositionDispositionUpdate = DateTime.now();
      }
    }
  }

  Future<void> _setSubscriptionDuration(Duration interval) async {
    return _initializeAndRun(() async {
      assert(interval.inMilliseconds > 0);
      await _plugin.setSubscriptionDuration(this, interval);
    });
  }

  /// internal method.
  /// Called by the Platform plugin to notify us that
  /// audio has finished playing to the end.
  void _audioPlayerFinished(PlaybackDisposition status) {
    // if we have finished then position should be at the end.
    var finalPosition = PlaybackDisposition(status.duration, status.duration);

    _playerController?.add(finalPosition);

    playerState = PlayerState.isStopped;
    if (_onStopped != null) _onStopped();
  }

  /// handles a pause coming up from the player
  void _onSystemPaused() {
    if (_onPaused != null) _onPaused(wasUser: true);
  }

  /// handles a resume coming up from the player
  void _onSystemResumed() {
    if (_onResumed != null) _onResumed(wasUser: true);
  }

  /// System event telling us that the app has been paused.
  /// Unless we are playing in the background then
  /// we need to stop playback and release resources.
  void _onSystemAppPaused() {
    Log.d(red('onSystemAppPaused _playInBackground=$_playInBackground'));
    if (!_playInBackground) {
      if (isPlaying) {
        /// we are only in a system pause if we were playing
        /// when the app was paused.
        _inSystemPause = true;
        stop();
      }
      _softRelease();
    }
  }

  /// System event telling us that our app has been resumed.
  /// If we had previously stopped then we resuming playing
  /// from the last position - 1 second.
  void _onSystemAppResumed() {
    Log.d(red('onSystemAppResumed _playInBackground=$_playInBackground '
        'track=$_track'));

    if (_inSystemPause && !_playInBackground && _track != null) {
      _inSystemPause = false;
      seekTo(_currentPosition);
      play(_track);
    }
  }

  /// handles a skip forward coming up from the player
  void _onSystemSkipForward() {
    if (_onSkipForward != null) _onSkipForward();
  }

  /// handles a skip forward coming up from the player
  void _onSystemSkipBackward() {
    if (_onSkipBackward != null) _onSkipBackward();
  }

  void _onSystemUpdatePlaybackState(SystemPlaybackState systemPlaybackState) {
    /// I have concerns about how these state changes interact with
    /// the SoundPlayer's own state management.
    /// Really we need a consistent source of 'state' and this should come
    /// up from the OS. The problem is that whilst TrackPlayer.java provides
    /// these state changes the FlutterSoundPlayer does not.
    /// I'm also not certain how to get a 'start' event out of android's
    /// MediaPlayer it will emmit an onPrepared event but I don't know
    /// if this happens in association with a start or whether it can happen
    /// but no start happens.
    /// Also need to find out if the call to MediaPlayer.start is async or
    /// sync as the doco is unclear.
    switch (systemPlaybackState) {
      case SystemPlaybackState.playing:
        playerState = PlayerState.isPlaying;
        if (_onStarted != null) _onStarted(wasUser: false);
        break;
      case SystemPlaybackState.paused:
        playerState = PlayerState.isPaused;
        if (_onPaused != null) _onPaused(wasUser: false);
        break;
      case SystemPlaybackState.stopped:
        playerState = PlayerState.isStopped;
        if (_onStopped != null) _onStopped(wasUser: false);
        break;
    }

    if (_onUpdatePlaybackState != null) {
      _onUpdatePlaybackState(systemPlaybackState);
    }
  }

  /// Pass a callback if you want to be notified
  /// when the user attempts to skip forward to the
  /// next track.
  /// This is only meaningful if you have used
  /// [AudioPlayer.withUI] which has a 'skip' button.
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

  /// Pass a callback if you want to be notified
  /// when the OS Media Player changs state.
  // ignore: avoid_setters_without_getters
  set onUpdatePlaybackState(OSPlayerStateEvent onUpdatePlaybackState) {
    _onUpdatePlaybackState = onUpdatePlaybackState;
  }

  ///
  /// Pass a callback if you want to be notified when
  /// playback is paused.
  /// The [wasUser] argument in the callback will
  /// be true if the user clicked the pause button
  /// on the OS UI.  To show the OS UI you must have called
  /// [AudioPlayer.withUI].
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
  /// [AudioPlayer.withUI].
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
  /// [AudioPlayer.withUI].
  // ignore: avoid_setters_without_getters
  set onStarted(PlayerEventWithCause onStarted) {
    _onStarted = onStarted;
  }

  /// Pass a callback if you want to be notified
  /// that audio has stopped playing.
  /// This can happen as the result of a user
  /// action (clicking the stop button) an api
  /// call [stop] or the audio naturally completes.
  ///
  /// [onStoppped]  can occur if you called [stop]
  /// or the user click the stop button (widget or OS)
  /// or the audio naturally completes.
  ///
  /// [AudioPlayer.withUI].
  // ignore: avoid_setters_without_getters
  set onStopped(PlayerEventWithCause onStopped) {
    _onStopped = onStopped;
  }

  /// Returns true if the specified decoder is supported
  ///  by flutter_sound on this platform
  Future<bool> isSupported(Codec codec) async {
    return _initializeAndRun<bool>(() async {
      // For decoding ogg/opus on ios, we need to support two steps :
      // - remux OGG file format to CAF file format (with ffmpeg)
      // - decode CAF/OPPUS (with native Apple AVFoundation)
      if ((codec == Codec.opusOGG) && (Platform.isIOS)) {
        codec = Codec.cafOpus;
      }
      return await _plugin.isSupported(this, codec);
    });
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
  /// the caller is responsible for using [audioFocus]
  /// and [abandonAudioFocus]
  ///    probably before startRecorder or startPlayer
  /// and stopPlayer and stopRecorder
  ///
  /// TODO
  /// Is this in the correct spot if it is only called once?
  /// Should we have a configuration object that sets
  /// up global options?
  ///
  /// I think this really needs to be abstracted out via our api.
  /// We should try to avoid any OS specific api's being exposed as
  /// part of the public api.
  ///
  Future<bool> iosSetCategory(
      IOSSessionCategory category, IOSSessionMode mode, int options) async {
    return _initializeAndRun<bool>(() async {
      return await _plugin.iosSetCategory(this, category, mode, options);
    });
  }

  ///  The caller can manage the audio focus with this function.
  /// Depending on your configuration this will either make
  /// this player the loudest stream or it will silence all other stream.
  Future<void> audioFocus(AudioFocus mode) async {
    return _initializeAndRun(() async {
      switch (mode) {
        case AudioFocus.focusAndKeepOthers:
          await _plugin.audioFocus(this, request: true);
          _setHush(hushOthers: false);
          break;
        case AudioFocus.focusAndStopOthers:
          await _plugin.audioFocus(this, request: true);
          // TODO: how do you stop other players?
          break;
        case AudioFocus.focusAndHushOthers:
          await _plugin.audioFocus(this, request: true);
          _setHush(hushOthers: true);
          break;
        case AudioFocus.abandonFocus:
          await _plugin.audioFocus(this, request: false);
          break;
      }
    });
  }

  /// Apply/Remove the hush other setting.
  void _setHush({bool hushOthers}) async {
    if (hushOthers) {
      if (Platform.isIOS) {
        await iosSetCategory(
            IOSSessionCategory.playAndRecord,
            IOSSessionMode.defaultMode,
            IOSSessionCategoryOption.iosDuckOthers |
                IOSSessionCategoryOption.iosDefaultToSpeaker);
      } else if (Platform.isAndroid) {
        await _androidFocusRequest(AndroidAudioFocusGain.transientMayDuck);
      }
    } else {
      if (Platform.isIOS) {
        await iosSetCategory(
            IOSSessionCategory.playAndRecord,
            IOSSessionMode.defaultMode,
            IOSSessionCategoryOption.iosDefaultToSpeaker);
      } else if (Platform.isAndroid) {
        await _androidFocusRequest(AndroidAudioFocusGain.defaultGain);
      }
    }
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

  Future<bool> _androidFocusRequest(int focusGain) async {
    return _initializeAndRun<bool>(() async {
      return await _plugin.androidFocusRequest(this, focusGain);
    });
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
typedef OSPlayerStateEvent = void Function(SystemPlaybackState);

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

void updateProgress(AudioPlayer player, PlaybackDisposition disposition) =>
    player._updateProgress(disposition);

/// Called if the audio has reached the end of the audio source
/// or if we or the os stopped the playback prematurely.
void audioPlayerFinished(AudioPlayer player, PlaybackDisposition status) =>
    player._audioPlayerFinished(status);

/// handles a pause coming up from the player
void onSystemPaused(AudioPlayer player) => player._onSystemPaused();

/// handles a resume coming up from the player
void onSystemResumed(AudioPlayer player) => player._onSystemResumed();

/// System event notification that the app has paused
void onSystemAppPaused(AudioPlayer player) => player._onSystemAppPaused();

/// System event notification that the app has resumed
void onSystemAppResumed(AudioPlayer player) => player._onSystemAppResumed();

/// handles a skip forward coming up from the player
void onSystemSkipForward(AudioPlayer player) => player._onSystemSkipForward();

/// handles a skip forward coming up from the player
void onSystemSkipBackward(AudioPlayer player) => player._onSystemSkipBackward();

/// Handles playback state changes coming up from the OS Media Player
void onSystemUpdatePlaybackState(
        AudioPlayer player, SystemPlaybackState playbackState) =>
    player._onSystemUpdatePlaybackState(playbackState);
