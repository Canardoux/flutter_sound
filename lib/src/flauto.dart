/*
 * This file is part of Flutter-Sound (Flauto).
 *
 *   Flutter-Sound (Flauto) is free software: you can redistribute it and/or modify
 *   it under the terms of the Lesser GNU General Public License
 *   version 3 (LGPL3) as published by the Free Software Foundation.
 *
 *   Flutter-Sound (Flauto) is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the Lesser GNU General Public License
 *   along with Flutter-Sound (Flauto).  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:async';
import 'dart:core';

import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound/track_player.dart';
import 'package:flutter_sound/flutter_sound_recorder.dart';
import 'package:flutter_sound/flutter_sound_player.dart';

import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';

// this enum MUST be synchronized with fluttersound/AudioInterface.java  and ios/Classes/FlutterSoundPlugin.h
enum Codec {
  DEFAULT,
  CODEC_AAC,
  CODEC_OPUS,
  CODEC_CAF_OPUS, // Apple encapsulates its bits in its own special envelope : .caf instead of a regular ogg/opus (.opus). This is completely stupid, this is Apple.
  CODEC_MP3,
  CODEC_VORBIS,
  CODEC_PCM,
}

FlutterSoundHelper flutterSoundHelper = FlutterSoundHelper(); // Singleton

class FlutterSoundHelper {
  FlutterFFmpeg flutterFFmpeg;
  FlutterFFmpegConfig _flutterFFmpegConfig;
  FlutterFFprobe _flutterFFprobe;

  /// We use here our own ffmpeg "execute" procedure instead of the one provided by the flutter_ffmpeg plugin,
  /// so that the developers not interested by ffmpeg can use flutter_plugin without the flutter_ffmpeg plugin
  /// and without any complain from the link-editor.
  ///
  /// Executes FFmpeg with [commandArguments] provided.
  Future<int> executeFFmpegWithArguments(List<String> arguments) {
    if (flutterFFmpeg == null) flutterFFmpeg = FlutterFFmpeg();
    return flutterFFmpeg.executeWithArguments(arguments);
  }

  /// We use here our own ffmpeg "getLastReturnCode" procedure instead of the one provided by the flutter_ffmpeg plugin,
  /// so that the developers not interested by ffmpeg can use flutter_plugin without the flutter_ffmpeg plugin
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

  /// We use here our own ffmpeg "getLastCommandOutput" procedure instead of the one provided by the flutter_ffmpeg plugin,
  /// so that the developers not interested by ffmpeg can use flutter_plugin without the flutter_ffmpeg plugin
  /// and without any complain from the link-editor.
  ///
  /// Returns log output of last executed command. Please note that disabling redirection using
  /// This method does not support executing multiple concurrent commands. If you execute multiple commands at the same time, this method will return output from all executions.
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

  Future<Map<dynamic, dynamic>> FFmpegGetMediaInformation(String uri) async {
    if (uri == null) return null;
    if (_flutterFFprobe == null) _flutterFFprobe = FlutterFFprobe();
    try {
      return await _flutterFFprobe.getMediaInformation(uri);
    } catch (e) {
      return null;
    }
  }

  Future<int> duration(String uri) async {
    if (uri == null) return null;
    Map<dynamic, dynamic> info = await FFmpegGetMediaInformation(uri);
    if (info == null) return null;
    int duration = info['duration'] as int;
    return duration;
  }
}

/// This class is deprecated. It is just to keep backward compatibility.
/// New users must use the class TrackPlayer
@deprecated
class Flauto extends FlutterSound {
  Flauto() {
    initializeMediaPlayer();
  }

  void initializeMediaPlayer() async {
    if (soundPlayer == null) soundPlayer = TrackPlayer();
    if (soundRecorder == null) soundRecorder = FlutterSoundRecorder();
    await soundPlayer.initialize();
    await soundRecorder.initialize();
  }

  Future<String> startPlayerFromTrack(
    Track track, {
    Codec codec,
    TWhenFinished whenFinished,
    TwhenPaused whenPaused,
    TonSkip onSkipForward,
    TonSkip onSkipBackward,
  }) async {
    /// The soundPlayer is always a TrackPlayer.
    TrackPlayer trackPlayer = soundPlayer as TrackPlayer;
    return trackPlayer.startPlayerFromTrack(
      track,
      whenFinished: whenFinished,
      onSkipBackward: onSkipBackward,
      onSkipForward: onSkipForward,
    );
  }
}
