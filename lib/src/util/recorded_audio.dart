import '../track.dart';

/// [RecordedAudio] is used to track the audio media
/// created during a recording session via the SoundRecorderUI.
///
class RecordedAudio {
  /// The length of the recording (so far)
  Duration duration = Duration.zero;

  /// The track we are recording audio intto.
  Track track;

  /// Creates a [RecordedAudio] that will store
  /// the recording to the given track.
  RecordedAudio.toTrack(this.track);
}
