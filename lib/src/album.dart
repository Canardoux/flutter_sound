import 'audio_player.dart';

import 'track.dart';

typedef TrackChange = Track Function(int currentTrackIndex, Track current);

/// An [Album] allows you to play a collection of [Tracks] via
/// the OS's builtin audio UI.
///
class Album {
  AudioPlayer _player;

  final bool _virtualAlbum;

  List<Track> _tracks;

  var _currentTrackIndex = 0;

  /// Returns the track that is currently selected.
  Track _currentTrack;

  /// If you use the [Album.virtual] constructor then
  /// you must provide a handler for [onFirstTrack].
  /// This should return the first track of the album.
  /// This call may be made multiple times (each time
  /// the method [play] is called).
  Track Function() onFirstTrack;

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
  /// By default the Album displays on the OS' audio player.
  /// To suppress the OS' audio player pass [SoundPlayer.noUI()]
  /// to [player].
  Album.fromTracks(this._tracks, AudioPlayer player) : _virtualAlbum = false {
    Album._internal(player, _virtualAlbum);

    if (_tracks.isEmpty) {
      throw NoTracksAlbumException('You must pass at least one track');
    }
  }

  Album._internal(AudioPlayer player, bool virtualAlbum)
      : _virtualAlbum = virtualAlbum {
    _player = player ?? AudioPlayer.withUI();

    _player.onSkipBackward = _skipBackward;
    _player.onSkipForward = _skipForward;
    _player.onFinished = _onFinished;
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
  Album.virtual(AudioPlayer player) : _virtualAlbum = true {
    Album._internal(player, _virtualAlbum);
  }

  void _onFinished() {}
  void _skipBackward() {
    if (_currentTrackIndex > 1) {
      stop();

      _currentTrack = _previousTrack();

      /// TODO might be nice to have the concept of a transition
      /// when stoping one track and starting the next.
      /// This may require us to monitor the playback progression
      /// and start the transition before the playback completes (e.g. fadeout)
      if (_currentTrack != null) play();
    }
  }

  void _skipForward() {
    if (_tracks == null || _currentTrackIndex < _tracks.length - 1) {
      stop();

      _currentTrack = _nextTrack();

      /// TODO might be nice to have the concept of a transition
      /// when stoping one track and starting the next.
      /// This may require us to monitor the playback progression
      /// and start the transition before the playback completes (e.g. fadeout)
      if (_currentTrack != null) play();
    }
  }

  /// finds the previous track.
  /// If the album is virtual it calls out
  /// to get the next track.
  Track _previousTrack() {
    Track previous;
    var originalIndex = _currentTrackIndex;
    _currentTrackIndex--;
    if (_virtualAlbum) {
      if (onSkipBackward != null) {
        previous = onSkipBackward(
          originalIndex,
          _currentTrack,
        );
      }
    } else {
      previous = _tracks[_currentTrackIndex];
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
    if (_virtualAlbum) {
      if (onSkipForward != null) {
        next = onSkipForward(
          originalIndex,
          _currentTrack,
        );
      }
    } else {
      next = _tracks[_currentTrackIndex];
    }
    return next;
  }

  /// Start the album playing from the first track.
  void play() {
    _currentTrackIndex = 0;
    if (_virtualAlbum) {
      _currentTrack = onFirstTrack();
    } else {
      _currentTrack = _tracks[_currentTrackIndex];
    }
    _player.play(_currentTrack);
  }

  /// stop the album playing.
  void stop() {
    _player.stop();
    trackRelease(_currentTrack);
  }

  /// pause the album playing
  void pause() {
    _player.pause();
  }

  /// resume the album playing.
  void resume() {
    _player.resume();
  }
}

/// throw if you try to create an album with no tracks.
class NoTracksAlbumException implements Exception {
  final String _message;

  ///
  NoTracksAlbumException(this._message);

  String toString() => _message;
}
