/*
 * Copyright 2018, 2019, 2020 Dooboolab.
 * Copyright 2021, 2022, 2023, 2024 Canardoux.
 *
 * This file is part of Flutter-Sound.
 *
 * Flutter-Sound is free software: you can redistribute it and/or modify
 * it under the terms of the Mozilla Public License version 2 (MPL-2.0),
 * as published by the Mozilla organization.
 *
 * Flutter-Sound is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * MPL General Public License for more details.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

/// Flutter Sound Player
///
/// ------------------------
/// A [FlutterSoundPlayer] is an object able to play something.
/// The [FlutterSoundPlayer] class can have multiple instances at the same time. Each instance is used to control the sound of its source.
///
/// ------------------------
/// {@category flutter_sound}
library;

import 'dart:async';
import 'dart:core';
import 'dart:io';
import 'dart:io' show Platform;
import 'dart:typed_data' show Uint8List, Float32List, Int16List;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_sound_platform_interface/flutter_sound_player_platform_interface.dart';
import 'package:logger/logger.dart' show Level, Logger;
import 'package:path_provider/path_provider.dart';
import 'package:synchronized/synchronized.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/services.dart';
import 'flutter_sound.dart';

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
typedef TWhenFinished = void Function();

/// A Player is an object that can playback from various sources.
///
/// ----------------------------------------------------------------------------------------------------
///
/// The Player class can have multiple instances at the same time. Each instance is used to control the sound of its source.
///
/// The sources possible can be:
/// - A file
/// - A remote URL
/// - An internal buffer
/// - A dart stream
///
/// Using a player is very simple :
///
/// 1. Create a new [FlutterSoundPlayer()]
///
/// 2. Open it with [openPlayer()]
///
/// 3. Start your playback with [startPlayer()].
///
/// 4. Use the various verbs (optional):
///    - [pausePlayer()]
///    - [resumePlayer()]
///    - [setVolume()]
///    - ...
///
/// 5. Stop your player : [stopPlayer()]
///
/// 6. Release your player when you have finished with it : [closePlayer()].
/// This verb will call [stopPlayer()] if necessary.
///
/// ![Player States](/images/PlayerStates.png)
/// _Player States_
///
/// If you are new to Flutter Sound, you may have a look to this [little guide](/tau/guides/guides_getting-started.html)
///
/// ----------------------------------------------------------------------------------------------------
///
class FlutterSoundPlayer implements FlutterSoundPlayerCallback {
  Codec codec = Codec.pcmFloat32;
  bool interleaved = true;
  int numChannels = 2;

  // The FlutterSoundPlayer Logger
  Logger _logger = Logger(level: Level.debug);
  Level _logLevel = Level.debug;

  // The default blockSize used when playing from Stream.
  int _bufferSize = 8192;

  /// The getter of the FlutterSoundPlayer Logger
  Logger get logger => _logger;

  // Are we waiting for needsForFood completer ?
  //bool _waitForFood = false;

  //
  bool _fromStream = false;

  /// Used if the App wants to dynamically change the Log Level.
  ///
  /// --------------------------------------------------------------
  ///
  /// Seldom used. Most of the time the Log Level is specified during the constructor.
  ///
  /// ## Parameters
  /// - **_aLevel:_** is the new logger level that you want.
  ///
  /// ## Example
  /// ```dart
  /// setLogLevel(Level.warning);
  /// ```
  void setLogLevel(Level aLevel) async {
    _logLevel = aLevel;
    _logger = Logger(level: aLevel);
    if (_isInited != Initialized.notInitialized) {
      FlutterSoundPlayerPlatform.instance.setLogLevel(this, aLevel);
    }
  }

  final _lock = Lock();
  static bool _reStarted = true;

  ///
  //StreamSubscription<Food>?
  //_foodStreamSubscription; // ignore: cancel_subscriptions

  //
  StreamSubscription<List<Float32List>>?
  _f32StreamSubscription; // ignore: cancel_subscriptions

  //
  StreamSubscription<List<Int16List>>?
  _int16StreamSubscription; // ignore: cancel_subscriptions

  //
  StreamSubscription<Uint8List>?
  _uint8StreamSubscription; // ignore: cancel_subscriptions

  //StreamController<Food>? _foodStreamController; //ignore: close_sinks

  StreamController<List<Float32List>>? _pcmF32Controller; //ignore: close_sinks
  StreamController<List<Int16List>>? _pcmInt16Controller; //ignore: close_sinks
  StreamController<Uint8List>? _pcmUint8Controller; //ignore: close_sinks

  ///
  Completer<int>? _needSomeFoodCompleter;

  ///
  Completer<Duration>? _startPlayerCompleter;
  Completer<void>? _pausePlayerCompleter;
  Completer<void>? _resumePlayerCompleter;
  Completer<void>? _stopPlayerCompleter;
  Completer<FlutterSoundPlayer>? _openPlayerCompleter;

  /// Instanciates a new Flutter Sound player.
  ///
  /// ----------------------------------------------------------------------------------------------------
  ///
  ///  The instanciation of a new player does not do many things. You are safe if you put this instanciation inside a global or instance variable initialization.
  /// You may instanciate several players at one moment.
  ///
  /// ## Parameters
  /// - **_logLevel:_** The optional parameter **logLevel** specifies the Logger Level you are interested by.
  /// - **_voiceProcessing:_** The optional parameter **voiceProcessing** is used to activate the VoiceProcessingIO AudioUnit (only for iOS)
  ///
  /// ## Example
  /// ```dart
  /// FlutterSoundPlayer myPlayer = FlutterSoundPlayer(logLevel = Level.warning);
  /// ```
  ///
  /// ----------------------------------------------------------------------------------------------------
  ///
  /* ctor */
  FlutterSoundPlayer({
    Level logLevel = Level.debug,
    bool voiceProcessing = false,
  }) {
    _logger = Logger(level: logLevel);
    _logger.d('ctor: FlutterSoundPlayer()');
  }

  //===================================  Callbacks ================================================================
  int _oldPosition = 0;

  /// Callback from the &tau; Core. Must not be called by the App
  /// @nodoc
  @override
  void updateProgress({int duration = 0, int position = 0}) {
    assert(position >= _oldPosition);
    _oldPosition = position;
    if (duration < position) {
      _logger.d(' Duration = $duration,   Position = $position');
    }
    _playerController!.add(
      PlaybackDisposition(
        position: Duration(milliseconds: position),
        duration: Duration(milliseconds: duration),
      ),
    );
  }

  /// Callback from the &tau; Core. Must not be called by the App
  /// @nodoc
  @override
  void updatePlaybackState(int state) {
    if (state >= 0 && state < PlayerState.values.length) {
      _playerState = PlayerState.values[state];
    }
  }

  /// Callback from the &tau; Core. Must not be called by the App
  /// @nodoc
  @override
  void needSomeFood(int ln) {
    assert(ln >= 0);
    // On iOS, we manage several buffers (4+1?).
    // FlutterSound core sends itself a "audioPlayerFinished" when those buffer are exhausted.
    // This is better than doing it here.
    // On Android we can't manage the buffers used by the OS.
    // We throw the event "audioPlayerFinished" when the driver needs some food, and nobody is waiting for this future.
    //if (Platform.isAndroid && !_waitForFood) {
    //audioPlayerFinished(PlayerState.isPaused.index);
    //}
    if (_needSomeFoodCompleter != null &&
        !_needSomeFoodCompleter!.isCompleted) {
      // On flutter Web we can receive many 'needSomeFood' events
      _needSomeFoodCompleter?.complete(ln);
    } //The completer is completed when the device accept new data
  }

  /// Callback from the &tau; Core. Must not be called by the App
  /// @nodoc
  @override
  void audioPlayerFinished(int state) async {
    _logger.d('FS:---> audioPlayerFinished');
    //await _lock.synchronized(() async {
    //playerState = PlayerState.isStopped;
    //int state = call['arg'] as int;
    _playerState = PlayerState.values[state];
    //await _stop(); // ??? Maybe

    if (_audioPlayerFinishedPlaying != null) {
      // We don't stop the player if the user has a callback
      _audioPlayerFinishedPlaying?.call();
    } else {
      if (!_fromStream) {
        await stopPlayer(); // ??? Maybe !!!!!!!!!!!
      }
    }
    //_cleanCompleters(); // We have problem when the record is finished and a resume is pending

    //});
    _logger.d('FS:<--- audioPlayerFinished');
  }

  /// Callback from the &tau; Core. Must not be called by the App
  /// @nodoc
  @override
  void openPlayerCompleted(int state, bool success) {
    _logger.d('---> openPlayerCompleted: $success');

    _playerState = PlayerState.values[state];
    _isInited =
        success ? Initialized.fullyInitialized : Initialized.notInitialized;
    if (_openPlayerCompleter == null) {
      _logger.e('Error : cannot process _openPlayerCompleter');
      return;
    }
    if (success) {
      _openPlayerCompleter!.complete(this);
    } else {
      _openPlayerCompleter!.completeError('openPlayer failed');
    }
    _openPlayerCompleter = null;
    _logger.d('<--- openPlayerCompleted: $success');
  }

  /// Callback from the &tau; Core. Must not be called by the App
  /// @nodoc
  @override
  void pausePlayerCompleted(int state, bool success) {
    _logger.d('---> pausePlayerCompleted: $success');
    if (_pausePlayerCompleter == null) {
      _logger.e('Error : cannot process _pausePlayerCompleter');
      return;
    }
    _playerState = PlayerState.values[state];
    if (success) {
      _pausePlayerCompleter!.complete();
    } else {
      _pausePlayerCompleter!.completeError('pausePlayer failed');
    }
    _pausePlayerCompleter = null;
    _logger.d('<--- pausePlayerCompleted: $success');
  }

  /// Callback from the &tau; Core. Must not be called by the App
  /// @nodoc
  @override
  void resumePlayerCompleted(int state, bool success) {
    _logger.d('---> resumePlayerCompleted: $success');
    if (_resumePlayerCompleter == null) {
      _logger.e('Error : cannot process _resumePlayerCompleter');
      return;
    }
    _playerState = PlayerState.values[state];
    if (success) {
      _resumePlayerCompleter!.complete();
    } else {
      _resumePlayerCompleter!.completeError('resumePlayer failed');
    }
    _resumePlayerCompleter = null;
    _logger.d('<--- resumePlayerCompleted: $success');
  }

  /// Callback from the &tau; Core. Must not be called by the App
  /// @nodoc
  @override
  void startPlayerCompleted(int state, bool success, int duration) {
    _logger.d('---> startPlayerCompleted: $success');
    if (_startPlayerCompleter == null) {
      _logger.e('Error : cannot process _startPlayerCompleter');
      return;
    }
    _playerState = PlayerState.values[state];
    if (success) {
      _startPlayerCompleter!.complete(Duration(milliseconds: duration));
    } else {
      _startPlayerCompleter!.completeError('startPlayer() failed');
    }
    _startPlayerCompleter = null;
    _logger.d('<--- startPlayerCompleted: $success');
  }

  /// Callback from the &tau; Core. Must not be called by the App
  /// @nodoc
  @override
  void stopPlayerCompleted(int state, bool success) {
    _logger.d('---> stopPlayerCompleted: $success');
    if (_stopPlayerCompleter == null) {
      _logger.d('Error : cannot process stopPlayerCompleted');
      _logger.d('<--- stopPlayerCompleted: $success');
      return;
    }
    _playerState = PlayerState.values[state];
    if (success) {
      _stopPlayerCompleter!.complete();
    } // stopPlayer must not gives errors
    else {
      _stopPlayerCompleter!.completeError('stopPlayer failed');
    }
    _stopPlayerCompleter = null;
    // cleanCompleters(); ????
    _logger.d('<--- stopPlayerCompleted: $success');
  }

  void _cleanCompleters() {
    if (_pausePlayerCompleter != null) {
      var completer = _pausePlayerCompleter;
      _logger.w('Kill _pausePlayer()');
      _pausePlayerCompleter = null;
      completer!.completeError('killed by cleanCompleters');
    }

    if (_resumePlayerCompleter != null) {
      var completer = _resumePlayerCompleter;
      _logger.w('Kill _resumePlayer()');
      _resumePlayerCompleter = null;
      completer!.completeError('killed by cleanCompleters');
    }

    if (_startPlayerCompleter != null) {
      var completer = _startPlayerCompleter;
      _logger.w('Kill _startPlayer()');
      _startPlayerCompleter = null;
      completer!.completeError('killed by cleanCompleters');
    }

    if (_stopPlayerCompleter != null) {
      var completer = _stopPlayerCompleter;
      _logger.w('Kill _stopPlayer()');
      _stopPlayerCompleter = null;
      completer!.completeError('killed by cleanCompleters');
    }

    if (_openPlayerCompleter != null) {
      var completer = _openPlayerCompleter;
      _logger.w('Kill openPlayer()');
      _openPlayerCompleter = null;
      completer!.completeError('killed by cleanCompleters');
    }
  }

  /// @nodoc
  @override
  void log(Level logLevel, String msg) {
    _logger.log(logLevel, msg);
  }

  //===============================================================================================================

  // Do not use. Private variable
  // @nodoc
  Initialized _isInited = Initialized.notInitialized;

  //
  PlayerState _playerState = PlayerState.isStopped;

  /// Getter of the current state of the Player
  ///
  /// -------------------------------------------------------------
  ///
  /// ## Return
  ///
  /// the current state of the player
  ///
  /// ## Example
  /// ```dart
  /// if (playerState == PlayerState.isPlaying) {
  ///   // doSomething
  /// }
  /// ```
  ///
  /// ## See also
  /// - [isPlaying]
  /// - [isPaused]
  /// - [isStopped]
  ///
  /// ------------------------------------------------------------------
  ///
  PlayerState get playerState => _playerState;

  // The [onProgress()] controller
  StreamController<PlaybackDisposition>? _playerController;

  /// The sink side of the Food Controller. Deprecated.
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
  //@Deprecated('Use [uint8ListSink]')
  //StreamSink<Food>? get foodSink => _foodStreamController?.sink;

  /// Getter of one of the three StreamSink that you may use to feed a player from Stream.
  ///
  /// ----------------------------------------------------------------------------------------------
  ///
  /// This stream is used when you have interleaved audio data and you don't want a flow control.
  /// You can look to this [small guide](/tau/guides/guides_live_streams.html) if you need precisions.
  ///
  /// ## Return
  ///
  /// The StreamSink that you may use to feed the player
  ///
  /// ## example
  ///
  /// ```dart
  /// await myPlayer.startPlayerFromStream
  /// (
  ///     codec: Codec.pcmFloat32
  ///     numChannels: 2
  ///     sampleRate: 48100
  ///     interleaved: true,
  /// );
  ///
  /// myPlayer.uint8ListSink.add(myData);
  /// ```
  ///
  /// ## See also
  ///
  /// - [float32Sink]
  /// - [int16Sink]
  /// - [feedF32FromStream()]
  /// - [feedInt16FromStream()]
  /// - [feedUint8FromStream()]
  /// - You can also look to this [small guide](/tau/guides/guides_live_streams.html) if you need precisions.
  ///
  /// ----------------------------------------------------------------------------------------------
  StreamSink<Uint8List>? get uint8ListSink => _pcmUint8Controller?.sink;

  /// Getter of one of the three StreamSink that you may use to feed a player from Stream.
  ///
  /// ----------------------------------------------------------------------------------------------
  ///
  /// This stream is used when you have NOT interleaved audio data and you don't want a flow control.
  /// You can look to this [small guide](/tau/guides/guides_live_streams.html) if you need precisions.
  ///
  /// ## Return
  ///
  /// The StreamSink that you may use to feed the player
  ///
  /// ## example
  ///
  /// ```dart
  /// await myPlayer.startPlayerFromStream
  /// (
  ///     codec: Codec.pcmFloat32
  ///     numChannels: 2
  ///     sampleRate: 48100
  ///     interleaved: false,
  /// );
  ///
  /// myPlayer.float32Sink.add(myData);
  /// ```
  ///
  /// ## See also
  ///
  /// - [uint8ListSink]
  /// - [int16Sink]
  /// - [feedF32FromStream()]
  /// - [feedInt16FromStream()]
  /// - [feedF32FromStream()]
  /// - You can also look to this [small guide](/tau/guides/guides_live_streams.html) if you need precisions.
  ///
  /// ----------------------------------------------------------------------------------------------
  StreamSink<List<Float32List>>? get float32Sink => _pcmF32Controller?.sink;

  /// Getter of one of the three StreamSink that you may use to feed a player from Stream.
  ///
  /// ----------------------------------------------------------------------------------------------
  ///
  /// This stream is used when you have NOT interleaved audio data and you don't want a flow control.
  /// You can look to this [small guide](/tau/guides/guides_live_streams.html) if you need precisions.
  ///
  /// ## Return
  ///
  /// The StreamSink that you may use to feed the player
  ///
  /// ## example
  ///
  /// ```dart
  /// await myPlayer.startPlayerFromStream
  /// (
  ///     codec: Codec.pcm16
  ///     numChannels: 2
  ///     sampleRate: 48100
  ///     interleaved: false,
  /// );
  ///
  /// myPlayer.int16Sink.add(myData);
  /// ```
  ///
  /// ## See also
  /// - [float32Sink]
  /// - [int16Sink]
  /// - [feedF32FromStream()]
  /// - [feedUint8FromStream()]
  /// - [feedF32FromStream()]
  /// - You can also look to this [small guide](/tau/guides/guides_live_streams.html) if you need precisions.
  ///
  /// ----------------------------------------------------------------------------------------------
  StreamSink<List<Int16List>>? get int16Sink => _pcmInt16Controller?.sink;

  /// The stream side of the [onProgress] Controller
  ///
  /// ----------------------------------------------------------------------------------------------
  ///
  /// This is a stream on which FlutterSound will post the player progression.
  /// You may listen to this Stream to have feedback on the current playback.
  ///
  /// If you want to receive events on this stream, do not forget to
  /// call also [setSubscriptionDuration()]. If you do not call this verb,
  /// you will not receive anything because the default value is 0ms which means
  /// not events!
  ///
  /// PlaybackDisposition has two fields :
  /// - Duration duration  (the total playback duration)
  /// - Duration position  (the current playback position)
  ///
  /// ## Example
  /// ```dart
  ///         _playerSubscription = myPlayer.onProgress.listen((e)
  ///         {
  ///                 Duration maxDuration = e.duration;
  ///                 Duration position = e.position;
  ///                 ...
  ///         }
  ///         await _mPlayer.setSubscriptionDuration(
  ///              Duration(milliseconds: 100, // an event each 100 ms
  ///         );
  /// ```
  ///
  /// ## See also
  /// - [setSubscriptionDuration()]
  /// - You may look to this [small guide](/tau/guides/guides_on_progress.html) if you need precisions about this.
  ///
  /// -----------------------------------------------------------------------------------------------
  ///
  Stream<PlaybackDisposition>? get onProgress => _playerController?.stream;

  /// Return true if the Player has been open.
  bool isOpen() {
    return (_isInited == Initialized.fullyInitialized);
  }

  // User callback "whenFinished:"
  TWhenFinished? _audioPlayerFinishedPlaying;

  /// Test the Player State
  ///
  /// ------------------------------------------
  /// ## See also
  /// - [playerState]
  /// - [isPaused]
  /// - [isStopped]
  ///
  /// ------------------------------------------
  bool get isPlaying => _playerState == PlayerState.isPlaying;

  /// Test the Player State
  ///
  /// -----------------------------------------
  /// ## See also
  /// - [playerState]
  /// - [isPlaying]
  /// - [isStopped]
  ///
  /// ------------------------------------------
  bool get isPaused => _playerState == PlayerState.isPaused;

  /// Test the Player State
  ///
  /// --------------------------------------------------
  /// ## See also
  /// - [playerState]
  /// - [isPaused]
  /// - [isPlaying]
  ///
  /// --------------------------------------------------
  ///
  bool get isStopped => _playerState == PlayerState.isStopped;

  Future<void> _waitOpen() async {
    while (_openPlayerCompleter != null) {
      _logger.d('Waiting for the player being opened');
      await _openPlayerCompleter!.future;
    }
    if (_isInited == Initialized.notInitialized) {
      throw Exception('Player is not open');
    }
  }

  /// Open the Player.
  ///
  /// ----------------------------------------------------------------------------------------------------
  /// A player must be opened before used.
  /// Opening a player takes resources inside the system. Those resources are freed with the verb [closePlayer()].
  ///
  /// ## Return
  /// Returns a Future, but the App does not need to wait the completion of this future before doing a [startPlayer()].
  /// The Future will be automaticaly waited by [startPlayer()].
  ///
  /// ## Example
  ///
  /// ```dart
  ///     myPlayer = await FlutterSoundPlayer().openPlayer();
  ///
  ///     ...
  ///     (do something with myPlayer)
  ///     ...
  ///
  ///     await myPlayer.closePlayer();
  ///     myPlayer = null;
  /// ```
  ///
  /// ## See also
  /// - closePlayer()
  ///
  /// ------------------------------------------------------------------------------------------------------
  Future<FlutterSoundPlayer?> openPlayer({bool isBGService = false}) async {
    //if (!Platform.isIOS && enableVoiceProcessing) {
    //throw ('VoiceProcessing is only available on iOS');
    //}

    if (_isInited != Initialized.notInitialized) {
      return this;
    }

    if (isBGService) {
      await MethodChannel(
        "xyz.canardoux.flutter_sound_bgservice",
      ).invokeMethod("setBGService");
    }

    Future<FlutterSoundPlayer?>? r;
    await _lock.synchronized(() async {
      r = _openPlayer();
    });
    return r;
  }

  Future<FlutterSoundPlayer> _openPlayer() async {
    _logger.d('FS:---> _openPlayer');
    while (_openPlayerCompleter != null) {
      _logger.w('Another openPlayer() in progress');
      await _openPlayerCompleter!.future;
    }

    Completer<FlutterSoundPlayer>? completer;
    if (_isInited != Initialized.notInitialized) {
      throw Exception('Player is already initialized');
    }

    if (_reStarted && foundation.kDebugMode) {
      // Perhaps a Hot Restart ?  We must reset the plugin
      _logger.d('Resetting flutter_sound Player Plugin');
      _reStarted = false;
      await FlutterSoundPlayerPlatform.instance.resetPlugin(this);
    }
    await FlutterSoundPlayerPlatform.instance.initPlugin();
    FlutterSoundPlayerPlatform.instance.openSession(this);
    _setPlayerCallback();
    assert(_openPlayerCompleter == null);
    _openPlayerCompleter = Completer<FlutterSoundPlayer>();
    completer = _openPlayerCompleter;
    try {
      var state = await FlutterSoundPlayerPlatform.instance.openPlayer(
        this,
        logLevel: _logLevel,
      );
      _playerState = PlayerState.values[state];

      //_pcmUint8Controller = StreamController();
      //_uint8StreamSubscription = _pcmUint8Controller!.stream.listen((food) async {
      //  _uint8StreamSubscription!.pause(_feed(food));
      //  //await _feed(food); // await?
      //});

      //_pcmF32Controller = StreamController();
      //_f32StreamSubscription = _pcmF32Controller!.stream.listen((food) async {
      //  _f32StreamSubscription!.pause(feedF32FromStream(food));
      //  //await feedF32FromStream(food); // await?
      //});

      //_pcmInt16Controller = StreamController();
      //_int16StreamSubscription = _pcmInt16Controller!.stream.listen((food) async {
      //  _int16StreamSubscription!.pause(feedInt16FromStream(food));
      // //await feedInt16FromStream(food); // await?
      //});

      //isInited = success ?  Initialized.fullyInitialized : Initialized.notInitialized;
    } on Exception {
      _openPlayerCompleter = null;
      rethrow;
    }
    _logger.d('FS:<--- _openPlayer');
    return completer!.future;
  }

  /// Close an open player.
  ///
  /// ------------------------------------------------------------------------------------
  ///
  /// Must be called when finished with a Player, to release all the resources.
  /// It is safe to call this procedure at any time.
  /// - If the Player is not open, this verb will do nothing
  /// - If the Player is currently in play or pause mode, it will be stopped before.
  ///
  /// ## Return
  ///
  /// - Returns a Future which is completed when the function is done.
  ///
  /// ## example
  ///
  /// ```dart
  /// @override
  /// void dispose()
  /// {
  ///         if (myPlayer != null)
  ///         {
  ///             myPlayer.closePlayer();
  ///             myPlayer = null;
  ///         }
  ///         super.dispose();
  /// }
  /// ```
  ///
  /// ## See also
  /// - [openPlayer()]
  /// -----------------------------------------------------------------------------------
  Future<void> closePlayer() async {
    await _lock.synchronized(() {
      return _closePlayer();
    });
  }

  Future<void> _closePlayer() async {
    _logger.d('FS:---> closePlayer ');

    if (_isInited == Initialized.notInitialized) {
      // Already closed
      _logger.d('Player already close');
      return;
    }

    await _stop(); // Stop the player if running
    //_isInited = Initialized.initializationInProgress; // BOF

    if (_pcmF32Controller != null) {
      await _pcmF32Controller!.sink.close();
      //await foodStreamController.stream.drain<bool>();
      await _pcmF32Controller!.close();
      _pcmF32Controller = null;
    }
    if (_pcmUint8Controller != null) {
      await _pcmUint8Controller!.sink.close();
      //await foodStreamController.stream.drain<bool>();
      await _pcmUint8Controller!.close();
      _pcmUint8Controller = null;
    }
    if (_pcmInt16Controller != null) {
      await _pcmInt16Controller!.sink.close();
      //await foodStreamController.stream.drain<bool>();
      await _pcmInt16Controller!.close();
      _pcmInt16Controller = null;
    }

    _cleanCompleters();
    _removePlayerCallback();
    await FlutterSoundPlayerPlatform.instance.closePlayer(this);

    FlutterSoundPlayerPlatform.instance.closeSession(this);
    _isInited = Initialized.notInitialized;
    _logger.d('FS:<--- closePlayer ');
  }

  /// Query the current state of the Flutter Sound Core layer.
  ///
  /// -------------------------------------------------------------------------------
  ///
  /// Most of the time, the App will not use this verb,
  /// but will use the [playerState] variable.
  /// This is seldom used when the App wants to get
  /// an updated value of the background state.
  ///
  /// ## See also
  /// - [playerState]
  ///
  /// -------------------------------------------------------------------------------
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
  /// ---------------------------------------------------------------------------
  ///
  /// It returns a `Map` with two Duration entries : `'progress'` and `'duration'`.
  /// Remark : actually only implemented on iOS.
  ///
  /// *Example:*
  /// ```dart
  ///         Duration progress = (await getProgress())['progress'];
  ///         Duration duration = (await getProgress())['duration'];
  /// ```
  ///
  /// ---------------------------------------------------------------------------
  ///
  @Deprecated('This function is not useful')
  Future<Map<String, Duration>> getProgress() async {
    await _waitOpen();
    if (_isInited != Initialized.fullyInitialized) {
      throw Exception('Player is not open');
    }

    return FlutterSoundPlayerPlatform.instance.getProgress(this);
  }

  /// Returns true if the specified decoder is supported by Flutter Sound on this platform
  ///
  /// ---------------------------------------------------------------------------
  ///
  /// ## Example
  /// ```dart
  ///         if ( await myPlayer.isDecoderSupported(Codec.aacADTS) ) doSomething;
  /// ```
  ///
  /// ---------------------------------------------------------------------------
  ///
  Future<bool> isDecoderSupported(Codec codec) async {
    var result = false;
    _logger.d('FS:---> isDecoderSupported ');
    await _waitOpen();
    if (_isInited != Initialized.fullyInitialized) {
      throw Exception('Player is not open');
    }
    result = await FlutterSoundPlayerPlatform.instance.isDecoderSupported(
      this,
      codec: codec,
    );
    _logger.d('FS:<--- isDecoderSupported ');
    return result;
  }

  /// Specify the callbacks frequency of the [onProgress] stream.
  ///
  /// ----------------------------------------------------------------------------
  ///
  /// The default value is 0 (zero) which means that there is no callbacks.
  /// If you really want to receive the events, do not forget to call this verb.
  ///
  /// ## Example
  /// ```dart
  /// myPlayer.setSubscriptionDuration(Duration(milliseconds: 100));
  /// ```
  ///
  /// ## See also
  /// - [onProgress]
  ///
  /// -----------------------------------------------------------------------------
  ///
  Future<void> setSubscriptionDuration(Duration duration) async {
    _logger.d('FS:---> setSubscriptionDuration ');
    await _waitOpen();
    if (_isInited != Initialized.fullyInitialized) {
      throw Exception('Player is not open');
    }
    var state = await FlutterSoundPlayerPlatform.instance
        .setSubscriptionDuration(this, duration: duration);
    _playerState = PlayerState.values[state];
    _logger.d('FS:<---- setSubscriptionDuration ');
  }

  ///
  void _setPlayerCallback() {
    _playerController ??= StreamController<PlaybackDisposition>.broadcast();
  }

  void _removePlayerCallback() {
    _playerController?.close();
    _playerController = null;
  }

  /// Used to play a sound on a player open with [openPlayer()].
  ///
  /// ------------------------------------------------------------------------------------------------------------------
  ///
  /// If you are new to Flutter Sound, you may look to this [simple guide](/tau/guides/guides_getting-started.html).
  /// If you want to play from a dart stream, use the verb [startPlayerFromStream] instead of this verb.
  ///
  /// When you want to stop the player, you call the verb [stopPlayer()].
  /// Note : Flutter Sound does not stop automatically the player when finished.
  /// If you want this, use the **_whenFinished_** parameter.
  ///
  /// ## Parameters
  ///
  /// - **_codec:_** is the audio and file format of the file/buffer.
  /// Very often, the `codec:` parameter is not useful. Flutter Sound will adapt itself depending on the real format of the file provided.
  /// But this parameter is necessary when Flutter Sound must do a format conversion.
  /// Please refer to the [Codec compatibility Table](/tau/guides/guides_codecs.html) to know which codecs are currently supported.
  /// - One of the two following parameters:
  ///   - **_fromDataBuffer:_** (if you want to play from a data buffer)
  ///   - **_fromUri:_**  (if you want to play a file or a remote URI).
  ///     The `fromUri` parameter, if specified, can be one of three possibilities :
  ///       - The URL of a remote file.
  ///       - The path of a local file. Hint: [path_provider](https://pub.dev/packages/path_provider)
  ///       can be useful if you want to get access to some directories on your device.
  ///       - The name of a temporary file (without any slash '/').
  /// - **_sampleRate:_** is mandatory with raw PCM codecs (`codec` == `Codec.pcm16` or `Codec.pcmFloat32`). Not used for other codecs.
  /// - **_numChannels:_** is only used with raw PCM codecs (`codec` == `Codec.pcm16` or `Codec.pcmFloat32`). Its value is the number of channels,
  /// - **_whenFinished:()_** : A function for specifying what to do when the playback will be finished.
  ///
  /// Note: You must specify one or the two parameters : `fromUri`, `fromDataBuffer`.
  ///
  /// ## Return
  ///
  /// [startPlayer()] returns a Duration Future, which is the record duration.
  ///
  /// ## Examples
  ///
  /// *Example:*
  /// ```dart
  ///         Duration d = await myPlayer.startPlayer(
  ///             codec: Codec.aacADTS,
  ///             fromURI: 'foo'
  ///         ); // Play a temporary file
  ///
  ///         _playerSubscription = myPlayer.onProgress.listen((e)
  ///         {
  ///                 // ...
  ///         });
  ///         myPlayer.setSubscriptionDuration(Duration(milliseconds: 100));
  /// }
  /// ```
  ///
  /// *Example:*
  /// ```dart
  ///     final fileUri = "https://file-examples.com/wp-content/uploads/2017/11/file_example_MP3_700KB.mp3";
  ///
  ///     Duration d = await myPlayer.startPlayer // Play a remote file
  ///     (
  ///                 codec: Codec.mp3,
  ///                 fromURI: fileUri,
  ///                 whenFinished: ()
  ///                 {
  ///                          logger.d( 'I hope you enjoyed listening to this song' );
  ///                          myPlayer.stopPlayer().then ( (_) { setState((){}); );
  ///                 },
  ///     );
  /// ```
  ///
  /// ## See also
  /// - [stopPlayer()]
  /// - [startPlayerFromStream()]
  ///
  /// ---------------------------------------------------------------------------------------------------------------
  ///
  Future<Duration?> startPlayer({
    Codec codec = Codec.aacADTS,
    String? fromURI,
    Uint8List? fromDataBuffer,
    int sampleRate = 16000, // Used only with PCM codecs
    int numChannels = 1, // Used only with PCM codecs
    TWhenFinished? whenFinished,
  }) async {
    Duration? r;
    await _lock.synchronized(() async {
      r = await _startPlayer(
        codec: codec,
        fromURI: fromURI,
        fromDataBuffer: fromDataBuffer,
        sampleRate: sampleRate,
        numChannels: numChannels,
        whenFinished: whenFinished,
      );
    }); // timeout: Duration(seconds: 10));
    return r;
  }

  Future<Duration> _startPlayer({
    String? fromURI,
    Uint8List? fromDataBuffer,
    Codec codec = Codec.aacADTS,
    int sampleRate = 16000, // Used only with codec == Codec.pcm16
    int numChannels = 1, // Used only with codec == Codec.pcm16
    TWhenFinished? whenFinished,
  }) async {
    _logger.d('FS:---> startPlayer ');
    await _waitOpen();
    if (_isInited != Initialized.fullyInitialized) {
      throw Exception('Player is not open');
    }
    this.codec = codec;
    //this.interleaved = interleaved;
    this.numChannels = numChannels;
    _oldPosition = 0;

    if (codec == Codec.pcm16 || codec == Codec.pcmFloat32) {
      if (fromURI != null) {
        var tempDir = await getTemporaryDirectory();
        var path = '${tempDir.path}/flutter_sound_tmp.wav';
        await flutterSoundHelper.pcmToWave(
          inputFile: fromURI,
          outputFile: path,
          numChannels: numChannels,
          sampleRate: sampleRate,
          codec: codec,
        );
        fromURI = path;
        codec = Codec.pcm16WAV;
      } else if (fromDataBuffer != null) {
        fromDataBuffer = await flutterSoundHelper.pcmToWaveBuffer(
          inputBuffer: fromDataBuffer,
          sampleRate: sampleRate,
          numChannels: numChannels,
          codec: codec,
        );
        codec = Codec.pcm16WAV;
      }
    }
    Completer<Duration>? completer;

    await _stop(); // Just in case

    if (_playerState != PlayerState.isStopped) {
      throw Exception('Player is not stopped');
    }
    _audioPlayerFinishedPlaying = whenFinished;
    _fromStream = false;

    if (_startPlayerCompleter != null) {
      _logger.w('Killing another startPlayer()');
      _startPlayerCompleter!.completeError('Killed by another startPlayer()');
    }
    try {
      _startPlayerCompleter = Completer<Duration>();
      //_startPlayerCompleter!.future.catchError(AssertionError('future not consumed'));
      //_startPlayerCompleter!.future.onError((error, stackTrace) {
      //_startPlayerCompleter = null;
      //throw Exception('Cannot start the player');
      //return Duration.zero;
      //});
      completer = _startPlayerCompleter;

      var state = await FlutterSoundPlayerPlatform.instance.startPlayer(
        this,
        codec: codec,
        fromDataBuffer: fromDataBuffer,
        fromURI: fromURI,
        numChannels: numChannels,
        sampleRate: sampleRate,
      );

      //var state = 0; startPlayerCompleted( state, false, -1); // !!!!!!!!!!!!
      _playerState = PlayerState.values[state];
      //if (_playerState == PlayerState.isStopped) // Player not Started
      {
        //_startPlayerCompleter = null;
        //throw Exception('Cannot start the player');
      }
    } on Exception {
      _startPlayerCompleter = null;
      rethrow;
    }
    //Duration duration = Duration(milliseconds: retMap['duration'] as int);
    _logger.d('FS:<--- startPlayer ');
    return completer!.future;
  }

  /// Starts the Microphone and plays what is recorded.
  ///
  /// The Speaker is directely linked to the Microphone.
  /// There is no processing between the Microphone and the Speaker.
  /// If you want to process the data before playing them, actually you must define a loop between a [FlutterSoundPlayer] and a [FlutterSoundRecorder].
  /// (Please, look to [this example](http://www.canardoux.xyz/flutter_sound/doc/pages/flutter-sound/api/topics/flutter_sound_examples_stream_loop.html)).
  ///
  /// Later, we will implement the _Tau Audio Graph_ concept, which will be a more general object.
  ///
  /// startPlayerFromMic() has four optional parameters :
  ///    - **_sampleRate:_** the Sample Rate used. Optional. Only used on Android. The default value is probably a good choice and the App can ommit this optional parameter.
  ///    - **_numChannels:_** 1 for monophony, 2 for stereophony. Optional. Actually only monophony is implemented.
  ///    - **_bufferSize:_** the size of the internal buffers. Probably the default choice is OK
  ///    - **_enableVoiceProcessing:_** is a flag that you can enable
  ///
  /// `startPlayerFromMic()` returns a Future, which is completed when the Player is really started.
  ///
  /// *Example:*
  /// ```dart
  ///     await myPlayer.startPlayerFromMic();
  ///     ...
  ///     myPlayer.stopPlayer();
  /// ```
  ///  'This function can very easily be emulated with a RecordToStream + a PlayFromStream',
  Future<void> startPlayerFromMic({
    int sampleRate = 48000, // The default value is probably a good choice.
    int numChannels =
        1, // 1 for monophony, 2 for stereophony (actually only monophony is supported).
    int bufferSize = 8192,
    enableVoiceProcessing = false,
  }) async {
    await _lock.synchronized(() async {
      await _startPlayerFromMic(
        sampleRate: sampleRate,
        numChannels: numChannels,
        bufferSize: bufferSize,
        enableVoiceProcessing: enableVoiceProcessing,
      );
    });
  }

  Future<Duration> _startPlayerFromMic({
    int sampleRate = 44000, // The default value is probably a good choice.
    int numChannels =
        1, // 1 for monophony, 2 for stereophony (actually only monophony is supported).
    int bufferSize = 8192,
    enableVoiceProcessing = false,
  }) async {
    _logger.d('FS:---> startPlayerFromMic ');
    await _waitOpen();
    if (_isInited != Initialized.fullyInitialized) {
      throw Exception('Player is not open');
    }
    _oldPosition = 0;

    Completer<Duration>? completer;
    await _stop(); // Just in case
    try {
      if (_startPlayerCompleter != null) {
        _logger.w('Killing another startPlayer()');
        _startPlayerCompleter!.completeError('Killed by another startPlayer()');
      }
      _startPlayerCompleter = Completer<Duration>();
      completer = _startPlayerCompleter;
      var state = await FlutterSoundPlayerPlatform.instance.startPlayerFromMic(
        this,
        numChannels: numChannels,
        sampleRate: sampleRate,
        bufferSize: bufferSize,
        enableVoiceProcessing: enableVoiceProcessing,
      );
      _playerState = PlayerState.values[state];
    } on Exception {
      _startPlayerCompleter = null;
      rethrow;
    }
    _logger.d('FS:<--- startPlayerFromMic ');
    return completer!.future;
  }

  /// Used to play something from a dart stream
  ///
  /// You use this verb instead of [startPlayer] when you want to play from a dart stream
  /// or if you want to use one of the three `feed()` verbs.
  /// For a complete discussion of the play from stream feature,
  /// please look to this [small guide](/tau/guides/guides_live_streams.html)
  ///
  /// ## Parameters
  ///
  ///  - **_codec:_** The only codecs supported are [Codec.pcm16] and [Codec.pcmFloat32]. This parameter is mandatory.
  ///  - **_interleaved:_** is a boolean specifying if the data that you will fee will be in an interleaved or a plan mode.
  ///  This parameter is mandatory.
  ///  - **_numChannels:_** is the number of channels of the audio data that you will provide. This parameter is mandatory.
  ///  - **_sampleRate:_** is the sample rate used by your data. This parameter is mandatory.
  ///  - **_bufferSize:_** is the size of the internal buffers. Most of the time you don't specify this parameter and use the default value.
  ///  - **_onBufferUnderflow_** is a callback which is fired when we run short on buffers. Perhaps because the playback is finished or because it has not fully started.
  ///
  ///   Please look to [the following notice](/tau/guides/guides_live_streams.html)
  ///
  ///   ## Return
  ///
  ///   Returns a Future which is completed when the function is done.
  ///
  ///   ## Example
  ///   You can look to the three provided examples :
  ///
  ///   - [This example](/tau/examples/ex_playback_from_stream_1.html) shows how to play live data, without Back Pressure from Flutter Sound
  ///   - [This example](/tau/examples/ex_playback_from_stream_2.html) shows how to play Live data, with Back Pressure from Flutter Sound
  ///   - [This example](/tau/examples/ex_streams.html) shows how to record and playback from streams.
  ///
  ///   **_Example 1:_**
  ///   ```dart
  ///   await myPlayer.startPlayerFromStream(codec: Codec.pcm16, numChannels: 1, sampleRate: 48000);
  ///
  ///   await myPlayer.feedF32FromStream(aBuffer);
  ///   await myPlayer.feedF32FromStream(anotherBuffer);
  ///   await myPlayer.feedF32FromStream(myOtherBuffer);
  ///
  ///   await myPlayer.stopPlayer();
  ///   ```
  ///   **_Example 2:_**
  ///   ```dart
  ///   await myPlayer.startPlayerFromStream(codec: Codec.pcm16, numChannels: 1, sampleRate: 48000);
  ///
  ///   myPlayer.float32Sink.add(aBuffer));
  ///   myPlayer.float32Sink.add(anotherBuffer);
  ///   myPlayer.float32Sink.add(myOtherBuffer);
  ///   ```
  ///
  /// ## See also
  /// - [startPlayer()]
  /// - [stopPlayer()]
  Future<void> startPlayerFromStream({
    required Codec codec, // = Codec.pcmFloat32,
    required bool interleaved, // = false,
    required int numChannels, // = 2,
    required int sampleRate, // = 48000,
    required int bufferSize, // = 1024,
    TWhenFinished? onBufferUnderflow,
  }) async {
    await _lock.synchronized(() async {
      await _startPlayerFromStream(
        codec: codec,
        interleaved: interleaved,
        sampleRate: sampleRate,
        numChannels: numChannels,
        bufferSize: bufferSize,
        onBufferUnderflow: onBufferUnderflow,
      );
    });
  }

  Future<Duration> _startPlayerFromStream({
    Codec codec = Codec.pcm16,
    bool interleaved = true,
    int numChannels = 1,
    int sampleRate = 16000,
    int bufferSize = 8192,
    TWhenFinished? onBufferUnderflow,
  }) async {
    _logger.d('FS:---> startPlayerFromStream ');
    await _waitOpen();
    if (_isInited != Initialized.fullyInitialized) {
      throw Exception('Player is not open');
    }
    this.codec = codec;
    this.interleaved = interleaved;
    this.numChannels = numChannels;

    Completer<Duration>? completer;
    _bufferSize = bufferSize;
    await _stop(); // Just in case

    //_foodStreamController = StreamController();
    //_foodStreamSubscription = _foodStreamController!.stream.listen((
    //  food,
    //) async {
    //      _foodStreamSubscription!.pause(food.exec(this));
    //      if (Platform.isAndroid && !_waitForFood) {
    //        audioPlayerFinished(PlayerState.isPaused.index);
    //      }
    //    });

    _pcmUint8Controller = StreamController();
    _uint8StreamSubscription = _pcmUint8Controller!.stream.listen((food) async {
      _uint8StreamSubscription!.pause(_feed(food));
      //await _feed(food); // await?
    });

    _pcmF32Controller = StreamController();
    _f32StreamSubscription = _pcmF32Controller!.stream.listen((food) async {
      _f32StreamSubscription!.pause(feedF32FromStream(food));
      //await feedF32FromStream(food); // await?
    });

    _pcmInt16Controller = StreamController();
    _int16StreamSubscription = _pcmInt16Controller!.stream.listen((food) async {
      _int16StreamSubscription!.pause(feedInt16FromStream(food));
      //await feedInt16FromStream(food); // await?
    });

    if (_startPlayerCompleter != null) {
      _logger.w('Killing another startPlayer()');
      _startPlayerCompleter!.completeError('Killed by another startPlayer()');
    }
    _audioPlayerFinishedPlaying = onBufferUnderflow;
    _fromStream = true;

    try {
      _startPlayerCompleter = Completer<Duration>();
      completer = _startPlayerCompleter;
      /*
      var state = await FlutterSoundPlayerPlatform.instance.startPlayer(
        this,
        codec: codec,
        interleaved: interleaved,
        fromDataBuffer: null,
        fromURI: null,
        numChannels: numChannels,
        sampleRate: sampleRate,
        bufferSize: bufferSize,
      );

       */
      var state = await FlutterSoundPlayerPlatform.instance
          .startPlayerFromStream(
            this,
            codec: codec,
            interleaved: interleaved,
            numChannels: numChannels,
            sampleRate: sampleRate,
            bufferSize: bufferSize,
          );
      _playerState = PlayerState.values[state];
    } on Exception {
      _startPlayerCompleter = null;
      rethrow;
    }
    _logger.d('FS:<--- startPlayerFromStream ');
    return completer!.future;
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
  @Deprecated('Use [feedUint8FromStream()]')
  Future<void> feedFromStream(Uint8List buffer) async {
    var lnData = 0;
    var totalLength = buffer.length;
    while (totalLength > 0 && !isStopped) {
      var bsize = totalLength > _bufferSize ? _bufferSize : totalLength;
      //_waitForFood = true;
      var ln = await _feed(buffer.sublist(lnData, lnData + bsize));
      //_waitForFood = false;
      assert(ln >= 0);
      lnData += ln;
      totalLength -= ln;
    }
  }

  ///
  Future<int> _feed(Uint8List data) async {
    // await _waitOpen();
    if (_isInited != Initialized.fullyInitialized) {
      throw Exception('Player is not open');
    }
    if (isStopped) {
      return 0;
    }
    _needSomeFoodCompleter =
        Completer<int>(); // Not completed until the device accept new data
    try {
      var ln = await (FlutterSoundPlayerPlatform.instance.feed(
        this,
        data: data,
      ));
      assert(ln >= 0); // feedFromStream() is not happy if < 0
      if (ln != 0) {
        // If the device accepted some data, then no need to wait
        // It is the tau_core responsability to send a "needSomeFood" then it is again available for new data
        _needSomeFoodCompleter = null;
        return (ln);
      } else {
        //logger.i("The device has enough data");
      }
    } on Exception {
      _needSomeFoodCompleter = null;
      if (isStopped) {
        return 0;
      }
      rethrow;
    }

    if (_needSomeFoodCompleter != null) {
      return _needSomeFoodCompleter!.future;
    }
    return 0;
  }

  /// Feed a Float32 stream not interleaved when a flow control is wanted
  ///
  /// ----------------------------------------------------------------------
  ///
  /// Please look to this [small guide](/tau/guides/guides_live_streams.html) if you need help.
  ///
  /// ## Parameters
  ///
  /// - **_buffer:_** is a List of Float32List containing the audio data that you want to play.
  /// The List length must be equal to the number of channels.
  /// All the Float32List length **MUST** be same and contain your data.
  ///
  /// ## Return
  ///
  /// Returns a Future that you MUST await if you really need a flow control.
  /// This future is declared _completed_ when the data has been played,
  /// or at least when they had be given to the lower layer of the software.
  /// Note: don't use the `int` returned. It is just for legacy reason and must not be used.
  ///
  /// ## Example
  /// ```dart
  /// await myPlayer.startPlayerFromStream
  /// (
  ///     codec: Codec.pcmFloat32
  ///     numChannels: 2
  ///     sampleRate: 48100
  ///     interleaved: false,
  /// );
  ///
  /// await myPlayer.feedF32FromStream(myData);
  /// ```
  ///
  /// ## See also
  /// - [feedInt16FromStream()]
  /// - [feedUint8FromStream()]
  /// - [float32Sink]
  /// - [int16Sink]
  /// - [uint8ListSink]
  /// - Please look to this [small guide](/tau/guides/guides_live_streams.html) if you need help
  /// ----------------------------------------------------------------------
  ///
  Future<int> feedF32FromStream(List<Float32List> buffer) async {
    await _waitOpen();
    if (_isInited != Initialized.fullyInitialized) {
      throw Exception('Player is not open');
    }
    if (isStopped) {
      return 0;
    }

    if (codec != Codec.pcmFloat32) {
      logger.e('Cannot feed with Float32 on a Codec <> pcmFloat32');
      throw Exception('Cannot feed with Float32 on a Codec <> pcmFloat32');
    }
    if (interleaved) {
      logger.e('Cannot feed with Float32 with interleaved mode');
      throw Exception('Cannot feed with Float32 with interleaved mode');
    }
    if (buffer.length != numChannels) {
      logger.e(
        'feedF32FromStream() : buffer length (${buffer.length}) != the number of channels ($numChannels)',
      );
      throw Exception(
        'feedF32FromStream() : buffer length (${buffer.length}) != the number of channels ($numChannels)',
      );
    }
    for (int channel = 1; channel < numChannels; ++channel) {
      if (buffer[channel].length != buffer[0].length) {
        logger.e(
          'feedF32FromStream() : buffer length[0] (${buffer[0].length}) != the number of channels ($numChannels)',
        );
        throw Exception(
          'feedF32FromStream() : buffer length[0] (${buffer.length}) != buffer[$channel].length (${buffer[channel].length})',
        );
      }
    }

    _needSomeFoodCompleter =
        Completer<int>(); // Not completed until the device accept new data
    try {
      var ln = await (FlutterSoundPlayerPlatform.instance.feedFloat32(
        this,
        data: buffer,
      ));
      assert(ln >= 0); // feedFromStream() is not happy if < 0
      if (ln != 0) {
        // If the device accepted some data, then no need to wait
        // It is the tau_core responsability to send a "needSomeFood" then it is again available for new data
        _needSomeFoodCompleter = null;
        return (ln);
      } else {
        //logger.i("The device has enough data");
      }
    } on Exception {
      _needSomeFoodCompleter = null;
      if (isStopped) {
        return 0;
      }
      rethrow;
    }

    if (_needSomeFoodCompleter != null) {
      return _needSomeFoodCompleter!.future;
    }
    return 0;
  }

  /// Feed a Int16 stream not interleaved when a flow control is wanted
  ///
  /// ----------------------------------------------------------------------
  ///
  /// Please look to this [small guide](/tau/guides/guides_live_streams.html) if you need help.
  ///
  /// ## Parameters
  ///
  /// - **_buffer:_** is a List of Int16List containing the audio data that you want to play.
  /// The List length must be equal to the number of channels.
  /// All the Int16List length **MUST** be same and contain your data.
  ///
  /// ## Return
  ///
  /// Returns a Future that you MUST await if you really need a flow control.
  /// This future is declared _completed_ when the data has been played,
  /// or at least when they had be given to the lower layer of the software.
  /// Note: don't use the `int` returned. It is just for legacy reason and must not be used.
  ///
  /// ## Example
  /// ```dart
  /// await myPlayer.startPlayerFromStream
  /// (
  ///     codec: Codec.pcm16
  ///     numChannels: 2
  ///     sampleRate: 48100
  ///     interleaved: false,
  /// );
  ///
  /// await myPlayer.feedInt16FromStream(myData);
  /// ```
  ///
  /// ## See also
  /// - [feedF32FromStream()]
  /// - [feedUint8FromStream()]
  /// - [float32Sink]
  /// - [int16Sink]
  /// - [uint8ListSink]
  /// - Please look to this [small guide](/tau/guides/guides_live_streams.html) if you need help
  ///
  /// ----------------------------------------------------------------------
  ///
  Future<int> feedInt16FromStream(List<Int16List> buffer) async {
    await _waitOpen();
    if (_isInited != Initialized.fullyInitialized) {
      throw Exception('Player is not open');
    }
    if (isStopped) {
      return 0;
    }

    if (codec != Codec.pcm16) {
      logger.e('Cannot feed with Int16 on a Codec <> pcm16');
      throw Exception('Cannot feed with Int16 on a Codec <> pcm16');
    }
    if (interleaved) {
      logger.e('Cannot feed with Int16 with interleaved mode');
      throw Exception('Cannot feed with Int16 with interleaved mode');
    }
    if (buffer.length != numChannels) {
      logger.e(
        'feedInt16FromStream() : buffer length (${buffer.length}) != the number of channels ($numChannels)',
      );
      throw Exception(
        'feedInt16FromStream() : buffer length (${buffer.length}) != the number of channels ($numChannels)',
      );
    }
    for (int channel = 1; channel < numChannels; ++channel) {
      if (buffer[channel].length != buffer[0].length) {
        logger.e(
          'feedInt16FromStream() : buffer length[0] (${buffer[0].length}) != the number of channels ($numChannels)',
        );
        throw Exception(
          'feedInt16FromStream() : buffer length[0] (${buffer.length}) != buffer[$channel].length (${buffer[channel].length})',
        );
      }
    }

    _needSomeFoodCompleter =
        Completer<int>(); // Not completed until the device accept new data
    try {
      var ln = await (FlutterSoundPlayerPlatform.instance.feedInt16(
        this,
        data: buffer,
      ));
      assert(ln >= 0); // feedFromStream() is not happy if < 0
      if (ln != 0) {
        // If the device accepted some data, then no need to wait
        // It is the tau_core responsability to send a "needSomeFood" then it is again available for new data
        _needSomeFoodCompleter = null;
        return (ln);
      } else {
        //logger.i("The device has enough data");
      }
    } on Exception {
      _needSomeFoodCompleter = null;
      if (isStopped) {
        return 0;
      }
      rethrow;
    }

    if (_needSomeFoodCompleter != null) {
      return _needSomeFoodCompleter!.future;
    }
    return 0;
  }

  /// Feed a UInt8 stream interleaved when a flow control is wanted
  ///
  /// ----------------------------------------------------------------------
  ///
  /// Please look to this [small guide](/tau/guides/guides_live_streams.html) if you need help.
  ///
  /// ## Parameters
  ///
  /// - **_buffer:_** is a Uint8List containing the audio data that you want to play.
  ///
  /// ## Return
  ///
  /// Returns a Future that you MUST await if you really need a flow control.
  /// This future is declared _completed_ when the data has been played,
  /// or at least when they had be given to the lower layer of the software.
  /// Note: don't use the `int` returned. It is just for legacy reason and must not be used.
  ///
  /// ## Example
  /// ```dart
  /// await myPlayer.startPlayerFromStream
  /// (
  ///     codec: Codec.pcm16
  ///     numChannels: 2
  ///     sampleRate: 48100
  ///     interleaved: true,
  /// );
  ///
  /// await myPlayer.feedUint8FromStream(myData);
  /// ```
  ///
  /// ## See also
  /// - [feedInt16FromStream()]
  /// - [feedF32FromStream()]
  /// - [float32Sink]
  /// - [int16Sink]
  /// - [uint8ListSink]
  /// - Please look to this [small guide](/tau/guides/guides_live_streams.html) if you need help
  ///
  /// ----------------------------------------------------------------------
  ///
  Future<int> feedUint8FromStream(Uint8List buffer) async {
    // await _waitOpen();
    if (_isInited != Initialized.fullyInitialized) {
      throw Exception('Player is not open');
    }
    if (isStopped) {
      return 0;
    }

    if (codec != Codec.pcmFloat32 && codec != Codec.pcm16) {
      logger.e(
        'feedUint8FromStream() : Cannot feed on a Codec <> pcmFloat32 or pcm16',
      );
      throw Exception(
        'feedUint8FromStream() : Cannot feed on a Codec <> pcmFloat32 or pcm16',
      );
    }
    if (!interleaved) {
      logger.e(
        'feedUint8FromStream() : Cannot feed with UInt8 with non interleaved mode',
      );
      throw Exception(
        'feedUint8FromStream() : Cannot feed with UInt8 with non interleaved mode',
      );
    }
    int s = 2;
    if (codec == Codec.pcmFloat32) {
      s = 4;
    }
    double n1 = (buffer.length.toDouble()) / (s * numChannels.toDouble());
    double n2 =
        (buffer.length.toDouble()) / (s * numChannels.toDouble()).round();
    if (n1 != n2) {
      logger.e(
        'feedUint8FromStream() : buffer length (${buffer.length}) is not a multiple of number of channels * $s ($numChannels)',
      );
      throw Exception(
        'feedUint8FromStream() : buffer length (${buffer.length}) is not a multiple of number of channels * $s($numChannels)',
      );
    }

    return _feed(buffer);
  }

  /// Stop a player.
  ///
  /// ------------------------------------------------------------------------
  ///
  /// This verb never throws any exception. It is safe to call it everywhere,
  /// for example when the App is not sure of the current Audio State and wants to recover a clean reset state.
  ///
  /// ## Return
  ///
  /// A future completed when the stopPlayer function is done
  ///
  /// ## Example
  ///
  /// ```dart
  ///         await myPlayer.stopPlayer();
  ///         if (_playerSubscription != null)
  ///         {
  ///                 _playerSubscription.cancel();
  ///                 _playerSubscription = null;
  ///         }
  /// ```
  ///
  /// ## See also
  /// - [startPlayer()]
  /// - [startPlayerFromStream()]
  ///
  /// --------------------------------------------------------------------------
  Future<void> stopPlayer() async {
    await _lock.synchronized(() async {
      await _stopPlayer();
    });
  }

  Future<void> _stopPlayer() async {
    _logger.d('FS:---> _stopPlayer ');
    while (_openPlayerCompleter != null) {
      _logger.w('Waiting for the player being opened');
      await _openPlayerCompleter!.future;
    }
    if (_isInited != Initialized.fullyInitialized) {
      _logger.d('<--- _stopPlayer : Player is not open');
      return;
    }
    try {
      //_removePlayerCallback(); // playerController is closed by this function
      await _stop();
    } on Exception catch (e) {
      _logger.e(e);
    }
    _logger.d('FS:<--- stopPlayer ');
  }

  Future<void> _stop() async {
    _logger.d('FS:---> _stop ');
    /*
    if (_foodStreamSubscription != null) {
      await _foodStreamSubscription!.cancel();
      _foodStreamSubscription = null;
    }
    
     */

    if (_f32StreamSubscription != null) {
      await _f32StreamSubscription!.cancel();
      await _pcmF32Controller?.sink.close();
      await _pcmF32Controller?.close();
      _pcmF32Controller = null;
      _f32StreamSubscription = null;
    }

    if (_int16StreamSubscription != null) {
      await _int16StreamSubscription!.cancel();
      await _pcmInt16Controller?.sink.close();
      await _pcmInt16Controller?.close();
      _pcmInt16Controller = null;
      _int16StreamSubscription = null;
    }

    if (_uint8StreamSubscription != null) {
      await _uint8StreamSubscription!.cancel();
      await _pcmUint8Controller?.sink.close();
      await _pcmUint8Controller?.close();
      _pcmUint8Controller = null;
      _uint8StreamSubscription = null;
    }

    _needSomeFoodCompleter = null;
    /*
    if (_foodStreamController != null) {
      await _foodStreamController!.sink.close();
      //await foodStreamController.stream.drain<bool>();
      await _foodStreamController!.close();
      _foodStreamController = null;
    }

 */

    Completer<void>? completer;
    _stopPlayerCompleter = Completer<void>();
    try {
      completer = _stopPlayerCompleter;
      var state = await FlutterSoundPlayerPlatform.instance.stopPlayer(this);

      _playerState = PlayerState.values[state];
      if (_playerState != PlayerState.isStopped) {
        _logger.d('Player is not stopped!');
      }
    } on Exception {
      _stopPlayerCompleter = null;
      rethrow;
    }

    _logger.d('FS:<--- _stop ');
    return completer!.future;
  }

  /// Pause the current playback.
  ///
  /// ------------------------------------------------------------------
  ///
  /// An exception is thrown if the player is not in the "playing" state.
  ///
  /// ## Return
  ///
  /// Return a Future which is completed when the function is done.
  ///
  /// ## Example
  /// ```dart
  /// await myPlayer.pausePlayer();
  /// ```
  ///
  /// ## See also
  /// - [resumePlayer()]
  ///
  /// ------------------------------------------------------------------
  ///
  Future<void> pausePlayer() async {
    _logger.d('FS:---> pausePlayer ');
    await _lock.synchronized(() async {
      await _pausePlayer();
    });
    _logger.d('FS:<--- pausePlayer ');
  }

  Future<void> _pausePlayer() async {
    _logger.d('FS:---> _pausePlayer ');
    await _waitOpen();
    if (_isInited != Initialized.fullyInitialized) {
      throw Exception('Player is not open');
    }
    Completer<void>? completer;
    if (_pausePlayerCompleter != null) {
      _logger.w('Killing another pausePlayer()');
      _pausePlayerCompleter!.completeError('Killed by another pausePlayer()');
    }
    try {
      _pausePlayerCompleter = Completer<void>();
      completer = _pausePlayerCompleter;
      _playerState =
          PlayerState.values[await FlutterSoundPlayerPlatform.instance
              .pausePlayer(this)];
      //if (_playerState != PlayerState.isPaused) {
      //throw _PlayerRunningException(
      //'Player is not paused.'); // I am not sure that it is good to throw an exception here
      //}
    } on Exception {
      _pausePlayerCompleter = null;
      rethrow;
    }
    _logger.d('FS:<--- _pausePlayer ');
    return completer!.future;
  }

  /// Resume the current playback.
  ///
  /// -------------------------------------------------------------------
  ///
  /// An exception is thrown if the player is not in the "paused" state.
  ///
  /// ## Return
  ///
  /// Returns a Future which is completed when the function is done
  ///
  /// ## Example
  /// ```dart
  /// await myPlayer.resumePlayer();
  /// ```
  ///
  /// ## See also
  /// - [resumePlayer()]
  ///
  /// -------------------------------------------------------------------
  ///
  Future<void> resumePlayer() async {
    _logger.d('FS:---> resumePlayer');
    await _lock.synchronized(() async {
      await _resumePlayer();
    });
    _logger.d('FS:<--- resumePlayer');
  }

  Future<void> _resumePlayer() async {
    _logger.d('FS:---> _resumePlayer');
    await _waitOpen();
    if (_isInited != Initialized.fullyInitialized) {
      throw Exception('Player is not open');
    }
    Completer<void>? completer;
    if (_resumePlayerCompleter != null) {
      _logger.w('Killing another resumePlayer()');
      _resumePlayerCompleter!.completeError('Killed by another resumePlayer()');
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
    _logger.d('FS:<--- _resumePlayer');
    return completer!.future;
  }

  /// To seek to a new location.
  ///
  /// -------------------------------------------------------------------
  ///
  /// The player must already be playing or paused. If not, an exception is thrown.
  ///
  /// ## Parameters
  ///
  /// - **_duration:_** is the position that you want to seek into your player
  ///
  /// ## Return
  ///
  /// Return a Future which is completed when the function is done.
  ///
  /// ## Example
  /// ```dart
  /// await myPlayer.seekToPlayer(Duration(milliseconds: milliSecs));
  /// ```
  /// --------------------------------------------------------------------
  ///
  Future<void> seekToPlayer(Duration duration) async {
    await _lock.synchronized(() async {
      await _seekToPlayer(duration);
    });
  }

  Future<void> _seekToPlayer(Duration duration) async {
    _logger.t('FS:---> seekToPlayer ');
    await _waitOpen();
    if (_isInited != Initialized.fullyInitialized) {
      throw Exception('Player is not open');
    }
    var state = await FlutterSoundPlayerPlatform.instance.seekToPlayer(
      this,
      duration: duration,
    );
    _oldPosition = 0;
    _playerState = PlayerState.values[state];
    _logger.t('FS:<--- seekToPlayer ');
  }

  /// Change the output volume
  ///
  /// -------------------------------------------------------------------------
  ///
  /// The volume can be changed when player is running or before [startPlayer()].
  ///
  /// ## Parameters
  /// - **_volume:_**The parameter is a floating point number between 0 and 1.
  ///
  /// ## Return
  ///
  /// - Return a Future which is completed when the function is done.
  ///
  /// ## Example
  ///
  /// ```dart
  /// await myPlayer.setVolume(0.1);
  /// ```
  ///
  /// ## See also
  /// - [setVolumePan()]
  ///
  /// -------------------------------------------------------------------------
  ///
  Future<void> setVolume(double volume) async {
    await _lock.synchronized(() async {
      await _setVolume(volume);
    });
  }

  Future<void> _setVolume(double volume) async {
    _logger.d('FS:---> setVolume ');
    await _waitOpen();
    if (_isInited != Initialized.fullyInitialized) {
      throw Exception('Player is not open');
    }
    //var indexedVolume = (!kIsWeb) && Platform.isIOS ? volume * 100 : volume;
    if (volume < 0.0 || volume > 1.0) {
      throw RangeError('Value of volume should be between 0.0 and 1.0.');
    }

    var state = await FlutterSoundPlayerPlatform.instance.setVolume(
      this,
      volume: volume,
    );
    _playerState = PlayerState.values[state];
    _logger.d('FS:<--- setVolume ');
  }

  /// FIXME : documentation of this verb
  Future<void> setVolumePan(double volume, double pan) async {
    await _lock.synchronized(() async {
      await _setVolumePan(volume, pan);
    });
  }

  Future<void> _setVolumePan(double volume, double pan) async {
    _logger.d('FS:---> setVolumePan ');
    await _waitOpen();
    if (_isInited != Initialized.fullyInitialized) {
      throw Exception('Player is not open');
    }
    //var indexedVolume = (!kIsWeb) && Platform.isIOS ? volume * 100 : volume;
    if (volume < 0.0 || volume > 1.0) {
      throw RangeError('Value of volume should be between 0.0 and 1.0.');
    }
    if (pan < -1.0 || pan > 1.0) {
      throw RangeError('Value of pan should be between -1.0 and 1.0.');
    }
    var state = await FlutterSoundPlayerPlatform.instance.setVolumePan(
      this,
      volume: volume,
      pan: pan,
    );
    _playerState = PlayerState.values[state];
    _logger.d('FS:<--- setVolumePan ');
  }

  /// Change the playback speed
  ///
  /// ----------------------------------------------------------------------
  ///
  /// The speed can be changed when player is running, or before [startPlayer()].
  ///
  /// ## Parameters
  /// - **_speed:_** The parameter is a floating point number between 0 and 1.0 to slow the speed,
  /// or 1.0 to n to accelerate the speed.
  ///
  /// ## Return
  ///
  /// - Returns a Future when the function is done.
  ///
  /// ## Example
  /// ```dart
  /// await myPlayer.setSpeed(0.8);
  /// ```
  /// -------------------------------------------------------------------
  ///
  Future<void> setSpeed(double speed) async {
    await _lock.synchronized(() async {
      await _setSpeed(speed);
    });
  }

  Future<void> _setSpeed(double speed) async {
    _logger.d('FS:---> _setSpeed ');
    await _waitOpen();
    if (_isInited != Initialized.fullyInitialized) {
      throw Exception('Player is not open');
    }
    if (speed < 0.0) {
      throw RangeError('Value of speed should be between 0.0 and n.');
    }

    var state = await FlutterSoundPlayerPlatform.instance.setSpeed(
      this,
      speed: speed,
    );
    _playerState = PlayerState.values[state];
    _logger.d('FS:<--- _setSpeed ');
  }

  /// Get the resource path.
  ///
  /// This verb should probably not be here...
  /// @nodoc
  Future<String?> getResourcePath() async {
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
