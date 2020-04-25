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

import 'dart:async';

import '../recording_disposition.dart';
import '../sound_recorder.dart';

/// An internal class which manages the RecordingDisposition stream.
/// Its main job is aggreate events coming up from the plugin
/// into a single stream.
class RecordingDispositionManager {
  final SoundRecorder _recorder;
  StreamController<RecordingDisposition> _dispositionController;

  /// tracks the last time we sent an update
  /// We do this as we need to 'merge' the two streams
  /// we recieve from the underlying plugin (duration and db)
  /// into a single stream.
  DateTime lastDispositonUpdate = DateTime.now();
  // The last duration we received from the plugin
  Duration _lastDispositionDuration = Duration(seconds: 0);
  // The last db we recieved from the plugin.
  double _lastDispositionDecibels = 0;

  /// The duration between updates to the stream.
  /// Defaults to [10ms].
  Duration interval = Duration(milliseconds: 10);

  /// ctor
  RecordingDispositionManager(this._recorder);

  /// Returns a stream of RecordingDispositions
  /// The stream is a broad cast stream and can be called
  /// multiple times however the [interval] is shared between
  /// all stream.
  /// The [interval] sets the time between stream updates.
  /// This is the minimum [interval] and updates may be less
  /// frequent.
  /// Updates will stop if the recorder is paused.
  Stream<RecordingDisposition> stream({Duration interval}) {
    this.interval = interval ?? this.interval;

    _dispositionController ??= StreamController.broadcast();
    recorderSetSubscriptionInterval(_recorder, interval);
    recorderSetDbLevelEnabled(_recorder, enabled: true);
    recorderSetDbPeakLevelUpdate(_recorder, interval);
    return _dispositionController.stream;
  }

  /// Internal classes calls this method to notify a change
  /// in the db level.
  void updateDbPeakDispostion(double decibels) {
    _lastDispositionDecibels = decibels;

    _trySendDisposition();
  }

  /// [timePaused] The raw duration from the android/ios subsystem
  /// ignores pauses so we need to subtract any pause time from the
  /// duratin.
  void updateDurationDisposition(Duration duration, Duration timePaused) {
    _lastDispositionDuration = duration - timePaused;

    _trySendDisposition();
  }

  /// Sends a disposition if the [interval] has elapsed since
  /// we last sent the data.
  void _trySendDisposition() {
    if (_dispositionController != null) {
      if (DateTime.now().difference(lastDispositonUpdate).inMilliseconds >=
          interval.inMilliseconds) {
        lastDispositonUpdate = DateTime.now();
        _dispositionController.add(RecordingDisposition(
            _lastDispositionDuration, _lastDispositionDecibels));
      }
    }
  }

  /// Call this method once you have finished with the recording
  /// api so we can release any attached resources.
  void release() {
    if (_dispositionController != null) {
      _dispositionController
        // TODO signal that the stream is closed?
        // ..add(null) // We keep that strange line for backward compatibility
        ..close();
      _dispositionController = null;
    }
  }
}
