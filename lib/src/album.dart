import 'sound_player.dart';
import 'track.dart';

typedef TrackChange = Track Function(int currentTrackIndex, Track current);

/// An [Album] allows you to play a collection of [Tracks] via
/// the OS's builtin audio UI.
///
class Album {
  List<Track> _tracks;

  var _currentTrackIndex = 0;

  Track currentTrack;

  /// If you use the [Album.virtual] constructor then
  /// you need to provide a handlers for [onSkipForward]
  /// method.
  /// see [Album.virtual()] for details.
  TrackChange onSkipForward;

  /// If you use the [Album.virtual] constructor then
  /// you need to provide a handlers for [onSkipbackward]
  /// method.
  /// see [Album.virtual()] for details.
  TrackChange onSkipBackward;

  /// Creates an album of tracks which will be played
  /// via the OS' built in player.
  /// The tracks will be played in order and the user
  /// has the ability to skip forward/backwards.
  Album.fromTracks(this._tracks) {
    // wire each track
    for (var track in _tracks) {
      track.onSkipBackward = (_) => _skipBackwards();
      track.onSkipForward = (_) => _skipForwards();
      track.onFinished = _skipForwards;
    }
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
  Album.virtual();

  void _skipBackwards() {
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

  void _skipForwards() {
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
    currentTrack.initialise();
    currentTrack.play();
  }

  void stop() {
    currentTrack.stop();
    currentTrack.release();
  }
}
