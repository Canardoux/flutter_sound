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

import '../flutter_ffmpeg.dart';

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

  /// We use here our own ffmpeg "execute" procedure instead
  /// of the one provided by the flutter_ffmpeg plugin,
  /// so that the developers not interested by ffmpeg can use
  /// flutter_plugin without the flutter_ffmpeg plugin
  /// and without any complain from the link-editor.
  ///
  /// Executes FFmpeg with [commandArguments] provided.
  Future<int> executeFFmpegWithArguments(List<String> arguments) {
    if (_flutterFFmpeg == null) _flutterFFmpeg = FlutterFFmpeg();
    return _flutterFFmpeg.executeWithArguments(arguments);
  }

  /// We use here our own ffmpeg "getLastReturnCode" procedure
  ///  instead of the one provided by the flutter_ffmpeg plugin,
  /// so that the developers not interested by ffmpeg can use
  /// flutter_plugin without the flutter_ffmpeg plugin
  /// and without any complain from the link-editor.
  ///
  /// Returns return code of last executed command.
  Future<int> getLastFFmpegReturnCode() {
    //if(_flutterFFmpeg == null)
    //_flutterFFmpeg = new FlutterFFmpeg();
    if (_flutterFFmpegConfig == null) {
      _flutterFFmpegConfig = FlutterFFmpegConfig();
    }
    return _flutterFFmpegConfig.getLastReturnCode();
    /*
        try
        {
                final Map<dynamic, dynamic> result =
                await _FFmpegChannel.invokeMethod( 'getLastReturnCode' );
                return result['lastRc'];
        }
        on PlatformException catch (e)
        {
                print( "Plugin error: ${e.message}" );
                return -1;
        }
         */
  }

  /// We use here our own ffmpeg "getLastCommandOutput" procedure
  ///  instead of the one provided by the flutter_ffmpeg plugin,
  /// so that the developers not interested by ffmpeg can use
  /// flutter_plugin without the flutter_ffmpeg plugin
  /// and without any complain from the link-editor.
  ///
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
    /*
        try
        {
                final Map<dynamic, dynamic> result =
                await _FFmpegChannel.invokeMethod( 'getLastCommandOutput' );
                return result['lastCommandOutput'];
        }
        on PlatformException catch (e)
        {
                print( "Plugin error: ${e.message}" );
                return null;
        }

         */
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
  Future<int> duration(String uri) async {
    if (uri == null) return null;
    var info = await _ffMpegGetMediaInformation(uri);
    if (info == null) return null;
    var duration = info['duration'] as int;
    return duration;
  }
}
