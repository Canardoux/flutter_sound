/*
 * Copyright 2018, 2019, 2020 Dooboolab.
 *
 * This file is part of Flutter-Sound.
 *
 * Flutter-Sound is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License version 3 (LGPL-V3), as published by
 * the Free Software Foundation.
 *
 * Flutter-Sound is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with Flutter-Sound.  If not, see <https://www.gnu.org/licenses/>.
 */

/// ---------
///
/// A module to print traces for info or debugging purpose
///
/// --------------
///
/// {@category Utilities}
library log;

//import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

import 'enum_helper.dart';
import 'stack_trace_impl.dart';

/// Logging class
class Log extends Logger {
  static Log _self;
  static String _localPath;

  /// The default log level.
  static Level loggingLevel = Level.debug;

  Log._internal(String currentWorkingDirectory)
      : super(printer: MyLogPrinter(currentWorkingDirectory));

  ///
  void debug(String message, {dynamic error, StackTrace stackTrace}) {
    autoInit();
    Log.d(message, error: error, stackTrace: stackTrace);
  }

  ///
  void info(String message, {dynamic error, StackTrace stackTrace}) {
    autoInit();
    Log.i(message, error: error, stackTrace: stackTrace);
  }

  ///
  void warn(String message, {dynamic error, StackTrace stackTrace}) {
    autoInit();
    Log.w(message, error: error, stackTrace: stackTrace);
  }

  ///
  void error(String message, {dynamic error, StackTrace stackTrace}) {
    autoInit();
    Log.e(message, error: error, stackTrace: stackTrace);
  }

  ///
  void color(String message, AnsiColor color,
      {dynamic error, StackTrace stackTrace}) {
    autoInit();
    Log.i(color.apply(message), error: error, stackTrace: stackTrace);
  }

  ///
  factory Log.color(String message, AnsiColor color,
      {dynamic error, StackTrace stackTrace}) {
    autoInit();
    _self.d(color.apply(message), error, stackTrace);
    return _self;
  }

  static final _recentLogs = <String, DateTime>{};

  ///
  factory Log.d(String message,
      {dynamic error, StackTrace stackTrace, bool supressDuplicates = false}) {
    autoInit();
    var suppress = false;

    if (supressDuplicates) {
      var lastLogged = _recentLogs[message];
      if (lastLogged != null &&
          lastLogged.add(Duration(milliseconds: 100)).isAfter(DateTime.now())) {
        suppress = true;
      }
      _recentLogs[message] = DateTime.now();
    }
    if (suppress) _self.d(message, error, stackTrace);
    return _self;
  }

  ///
  factory Log.i(String message, {dynamic error, StackTrace stackTrace}) {
    autoInit();
    _self.i(message, error, stackTrace);
    return _self;
  }

  ///
  factory Log.w(String message, {dynamic error, StackTrace stackTrace}) {
    autoInit();
    _self.w(message, error, stackTrace);
    return _self;
  }

  ///
  factory Log.e(String message, {dynamic error, StackTrace stackTrace}) {
    autoInit();
    _self.e(message, error, stackTrace);
    return _self;
  }

  ///
  static void autoInit() {
    if (_self == null) {
      init('.');
    }
  }

  ///
  static void init(String currentWorkingDirectory) {
    _self = Log._internal(currentWorkingDirectory);

    var frames = StackTraceImpl();

    for (var frame in frames.frames) {
      _localPath = frame.sourceFile.path
          .substring(frame.sourceFile.path.lastIndexOf('/'));
      break;
    }
  }
}

///
class MyLogPrinter extends LogPrinter {
  ///
  bool colors = true;

  ///
  String currentWorkingDirectory;

  ///
  MyLogPrinter(this.currentWorkingDirectory);

  @override
  List<String> log(LogEvent event) {
    if (EnumHelper.getIndexOf(Level.values, Log.loggingLevel) >
        EnumHelper.getIndexOf(Level.values, event.level)) {
      // don't log events where the log level is set higher
      return [];
    }
    //var formatter = DateFormat('dd HH:mm:ss.');
    //var now = DateTime.now();
    //var formattedDate = formatter.format(now) + now.millisecond.toString();

    var frames = StackTraceImpl();
    var i = 0;
    var depth = 0;
    for (var frame in frames.frames) {
      i++;
      var path2 = frame.sourceFile.path;
      if (!path2.contains(Log._localPath) && !path2.contains('logger.dart')) {
        depth = i - 1;
        break;
      }
    }

    print(color(
        event.level,
        '${EnumHelper.getName(event.level)} '
        '${StackTraceImpl(skipFrames: depth).formatStackTrace(methodCount: 1)} '
        '::: ${event.message}'));

    if (event.error != null) {
      print(color(event.level, '${event.error}'));
    }

    if (event.stackTrace != null) {
      if (event.stackTrace.runtimeType == StackTraceImpl) {
        var st = event.stackTrace as StackTraceImpl;
        print(color(event.level, '$st'));
      } else {
        print(color(event.level, '${event.stackTrace}'));
      }
    }
    return []; // TODO
  }

  ///
  String color(Level level, String line) {
    var result = '';

    switch (level) {
      case Level.debug:
        result += grey(line, level: 0.75);
        break;
      case Level.verbose:
        result += grey(line, level: 0.50);
        break;
      case Level.info:
        result += line;
        break;
      case Level.warning:
        result += orange(line);
        break;
      case Level.error:
        result += red(line);
        break;
      case Level.wtf:
        result += red(line, bgcolor: AnsiColor.yellow);
        break;
      case Level.nothing:
        result += line;
        break;
    }
    return result;
  }
}

///
class LogLevel {
  ///
  /// This log level is used to specify logs printed to stderr by ffmpeg.
  /// Logs that has this level are not filtered and always redirected.
  static const int avLogStderr = -16;

  /// Print no output.
  static const int avLogQuiet = -8;

  /// Something went really wrong and we will crash now.
  static const int avLogPanic = 0;

  /// Something went wrong and recovery is not possible.
  /// For example, no header was found for a format which depends
  /// on headers or an illegal combination of parameters is used.
  static const int avLogFatal = 8;

  /// Something went wrong and cannot losslessly be recovered.
  /// However, not all future data is affected.
  static const int avLogError = 16;

  /// Something somehow does not look correct. This may or may not
  /// lead to problems. An example would be the use of '-vstrict -2'.
  static const int avLogWarning = 24;

  /// int Standard information.
  static const int avLogInfo = 32;

  /// Detailed information.
  static const int avLogVerbose = 40;

  /// Stuff which is only useful for libav* developers.
  static const int avLogDebug = 48;

  /// Extremely verbose debugging, useful for libav* development.
  static const int avLogTrace = 56;

  /// Returns log level string from int
  static String levelToString(int level) {
    switch (level) {
      case LogLevel.avLogTrace:
        return 'TRACE';
      case LogLevel.avLogDebug:
        return 'DEBUG';
      case LogLevel.avLogVerbose:
        return 'VERBOSE';
      case LogLevel.avLogInfo:
        return 'INFO';
      case LogLevel.avLogWarning:
        return 'WARNING';
      case LogLevel.avLogError:
        return 'ERROR';
      case LogLevel.avLogFatal:
        return 'FATAL';
      case LogLevel.avLogPanic:
        return 'PANIC';
      case LogLevel.avLogStderr:
        return 'STDERR';
      case LogLevel.avLogQuiet:
      default:
        return '';
    }
  }
}

/// Returns a string wrapped with the selected ansi
/// fg color codes.
String red(String text, {AnsiColor bgcolor = AnsiColor.none}) =>
    AnsiColor._apply(AnsiColor.red, text, bgcolor: bgcolor);

///
String black(String text, {AnsiColor bgcolor = AnsiColor.white}) =>
    AnsiColor._apply(AnsiColor.black, text, bgcolor: bgcolor);

///
String green(String text, {AnsiColor bgcolor = AnsiColor.none}) =>
    AnsiColor._apply(AnsiColor.green, text, bgcolor: bgcolor);

///
String blue(String text, {AnsiColor bgcolor = AnsiColor.none}) =>
    AnsiColor._apply(AnsiColor.blue, text, bgcolor: bgcolor);

///
String yellow(String text, {AnsiColor bgcolor = AnsiColor.none}) =>
    AnsiColor._apply(AnsiColor.yellow, text, bgcolor: bgcolor);

///
String magenta(String text, {AnsiColor bgcolor = AnsiColor.none}) =>
    AnsiColor._apply(AnsiColor.magenta, text, bgcolor: bgcolor);

///
String cyan(String text, {AnsiColor bgcolor = AnsiColor.none}) =>
    AnsiColor._apply(AnsiColor.cyan, text, bgcolor: bgcolor);

///
String white(String text, {AnsiColor bgcolor = AnsiColor.none}) =>
    AnsiColor._apply(AnsiColor.white, text, bgcolor: bgcolor);

///
String orange(String text, {AnsiColor bgcolor = AnsiColor.none}) =>
    AnsiColor._apply(AnsiColor.orange, text, bgcolor: bgcolor);

///
String grey(String text,
        {double level = 0.5, AnsiColor bgcolor = AnsiColor.none}) =>
    AnsiColor._apply(AnsiColor.grey(level: level), text, bgcolor: bgcolor);

///
class AnsiColor {
  ///
  static String reset() => _emmit(resetCode);

  ///
  static String fgReset() => _emmit(fgResetCode);

  ///
  static String bgReset() => _emmit(bgResetCode);

  final int _code;

  ///
  const AnsiColor(int code) : _code = code;

  ///
  int get code => _code;

  ///
  String apply(String text, {AnsiColor bgcolor = none}) =>
      _apply(this, text, bgcolor: bgcolor);

  static String _apply(AnsiColor color, String text,
      {AnsiColor bgcolor = none}) {
    String output;

    output = '${_fg(color.code)}${_bg(bgcolor?.code)}$text$_reset';
    return output;
  }

  static String get _reset {
    return '$esc${resetCode}m';
  }

  static String _fg(int code) {
    String output;

    if (code == none.code) {
      output = '';
    } else if (code > 39) {
      output = '$esc$fgColor${code}m';
    } else {
      output = '$esc${code}m';
    }
    return output;
  }

  // background colors are fg color + 10
  static String _bg(int code) {
    String output;

    if (code == none.code) {
      output = '';
    } else if (code > 49) {
      output = '$esc$bgColor${code + 10}m';
    } else {
      output = '$esc${code + 10}m';
    }
    return output;
  }

  static String _emmit(String ansicode) {
    return '$esc${ansicode}m';
  }

  /// ANSI Control Sequence Introducer, signals the terminal for new settings.
  static const esc = '\x1B[';

  /// Resets

  /// Reset fg and bg colors
  static const String resetCode = '0';

  /// Defaults the terminal's fg color without altering the bg.
  static const String fgResetCode = '39';

  /// Defaults the terminal's bg color without altering the fg.
  static const String bgResetCode = '49';

  /// emmit this code followed by a color code to set the fg color
  static const String fgColor = '38;5;';

  /// emmit this code followed by a color code to set the fg color
  static const String bgColor = '48;5;';

  /// Colors
  static const AnsiColor black = AnsiColor(30);

  ///
  static const AnsiColor red = AnsiColor(31);

  ///
  static const AnsiColor green = AnsiColor(32);

  ///
  static const AnsiColor yellow = AnsiColor(33);

  ///
  static const AnsiColor blue = AnsiColor(34);

  ///
  static const AnsiColor magenta = AnsiColor(35);

  ///
  static const AnsiColor cyan = AnsiColor(36);

  ///
  static const AnsiColor white = AnsiColor(37);

  ///
  static const AnsiColor orange = AnsiColor(208);

  ///
  static AnsiColor grey({double level = 0.5}) =>
      AnsiColor(232 + (level.clamp(0.0, 1.0) * 23).round());

  /// passing this as the background color will cause
  /// the background code to be suppressed resulting
  /// in the default background color.
  static const AnsiColor none = AnsiColor(-1);
}
