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

class LogLevel {
  ///
  /// This log level is used to specify logs printed to stderr by ffmpeg.
  /// Logs that has this level are not filtered and always redirected.
  static const int AV_LOG_STDERR = -16;

  /// Print no output.
  static const int AV_LOG_QUIET = -8;

  /// Something went really wrong and we will crash now.
  static const int AV_LOG_PANIC = 0;

  /// Something went wrong and recovery is not possible.
  /// For example, no header was found for a format which depends
  /// on headers or an illegal combination of parameters is used.
  static const int AV_LOG_FATAL = 8;

  /// Something went wrong and cannot losslessly be recovered.
  /// However, not all future data is affected.
  static const int AV_LOG_ERROR = 16;

  /// Something somehow does not look correct. This may or may not
  /// lead to problems. An example would be the use of '-vstrict -2'.
  static const int AV_LOG_WARNING = 24;

  /// int Standard information.
  static const int AV_LOG_INFO = 32;

  /// Detailed information.
  static const int AV_LOG_VERBOSE = 40;

  /// Stuff which is only useful for libav* developers.
  static const int AV_LOG_DEBUG = 48;

  /// Extremely verbose debugging, useful for libav* development.
  static const int AV_LOG_TRACE = 56;

  /// Returns log level string from int
  static String levelToString(int level) {
    switch (level) {
      case LogLevel.AV_LOG_TRACE:
        return "TRACE";
      case LogLevel.AV_LOG_DEBUG:
        return "DEBUG";
      case LogLevel.AV_LOG_VERBOSE:
        return "VERBOSE";
      case LogLevel.AV_LOG_INFO:
        return "INFO";
      case LogLevel.AV_LOG_WARNING:
        return "WARNING";
      case LogLevel.AV_LOG_ERROR:
        return "ERROR";
      case LogLevel.AV_LOG_FATAL:
        return "FATAL";
      case LogLevel.AV_LOG_PANIC:
        return "PANIC";
      case LogLevel.AV_LOG_STDERR:
        return "STDERR";
      case LogLevel.AV_LOG_QUIET:
      default:
        return "";
    }
  }
}
