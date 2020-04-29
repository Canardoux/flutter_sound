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
import 'dart:core';

import '../util/file_management.dart';

import 'flutter_ffmpeg.dart';

/// Utility class for Flutter Sound.
class FFMpegUtil {
  static FFMpegUtil _self;

  FlutterFFmpeg _flutterFFmpeg;
  FlutterFFmpegConfig _flutterFFmpegConfig;
  FlutterFFprobe _flutterFFprobe;

  /// Factory
  factory FFMpegUtil() {
    _self ??= FFMpegUtil._internal();
    return _self;
  }
  FFMpegUtil._internal();

  /// Check if FFmpeg is linked to flutter_sound.
  /// (flutter_sound_lite is not linked with FFmpeg)
  /// Return `true` if FFmpeg is there
  Future<bool> isFFmpegAvailable() async {
    try {
      if (_flutterFFmpegConfig == null) {
        _flutterFFmpegConfig = FlutterFFmpegConfig();
      }
      var version = await _flutterFFmpegConfig.getFFmpegVersion();
      return (version != null);
    } on Object catch (_) {
      return false;
    }
  }

  /// Executes FFmpeg with [commandArguments] provided.
  Future<int> executeFFmpegWithArguments(List<String> arguments) {
    if (_flutterFFmpeg == null) _flutterFFmpeg = FlutterFFmpeg();
    return _flutterFFmpeg.executeWithArguments(arguments);
  }

  /// Returns return code of last executed command.
  Future<int> getLastFFmpegReturnCode() {
    //if(_flutterFFmpeg == null)
    //_flutterFFmpeg = new FlutterFFmpeg();
    if (_flutterFFmpegConfig == null) {
      _flutterFFmpegConfig = FlutterFFmpegConfig();
    }
    return _flutterFFmpegConfig.getLastReturnCode();
  }

  /// Returns log output of last executed command. Please note
  /// that disabling redirection using
  /// This method does not support executing multiple concurrent
  /// commands. If you execute multiple commands at the same time,
  /// this method will return output from all executions.
  /// [disableRedirection()] method also disables this functionality.
  Future<String> getLastFFmpegCommandOutput() async {
    if (_flutterFFmpegConfig == null) {
      _flutterFFmpegConfig = FlutterFFmpegConfig();
    }
    return _flutterFFmpegConfig.getLastCommandOutput();
  }

  Future<Map<dynamic, dynamic>> _ffMpegGetMediaInformation(String uri) async {
    if (uri == null) return null;
    if (_flutterFFprobe == null) _flutterFFprobe = FlutterFFprobe();
    try {
      return await _flutterFFprobe.getMediaInformation(uri);
    } on Object catch (_) {
      return null;
    }
  }

  /// Determines the duration of the passed uri.
  Future<Duration> duration(String uri) async {
    if (uri == null) return null;

    assert(exists(uri));
    var info = await _ffMpegGetMediaInformation(uri);
    if (info == null) return null;
    var duration = Duration(milliseconds: info['duration'] as int);
    return duration;
  }
}
