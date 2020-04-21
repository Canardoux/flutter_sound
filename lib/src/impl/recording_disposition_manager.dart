import 'dart:async';
import 'dart:convert';

import '../recording_disposition.dart';
import 'sound_recorder_impl.dart';

/// An internal class which manages the RecordingDisposition stream.
/// Its main job is aggreate events coming up from the plugin
/// into a single stream.
class RecordingDispositionManager {
  final SoundRecorderImpl _recorder;
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
    this.interval = interval;

    _dispositionController ??= StreamController.broadcast();
    _recorder.setSubscriptionDuration(interval);
    _recorder.setDbLevelEnabled(enabled: true);
    _recorder.setDbPeakLevelUpdate(interval);
    return _dispositionController.stream;
  }

  /// Internal classes calls this method to notify a change
  /// in the db level.
  void updateDbPeakDispostion(Map<dynamic, dynamic> call) {
    _lastDispositionDecibels = call['arg'] as double;

    _trySendDisposition();
  }

  /// [timePaused] The raw duration from the android/ios subsystem
  /// ignores pauses so we need to subtract any pause time from the
  /// duratin.
  void updateDurationDisposition(Map call, Duration timePaused) {
    var result = json.decode(call['arg'] as String) as Map<String, dynamic>;

    _lastDispositionDuration = Duration(
            milliseconds:
                double.parse(result['current_position'] as String).toInt()) -
        timePaused;

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
