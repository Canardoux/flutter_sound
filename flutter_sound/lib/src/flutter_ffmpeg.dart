/*
 * Copyright (c) 2019 Taner Sener
 *
 * This file is part of FlutterFFmpeg.
 *
 * FlutterFFmpeg is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * FlutterFFmpeg is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with FlutterFFmpeg.  If not, see <http://www.gnu.org/licenses/>.
 */

import 'dart:async';

import 'package:flutter/services.dart';

class FlutterFFmpegConfig {
  static const MethodChannel _methodChannel =
      const MethodChannel('flutter_ffmpeg');
  static const EventChannel _eventChannel =
      const EventChannel('flutter_ffmpeg_event');

  Function(int level, String message) logCallback;
  Function(
      int time,
      int size,
      double bitrate,
      double speed,
      int videoFrameNumber,
      double videoQuality,
      double videoFps) statisticsCallback;

  FlutterFFmpegConfig() {
    logCallback = null;
    statisticsCallback = null;

    print("Loading flutter-ffmpeg.");

    _eventChannel.receiveBroadcastStream().listen(_onEvent, onError: _onError);

    enableLogs();
    enableStatistics();
    enableRedirection();

    getPlatform().then((name) => print("Loaded flutter-ffmpeg-$name."));
  }

  void _onEvent(Object event) {
    if (event is Map<dynamic, dynamic>) {
      final Map<String, dynamic> eventMap = event.cast();
      final Map<dynamic, dynamic> logEvent =
          eventMap['FlutterFFmpegLogCallback'];
      final Map<dynamic, dynamic> statisticsEvent =
          eventMap['FlutterFFmpegStatisticsCallback'];

      if (logEvent != null) {
        int level = logEvent['level'];
        String message = logEvent['log'];

        if (this.logCallback == null) {
          if (message.length > 0) {
            // PRINT ALREADY ADDS NEW LINE. SO REMOVE THIS ONE
            if (message.endsWith('\n')) {
              print(message.substring(0, message.length - 1));
            } else {
              print(message);
            }
          }
        } else {
          this.logCallback(level, message);
        }
      }

      if (statisticsEvent != null) {
        if (this.statisticsCallback != null) {
          int time = statisticsEvent['time'];
          int size = statisticsEvent['size'];
          double bitrate = _doublePrecision(statisticsEvent['bitrate'], 2);
          double speed = _doublePrecision(statisticsEvent['speed'], 2);
          int videoFrameNumber = statisticsEvent['videoFrameNumber'];
          double videoQuality =
              _doublePrecision(statisticsEvent['videoQuality'], 2);
          double videoFps = _doublePrecision(statisticsEvent['videoFps'], 2);

          this.statisticsCallback(time, size, bitrate, speed, videoFrameNumber,
              videoQuality, videoFps);
        }
      }
    }
  }

  void _onError(Object error) {
    print('Event error: $error');
  }

  double _doublePrecision(double value, int precision) {
    if (value == null) {
      return 0;
    } else {
      return num.parse(value.toStringAsFixed(precision));
    }
  }

  /// Returns FFmpeg version bundled within the library.
  Future<String> getFFmpegVersion() async {
    try {
      final Map<dynamic, dynamic> result =
          await _methodChannel.invokeMethod('getFFmpegVersion');
      return result['version'];
    } on PlatformException catch (e) {
      print("Plugin error: ${e.message}");
      return null;
    }
  }

  /// Returns platform name where library is loaded.
  Future<String> getPlatform() async {
    try {
      final Map<dynamic, dynamic> result =
          await _methodChannel.invokeMethod('getPlatform');
      return result['platform'];
    } on PlatformException catch (e) {
      print("Plugin error: ${e.message}");
      return null;
    }
  }

  /// Enables redirection
  Future<void> enableRedirection() async {
    try {
      await _methodChannel.invokeMethod('enableRedirection');
    } on PlatformException catch (e) {
      print("Plugin error: ${e.message}");
    }
  }

  /// Disables log and statistics redirection. By default redirection is enabled in constructor.
  /// When redirection is enabled FFmpeg logs are printed to console and can be routed further to a callback function.
  /// By disabling redirection, logs are redirected to stderr.
  /// Statistics redirection behaviour is similar. Statistics are not printed at all if redirection is not enabled.
  /// If it is enabled then it is possible to define a statistics callback function but if you don't, they are not
  /// printed anywhere and only saved as codelastReceivedStatistics data which can be polled with
  /// [getLastReceivedStatistics()].
  Future<void> disableRedirection() async {
    try {
      await _methodChannel.invokeMethod('disableRedirection');
    } on PlatformException catch (e) {
      print("Plugin error: ${e.message}");
    }
  }

  /// Returns log level.
  Future<int> getLogLevel() async {
    try {
      final Map<dynamic, dynamic> result =
          await _methodChannel.invokeMethod('getLogLevel');
      return result['level'];
    } on PlatformException catch (e) {
      print("Plugin error: ${e.message}");
      return -1;
    }
  }

  /// Sets log level.
  Future<void> setLogLevel(int logLevel) async {
    try {
      await _methodChannel.invokeMethod('setLogLevel', {'level': logLevel});
    } on PlatformException catch (e) {
      print("Plugin error: ${e.message}");
    }
  }

  /// Enables log events
  Future<void> enableLogs() async {
    try {
      await _methodChannel.invokeMethod('enableLogs');
    } on PlatformException catch (e) {
      print("Plugin error: ${e.message}");
    }
  }

  /// Disables log functionality of the library. Logs will not be printed to console and log callback will be disabled.
  /// Note that log functionality is enabled by default.
  Future<void> disableLogs() async {
    try {
      await _methodChannel.invokeMethod('disableLogs');
    } on PlatformException catch (e) {
      print("Plugin error: ${e.message}");
    }
  }

  /// Enables statistics events.
  Future<void> enableStatistics() async {
    try {
      await _methodChannel.invokeMethod('enableStatistics');
    } on PlatformException catch (e) {
      print("Plugin error: ${e.message}");
    }
  }

  /// Disables statistics functionality of the library. Statistics callback will be disabled but the last received
  /// statistics data will be still available.
  /// Note that statistics functionality is enabled by default.
  Future<void> disableStatistics() async {
    try {
      await _methodChannel.invokeMethod('disableStatistics');
    } on PlatformException catch (e) {
      print("Plugin error: ${e.message}");
    }
  }

  /// Sets a callback to redirect FFmpeg logs. [newCallback] is a new log callback function, use null to disable a previously defined callback
  void enableLogCallback(Function(int level, String message) newCallback) {
    try {
      this.logCallback = newCallback;
    } on PlatformException catch (e) {
      print("Plugin error: ${e.message}");
    }
  }

  /// Sets a callback to redirect FFmpeg statistics. [newCallback] is a new statistics callback function, use null to disable a previously defined callback
  void enableStatisticsCallback(
      Function(int time, int size, double bitrate, double speed,
              int videoFrameNumber, double videoQuality, double videoFps)
          newCallback) {
    try {
      this.statisticsCallback = newCallback;
    } on PlatformException catch (e) {
      print("Plugin error: ${e.message}");
    }
  }

  /// Returns the last received statistics data stored in bitrate, size, speed, time, videoFps, videoFrameNumber and
  /// videoQuality fields
  Future<Map<dynamic, dynamic>> getLastReceivedStatistics() async {
    try {
      final Map<dynamic, dynamic> result =
          await _methodChannel.invokeMethod('getLastReceivedStatistics');
      return result;
    } on PlatformException catch (e) {
      print("Plugin error: ${e.message}");
      return null;
    }
  }

  /// Resets last received statistics. It is recommended to call it before starting a new execution.
  Future<void> resetStatistics() async {
    try {
      await _methodChannel.invokeMethod('resetStatistics');
    } on PlatformException catch (e) {
      print("Plugin error: ${e.message}");
    }
  }

  /// Sets and overrides fontconfig configuration directory.
  Future<void> setFontconfigConfigurationPath(String path) async {
    try {
      await _methodChannel
          .invokeMethod('setFontconfigConfigurationPath', {'path': path});
    } on PlatformException catch (e) {
      print("Plugin error: ${e.message}");
    }
  }

  /// Registers fonts inside the given [fontDirectory], so they are available to use in FFmpeg filters.
  Future<void> setFontDirectory(
      String fontDirectory, Map<String, String> fontNameMap) async {
    var parameters;
    if (fontNameMap == null) {
      parameters = {'fontDirectory': fontDirectory};
    } else {
      parameters = {'fontDirectory': fontDirectory, 'fontNameMap': fontNameMap};
    }

    try {
      await _methodChannel.invokeMethod('setFontDirectory', parameters);
    } on PlatformException catch (e) {
      print("Plugin error: ${e.message}");
    }
  }

  /// Returns FlutterFFmpeg package name.
  Future<String> getPackageName() async {
    try {
      final Map<dynamic, dynamic> result =
          await _methodChannel.invokeMethod('getPackageName');
      return result['packageName'];
    } on PlatformException catch (e) {
      print("Plugin error: ${e.message}");
      return null;
    }
  }

  /// Returns supported external libraries.
  Future<List<dynamic>> getExternalLibraries() async {
    try {
      final List<dynamic> result =
          await _methodChannel.invokeMethod('getExternalLibraries');
      return result;
    } on PlatformException catch (e) {
      print("Plugin error: ${e.message}");
      return null;
    }
  }

  /// Returns return code of last executed command.
  Future<int> getLastReturnCode() async {
    try {
      final Map<dynamic, dynamic> result =
          await _methodChannel.invokeMethod('getLastReturnCode');
      return result['lastRc'];
    } on PlatformException catch (e) {
      print("Plugin error: ${e.message}");
      return -1;
    }
  }

  /// Returns log output of last executed command. Please note that disabling redirection using
  /// This method does not support executing multiple concurrent commands. If you execute multiple commands at the same time, this method will return output from all executions.
  /// [disableRedirection()] method also disables this functionality.
  Future<String> getLastCommandOutput() async {
    try {
      final Map<dynamic, dynamic> result =
          await _methodChannel.invokeMethod('getLastCommandOutput');
      return result['lastCommandOutput'];
    } on PlatformException catch (e) {
      print("Plugin error: ${e.message}");
      return null;
    }
  }

  /// Creates a new FFmpeg pipe and returns its path.
  Future<String> registerNewFFmpegPipe() async {
    try {
      final Map<dynamic, dynamic> result =
          await _methodChannel.invokeMethod('registerNewFFmpegPipe');
      return result['pipe'];
    } on PlatformException catch (e) {
      print("Plugin error: ${e.message}");
      return null;
    }
  }
}

class FlutterFFmpeg {
  static const MethodChannel _methodChannel =
      const MethodChannel('flutter_ffmpeg');

  /// Executes FFmpeg with [commandArguments] provided.
  Future<int> executeWithArguments(List<String> arguments) async {
    try {
      final Map<dynamic, dynamic> result = await _methodChannel
          .invokeMethod('executeFFmpegWithArguments', {'arguments': arguments});
      return result['rc'];
    } on PlatformException catch (e) {
      print("Plugin error: ${e.message}");
      return -1;
    }
  }

  /// Executes FFmpeg [command] provided.
  Future<int> execute(String command) async {
    try {
      final Map<dynamic, dynamic> result = await _methodChannel.invokeMethod(
          'executeFFmpegWithArguments',
          {'arguments': FlutterFFmpeg.parseArguments(command)});
      return result['rc'];
    } on PlatformException catch (e) {
      print("Plugin error: ${e.message}");
      return -1;
    }
  }

  /// Cancels an ongoing operation.
  Future<void> cancel() async {
    try {
      await _methodChannel.invokeMethod('cancel');
    } on PlatformException catch (e) {
      print("Plugin error: ${e.message}");
    }
  }

  /// Parses the given [command] into arguments.
  static List<String> parseArguments(String command) {
    List<String> argumentList = new List();
    StringBuffer currentArgument = new StringBuffer();

    bool singleQuoteStarted = false;
    bool doubleQuoteStarted = false;

    for (int i = 0; i < command.length; i++) {
      var previousChar;
      if (i > 0) {
        previousChar = command.codeUnitAt(i - 1);
      } else {
        previousChar = null;
      }
      var currentChar = command.codeUnitAt(i);

      if (currentChar == ' '.codeUnitAt(0)) {
        if (singleQuoteStarted || doubleQuoteStarted) {
          currentArgument.write(String.fromCharCode(currentChar));
        } else if (currentArgument.length > 0) {
          argumentList.add(currentArgument.toString());
          currentArgument = new StringBuffer();
        }
      } else if (currentChar == '\''.codeUnitAt(0) &&
          (previousChar == null || previousChar != '\\'.codeUnitAt(0))) {
        if (singleQuoteStarted) {
          singleQuoteStarted = false;
        } else if (doubleQuoteStarted) {
          currentArgument.write(String.fromCharCode(currentChar));
        } else {
          singleQuoteStarted = true;
        }
      } else if (currentChar == '\"'.codeUnitAt(0) &&
          (previousChar == null || previousChar != '\\'.codeUnitAt(0))) {
        if (doubleQuoteStarted) {
          doubleQuoteStarted = false;
        } else if (singleQuoteStarted) {
          currentArgument.write(String.fromCharCode(currentChar));
        } else {
          doubleQuoteStarted = true;
        }
      } else {
        currentArgument.write(String.fromCharCode(currentChar));
      }
    }

    if (currentArgument.length > 0) {
      argumentList.add(currentArgument.toString());
    }

    return argumentList;
  }
}

class FlutterFFprobe {
  static const MethodChannel _methodChannel =
      const MethodChannel('flutter_ffmpeg');

  /// Executes FFprobe with [commandArguments] provided.
  Future<int> executeWithArguments(List<String> arguments) async {
    try {
      final Map<dynamic, dynamic> result = await _methodChannel.invokeMethod(
          'executeFFprobeWithArguments', {'arguments': arguments});
      return result['rc'];
    } on PlatformException catch (e) {
      print("Plugin error: ${e.message}");
      return -1;
    }
  }

  /// Executes FFprobe [command] provided.
  Future<int> execute(String command) async {
    try {
      final Map<dynamic, dynamic> result = await _methodChannel.invokeMethod(
          'executeFFprobeWithArguments',
          {'arguments': FlutterFFmpeg.parseArguments(command)});
      return result['rc'];
    } on PlatformException catch (e) {
      print("Plugin error: ${e.message}");
      return -1;
    }
  }

  /// Returns media information for given [path]
  Future<Map<dynamic, dynamic>> getMediaInformation(String path) async {
    try {
      return await _methodChannel
          .invokeMethod('getMediaInformation', {'path': path});
    } on PlatformException catch (e) {
      print("Plugin error: ${e.message}");
      return null;
    }
  }
}
