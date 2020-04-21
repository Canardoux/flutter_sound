import 'dart:async';

import 'package:flutter_sound/flutter_sound.dart';

import 'main.dart';

/// Used to track the players state.
class PlayerState {
  static final PlayerState _self = PlayerState._internal();

  bool _hushOthers = false;

  StreamSubscription _playerSubscription;
  // StreamSubscription _playbackStateSubscription;

  /// the primary player
  QuickPlay playerModule;

  /// secondary player used to demo two audio streams playing.
  QuickPlay playerModule_2; // Used if REENTRANCE_CONCURENCY

  final StreamController<PlaybackDisposition> _playStatusController =
      StreamController<PlaybackDisposition>.broadcast();

  /// factory to retrieve a PlayerState
  factory PlayerState() {
    return _self;
  }

  PlayerState._internal();

  /// returns [true] if hushOthers (reduce other players volume)
  /// is enabled.
  bool get hushOthers => _hushOthers;

  /// get the PlayStatus stream.
  Stream<PlaybackDisposition> get playStatusStream {
    return _playStatusController.stream;
  }

  /// true if the player is currently playing or paused.
  bool get isPlayingOrPaused {
    return isPlaying || isPaused;
  }

  /// true if the player is currently stoped
  bool get isStopped => playerModule != null && playerModule.isStopped;

  /// true if the player is currently playing
  bool get isPlaying => playerModule != null && playerModule.isPlaying;

  /// true if the player is currently paused
  bool get isPaused => playerModule != null && playerModule.isPaused;

  /// initialise the player.
  void init() async {}

  /// cancel all subscriptions.
  void cancelPlayerSubscriptions() {
    if (_playerSubscription != null) {
      _playerSubscription.cancel();
      _playerSubscription = null;
    }
  }

  /// When we play something during whilst other audio is playing
  ///
  /// E.g. if Spotify is playing
  /// We can:
  // Stop Spotify
  // Play both our sound and Spotify
  // Or lower Spotify Sound during our playback.
  /// [setHush] controls option three.
  /// When passsing [true] to [setHush] the other auidio
  /// player's (e.g. spotify) sound is lowered.
  ///
  Future<void> setHush({bool hushOthers}) async {
    _hushOthers = hushOthers;
  }

  /// Call this method to release the player when
  /// you have finished.
  void release() async {
    if (playerModule != null) {
      await playerModule.release();
    }
    if (playerModule_2 != null) {
      await playerModule_2.release();
    }
  }

  /// stop the player.
  Future<void> stopPlayer() async {
    try {
      if (playerModule != null) {
        await playerModule.stop();
      }

      /// signal
      _playStatusController.add(PlaybackDisposition.zero());
      if (_playerSubscription != null) {
        await _playerSubscription.cancel();
        _playerSubscription = null;
      }
    } on Object catch (err) {
      print('error: $err');
    }
    if (renetranceConcurrency) {
      try {
        await playerModule_2.stop();
      } on Object catch (err) {
        print('error: $err');
      }
    }
  }

  /// toggles between a paused and resumed state of play.
  void pauseResumePlayer() {
    if (playerModule.isPlaying) {
      playerModule.pause();
      if (renetranceConcurrency) {
        playerModule_2.pause();
      }
    } else {
      playerModule.resume();
      if (renetranceConcurrency) {
        playerModule_2.resume();
      }
    }
  }

  /// position the playback point
  void seekToPlayer(Duration position) async {
    await playerModule.seekTo(position);
  }
}
