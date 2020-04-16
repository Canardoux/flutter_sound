import 'package:flutter/foundation.dart';

/// Holds point in time details of the recording disposition
/// including the current duration and decibels.
/// Use the [dispositionStream] method to subscribe to a stream
/// of [RecordingDisposition] will be emmited whilst recording.
@immutable
class RecordingDisposition {
  /// The total duration of the recording at this point in time.
  final Duration duration;

  /// The volume of the audio being captured
  /// at this point in time.
  /// Value ranges from 0 to 120
  final double decibels;

  /// ctor
  RecordingDisposition(this.duration, this.decibels);

  /// use this ctor to as the initial value when building
  /// a [StreamBuilder]
  RecordingDisposition.zero()
      : duration = Duration(seconds: 0),
        decibels = 0;

  @override
  String toString() {
    return 'duration: $duration decibels: $decibels';
  }
}
