import '../audio_session/audio_session.dart';

import '../track.dart';
import 'album_impl.dart';

typedef TrackChange = Track Function(int currentTrackIndex, Track current);

/// An [Album] allows you to play a collection of [Tracks] via
/// the OS's builtin audio UI.
///
class Album {
  AlbumImpl _impl;

  /// Returns the track that is currently selected.
  Track get currentTrack => _impl.currentTrack;

  /// If you use the [Album.virtual] constructor then
  /// you need to provide a handlers for [onSkipForward]
  /// method.
  /// see [Album.virtual()] for details.
  TrackChange get onSkipForward => _impl.onSkipForward;

  /// If you use the [Album.virtual] constructor then
  /// you need to provide a handlers for [onSkipForward]
  /// method.
  /// see [Album.virtual()] for details.
  set onSkipForward(TrackChange onSkipForward) {
    _impl.onSkipForward = onSkipForward;
  }

  /// If you use the [Album.virtual] constructor then
  /// you need to provide a handlers for [onSkipbackward]
  /// method.
  /// see [Album.virtual()] for details.
  TrackChange get onSkipBackward => _impl.onSkipBackward;

  /// If you use the [Album.virtual] constructor then
  /// you need to provide a handlers for [onSkipbackward]
  /// method.
  /// see [Album.virtual()] for details.
  set onSkipBackward(TrackChange onSkipBackward) {
    _impl.onSkipBackward = onSkipBackward;
  }

  /// Creates an album of tracks which will be played
  /// via the OS' built in player.
  /// The tracks will be played in order and the user
  /// has the ability to skip forward/backwards.
  /// By default the Album displays on the OS' audio player.
  /// To suppress the OS' audio player pass [AudioSession.noUI()]
  /// to [session].
  Album.fromTracks(List<Track> tracks, {AudioSession session}) {
    _impl = AlbumImpl.fromTracks(tracks, session);
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
  /// To suppress the OS' audio player pass [AudioSession.noUI()]
  /// to [session].
  Album.virtual({AudioSession session}) {
    _impl = AlbumImpl.virtual(session);
  }

  /// Starts the album playing from the first track.
  /// see [resume]
  void play() => _impl.play();

  /// stops the album playing
  /// see [pause]
  void stop() => _impl.stop();

  /// pauses the album.
  void pause() => _impl.pause();

  /// resumes the album playing.
  void resume() => _impl.resume();
}
