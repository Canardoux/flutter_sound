class PlayStatus {
  final Duration duration;
  Duration position;

  /// A convenience ctor. If you are using a stream builder
  /// you can use this to set initialData with both duration
  /// and postion as 0.
  PlayStatus.zero()
      : duration = Duration(seconds: 0),
        position = Duration(seconds: 0);

  PlayStatus.fromJSON(Map<String, dynamic> json)
      : duration = Duration(
            milliseconds: double.parse(json['duration'] as String).toInt()),
        position = Duration(
            milliseconds:
                double.parse(json['current_position'] as String).toInt());

  @override
  String toString() {
    return 'duration: $duration, '
        'currentPosition: $position';
  }
}
