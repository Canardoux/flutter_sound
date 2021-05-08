/*
 * Copyright 2018, 2019, 2020 Dooboolab.
 *
 * This file is part of Flutter-Sound.
 *
 * Flutter-Sound is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License version 3 (LGPL-V3), as published by
 * the Free Software Foundation.
 *
 * Flutter-Sound is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with Flutter-Sound.  If not, see <https://www.gnu.org/licenses/>.
 */

/// **THE** Flutter Sound Player
/// {@category Main}
library player;

import 'dart:async';
//import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:io' show Platform;
import 'dart:typed_data' show Uint8List;
import 'package:synchronized/synchronized.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_platform_interface.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_player_platform_interface.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../flutter_sound.dart';

/// The default blocksize used when playing from Stream.
const _blockSize = 4096;

/// The possible states of the Player.
enum PlayerState {
  /// Player is stopped
  isStopped,

  /// Player is playing
  isPlaying,

  /// Player is paused
  isPaused,
}

/// Playback function type for [FlutterSoundPlayer.startPlayer()].
///
/// Note : this type must include a parameter with a reference to the FlutterSoundPlayer object involved.
typedef TWhenFinished = void Function();

/// Playback function type for [FlutterSoundPlayer.startPlayerFromTrack()].
///
/// Note : this type must include a parameter with a reference to the FlutterSoundPlayer object involved.
typedef TonPaused = void Function(bool paused);

/// Playback function type for [FlutterSoundPlayer.startPlayerFromTrack()].
///
/// Note : this type must include a parameter with a reference to the FlutterSoundPlayer object involved.
typedef TonSkip = void Function();

//--------------------------------------------------------------------------------------------------------------------------------------------

/// A Player is an object that can playback from various sources.
///
/// ----------------------------------------------------------------------------------------------------
///
/// Using a player is very simple :
///
/// 1. Create a new `FlutterSoundPlayer`
///
/// 2. Open it with [openAudioSession()]
///
/// 3. Start your playback with [startPlayer()].
///
/// 4. Use the various verbs (optional):
///    - [pausePlayer()]
///    - [resumePlayer()]
///    - ...
///
/// 5. Stop your player : [stopPlayer()]
///
/// 6. Release your player when you have finished with it : [closeAudioSession()].
/// This verb will call [stopPlayer()] if necessary.
///
/// ----------------------------------------------------------------------------------------------------
class FlutterSoundPlayer implements FlutterSoundPlayerCallback {
  TonSkip _onSkipForward; // User callback "onPaused:"
  TonSkip _onSkipBackward; // User callback "onPaused:"
  TonPaused _onPaused; // user callback "whenPause:"
  final _lock = Lock();
  static bool _reStarted = true;

  ///
  StreamSubscription<Food> _foodStreamSubscription;

  ///
  StreamController<Food> _foodStreamController;

  ///
  Completer<int> _needSomeFoodCompleter;

  ///
  Completer<Duration> _startPlayerCompleter;
  Completer<void> _pausePlayerCompleter;
  Completer<void> _resumePlayerCompleter;
  Completer<void> _stopPlayerCompleter;
  Completer<void> _closePlayerCompleter;
  Completer<FlutterSoundPlayer> _openPlayerCompleter;

  ///
  static const List<Codec> _tabAndroidConvert = [
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
    Codec.defaultCodec, // amrNB
    Codec.defaultCodec, // amrWB
    Codec.defaultCodec, // pcm8
    Codec.defaultCodec, // pcmFloat32
    Codec.defaultCodec, // pcmWebM
    Codec.defaultCodec, // opusWebM
    Codec.defaultCodec, // vorbisWebM
  ];

  ///
  static const List<Codec> _tabIosConvert = [
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
    Codec.defaultCodec, // amrNB
    Codec.defaultCodec, // amrWB
    Codec.defaultCodec, // pcm8
    Codec.defaultCodec, // pcmFloat32
    Codec.defaultCodec, // pcmWebM
    Codec.defaultCodec, // opusWebM
    Codec.defaultCodec, // vorbisWebM
  ];

  ///
  static const List<Codec> _tabWebConvert = [
    Codec.defaultCodec, // defaultCodec
    Codec.defaultCodec, // aacADTS
    Codec.defaultCodec, // opusOGG
    Codec.defaultCodec, // opusCAF
    Codec.defaultCodec, // mp3
    Codec.defaultCodec, // vorbisOGG
    Codec.defaultCodec, // pcm16
    Codec.defaultCodec, // pcm16WAV
    Codec.defaultCodec, // pcm16AIFF
    Codec.defaultCodec, // pcm16CAF
    Codec.defaultCodec, // flac
    Codec.defaultCodec, // aacMP4
    Codec.defaultCodec, // amrNB
    Codec.defaultCodec, // amrWB
    Codec.defaultCodec, // pcm8
    Codec.defaultCodec, // pcmFloat32
    Codec.defaultCodec, // pcmWebM
    Codec.defaultCodec, // opusWebM
    Codec.defaultCodec, // vorbisWebM
  ];

  //===================================  Callbacks ================================================================

  /// Callback from the &tau; Core. Must not be called by the App
  /// @nodoc
  @override
  void updateProgress({
    int duration,
    int position,
  }) {
    if (duration < position) {
      print(' Duration = $duration,   Position = $position');
    }
    _playerController.add(
      PlaybackDisposition(
        position: Duration(milliseconds: position),
        duration: Duration(milliseconds: duration),
      ),
    );
  }

  /// Callback from the &tau; Core. Must not be called by the App
  /// @nodoc
  @override
  void pause(int state) async {
    print('FS:---> pause ');
    await _lock.synchronized(() async {
      assert(state != null);
      _playerState = PlayerState.values[state];
      if (_onPaused != null) // Probably always true
      {
        _onPaused(true);
      }
    });
    print('FS:<--- pause ');
  }

  /// Callback from the &tau; Core. Must not be called by the App
  /// @nodoc
  @override
  void resume(int state) async {
    print('FS:---> pause ');
    await _lock.synchronized(() async {
      assert(state != null);
      _playerState = PlayerState.values[state];
      if (_onPaused != null) // Probably always true
      {
        _onPaused(false);
      }
    });
    print('FS:<--- pause ');
  }

  /// Callback from the &tau; Core. Must not be called by the App
  /// @nodoc
  @override
  void skipBackward(int state) async {
    print('FS:---> skipBackward ');
    await _lock.synchronized(() async {
      assert(state != null);
      _playerState = PlayerState.values[state];

      if (_onSkipBackward != null) {
        _onSkipBackward();
      }
    });
    print('FS:<--- skipBackward ');
  }

  /// Callback from the &tau; Core. Must not be called by the App
  /// @nodoc
  @override
  void skipForward(int state) async {
    print('FS:---> skipForward ');
    await _lock.synchronized(() async {
      assert(state != null);
      _playerState = PlayerState.values[state];
      if (_onSkipForward != null) {
        _onSkipForward();
      }
    });
    print('FS:<--- skipForward ');
  }

  /// Callback from the &tau; Core. Must not be called by the App
  /// @nodoc
  @override
  void updatePlaybackState(int state) {
    assert(state != null);
    _playerState = PlayerState.values[state];
  }

  /// Callback from the &tau; Core. Must not be called by the App
  /// @nodoc
  @override
  void needSomeFood(int ln) {
    assert(ln >= 0);
    if (_needSomeFoodCompleter != null) {
      _needSomeFoodCompleter.complete(ln);
    }
  }

  /// Callback from the &tau; Core. Must not be called by the App
  /// @nodoc
  @override
  void audioPlayerFinished(int state) async {
    print('FS:---> audioPlayerFinished');
    //await _lock.synchronized(() async {
    //playerState = PlayerState.isStopped;
    //int state = call['arg'] as int;
    assert(state != null);
    _playerState = PlayerState.values[state];
    //await _stop(); // ??? Maybe ??? perhaps ??? //
    await stopPlayer(); // ??? Maybe ??? perhaps ??? //
    _cleanCompleters(); // We have problem when the record is finished and a resume is pending

    if (_audioPlayerFinishedPlaying != null) {
      _audioPlayerFinishedPlaying();
    }
    //});
    print('FS:<--- audioPlayerFinished');
  }

  /// Callback from the &tau; Core. Must not be called by the App
  /// @nodoc
  @override
  void openPlayerCompleted(int state, bool success) {
    print('---> openPlayerCompleted: $success');

    _playerState = PlayerState.values[state];
    _isInited =
        success ? Initialized.fullyInitialized : Initialized.notInitialized;
    if (success) {
      assert(state != null);
      if (_openPlayerCompleter == null) {
        print('Error : cannot process _openPlayerCompleter');
        return;
      }
      _openPlayerCompleter.complete(this);
    } else {
      _openPlayerCompleter.completeError('openPlayer failed');
    }
    _openPlayerCompleter = null;
    print('<--- openPlayerCompleted: $success');
  }

  /// Callback from the &tau; Core. Must not be called by the App
  /// @nodoc
  @override
  void closePlayerCompleted(int state, bool success) {
    print('---> closePlayerCompleted');
    _playerState = PlayerState.values[state];
    _isInited = Initialized.notInitialized;

    if (success) {
      if (_closePlayerCompleter == null) {
        print('Error : cannot process _closePlayerCompleter');
        return;
      }
      _closePlayerCompleter.complete(this);
    } else {
      _closePlayerCompleter.completeError('closePlayer failed');
    }
    _closePlayerCompleter = null;

    _cleanCompleters();
    print('<--- closePlayerCompleted');
  }

  /// Callback from the &tau; Core. Must not be called by the App
  /// @nodoc
  @override
  void pausePlayerCompleted(int state, bool success) {
    print('---> pausePlayerCompleted: $success');
    assert(state != null);
    if (_pausePlayerCompleter == null) {
      print('Error : cannot process _pausePlayerCompleter');
      return;
    }
    _playerState = PlayerState.values[state];
    if (success) {
      _pausePlayerCompleter.complete();
    } else {
      _pausePlayerCompleter.completeError('pausePlayer failed');
    }
    _pausePlayerCompleter = null;
    print('<--- pausePlayerCompleted: $success');
  }

  /// Callback from the &tau; Core. Must not be called by the App
  /// @nodoc
  @override
  void resumePlayerCompleted(int state, bool success) {
    print('---> resumePlayerCompleted: $success');
    assert(state != null);
    if (_resumePlayerCompleter == null) {
      print('Error : cannot process _resumePlayerCompleter');
      return;
    }
    _playerState = PlayerState.values[state];
    if (success) {
      _resumePlayerCompleter.complete();
    } else {
      _resumePlayerCompleter.completeError('resumePlayer failed');
    }
    _resumePlayerCompleter = null;
    print('<--- resumePlayerCompleted: $success');
  }

  /// Callback from the &tau; Core. Must not be called by the App
  /// @nodoc
  @override
  void startPlayerCompleted(int state, bool success, int duration) {
    print('---> startPlayerCompleted: $success');
    assert(state != null);
    if (_startPlayerCompleter == null) {
      print('Error : cannot process _startPlayerCompleter');
      return;
    }
    _playerState = PlayerState.values[state];
    if (success) {
      _startPlayerCompleter.complete(Duration(milliseconds: duration));
    } else {
      _startPlayerCompleter.completeError('startPlayer() failed');
    }
    _startPlayerCompleter = null;
    print('<--- startPlayerCompleted: $success');
  }

  /// Callback from the &tau; Core. Must not be called by the App
  /// @nodoc
  @override
  void stopPlayerCompleted(int state, bool success) {
    print('---> stopPlayerCompleted: $success');
    assert(state != null);
    if (_stopPlayerCompleter == null) {
      print('Error : cannot process stopPlayerCompleted');
      print('<--- stopPlayerCompleted: $success');
      return;
    }
    _playerState = PlayerState.values[state];
    if (success) {
      _stopPlayerCompleter.complete();
    } // stopRecorder must not gives errors
    else {
      _stopPlayerCompleter.completeError('stopPlayer failed');
    }
    _stopPlayerCompleter = null;
    // cleanCompleters(); ????
    print('<--- stopPlayerCompleted: $success');
  }

  void _cleanCompleters() {
    if (_pausePlayerCompleter != null) {
      print('Kill _pausePlayer()');
      var completer = _pausePlayerCompleter;
      _pausePlayerCompleter = null;
      completer.completeError('killed by cleanCompleters');
    }
    if (_resumePlayerCompleter != null) {
      print('Kill _resumePlayer()');
      var completer = _resumePlayerCompleter;
      _resumePlayerCompleter = null;
      completer.completeError('killed by cleanCompleters');
    }

    if (_startPlayerCompleter != null) {
      print('Kill _startPlayer()');
      Completer<void> completer = _startPlayerCompleter;
      _startPlayerCompleter = null;
      completer.completeError('killed by cleanCompleters');
    }

    if (_stopPlayerCompleter != null) {
      print('Kill _stopPlayer()');
      var completer = _stopPlayerCompleter;
      _stopPlayerCompleter = null;
      completer.completeError('killed by cleanCompleters');
    }

    if (_openPlayerCompleter != null) {
      print('Kill openPlayer()');
      Completer<void> completer = _openPlayerCompleter;
      _openPlayerCompleter = null;
      completer.completeError('killed by cleanCompleters');
    }

    if (_closePlayerCompleter != null) {
      print('Kill _closePlayer()');
      var completer = _closePlayerCompleter;
      _closePlayerCompleter = null;
      completer.completeError('killed by cleanCompleters');
    }
  }

  //===============================================================================================================

  /// Do not use. Should be a private variable
  /// @nodoc
  Initialized _isInited = Initialized.notInitialized;

  ///
  PlayerState _playerState = PlayerState.isStopped;

  /// The current state of the Player
  PlayerState get playerState => _playerState;

  /// The food Controller
  StreamController<PlaybackDisposition> _playerController;

  /// The sink side of the Food Controller
  ///
  /// This the output stream that you use when you want to play asynchronously live data.
  /// This StreamSink accept two kinds of objects :
  /// - FoodData (the buffers that you want to play)
  /// - FoodEvent (a call back to be called after a resynchronisation)
  ///
  /// *Example:*
  ///
  /// `This example` shows how to play Live data, without Back Pressure from Flutter Sound
  /// ```dart
  /// await myPlayer.startPlayerFromStream(codec: Codec.pcm16, numChannels: 1, sampleRate: 48000);
  ///
  /// myPlayer.foodSink.add(FoodData(aBuffer));
  /// myPlayer.foodSink.add(FoodData(anotherBuffer));
  /// myPlayer.foodSink.add(FoodData(myOtherBuffer));
  /// myPlayer.foodSink.add(FoodEvent((){_mPlayer.stopPlayer();}));
  /// ```
  StreamSink<Food> get foodSink =>
      _foodStreamController != null ? _foodStreamController.sink : null;

  /// The stream side of the Food Controller
  ///
  /// This is a stream on which FlutterSound will post the player progression.
  /// You may listen to this Stream to have feedback on the current playback.
  ///
  /// PlaybackDisposition has two fields :
  /// - Duration duration  (the total playback duration)
  /// - Duration position  (the current playback position)
  ///
  /// *Example:*
  /// ```dart
  ///         _playerSubscription = myPlayer.onProgress.listen((e)
  ///         {
  ///                 Duration maxDuration = e.duration;
  ///                 Duration position = e.position;
  ///                 ...
  ///         }
  /// ```
  Stream<PlaybackDisposition> get onProgress =>
      _playerController != null ? _playerController.stream : null;

  /// Return true if the Player has been open
  bool isOpen() {
    return (_isInited == Initialized.fullyInitialized);
  }

  /// Provides a stream of dispositions which
  /// provide updated position and duration
  /// as the audio is played.
  ///
  /// The duration may start out as zero until the
  /// media becomes available.
  /// The `interval` dictates the minimum interval between events
  /// being sent to the stream.
  ///
  /// The minimum interval supported is 100ms.
  ///
  /// Note: the underlying stream has a minimum frequency of 100ms
  /// so multiples of 100ms will give you the most consistent timing
  /// source.
  ///
  /// Note: all calls to [dispositionStream] against this player will
  /// share a single interval which will controlled by the last
  /// call to this method.
  ///
  /// If you pause the audio then no updates will be sent to the
  /// stream.
  Stream<PlaybackDisposition> dispositionStream() {
    return _playerController != null ? _playerController.stream : null;
  }

  /// User callback "whenFinished:"
  TWhenFinished _audioPlayerFinishedPlaying;

  /// Test the Player State
  bool get isPlaying => _playerState == PlayerState.isPlaying;

  /// Test the Player State
  bool get isPaused => _playerState == PlayerState.isPaused;

  /// Test the Player State
  bool get isStopped => _playerState == PlayerState.isStopped;

  Future<void> _waitOpen() async {
    while (_openPlayerCompleter != null) {
      print('Waiting for the player being opened');
      await _openPlayerCompleter.future;
    }
    if (_isInited == Initialized.notInitialized) {
      throw Exception('Player is not open');
    }
  }

  /// Open the Player.
  ///
  /// A player must be opened before used. A player correspond to an Audio Session. With other words, you must *open* the Audio Session before using it.
  /// When you have finished with a Player, you must close it. With other words, you must close your Audio Session.
  /// Opening a player takes resources inside the OS. Those resources are freed with the verb `closeAudioSession()`.
  /// Returns a Future, but the App does not need to wait the completion of this future before doing a [startPlayer()].
  /// The Future will be automaticaly waited by [startPlayer()]
  ///
  /// - [focus] : What to do with others App if they have already the Focus
  /// - [Category] : An optional parameter for iOS. See [iOS documentation](https://developer.apple.com/documentation/avfoundation/avaudiosessioncategory?language=objc).
  /// - [mode] : an optional parameter for iOS. See [iOS documentation](https://developer.apple.com/documentation/avfoundation/avaudiosessionmode?language=objc) to understand the meaning of this parameter.
  /// - [audioFlags] : an optional parameter for iOS
  /// - [withUI] : true if the App plan to use [closeAudioSession] later.
  ///
  ///
  /// *Example:*
  /// ```dart
  ///     myPlayer = await FlutterSoundPlayer().closeAudioSession(focus: Focus.requestFocusAndDuckOthers, outputToSpeaker | allowBlueTooth);
  ///
  ///     ...
  ///     (do something with myPlayer)
  ///     ...
  ///
  ///     await myPlayer.closeAudioSession();
  ///     myPlayer = null;
  /// ```
  Future<FlutterSoundPlayer> openAudioSession({
    AudioFocus focus = AudioFocus.requestFocusAndKeepOthers,
    SessionCategory category = SessionCategory.playAndRecord,
    SessionMode mode = SessionMode.modeDefault,
    AudioDevice device = AudioDevice.speaker,
    int audioFlags = outputToSpeaker | allowBlueToothA2DP | allowAirPlay,
    bool withUI = false,
  }) async {
    FlutterSoundPlayer r;
    await _lock.synchronized(() async {
      r = await _openAudioSession(
        focus: focus,
        category: category,
        mode: mode,
        device: device,
        audioFlags: audioFlags,
        withUI: withUI,
      );
    });
    return r;
  }

  Future<FlutterSoundPlayer> _openAudioSession({
    AudioFocus focus = AudioFocus.requestFocusAndKeepOthers,
    SessionCategory category = SessionCategory.playAndRecord,
    SessionMode mode = SessionMode.modeDefault,
    AudioDevice device = AudioDevice.speaker,
    int audioFlags = outputToSpeaker | allowBlueToothA2DP | allowAirPlay,
    bool withUI = false,
  }) async {
    print('FS:---> openAudioSession');
    while (_openPlayerCompleter != null) {
      //try {
      print('Another openPlayer() in progress');
      await _openPlayerCompleter.future;
      //}
      //catch (e) {

      //}
    }

    Completer<FlutterSoundPlayer> completer;
    //if (_isInited != Initialized.notInitialized)
    //await closeAudioSession(); // to be in a clean state
    if (_isInited != Initialized.notInitialized) {
      throw Exception('Player is already initialized');
    }

    if (_reStarted) {
      // Perhaps a Hot Restart ?  We must reset the plugin
      print("Resetting flutter_sound Player Plugin");
      _reStarted = false;
      await FlutterSoundPlayerPlatform.instance.resetPlugin(this);
    }
    FlutterSoundPlayerPlatform.instance.openSession(this);
    _setPlayerCallback();
    assert(_openPlayerCompleter == null);
    _openPlayerCompleter = Completer<FlutterSoundPlayer>();
    completer = _openPlayerCompleter;
    try {
      var state = await FlutterSoundPlayerPlatform.instance.openPlayer(this,
          focus: focus,
          category: category,
          mode: mode,
          audioFlags: audioFlags,
          device: device,
          withUI: withUI);
      _playerState = PlayerState.values[state];
      //isInited = success ?  Initialized.fullyInitialized : Initialized.notInitialized;
    } on Exception {
      _openPlayerCompleter = null;
      rethrow;
    }
    print('FS:<--- openAudioSession');
    return completer.future;
  }

  /// @nodoc
  @deprecated
  Future<FlutterSoundPlayer> openAudioSessionWithUI(
      {AudioFocus focus = AudioFocus.requestFocusAndKeepOthers,
      SessionCategory category = SessionCategory.playAndRecord,
      SessionMode mode = SessionMode.modeDefault,
      AudioDevice device = AudioDevice.speaker,
      int audioFlags = outputToSpeaker | allowBlueToothA2DP | allowAirPlay}) {
    return openAudioSession(
        focus: focus,
        category: category,
        mode: mode,
        device: device,
        withUI: true);
  }

  /// Set or unset the Audio Focus.
  ///
  /// This verb is very similar to [openAudioSession] and allow to change the parameters during an open Session
  /// *Example:*
  /// ```dart
  ///         myPlayer.setAudioFocus(focus: AudioFocus.requestFocusAndDuckOthers);
  /// ```
  Future<void> setAudioFocus({
    AudioFocus focus = AudioFocus.requestFocusAndKeepOthers,
    SessionCategory category = SessionCategory.playback,
    SessionMode mode = SessionMode.modeDefault,
    AudioDevice device = AudioDevice.speaker,
    int audioFlags =
        outputToSpeaker | allowBlueTooth | allowBlueToothA2DP | allowEarPiece,
  }) async {
    await _lock.synchronized(() async {
      await _setAudioFocus(
        focus: focus,
        category: category,
        mode: mode,
        device: device,
        audioFlags: audioFlags,
      );
    });
  }

  Future<void> _setAudioFocus({
    AudioFocus focus = AudioFocus.requestFocusAndKeepOthers,
    SessionCategory category = SessionCategory.playback,
    SessionMode mode = SessionMode.modeDefault,
    AudioDevice device = AudioDevice.speaker,
    int audioFlags =
        outputToSpeaker | allowBlueTooth | allowBlueToothA2DP | allowEarPiece,
  }) async {
    print('FS:---> setAudioFocus ');
    await _waitOpen();
    if (_isInited != Initialized.fullyInitialized) {
      throw Exception('Player is not open');
    }
    var state = await FlutterSoundPlayerPlatform.instance.setAudioFocus(
      this,
      focus: focus,
      category: category,
      mode: mode,
      audioFlags: audioFlags,
      device: device,
    );
    _playerState = PlayerState.values[state];
    print('FS:<--- setAudioFocus ');
  }

  /// Close an open session.
  ///
  /// Must be called when finished with a Player, to release all the resources.
  /// It is safe to call this procedure at any time.
  /// - If the Player is not open, this verb will do nothing
  /// - If the Player is currently in play or pause mode, it will be stopped before.
  ///
  /// example:
  /// ```dart
  /// @override
  /// void dispose()
  /// {
  ///         if (myPlayer != null)
  ///         {
  ///             myPlayer.closeAudioSession();
  ///             myPlayer = null;
  ///         }
  ///         super.dispose();
  /// }
  /// ```
  Future<void> closeAudioSession() async {
    await _lock.synchronized(() async {
      await _closeAudioSession();
    });
  }

  Future<void> _closeAudioSession() async {
    print('FS:---> closeAudioSession ');

    // If another closePlayer() is already in progress, wait until finished
    while (_closePlayerCompleter != null) {
      //try {
      print('Another closePlayer() in progress');
      await _closePlayerCompleter.future;
      //}
      //catch (e) {

      //}
    }

    if (_isInited == Initialized.notInitialized) {
      // Already closed
      print('Player already close');
      return;
    }

    Completer<void> completer;
    try {
      await _stop(); // Stop the player if running
      //_isInited = Initialized.initializationInProgress; // BOF

      _removePlayerCallback();
      assert(_closePlayerCompleter == null);
      _closePlayerCompleter = Completer<void>();
      completer = _closePlayerCompleter;
      await FlutterSoundPlayerPlatform.instance.closePlayer(this);

      FlutterSoundPlayerPlatform.instance.closeSession(this);
      //_isInited = Initialized.notInitialized;
    } on Exception {
      _closePlayerCompleter = null;
      rethrow;
    }
    print('FS:<--- closeAudioSession ');
    return completer.future;
  }

  /// Query the current state to the Tau Core layer.
  ///
  /// Most of the time, the App will not use this verb,
  /// but will use the [playerState] variable.
  /// This is seldom used when the App wants to get
  /// an updated value the background state.
  Future<PlayerState> getPlayerState() async {
    await _waitOpen();
    if (_isInited != Initialized.fullyInitialized) {
      throw Exception('Player is not open');
    }
    var state = await FlutterSoundPlayerPlatform.instance.getPlayerState(this);
    _playerState = PlayerState.values[state];
    return _playerState;
  }

  /// Get the current progress of a playback.
  ///
  /// It returns a `Map` with two Duration entries : `'progress'` and `'duration'`.
  /// Remark : actually only implemented on iOS.
  ///
  /// *Example:*
  /// ```dart
  ///         Duration progress = (await getProgress())['progress'];
  ///         Duration duration = (await getProgress())['duration'];
  /// ```
  Future<Map<String, Duration>> getProgress() async {
    await _waitOpen();
    if (_isInited != Initialized.fullyInitialized) {
      throw Exception('Player is not open');
    }

    return FlutterSoundPlayerPlatform.instance.getProgress(this);
  }

  ///
  bool _needToConvert(Codec codec) {
    print('FS:---> needToConvert ');
    if (codec == null) return false;
    var convert = (kIsWeb)
        ? _tabWebConvert[codec.index]
        : (Platform.isIOS)
            ? _tabIosConvert[codec.index]
            : (Platform.isAndroid)
                ? _tabAndroidConvert[codec.index]
                : null;
    print('FS:<--- needToConvert ');
    return (convert != Codec.defaultCodec);
  }

  /// Returns true if the specified decoder is supported by flutter_sound on this platform
  ///
  /// *Example:*
  /// ```dart
  ///         if ( await myPlayer.isDecoderSupported(Codec.opusOGG) ) doSomething;
  /// ```
  Future<bool> isDecoderSupported(Codec codec) async {
    bool result;
    print('FS:---> isDecoderSupported ');
    await _waitOpen();
    if (_isInited != Initialized.fullyInitialized) {
      throw Exception('Player is not open');
    }
    // For decoding ogg/opus on ios, we need to support two steps :
    // - remux OGG file format to CAF file format (with ffmpeg)
    // - decode CAF/OPPUS (with native Apple AVFoundation)

    if (_needToConvert(codec)) {
      if (!await flutterSoundHelper.isFFmpegAvailable()) return false;
      var convert = kIsWeb
          ? _tabWebConvert[codec.index]
          : (Platform.isIOS)
              ? _tabIosConvert[codec.index]
              : (Platform.isAndroid)
                  ? _tabAndroidConvert[codec.index]
                  : null;
      result = await FlutterSoundPlayerPlatform.instance
          .isDecoderSupported(this, codec: convert);
    } else {
      result = await FlutterSoundPlayerPlatform.instance
          .isDecoderSupported(this, codec: codec);
    }
    print('FS:<--- isDecoderSupported ');
    return result;
  }

  /// Specify the callbacks frenquency, before calling [startPlayer].
  ///
  /// The default value is 0 (zero) which means that there is no callbacks.
  ///
  /// This verb will be Deprecated soon.
  ///
  /// *Example:*
  /// ```dart
  /// myPlayer.setSubscriptionDuration(Duration(milliseconds: 100));
  /// ```
  Future<void> setSubscriptionDuration(Duration duration) async {
    print('FS:---> setSubscriptionDuration ');
    await _waitOpen();
    if (_isInited != Initialized.fullyInitialized) {
      throw Exception('Player is not open');
    }
    var state = await FlutterSoundPlayerPlatform.instance
        .setSubscriptionDuration(this, duration: duration);
    _playerState = PlayerState.values[state];
    print('FS:<---- setSubscriptionDuration ');
  }

  ///
  void _setPlayerCallback() {
    _playerController ??= StreamController<PlaybackDisposition>.broadcast();
  }

  void _removePlayerCallback() {
    if (_playerController != null) {
      _playerController
        //..add(null)
        ..close();
      _playerController = null;
    }
  }

  ///
  Future<void> _convertAudio(Map<String, dynamic> what) async {
    // If we want to play OGG/OPUS on iOS, we remux the OGG file format to a specific Apple CAF envelope before starting the player.
    // We use FFmpeg for that task.
    print('FS:---> _convertAudio ');
    var tempDir = await getTemporaryDirectory();
    var codec = what['codec'] as Codec;
    var convert = kIsWeb
        ? _tabWebConvert[codec.index]
        : (Platform.isIOS)
            ? _tabIosConvert[codec.index]
            : (Platform.isAndroid)
                ? _tabAndroidConvert[codec.index]
                : null;
    var fout = '${tempDir.path}/flutter_sound-tmp2${ext[convert.index]}';
    var path = what['path'] as String;
    await flutterSoundHelper.convertFile(path, codec, fout, convert);

    // Now we can play Apple CAF/OPUS

    what['path'] = fout;
    what['codec'] = convert;
    print('FS:<--- _convertAudio ');
  }

  Future<void> _convert(Map<String, dynamic> what) async {
    print('FS:---> _convert ');
    var codec = what['codec'] as Codec;
    if (_needToConvert(codec)) {
      var fromDataBuffer = what['fromDataBuffer'] as Uint8List;

      if (fromDataBuffer != null) {
        var tempDir = await getTemporaryDirectory();
        var inputFile = File('${tempDir.path}/flutter_sound-tmp');

        if (inputFile.existsSync()) {
          await inputFile.delete();
        }
        inputFile.writeAsBytesSync(
            fromDataBuffer); // Write the user buffer into the temporary file
        what['fromDataBuffer'] = null;
        what['path'] = inputFile.path;
      }
      await _convertAudio(what);
    }
    print('FS:<--- _convert ');
  }

  /// Used to play a sound.
  //
  /// - `startPlayer()` has three optional parameters, depending on your sound source :
  ///    - `fromUri:`  (if you want to play a file or a remote URI)
  ///    - `fromDataBuffer:` (if you want to play from a data buffer)
  ///    - `sampleRate` is mandatory if `codec` == `Codec.pcm16`. Not used for other codecs.
  ///
  /// You must specify one or the three parameters : `fromUri`, `fromDataBuffer`, `fromStream`.
  ///
  /// - You use the optional parameter`codec:` for specifying the audio and file format of the file. Please refer to the [Codec compatibility Table](codec.md#actually-the-following-codecs-are-supported-by-flutter_sound) to know which codecs are currently supported.
  ///
  /// - `whenFinished:()` : A lambda function for specifying what to do when the playback will be finished.
  ///
  /// Very often, the `codec:` parameter is not useful. Flutter Sound will adapt itself depending on the real format of the file provided.
  /// But this parameter is necessary when Flutter Sound must do format conversion (for example to play opusOGG on iOS).
  ///
  /// `startPlayer()` returns a Duration Future, which is the record duration.
  ///
  /// The `fromUri` parameter, if specified, can be one of three posibilities :
  /// - The URL of a remote file
  /// - The path of a local file
  /// - The name of a temporary file (without any slash '/')
  ///
  /// Hint: [path_provider](https://pub.dev/packages/path_provider) can be useful if you want to get access to some directories on your device.
  ///
  ///
  /// *Example:*
  /// ```dart
  ///         Duration d = await myPlayer.startPlayer(fromURI: 'foo', codec: Codec.aacADTS); // Play a temporary file
  ///
  ///         _playerSubscription = myPlayer.onProgress.listen((e)
  ///         {
  ///                 // ...
  ///         });
  /// }
  /// ```
  ///
  /// *Example:*
  /// ```dart
  ///     final fileUri = "https://file-examples.com/wp-content/uploads/2017/11/file_example_MP3_700KB.mp3";
  ///
  ///     Duration d = await myPlayer.startPlayer
  ///     (
  ///                 fromURI: fileUri,
  ///                 codec: Codec.mp3,
  ///                 whenFinished: ()
  ///                 {
  ///                          print( 'I hope you enjoyed listening to this song' );
  ///                 },
  ///     );
  /// ```
  Future<Duration> startPlayer({
    String fromURI,
    Uint8List fromDataBuffer,
    Codec codec = Codec.aacADTS,
    int sampleRate = 16000, // Used only with codec == Codec.pcm16
    int numChannels = 1, // Used only with codec == Codec.pcm16
    TWhenFinished whenFinished,
  }) async {
    Duration r;
    await _lock.synchronized(() async {
      r = await _startPlayer(
        fromURI: fromURI,
        fromDataBuffer: fromDataBuffer,
        codec: codec,
        sampleRate: sampleRate,
        numChannels: numChannels,
        whenFinished: whenFinished,
      );
    });
    return r;
  }

  Future<Duration> _startPlayer({
    String fromURI,
    Uint8List fromDataBuffer,
    Codec codec = Codec.aacADTS,
    int sampleRate = 16000, // Used only with codec == Codec.pcm16
    int numChannels = 1, // Used only with codec == Codec.pcm16
    TWhenFinished whenFinished,
  }) async {
    print('FS:---> startPlayer ');
    await _waitOpen();
    if (_isInited != Initialized.fullyInitialized) {
      throw Exception('Player is not open');
    }

    if (codec == Codec.pcm16 && fromURI != null) {
      var tempDir = await getTemporaryDirectory();
      var path = '${tempDir.path}/flutter_sound_tmp.wav';
      await flutterSoundHelper.pcmToWave(
        inputFile: fromURI,
        outputFile: path,
        numChannels: 1,
        //bitsPerSample: 16,
        sampleRate: sampleRate,
      );
      fromURI = path;
      codec = Codec.pcm16WAV;
    } else if (codec == Codec.pcm16 && fromDataBuffer != null) {
      fromDataBuffer = await flutterSoundHelper.pcmToWaveBuffer(
          inputBuffer: fromDataBuffer,
          sampleRate: sampleRate,
          numChannels: numChannels);
      codec = Codec.pcm16WAV;
    }
    Completer<Duration> completer;

    await _stop(); // Just in case

    //playerState = PlayerState.isPlaying;
    var what = <String, dynamic>{
      'codec': codec,
      'path': fromURI,
      'fromDataBuffer': fromDataBuffer,
    };
    await _convert(what);
    codec = what['codec'] as Codec;
    fromURI = what['path'] as String;
    fromDataBuffer = what['fromDataBuffer'] as Uint8List;
    if (_playerState != PlayerState.isStopped) {
      throw Exception('Player is not stopped');
    }
    _audioPlayerFinishedPlaying = whenFinished;
    if (_startPlayerCompleter != null) {
      print("Killing another startPlayer()");
      _startPlayerCompleter.completeError('Killed by another startPlayer()');
    }
    try {
      _startPlayerCompleter = Completer<Duration>();
      completer = _startPlayerCompleter;
      var state = await FlutterSoundPlayerPlatform.instance.startPlayer(
        this,
        codec: codec,
        fromDataBuffer: fromDataBuffer,
        fromURI: fromURI,
      );
      _playerState = PlayerState.values[state];
    } on Exception {
      _startPlayerCompleter = null;
      rethrow;
    }
    //Duration duration = Duration(milliseconds: retMap['duration'] as int);
    print('FS:<--- startPlayer ');
    return completer.future;
  }

  /// Starts the Microphone and plays what is recorded.
  ///
  /// The Speaker is directely linked to the Microphone.
  /// There is no processing between the Microphone and the Speaker.
  /// If you want to process the data before playing them, actually you must define a loop between a [FlutterSoundPlayer] and a [FlutterSoundRecorder].
  /// (Please, look to [this example](http://www.canardoux.xyz/tau_sound/doc/pages/flutter-sound/api/topics/flutter_sound_examples_stream_loop.html)).
  ///
  /// Later, we will implement the _Tau Audio Graph_ concept, which will be a more general object.
  ///
  /// - `startPlayerFromMic()` has two optional parameters :
  ///    - `sampleRate:` the Sample Rate used. Optional. Only used on Android. The default value is probably a good choice and the App can ommit this optional parameter.
  ///    - `numChannels:` 1 for monophony, 2 for stereophony. Optional. Actually only monophony is implemented.
  ///
  /// `startPlayerFromMic()` returns a Future, which is completed when the Player is really started.
  ///
  /// *Example:*
  /// ```dart
  ///     await myPlayer.startPlayerFromMic();
  ///     ...
  ///     myPlayer.stopPlayer();
  /// ```
  Future<void> startPlayerFromMic({
    int sampleRate = 44000, // The default value is probably a good choice.
    int numChannels =
        1, // 1 for monophony, 2 for stereophony (actually only monophony is supported).
  }) async {
    await _lock.synchronized(() async {
      await _startPlayerFromMic(
        sampleRate: sampleRate,
        numChannels: numChannels,
      );
    });
  }

  Future<void> _startPlayerFromMic({
    int sampleRate = 44000, // The default value is probably a good choice.
    int numChannels =
        1, // 1 for monophony, 2 for stereophony (actually only monophony is supported).
  }) async {
    print('FS:---> startPlayerFromMic ');
    await _waitOpen();
    if (_isInited != Initialized.fullyInitialized) {
      throw Exception('Player is not open');
    }
    Completer<Duration> completer;
    await _stop(); // Just in case
    try {
      if (_startPlayerCompleter != null) {
        print('Killing another startPlayer()');
        _startPlayerCompleter.completeError('Killed by another startPlayer()');
      }
      _startPlayerCompleter = Completer<Duration>();
      completer = _startPlayerCompleter;
      var state = await FlutterSoundPlayerPlatform.instance.startPlayerFromMic(
          this,
          numChannels: numChannels,
          sampleRate: sampleRate);
      _playerState = PlayerState.values[state];
    } on Exception {
      _startPlayerCompleter = null;
      rethrow;
    }
    print('FS:<--- startPlayerFromMic ');
    return completer.future;
  }

  /// Used to play something froma Dart stream
  ///
  /// **This functionnality needs, at least, and Android SDK >= 21**
  ///
  ///   - The only codec supported is actually `Codec.pcm16`.
  ///   - The only value possible for `numChannels` is actually 1.
  ///   - SampleRate is the sample rate of the data you want to play.
  ///
  ///   Please look to [the following notice](codec.md#playing-pcm-16-from-a-dart-stream)
  ///
  ///   *Example*
  ///   You can look to the three provided examples :
  ///
  ///   - [This example](../flutter_sound/example/example.md#liveplaybackwithbackpressure) shows how to play Live data, with Back Pressure from Flutter Sound
  ///   - [This example](../flutter_sound/example/example.md#liveplaybackwithoutbackpressure) shows how to play Live data, without Back Pressure from Flutter Sound
  ///   - [This example](../flutter_sound/example/example.md#soundeffect) shows how to play some real time sound effects.
  ///
  ///   *Example 1:*
  ///   ```dart
  ///   await myPlayer.startPlayerFromStream(codec: Codec.pcm16, numChannels: 1, sampleRate: 48000);
  ///
  ///   await myPlayer.feedFromStream(aBuffer);
  ///   await myPlayer.feedFromStream(anotherBuffer);
  ///   await myPlayer.feedFromStream(myOtherBuffer);
  ///
  ///   await myPlayer.stopPlayer();
  ///   ```
  ///   *Example 2:*
  ///   ```dart
  ///   await myPlayer.startPlayerFromStream(codec: Codec.pcm16, numChannels: 1, sampleRate: 48000);
  ///
  ///   myPlayer.foodSink.add(FoodData(aBuffer));
  ///  myPlayer.foodSink.add(FoodData(anotherBuffer));
  ///   myPlayer.foodSink.add(FoodData(myOtherBuffer));
  ///
  ///   myPlayer.foodSink.add(FoodEvent((){_mPlayer.stopPlayer();}));
  ///   ```
  Future<void> startPlayerFromStream({
    Codec codec = Codec.pcm16,
    int numChannels = 1,
    int sampleRate = 16000,
  }) async {
    await _lock.synchronized(() async {
      await _startPlayerFromStream(
        codec: codec,
        sampleRate: sampleRate,
        numChannels: numChannels,
      );
    });
  }

  Future<void> _startPlayerFromStream({
    Codec codec = Codec.pcm16,
    int numChannels = 1,
    int sampleRate = 16000,
  }) async {
    print('FS:---> startPlayerFromStream ');
    await _waitOpen();
    if (_isInited != Initialized.fullyInitialized) {
      throw Exception('Player is not open');
    }
    Completer<Duration> completer;

    await _stop(); // Just in case
    _foodStreamController = StreamController();
    _foodStreamSubscription = _foodStreamController.stream.listen((food) {
      _foodStreamSubscription.pause(food.exec(this));
    });
    if (_startPlayerCompleter != null) {
      print('Killing another startPlayer()');
      _startPlayerCompleter.completeError('Killed by another startPlayer()');
    }
    try {
      _startPlayerCompleter = Completer<Duration>();
      completer = _startPlayerCompleter;
      var state = await FlutterSoundPlayerPlatform.instance.startPlayer(this,
          codec: codec,
          fromDataBuffer: null,
          fromURI: null,
          numChannels: numChannels,
          sampleRate: sampleRate);
      _playerState = PlayerState.values[state];
    } on Exception {
      _startPlayerCompleter = null;
      rethrow;
    }
    print('FS:<--- startPlayerFromStream ');
    return completer.future;
  }

  ///  Used when you want to play live PCM data synchronously.
  ///
  ///  This procedure returns a Future. It is very important that you wait that this Future is completed before trying to play another buffer.
  ///
  ///  *Example:*
  ///
  ///  - [This example](../flutter_sound/example/example.md#liveplaybackwithbackpressure) shows how to play Live data, with Back Pressure from Flutter Sound
  ///  - [This example](../flutter_sound/example/example.md#soundeffect) shows how to play some real time sound effects synchronously.
  ///
  ///  ```dart
  ///  await myPlayer.startPlayerFromStream(codec: Codec.pcm16, numChannels: 1, sampleRate: 48000);
  ///
  ///  await myPlayer.feedFromStream(aBuffer);
  ///  await myPlayer.feedFromStream(anotherBuffer);
  ///  await myPlayer.feedFromStream(myOtherBuffer);
  ///
  ///  await myPlayer.stopPlayer();
  ///  ```
  Future<void> feedFromStream(Uint8List buffer) async {
    await _feedFromStream(buffer);
  }

  Future<void> _feedFromStream(Uint8List buffer) async {
    var lnData = 0;
    var totalLength = buffer.length;
    while (totalLength > 0 && !isStopped) {
      var bsize = totalLength > _blockSize ? _blockSize : totalLength;
      var ln = await _feed(buffer.sublist(lnData, lnData + bsize));
      assert(ln >= 0);
      lnData += ln;
      totalLength -= ln;
    }
  }

  ///
  Future<int> _feed(Uint8List data) async {
    await _waitOpen();
    if (_isInited != Initialized.fullyInitialized) {
      throw Exception('Player is not open');
    }
    if (isStopped) {
      return 0;
    }
    _needSomeFoodCompleter = Completer<int>();
    try {
      var ln = await FlutterSoundPlayerPlatform.instance.feed(
        this,
        data: data,
      );
      assert(ln >= 0); // feedFromStream() is not happy if < 0
      if (ln != 0) {
        _needSomeFoodCompleter = null;
        return (ln);
      }
    } on Exception {
      _needSomeFoodCompleter = null;
      if (isStopped) {
        return 0;
      }
      rethrow;
    }

    if (_needSomeFoodCompleter != null) {
      return _needSomeFoodCompleter.future;
    }
    return 0;
  }

  /// Play data from a track specification and display controls on the lock screen or an Apple Watch.
  ///
  /// The Audio Session must have been open with the parameter `withUI`.
  ///
  /// - `track` parameter is a simple structure which describe the sound to play. Please see [here the Track structure specification](track.md)
  ///
  ///   - `whenFinished:()` : A function for specifying what to do when the playback will be finished.
  ///
  ///  - `onPaused:()` : this parameter can be :
  ///  - a call back function to call when the user hit the Skip Pause button on the lock screen
  ///  - `null` : The pause button will be handled by Flutter Sound internal
  ///
  ///   - `onSkipForward:()` : this parameter can be :
  ///   - a call back function to call when the user hit the Skip Forward button on the lock screen
  ///   - `null` : The Skip Forward button will be disabled
  ///
  ///  - `onSkipBackward:()` : this parameter can be :
  ///   - a call back function to call when the user hit the Skip Backward button on the lock screen
  ///   - <null> : The Skip Backward button will be disabled
  ///
  ///   - `removeUIWhenStopped` : is a boolean to specify if the UI on the lock screen must be removed when the sound is finished or when the App does a `stopPlayer()`.
  ///   Most of the time this parameter must be true. It is used only for the rare cases where the App wants to control the lock screen between two playbacks.
  ///   Be aware that if the UI is not removed, the button Pause/Resume, Skip Backward and Skip Forward remain active between two playbacks.
  ///   If you want to disable those button, use the API verb ```nowPlaying()```.
  ///   Remark: actually this parameter is implemented only on iOS.
  ///
  ///   - `defaultPauseResume` : is a boolean value to specify if Flutter Sound must pause/resume the playback by itself when the user hit the pause/resume button. Set this parameter to *FALSE* if the App wants to manage itself the pause/resume button. If you do not specify this parameter and the `onPaused` parameter is specified then Flutter Sound will assume `FALSE`. If you do not specify this parameter and the `onPaused` parameter is not specified then Flutter Sound will assume `TRUE`.
  ///   Remark: actually this parameter is implemented only on iOS.
  ///
  ///
  ///  `startPlayerFromTrack()` returns a Duration Future, which is the record duration.
  ///
  ///
  ///   *Example:*
  ///   ```dart
  ///   final fileUri = "https://file-examples.com/wp-content/uploads/2017/11/file_example_MP3_700KB.mp3";
  ///   Track track = Track( codec: Codec.opusOGG, trackPath: fileUri, trackAuthor: '3 Inches of Blood', trackTitle: 'Axes of Evil', albumArtAsset: albumArt )
  ///   Duration d = await myPlayer.startPlayerFromTrack
  ///   (
  ///   track,
  ///   whenFinished: ()
  ///   {
  ///     print( 'I hope you enjoyed listening to this song' );
  ///   },
  ///   );
  ///   ```
  Future<Duration> startPlayerFromTrack(
    Track track, {
    TonSkip onSkipForward,
    TonSkip onSkipBackward,
    TonPaused onPaused,
    TWhenFinished whenFinished,
    Duration progress,
    Duration duration,
    bool defaultPauseResume,
    bool removeUIWhenStopped = true,
  }) async {
    Duration r;
    await _lock.synchronized(() async {
      r = await _startPlayerFromTrack(
        track,
        onSkipForward: onSkipForward,
        onSkipBackward: onSkipBackward,
        onPaused: onPaused,
        whenFinished: whenFinished,
        progress: progress,
        duration: duration,
        defaultPauseResume: defaultPauseResume,
        removeUIWhenStopped: removeUIWhenStopped,
      );
    });
    return r;
  }

  Future<Duration> _startPlayerFromTrack(
    Track track, {
    TonSkip onSkipForward,
    TonSkip onSkipBackward,
    TonPaused onPaused,
    TWhenFinished whenFinished,
    Duration progress,
    Duration duration,
    bool defaultPauseResume,
    bool removeUIWhenStopped = true,
  }) async {
    print('FS:---> startPlayerFromTrack ');
    await _waitOpen();
    if (_isInited != Initialized.fullyInitialized) {
      throw Exception('Player is not open');
    }
    Completer<Duration> completer;
    //Map retMap;
    try {
      await _stop(); // Just in case
      _audioPlayerFinishedPlaying = whenFinished;
      _onSkipForward = onSkipForward;
      _onSkipBackward = onSkipBackward;
      _onPaused = onPaused;
      var trackDico = track.toMap();
      var what = <String, dynamic>{
        'codec': track.codec,
        'path': track.trackPath,
        'fromDataBuffer': track.dataBuffer,
      };
      await _convert(what);
      var codec = what['codec'] as Codec;
      trackDico['bufferCodecIndex'] = codec.index;
      trackDico['path'] = what['path'];
      trackDico['dataBuffer'] = what['fromDataBuffer'];
      trackDico['codec'] = codec.index;

      defaultPauseResume ??= (onPaused == null);
      if (_playerState != PlayerState.isStopped) {
        throw Exception('Player is not stopped');
      }

      if (_startPlayerCompleter != null) {
        print('Killing another startPlayer()');
        _startPlayerCompleter.completeError('Killed by another startPlayer()');
      }
      _startPlayerCompleter = Completer<Duration>();
      completer = _startPlayerCompleter;

      var state =
          await FlutterSoundPlayerPlatform.instance.startPlayerFromTrack(
        this,
        progress: progress,
        duration: duration,
        track: trackDico,
        canPause: (onPaused != null || defaultPauseResume),
        canSkipForward: (onSkipForward != null),
        canSkipBackward: (onSkipBackward != null),
        defaultPauseResume: defaultPauseResume,
        removeUIWhenStopped: removeUIWhenStopped,
      );
      _playerState = PlayerState.values[state];
    } on Exception {
      _startPlayerCompleter = null;
      rethrow;
    }
    //Duration d = Duration(milliseconds: retMap['duration'] as int);
    //int state = retMap['state'] as int;
    //playerState = PlayerState.values[state];
    print('FS:<--- startPlayerFromTrack ');
    return completer.future;
  }

  /// Set the Lock screen fields without starting a new playback.
  ///
  /// The fields 'dataBuffer' and 'trackPath' of the Track parameter are not used.
  /// Please refer to 'startPlayerFromTrack' for the meaning of the others parameters.
  /// Remark `setUIProgressBar()` is implemented only on iOS.
  ///
  ///  *Example:*
  ///  ```dart
  ///  Track track = Track( codec: Codec.opusOGG, trackPath: fileUri, trackAuthor: '3 Inches of Blood', trackTitle: 'Axes of Evil', albumArtAsset: albumArt );
  ///  await nowPlaying(Track);
  ///  ```
  Future<void> nowPlaying(
    Track track, {
    Duration duration,
    Duration progress,
    TonSkip onSkipForward,
    TonSkip onSkipBackward,
    TonPaused onPaused,
    bool defaultPauseResume,
  }) async {
    await _lock.synchronized(() async {
      await _nowPlaying(
        track,
        duration: duration,
        progress: progress,
        onSkipBackward: _onSkipBackward,
        onSkipForward: _onSkipForward,
        onPaused: onPaused,
        defaultPauseResume: defaultPauseResume,
      );
    });
  }

  Future<void> _nowPlaying(
    Track track, {
    Duration duration,
    Duration progress,
    TonSkip onSkipForward,
    TonSkip onSkipBackward,
    TonPaused onPaused,
    bool defaultPauseResume,
  }) async {
    print('FS:---> nowPlaying ');
    await _waitOpen();
    if (_isInited != Initialized.fullyInitialized) {
      throw Exception('Player is not open');
    }

    _onSkipForward = onSkipForward;
    _onSkipBackward = onSkipBackward;
    _onPaused = onPaused;

    var trackDico = (track != null) ? track.toMap() : null;
    defaultPauseResume ??= (onPaused == null);
    var state = await FlutterSoundPlayerPlatform.instance.nowPlaying(
      this,
      track: trackDico,
      duration: duration,
      progress: progress,
      canPause: (onPaused != null || defaultPauseResume),
      canSkipForward: (onSkipForward != null),
      canSkipBackward: (onSkipBackward != null),
      defaultPauseResume: defaultPauseResume,
    );
    _playerState = PlayerState.values[state];
    print('FS:<--- nowPlaying ');
  }

  /// Stop a playback.
  ///
  /// This verb never throw any exception. It is safe to call it everywhere,
  /// for example when the App is not sure of the current Audio State and want to recover a clean reset state.
  ///
  /// *Example:*
  /// ```dart
  ///         await myPlayer.stopPlayer();
  ///         if (_playerSubscription != null)
  ///         {
  ///                 _playerSubscription.cancel();
  ///                 _playerSubscription = null;
  ///         }
  /// ```
  Future<void> stopPlayer() async {
    await _lock.synchronized(() async {
      await _stopPlayer();
    });
  }

  Future<void> _stopPlayer() async {
    print('FS:---> stopPlayer ');
    while (_openPlayerCompleter != null) {
      print('Waiting for the recorder being opened');
      await _openPlayerCompleter.future;
    }
    if (_isInited != Initialized.fullyInitialized) {
      print('<--- stopPlayer : Player is not open');
      return;
    }
    try {
      //_removePlayerCallback(); // playerController is closed by this function
      await _stop();
    } on Exception catch (e) {
      print(e);
    }
    print('FS:<--- stopPlayer ');
  }

  /// @nodoc
  Future<void> _stop() async {
    print('FS:---> stop ');
    if (_foodStreamSubscription != null) {
      await _foodStreamSubscription.cancel();
      _foodStreamSubscription = null;
    }
    _needSomeFoodCompleter = null;
    if (_foodStreamController != null) {
      await _foodStreamController.sink.close();
      //await foodStreamController.stream.drain<bool>();
      await _foodStreamController.close();
      _foodStreamController = null;
    }
    Completer<void> completer;
    _stopPlayerCompleter = Completer<Duration>();
    try {
      completer = _stopPlayerCompleter;
      var state = await FlutterSoundPlayerPlatform.instance.stopPlayer(this);

      _playerState = PlayerState.values[state];
      if (_playerState != PlayerState.isStopped) {
        print('Player is not stopped!');
      }
    } on Exception {
      _stopPlayerCompleter = null;
      rethrow;
    }

    print('FS:<--- stop ');
    return completer.future;
  }

  /// Pause the current playback.
  ///
  /// An exception is thrown if the player is not in the "playing" state.
  ///
  /// *Example:*
  /// ```dart
  /// await myPlayer.pausePlayer();
  /// ```
  Future<void> pausePlayer() async {
    print('FS:---> pausePlayer ');
    await _lock.synchronized(() async {
      await _pausePlayer();
    });
    print('FS:<--- pausePlayer ');
  }

  Future<void> _pausePlayer() async {
    print('FS:---> _pausePlayer ');
    await _waitOpen();
    if (_isInited != Initialized.fullyInitialized) {
      throw Exception('Player is not open');
    }
    Completer<void> completer;
    if (_pausePlayerCompleter != null) {
      print('Killing another pausePlayer()');
      _pausePlayerCompleter.completeError('Killed by another pausePlayer()');
    }
    try {
      _pausePlayerCompleter = Completer<void>();
      completer = _pausePlayerCompleter;
      _playerState = PlayerState
          .values[await FlutterSoundPlayerPlatform.instance.pausePlayer(this)];
      //if (_playerState != PlayerState.isPaused) {
      //throw _PlayerRunningException(
      //'Player is not paused.'); // I am not sure that it is good to throw an exception here
      //}
    } on Exception {
      _pausePlayerCompleter = null;
      rethrow;
    }
    print('FS:<--- _pausePlayer ');
    return completer.future;
  }

  /// Resume the current playback.
  ///
  /// An exception is thrown if the player is not in the "paused" state.
  ///
  /// *Example:*
  /// ```dart
  /// await myPlayer.resumePlayer();
  /// ```
  Future<void> resumePlayer() async {
    print('FS:---> resumePlayer');
    await _lock.synchronized(() async {
      await _resumePlayer();
    });
    print('FS:<--- resumePlayer');
  }

  Future<void> _resumePlayer() async {
    print('FS:---> _resumePlayer');
    await _waitOpen();
    if (_isInited != Initialized.fullyInitialized) {
      throw Exception('Player is not open');
    }
    Completer<void> completer;
    if (_resumePlayerCompleter != null) {
      print('Killing another resumePlayer()');
      _resumePlayerCompleter.completeError('Killed by another resumePlayer()');
    }
    _resumePlayerCompleter = Completer<void>();
    try {
      completer = _resumePlayerCompleter;
      var state = await FlutterSoundPlayerPlatform.instance.resumePlayer(this);
      _playerState = PlayerState.values[state];
      //if (_playerState != PlayerState.isPlaying) {
      //throw _PlayerRunningException(
      //'Player is not resumed.'); // I am not sure that it is good to throw an exception here
      //}
    } on Exception {
      _resumePlayerCompleter = null;
      rethrow;
    }
    print('FS:<--- _resumePlayer');
    return completer.future;
  }

  /// To seek to a new location.
  ///
  /// The player must already be playing or paused. If not, an exception is thrown.
  ///
  /// *Example:*
  /// ```dart
  /// await myPlayer.seekToPlayer(Duration(milliseconds: milliSecs));
  /// ```
  Future<void> seekToPlayer(Duration duration) async {
    await _lock.synchronized(() async {
      await _seekToPlayer(duration);
    });
  }

  Future<void> _seekToPlayer(Duration duration) async {
    //print('FS:---> seekToPlayer ');
    await _waitOpen();
    if (_isInited != Initialized.fullyInitialized) {
      throw Exception('Player is not open');
    }
    var state = await FlutterSoundPlayerPlatform.instance.seekToPlayer(
      this,
      duration: duration,
    );
    _playerState = PlayerState.values[state];
    //print('FS:<--- seekToPlayer ');
  }

  /// Change the output volume
  ///
  /// The parameter is a floating point number between 0 and 1.
  /// Volume can be changed when player is running. Manage this after player starts.
  ///
  /// *Example:*
  /// ```dart
  /// await myPlayer.setVolume(0.1);
  /// ```
  Future<void> setVolume(double volume) async {
    await _lock.synchronized(() async {
      await _setVolume(volume);
    });
  }

  Future<void> _setVolume(double volume) async {
    print('FS:---> setVolume ');
    await _waitOpen();
    if (_isInited != Initialized.fullyInitialized) {
      throw Exception('Player is not open');
    }
    var indexedVolume = (!kIsWeb) && Platform.isIOS ? volume * 100 : volume;
    if (volume < 0.0 || volume > 1.0) {
      throw RangeError('Value of volume should be between 0.0 and 1.0.');
    }

    var state = await FlutterSoundPlayerPlatform.instance.setVolume(
      this,
      volume: indexedVolume,
    );
    _playerState = PlayerState.values[state];
    print('FS:<--- setVolume ');
  }

  /// Used if the App wants to control itself the Progress Bar on the lock screen.
  ///
  /// By default, this progress bar is handled automaticaly by Flutter Sound.
  /// Remark `setUIProgressBar()` is implemented only on iOS.
  ///
  /// *Example:*
  /// ```dart
  ///
  ///         Duration progress = (await getProgress())['progress'];
  ///         Duration duration = (await getProgress())['duration'];
  ///         setUIProgressBar(progress: Duration(milliseconds: progress.milliseconds - 500), duration: duration)
  /// ````
  Future<void> setUIProgressBar({
    Duration duration,
    Duration progress,
  }) async {
    await _lock.synchronized(() async {
      await _setUIProgressBar(progress: progress, duration: duration);
    });
  }

  Future<void> _setUIProgressBar({
    Duration duration,
    Duration progress,
  }) async {
    print('FS:---> setUIProgressBar : duration=$duration  progress=$progress');
    await _waitOpen();
    if (_isInited != Initialized.fullyInitialized) {
      throw Exception('Player is not open');
    }
    var state = await FlutterSoundPlayerPlatform.instance
        .setUIProgressBar(this, duration: duration, progress: progress);
    _playerState = PlayerState.values[state];
    print('FS:<--- setUIProgressBar ');
  }

  /// Get the resource path.
  ///
  /// This verb should probably not be here...
  Future<String> getResourcePath() async {
    await _waitOpen();
    if (_isInited != Initialized.fullyInitialized) {
      throw Exception('Player is not open');
    }
    if (kIsWeb) {
      return null;
    } else if (Platform.isIOS) {
      var s = await FlutterSoundPlayerPlatform.instance.getResourcePath(this);
      return s;
    } else {
      return (await getApplicationDocumentsDirectory()).path;
    }
  }
}

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

  /// The constructor
  PlaybackDisposition({
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  ///
  @override
  String toString() {
    return 'duration: $duration, '
        'position: $position';
  }
}

/// The track to play by [FlutterSoundPlayer.startPlayerFromTrack()].
class Track {
  /// The title of this track
  String trackTitle;

  /// The buffer containing the audio file to play
  Uint8List dataBuffer;

  /// The name of the author of this track
  String trackAuthor;

  /// The path that points to the track audio file
  String trackPath;

  /// The URL that points to the album art of the track
  String albumArtUrl;

  /// The asset that points to the album art of the track
  String albumArtAsset;

  /// The file that points to the album art of the track
  String albumArtFile;

  /// The image that points to the album art of the track
  //final String albumArtImage;

  /// The codec of the audio file to play. If this parameter's value is null
  /// it will be set to `t_CODEC.DEFAULT`.
  Codec codec;

  /// The constructor
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
    assert((!(trackPath != null && dataBuffer != null)),
        'You cannot provide both a path and a buffer.');
  }

  /// Convert this object to a [Map] containing the properties of this object
  /// as values.
  Map<String, dynamic> toMap() {
    final map = {
      'path': trackPath,
      'dataBuffer': dataBuffer,
      'title': trackTitle,
      'author': trackAuthor,
      'albumArtUrl': albumArtUrl,
      'albumArtAsset': albumArtAsset,
      'albumArtFile': albumArtFile,
      'bufferCodecIndex': codec?.index,
    };

    return map;
  }
}
