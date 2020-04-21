import 'dart:async';

import '../codec.dart';
import '../ios/ios_session_category.dart';
import '../ios/ios_session_mode.dart';
import '../playback_disposition.dart';
import '../track.dart';
import 'audio_session_impl.dart';

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

/// An audio session that supports playing track.
///
/// Unforunately the concept of tracks is tightly couple
/// to displaying using the OS media player due to the
/// plugin architecture.
/// It would be nice to review this so a track can be used
/// with a third party player.
class AudioSession {
  final AudioSessionImpl _impl;

  /// Create a [AudioSession] that displays the OS' audio UI.
  AudioSession.withUI(
      {bool canPause, bool canSkipBackward, bool canSkipForward})
      : _impl = AudioSessionImpl.withUI(
          canPause: canPause,
          canSkipBackward: canSkipBackward,
          canSkipForward: canSkipForward,
        );

  /// Create an [AudioSession] that does not have a UI.
  /// You can use this version to simply playback audio without
  /// a UI or to build your own UI as [Playbar] does.
  AudioSession.noUI() : _impl = AudioSessionImpl.noUI();

  /// Returns the
  PlayerState get playerState => _impl.playerState;

  set playerState(PlayerState playerState) {
    _impl.playerState = playerState;
  }

  /// The [uri] of the file to download and playback
  /// The [codec] of the file the [uri] points to. The default
  /// value is [Codec.fromExtension].
  /// If the default [Codec.fromExtension] is used then
  /// [SoundPlayer] will use the files extension to guess the codec.
  /// If the file extension doesn't match a known codec then
  /// [SoundPlayer] will throw an [CodecNotSupportedException] in which
  /// case you need pass one of the known codecs.
  ///
  ///
  /// Starts playback.
  Future<void> play(Track track) async => _impl.play(track);

  /// call this method once you are down with the player
  /// so that it can release all of the attached resources.
  Future<void> release() async => _impl.release();

  /// Stops playback.
  Future<void> stop() async => _impl.stop();

  /// Pauses playback.
  /// If you call this and the audio is not playing
  /// a [PlayerInvalidStateException] will be thrown.
  Future<void> pause() async => _impl.pause();

  /// Resumes playback.
  /// If you call this when audio is not paused
  /// then a [PlayerInvalidStateException] will be thrown.
  Future<void> resume() async => _impl.resume();

  /// Moves the current playback position to the given offset in the
  /// recording.
  /// [position] is the position in the recording to set the playback
  /// location from.
  /// You may call this before [play] or whilst the audio is playing.
  /// If you call [seekTo] before calling [play] then when you call
  /// [play] we will start playing the recording from the [position]
  /// passed to [seekTo].
  Future<void> seekTo(Duration position) async => _impl.seekTo(position);

  /// Sets the playback volume
  /// The [volume] must be in the range 0.0 to 1.0.
  Future<void> setVolume(double volume) async => _impl.setVolume(volume);

  ///  The caller can manage his audio focus with this function
  /// Depending on your configuration this will either make
  /// this player the loudest stream or it will silence all other stream.
  Future<void> requestAudioFocus() async => _impl.requestAudioFocus();

  /// Reliquences the foreground audio.
  Future<void> abandonAudioFocus({bool enabled}) async =>
      _impl.abandonAudioFocus();

  /// TODO does this need to be exposed?
  /// The simple action of stopping the playback may be sufficient
  /// Given the user has to call stop
  void closeDispositionStream() => _impl.closeDispositionStream();

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
          {Duration interval = const Duration(milliseconds: 100)}) =>
      _impl.dispositionStream(interval: interval);

  /// [true] if the player is currently playing audio
  bool get isPlaying => _impl.isPlaying;

  /// [true] if the player is playing but the audio is paused
  bool get isPaused => _impl.isPaused;

  /// [true] if the player is stopped.
  bool get isStopped => _impl.isStopped;

  /// Instructs the OS to reduce the volume of other audio
  /// whilst we play this audio file.
  /// The exact effect of this is OS dependant.
  /// The effect is only applied when we start the audio play.
  /// Changing this value whilst audio is play will have no affect.
  bool get hushOthers => _impl.hushOthers;

  /// Instructs the OS to reduce the volume of other audio
  /// whilst we play this audio file.
  /// The exact effect of this is OS dependant.
  /// The effect is only applied when we start the audio play.
  /// Changing this value whilst audio is play will have no affect.
  set hushOthers(bool hushOthers) {
    _impl.hushOthers = hushOthers;
  }

  /// Pass a callback if you want to be notified when
  /// a track finishes to completion.
  /// see [onStopped] for events when the user or system stops playback.
  // ignore: avoid_setters_without_getters
  set onFinished(PlayerEvent onFinished) {
    _impl.onFinished = onFinished;
  }

  ///
  /// Pass a callback if you want to be notified when
  /// playback is paused.
  /// The [wasUser] argument in the callback will
  /// be true if the user clicked the pause button
  /// on the OS UI.
  ///
  /// [wasUser] will be false if you paused the audio
  /// via a call to [pause].
  // ignore: avoid_setters_without_getters
  set onPaused(PlayerEventWithCause onPaused) {
    _impl.onPaused = onPaused;
  }

  ///
  /// Pass a callback if you want to be notified when
  /// playback is resumed.
  /// The [wasUser] argument in the callback will
  /// be true if the user clicked the resume button
  /// on the OS UI.
  ///
  /// [wasUser] will be false if you resumed the audio
  /// via a call to [resume].
  // ignore: avoid_setters_without_getters
  set onResumed(PlayerEventWithCause onResumed) {
    _impl.onResumed = onResumed;
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
  /// OS UI.
  // ignore: avoid_setters_without_getters
  set onStarted(PlayerEventWithCause onStarted) {
    _impl.onStarted = onStarted;
  }

  /// Pass a callback if you want to be notified
  /// that audio has stopped playing.
  /// This is different from [onFinished] which
  /// is called when the auido plays to completion.
  ///
  /// [onStoppped]  can occur if you called [stop]
  /// or the user click the stop button on the

  // ignore: avoid_setters_without_getters
  set onStopped(PlayerEventWithCause onStopped) {
    _impl.onStopped = onStopped;
  }

  /// Pass a callback if you want to be notified
  /// when the user attempts to skip forward to the
  /// next track.
  /// This is only meaningful if you have set
  /// [showOSUI] which has a 'skip' button.
  /// The AudioSessionImpl essentially ignores this event
  /// as the AudioSessionImpl has no concept of an Album.
  ///
  /// It is up to you to create a new AudioSessionImpl with the
  /// next track and start it playing.
  ///
  // ignore: avoid_setters_without_getters
  set onSkipForward(PlayerEvent onSkipForward) {
    _impl.onSkipForward = onSkipForward;
  }

  /// Pass a callback if you want to be notified
  /// when the user attempts to skip backward to the
  /// prior track.
  /// This is only meaningful if you have set
  /// [showOSUI] which has a 'skip' button.
  /// The AudioSessionImpl essentially ignores this event
  /// as the AudioSessionImpl has no concept of an Album.
  ///
  ///
  // ignore: avoid_setters_without_getters
  set onSkipBackward(PlayerEvent onSkipBackward) {
    _impl.onSkipBackward = onSkipBackward;
  }

  /// Returns true if the specified decoder is supported
  ///  by flutter_sound on this platform
  Future<bool> isSupported(Codec codec) async => _impl.isSupported(codec);

  /// For iOS only.
  /// If this function is not called,
  /// everything is managed by default by flutter_sound.
  /// If this function is called,
  /// it is probably called just once when the app starts.
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
  Future<bool> iosSetCategory(IOSSessionCategory category, IOSSessionMode mode,
          int options) async =>
      _impl.iosSetCategory(category, mode, options);
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
