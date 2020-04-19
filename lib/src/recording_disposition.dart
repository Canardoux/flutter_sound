/*
 * This file is part of Flutter-Sound.
 *
 *   Flutter-Sound is free software: you can redistribute it and/or modify
 *   it under the terms of the Lesser GNU General Public License
 *   version 3 (LGPL3) as published by the Free Software Foundation.
 *
 *   Flutter-Sound is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the Lesser GNU General Public License
 *   along with Flutter-Sound.  If not, see <https://www.gnu.org/licenses/>.
 */

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
