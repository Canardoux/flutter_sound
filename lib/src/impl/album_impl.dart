import '../audio_session/audio_session.dart';

import '../track.dart';
import 'album.dart';

typedef TrackChange = Track Function(int currentTrackIndex, Track current);

/// An [AlbumImpl] allows you to play a collection of [Tracks] via
/// the OS's builtin audio UI.
///
class AlbumImpl implements Album {
  AudioSession _session;

  List<Track> _tracks;

  var _currentTrackIndex = 0;

  Track currentTrack;

  /// If you use the [AlbumImpl.virtual] constructor then
  /// you need to provide a handlers for [onSkipForward]
  /// method.
  /// see [Album.virtual()] for details.
  TrackChange onSkipForward;

  /// If you use the [AlbumImpl.virtual] constructor then
  /// you need to provide a handlers for [onSkipbackward]
  /// method.
  /// see [Album.virtual()] for details.
  TrackChange onSkipBackward;

  /// Creates an album of tracks which will be played
  /// via the OS' built in player.
  /// The tracks will be played in order and the user
  /// has the ability to skip forward/backwards.

  AlbumImpl.fromTracks(this._tracks, AudioSession session) {
    AlbumImpl._internal(session);
  }

  AlbumImpl._internal(AudioSession session) {
    _session = session ?? AudioSession.withUI();

    _session.onSkipBackward = _skipBackward;
    _session.onSkipForward = _skipForward;
    _session.onFinished = _onFinished;
  }

  /// Creates a virtual album which will be played
  /// via the OS' built in player.
  /// Each time the album needs a new track the [onSkipForward]
  /// method is called an you need to return the track to be played.
  /// When you [play] an album [onSkipForward] is called immediately
  /// to get the first track.
  /// If the user clicks the skip back button on the OS UI then
  /// the [onSkipBackward] method is called and you need to supply
  /// the new track to play.
  /// The Album will not allow the user to skip back past the first
  /// track you supplied so there is no looping back over the start
  /// of an album.
  AlbumImpl.virtual(AudioSession session) {
    AlbumImpl._internal(session);
  }

  void _onFinished() {}
  void _skipBackward() {
    if (_currentTrackIndex > 1) {
      stop();

      currentTrack = _previousTrack();

      /// TODO might be nice to have the concept of a transition
      /// when stoping one track and starting the next.
      /// This may require us to monitor the playback progression
      /// and start the transition before the playback completes (e.g. fadeout)
      if (currentTrack != null) play();
    }
  }

  void _skipForward() {
    if (_tracks == null || _currentTrackIndex < _tracks.length - 1) {
      stop();

      currentTrack = _nextTrack();

      /// TODO might be nice to have the concept of a transition
      /// when stoping one track and starting the next.
      /// This may require us to monitor the playback progression
      /// and start the transition before the playback completes (e.g. fadeout)
      if (currentTrack != null) play();
    }
  }

  /// finds the previous track.
  /// If the album is virtual it calls out
  /// to get the next track.
  Track _previousTrack() {
    Track previous;
    var originalIndex = _currentTrackIndex;
    _currentTrackIndex--;
    if (_tracks != null) {
      previous = _tracks[_currentTrackIndex];
    } else {
      // virtual album
      if (onSkipBackward != null) {
        previous = onSkipBackward(
          originalIndex,
          currentTrack,
        );
      }
    }
    return previous;
  }

  /// finds the next track .
  /// If the album is virtual it calls out
  /// to get the next track.
  Track _nextTrack() {
    Track next;
    var originalIndex = _currentTrackIndex;
    _currentTrackIndex++;
    if (_tracks != null) {
      next = _tracks[_currentTrackIndex];
    } else {
      // virtual album
      if (onSkipForward != null) {
        next = onSkipForward(
          originalIndex,
          currentTrack,
        );
      }
    }
    return next;
  }

  void play() {
    _session.play(currentTrack);
  }

  void stop() {
    _session.stop();
    currentTrack.release();
  }

  void pause() {
    _session.pause();
  }

  void resume() {
    _session.resume();
  }
}
