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

import 'audio_focus_mode.dart';
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
  PlayerEvent _onSkipForward;
  PlayerEvent _onSkipBackward;
  PlayerEvent _onFinished;
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
  final bool playInBackground;

  /// If the user calls seekTo before starting the track
  /// we cache the value until we start the player and
  /// then we apply the seek offset.
  Duration _seekTo;

  final PlayerBasePlugin _plugin;

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

  /// Used to wait for the plugin to connect us to an OS MediaPlayer
  Future<bool> _initialised;

  /// When we do a [softRelease] we need to flag that the plugin
  /// needs to be initialised so we set this to true.
  /// Its also true on construction to force the initial initialisation.
  bool _pluginInitRequired = true;

  Completer<bool> _connected = Completer<bool>();

  /// hack until we implement onConnect in the all the plugins.
  final bool _fakeOnConnect;

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
  /// player.onFinished = () => player.release();
  /// player.onStop = () => player.release();
  /// player.play(track);
  /// ```
  /// The above example guarentees that the player will be released.
  /// {@end-tool}
  AudioPlayer.withUI({
    this.canPause = true,
    this.canSkipBackward = false,
    this.canSkipForward = false,
    this.playInBackground = false,
  })  : _fakeOnConnect = Platform.isIOS,
        _plugin = SoundPlayerTrackPlugin() {
    _commonInit();
    _initialisePlugin();
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
  /// player.onFinished = () => player.release();
  /// player.onStop = () => player.release();
  /// player.play(track);
  /// ```
  /// The above example guarentees that the player will be released.
  /// {@end-tool}
  AudioPlayer.noUI({this.playInBackground = false})
      : _fakeOnConnect = true,
        _plugin = SoundPlayerPlugin() {
    canPause = false;
    canSkipBackward = false;
    canSkipForward = false;
    _commonInit();
    _initialisePlugin();
  }

  /// once off initialisation used by call ctors.
  void _commonInit() {
    _plugin.register(this);
    _plugin.onConnected = _onConnected;

    // place _initialised into a non-completed state.
    _connected = Completer<bool>();
    _initialised = _connected.future;

    /// track the current position
    _playerController.stream.listen((playbackDisposition) {
      _currentPosition = playbackDisposition.position;
    });
  }

  /// Initialises the plugin
  ///
  /// This will be called multiple times in the life cycle
  /// of a [AudioPlayer] as we release the plugin
  /// each time we stop the player.
  ///
  void _initialisePlugin() {
    if (_pluginInitRequired) {
      _pluginInitRequired = false;

      /// we allow five seconds for the connect to complete or
      /// we timeout returning false.
      _initialised = _connected.future
          .timeout(Duration(seconds: 5), onTimeout: () => Future.value(false));

      /// The plugin will call [onConnected] which completes
      /// the intialisation.
      _plugin.initialisePlayer(this);

      _setSubscriptionDuration(Duration(milliseconds: 100));

      /// hack until we implement onConnect in the all the plugins.
      if (_fakeOnConnect) _onConnected(result: true);
    }
  }

  /// Call this method once you are done with the player
  /// so that it can release all of the attached resources.
  /// await the [release] to ensure that all resources are released before
  /// you take future action.
  Future<void> release() async {
    var done = Completer<void>();
    initialised.then<void>((result) async {
      if (result == true) {
        _closeDispositionStream();
        await _softRelease();
        await _plugin.release(this);
      }
    }).whenComplete(() => done.complete());
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

      /// the plugin is in an initialised state
      /// so we need to release it.
      await _plugin.releasePlayer(this);
    }

    if (_track != null) {
      await t.trackRelease(_track);
    }

    // put _initilaised into a non completed
    // state so everyone will wait on it again.
    _connected = Completer<bool>();
    _initialised = _connected.future;
  }

  /// Future indicating if initialisation has completed.
  Future<bool> get initialised => _initialised;

  /// callback occurs when the OS MediaPlayer successfully connects:
  /// TODO: implement the onConnected event from iOS.
  /// [result] true if the connection succeeded.
  void _onConnected({bool result}) {
    _connected.complete(result);
  }

  /// Starts playback.
  /// The [track] to play.
  Future<void> play(t.Track track) async {
    assert(track != null);
    var started = Completer<void>();

    _currentPosition = Duration.zero;

    /// after stop is called the plugin will be released
    /// to save resources so we potentially need to re-initialise
    _initialisePlugin();
    initialised.then<void>((result) async {
      if (result == true) {
        _track = track;

        if (!isStopped) {
          var exception =
              PlayerInvalidStateException("The player must not be running.");
          started.completeError(exception);
          throw exception;
        }

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
      } else {
        var exception =
            PlayerInvalidStateException('Player initialisation failed');
        started.completeError(exception);
        throw exception;
      }
    });
    Log.d('*************play returning');
    return started.future;
  }

  /// Stops playback.
  Future<void> stop() async {
    initialised.then<void>((result) async {
      if (result == true) {
        if (isStopped) {
          Log.d("stop() was called when the player wasn't playing. Ignored");
        } else {
          try {
            playerState = PlayerState.isStopped;
            if (_onStopped != null) _onStopped(wasUser: false);
          } on Object catch (e) {
            Log.d(e.toString());
            rethrow;
          }
        }
      } else {
        throw PlayerInvalidStateException('Player initialisation failed');
      }
    });
  }

  /// Pauses playback.
  /// If you call this and the audio is not playing
  /// a [PlayerInvalidStateException] will be thrown.
  Future<void> pause() async {
    _initialisePlugin();
    initialised.then<void>((result) async {
      if (result == true) {
        if (playerState != PlayerState.isPlaying) {
          throw PlayerInvalidStateException('Player is not playing.');
        }
        playerState = PlayerState.isPaused;
        await _plugin.pause(this);

        if (_onPaused != null) _onPaused(wasUser: false);
      } else {
        throw PlayerInvalidStateException('Player initialisation failed');
      }
    });
  }

  /// Resumes playback.
  /// If you call this when audio is not paused
  /// then a [PlayerInvalidStateException] will be thrown.
  Future<void> resume() async {
    var canResume = await initialised;
    _initialisePlugin();
    initialised.then<void>((result) async {
      if (result == true) {
        if (playerState != PlayerState.isPaused) {
          throw PlayerInvalidStateException('Player is not paused.');
        }
        playerState = PlayerState.isPlaying;

        /// if the app has been sent to the background we will have
        /// released the plugin in which case a simple resume
        /// won't work.
        if (!canResume) {
          seekTo(_currentPosition);
          // given we have been pushed to the background
          // a little duplication of the audio is probably called for.
          rewind(Duration(seconds: 1));
        }
        await _plugin.resume(this);

        if (_onResumed != null) _onResumed(wasUser: false);
      } else {
        throw PlayerInvalidStateException('Player initialisation failed');
      }
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
    initialised.then<void>((result) async {
      if (result == true) {
        if (!isPlaying) {
          _seekTo = position;
        } else {
          await _plugin.seekToPlayer(this, position);
        }
      } else {
        throw PlayerInvalidStateException('Player initialisation failed');
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
    initialised.then<void>((result) async {
      if (result == true) {
        await _plugin.setVolume(this, volume);
      } else {
        throw PlayerInvalidStateException('Player initialisation failed');
      }
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
    initialised.then<void>((result) async {
      if (result == true) {
        assert(interval.inMilliseconds > 0);
        await _plugin.setSubscriptionDuration(this, interval);
      } else {
        throw PlayerInvalidStateException('Player initialisation failed');
      }
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
    if (_onFinished != null) _onFinished();
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
    Log.d(red('onSystemAppPaused playInBackground=$playInBackground'));
    if (!playInBackground) {
      if (isPlaying) {
        stop();
      }
      _softRelease();
    }
  }

  /// System event telling us that our app has been resumed.
  /// If we had previously stopped then we resuming playing
  /// from the last position - 1 second.
  void _onSystemAppResumed() {
    Log.d(red(
        'onSystemAppResumed playInBackground=$playInBackground track=$_track'));

    /// Looks like we can get multiple resume events so we
    /// check isPlaying to protect ourselves.
    if (!playInBackground && _track != null && !isPlaying) {
      rewind(Duration(seconds: 1));
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
  /// This is different from [onFinished] which
  /// is called when the auido plays to completion.
  ///
  /// [onStoppped]  can occur if you called [stop]
  /// or the user click the stop button on the
  /// OSs' UI. To show the OS UI you must have called
  /// [AudioPlayer.withUI].
  // ignore: avoid_setters_without_getters
  set onStopped(PlayerEventWithCause onStopped) {
    _onStopped = onStopped;
  }

  /// Returns true if the specified decoder is supported
  ///  by flutter_sound on this platform
  Future<bool> isSupported(Codec codec) async {
    return initialised.then<bool>((result) async {
      if (result == true) {
        bool result;
        // For decoding ogg/opus on ios, we need to support two steps :
        // - remux OGG file format to CAF file format (with ffmpeg)
        // - decode CAF/OPPUS (with native Apple AVFoundation)
        if ((codec == Codec.opusOGG) && (Platform.isIOS)) {
          codec = Codec.cafOpus;
        }
        result = await _plugin.isSupported(this, codec);
        return result;
      } else {
        throw PlayerInvalidStateException('Player initialisation failed');
      }
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
    return initialised.then<bool>((result) async {
      if (result == true) {
        return await _plugin.iosSetCategory(this, category, mode, options);
      } else {
        throw PlayerInvalidStateException('Player initialisation failed');
      }
    });
  }

  ///  The caller can manage his audio focus with this function
  /// Depending on your configuration this will either make
  /// this player the loudest stream or it will silence all other stream.
  Future<void> audioFocus(AudioFocusMode mode) async {
    initialised.then<void>((result) async {
      if (result == true) {
        switch (mode) {
          case AudioFocusMode.focusAndKeepOthers:
            await _plugin.audioFocus(this, request: true);
            _setHush(hushOthers: false);
            break;
          case AudioFocusMode.focusAndStopOthers:
            await _plugin.audioFocus(this, request: true);
            // TODO: how do you stop other players?
            break;
          case AudioFocusMode.focusAndDuckOthers:
            await _plugin.audioFocus(this, request: true);
            _setHush(hushOthers: true);
            break;
          case AudioFocusMode.abandonFocus:
            await _plugin.audioFocus(this, request: false);
            break;
        }
      } else {
        throw PlayerInvalidStateException('Player initialisation failed');
      }
    });
  }

  /// Apply/Remoe the hush other setting.
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
    return initialised.then<bool>((result) async {
      if (result == true) {
        return await _plugin.androidFocusRequest(this, focusGain);
      } else {
        throw PlayerInvalidStateException('Player initialisation failed');
      }
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
