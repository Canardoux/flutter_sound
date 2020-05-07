import 'dart:async';

import 'audio_focus.dart';
import 'audio_player.dart';
import 'codec.dart';
import 'playback_disposition.dart';
import 'track.dart';

///
class SoundPlayer {
  AudioPlayer _player;

  ///
  SoundPlayer({bool playInBackground = false}) {
    _player = AudioPlayer.noUI(playInBackground: playInBackground);
  }

  /// initialise the SoundPlayer.
  /// You do not need to call this as the player auto initialises itself
  /// and in fact has to re-initialise its self after an app pause.
  void initialise() {
    // NOOP - as its not required but apparently wanted.
  }

  /// call this method once you are done with the player
  /// so that it can release all of the attached resources.
  ///
  Future<void> release() async {
    return _player.release();
  }

  /// Starts playback.
  /// The [track] to play.
  Future<void> play(Track track) async {
    return _player.play(track);
  }

  /// Stops playback.
  Future<void> stop() async {
    return _player.stop();
  }

  /// Pauses playback.
  /// If you call this and the audio is not playing
  /// a [PlayerInvalidStateException] will be thrown.
  Future<void> pause() async {
    return _player.pause();
  }

  /// Resumes playback.
  /// If you call this when audio is not paused
  /// then a [PlayerInvalidStateException] will be thrown.
  Future<void> resume() async {
    return _player.resume();
  }

  ///
  Future<void> seekTo(Duration position) async {
    return _player.seekTo(position);
  }

  /// Rewinds the current track by the given interval
  Future<void> rewind(Duration interval) {
    return _player.rewind(interval);
  }

  /// Sets the playback volume
  /// The [volume] must be in the range 0.0 to 1.0.
  Future<void> setVolume(double volume) async {
    return _player.setVolume(volume);
  }

  /// Returns true if the specified decoder is supported
  ///  by flutter_sound on this platform
  Future<bool> isSupported(Codec codec) async {
    return _player.isSupported(codec);
  }

  ///  The caller can manage his audio focus with this function
  /// Depending on your configuration this will either make
  /// this player the loudest stream or it will silence all other stream.
  Future<void> audioFocus(AudioFocus mode) async {
    return _player.audioFocus(mode);
  }




  /// [true] if the player is currently playing audio
  bool get isPlaying => _player.isPlaying;

  /// [true] if the player is playing but the audio is paused
  bool get isPaused => _player.isPaused;

  /// [true] if the player is stopped.
  bool get isStopped => _player.isStopped;

  ///
  Stream<PlaybackDisposition> dispositionStream(
      {Duration interval = const Duration(milliseconds: 100)}) {
    return _player.dispositionStream(interval: interval);
  }

  /// Pass a callback if you want to be notified
  /// when the OS Media Player changs state.
  // ignore: avoid_setters_without_getters
  set onUpdatePlaybackState(OSPlayerStateEvent onUpdatePlaybackState) {
    _player.onUpdatePlaybackState = onUpdatePlaybackState;
  }

  /// Pass a callback if you want to be notified when
  /// a track finishes to completion.
  /// see [onStopped] for events when the user or system stops playback.
  // ignore: avoid_setters_without_getters
  set onFinished(PlayerEvent onFinished) {
    _player.onFinished = onFinished;
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
    _player.onPaused = onPaused;
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
    _player.onResumed = onResumed;
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
    _player.onStarted = onStarted;
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
    _player.onStopped = onStopped;
  }
}
