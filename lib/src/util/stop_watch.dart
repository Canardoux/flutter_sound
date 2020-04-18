import 'dart:core' hide Stopwatch;
import 'dart:core' as core show Stopwatch;

///
/// [StopWatch] is designed to provide profiling information
/// by tracking the time between two lines of code.
///
/// ```dart
/// StopWatch stopWatch = StopWatch("Doing Fetch", showStackTrace = true);
///
/// ... do some fetching
///
/// stopWatch.end(); // logs the time
/// ```
class StopWatch {
  final core.Stopwatch _stopWatch = core.Stopwatch();
  String _description;

  /// create a stop watch to time between two code points.
  StopWatch(this._description) {
    _stopWatch.start();
  }

  /// Return the duration between the ctor and [end] being called.
  Duration get runtime =>
      Duration(milliseconds: _stopWatch.elapsedMilliseconds);

  /// stop the stop watch and print out the duration.
  void end({bool log = true}) {
    _stopWatch.stop();
    _description ??= "";
    if (log) {
      print(
        "Elapsed ${_stopWatch.elapsedMilliseconds} ms for $_description",
      );
    }
  }
}
