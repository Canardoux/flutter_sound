import 'dart:async';
import 'dart:convert';

import 'flutter_sound_recorder.dart';
import 'recording_disposition.dart';

/// An internal class which manages the RecordingDisposition stream.
class RecordingDispositionManager {
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

  final FlutterSoundRecorder _recorder;

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
    _recorder.initialize().then<void>((_) {
      _setSubscriptionDuration(interval);
      _setDbLevelEnabled(true);
      _setDbPeakLevelUpdate(interval);
    });
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

  /// Sets the frequency at which duration updates are sent to
  /// duration listeners.
  /// The default is every 10 milliseconds.
  Future<String> _setSubscriptionDuration(Duration interval) async {
    await _recorder.initialize();
    var r = await _recorder
        .invokeMethod('setSubscriptionDuration', <String, dynamic>{
      'sec': interval.inSeconds.toDouble(),
    }) as String;
    return r;
  }

  /// Defines the interval at which the peak level should be updated.
  /// Default is 0.8 seconds
  Future<String> _setDbPeakLevelUpdate(Duration interval) async {
    await _recorder.initialize();
    var r =
        await _recorder.invokeMethod('setDbPeakLevelUpdate', <String, dynamic>{
      'intervalInSecs': interval.inSeconds.toDouble(),
    }) as String;
    return r;
  }

  /// Enables or disables processing the Peak level in db's. Default is disabled
  Future<String> _setDbLevelEnabled(bool enabled) async {
    await _recorder.initialize();
    var r = await _recorder.invokeMethod('setDbLevelEnabled', <String, dynamic>{
      'enabled': enabled,
    }) as String;
    return r;
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
