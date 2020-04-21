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

  ///
  PlaybackDisposition(this.position, this.duration);

  @override
  String toString() {
    return 'duration: $duration, '
        'position: $position';
  }
}
