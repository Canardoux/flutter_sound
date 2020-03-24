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
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:io' show Platform;
import 'dart:typed_data' show Uint8List;

import 'package:flutter/services.dart';
import 'package:flutter_sound/android_encoder.dart';
import 'package:flutter_sound/ios_quality.dart';
import 'package:flutter_sound/flauto.dart';
import 'package:flutter_sound/flutter_sound_player.dart';
import 'package:flutter_sound/flutter_sound_recorder.dart';
import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

/// This module is deprecated. It is just to keep backward compatibility.
/// New users must muse the classes SoundPlayer and SoundRecorder
enum t_AUDIO_STATE {
  IS_STOPPED,
  IS_PLAYING,
  IS_PAUSED,
  IS_RECORDING,
  IS_RECORDING_PAUSED,
}

/// This class is deprecated. It is just to keep backward compatibility.
/// New users must use the classes SoundPlayer and SoundRecorder
@deprecated
class FlutterSound {
  static const MethodChannel _channel = const MethodChannel('flutter_sound');
  static const MethodChannel _FFmpegChannel = const MethodChannel('flutter_ffmpeg');
  static StreamController<RecordStatus> _recorderController;
  static StreamController<double> _dbPeakController;
  static StreamController<PlayStatus> _playerController;
  static bool isOppOpus = false; // Set by startRecorder when the user wants to record an ogg/opus
  static String savedUri; // Used by startRecorder/stopRecorder to keep the caller wanted uri
  static String tmpUri; // Used by startRecorder/stopRecorder to keep the temporary uri to record CAF

  /// Dispose of underlying stream controllers
  void dispose (){
    _recorderController.close();
    _dbPeakController.close();
    _playerController.close();
  }
	
  /// Value ranges from 0 to 120
  Stream<double> get onRecorderDbPeakChanged => _dbPeakController.stream;
  Stream<RecordStatus> get onRecorderStateChanged => _recorderController.stream;
  Stream<PlayStatus> get onPlayerStateChanged => _playerController.stream;
  @Deprecated('Prefer to use audio_state variable')
  bool get isPlaying => _isPlaying();
  bool get isRecording => _isRecording();
  t_AUDIO_STATE get audioState => _audioState;

  bool _isRecording() => _audioState == t_AUDIO_STATE.IS_RECORDING ;
  t_AUDIO_STATE _audioState = t_AUDIO_STATE.IS_STOPPED;
  bool _isPlaying() => _audioState == t_AUDIO_STATE.IS_PLAYING || _audioState == t_AUDIO_STATE.IS_PAUSED;

  Future<String> defaultPath(t_CODEC codec) async
  {
    Directory tempDir = await getTemporaryDirectory ();
    File fout = File ('${tempDir.path}/${defaultPaths[codec.index]}');
    return fout.path;
  }


  /// Returns true if the flutter_ffmpeg plugin is really plugged
  Future<bool>isFFmpegSupported() async
  {
    try {
      final Map<dynamic, dynamic> vers = await _FFmpegChannel.invokeMethod('getFFmpegVersion');
      final Map<dynamic, dynamic> platform = await _FFmpegChannel.invokeMethod('getPlatform');
      final Map<dynamic, dynamic> packageName = await _FFmpegChannel.invokeMethod('getPackageName');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// We use here our own ffmpeg "execute" procedure instead of the one provided by the flutter_ffmpeg plugin,
  /// so that the developers not interested by ffmpeg can use flutter_plugin without the flutter_ffmpeg plugin
  /// and without any complain from the link-editor.
  ///
  /// Executes FFmpeg with [commandArguments] provided.
  Future<int> executeFFmpegWithArguments(List<String> arguments) async {
    try {
      final Map<dynamic, dynamic> result = await _FFmpegChannel
          .invokeMethod('executeFFmpegWithArguments', {'arguments': arguments});
      return result['rc'];
    } on PlatformException catch (e) {
      print("Plugin error: ${e.message}");
      return -1;
    }
  }



  /// Returns true if the specified encoder is supported by flutter_sound on this platform
  Future<bool> isEncoderSupported(t_CODEC codec) async {
      bool result;
      // For encoding ogg/opus on ios, we need to support two steps :
      // - encode CAF/OPPUS (with native Apple AVFoundation)
      // - remux CAF file format to OPUS file format (with ffmpeg)

      if ( (codec == t_CODEC.CODEC_OPUS) &&  (Platform.isIOS) ){
        if ( ! await isFFmpegSupported() )
          result = false;
        else
          result = await _channel.invokeMethod('isEncoderSupported', <String, dynamic> { 'codec': t_CODEC.CODEC_CAF_OPUS.index } );
      } else
        result = await _channel.invokeMethod('isEncoderSupported', <String, dynamic> { 'codec': codec.index } );
      return result;
  }


  /// Returns true if the specified decoder is supported by flutter_sound on this platform
  Future<bool>  isDecoderSupported(t_CODEC codec) async {
    bool result;
    // For decoding ogg/opus on ios, we need to support two steps :
    // - remux OGG file format to CAF file format (with ffmpeg)
    // - decode CAF/OPPUS (with native Apple AVFoundation)
    if ( (codec == t_CODEC.CODEC_OPUS) &&  (Platform.isIOS) ){
        if ( ! await isFFmpegSupported() )
          result = false;
        else
          result = await _channel.invokeMethod('isDecoderSupported', <String, dynamic> { 'codec': t_CODEC.CODEC_CAF_OPUS.index } );
    } else
        result = await _channel.invokeMethod('isDecoderSupported', <String, dynamic> { 'codec': codec.index } );
    return result;
  }

  Future<String> setSubscriptionDuration(double sec) async {
    String result = await _channel
        .invokeMethod('setSubscriptionDuration', <String, dynamic>{
      'sec': sec,
    });
    return result;
  }

  Future<void> _setRecorderCallback() async {
    if (_recorderController == null) {
      _recorderController = new StreamController.broadcast();
    }
    if (_dbPeakController == null) {
      _dbPeakController = new StreamController.broadcast();
    }

    _channel.setMethodCallHandler((MethodCall call) {
      switch (call.method) {
        case "updateRecorderProgress":
          Map<String, dynamic> result = json.decode(call.arguments);
          if (_recorderController != null)
            _recorderController.add(new RecordStatus.fromJSON(result));
          break;
        case "updateDbPeakProgress":
        if (_dbPeakController!= null)
          _dbPeakController.add(call.arguments);
          break;
        default:
          throw new ArgumentError('Unknown method ${call.method} ');
      }
      return null;
    });
  }

  bool get isPlaying => soundPlayer.isPlaying;

  bool get isRecording => soundRecorder.isRecording;

  bool get isPaused => soundPlayer.isPaused;

  t_AUDIO_STATE get audioState {
    if (soundPlayer.isPlaying) return t_AUDIO_STATE.IS_PLAYING;
    if (soundPlayer.isPaused) return t_AUDIO_STATE.IS_PAUSED;
    if (soundRecorder.isRecording) return t_AUDIO_STATE.IS_RECORDING;
    if (soundRecorder.isPaused) return t_AUDIO_STATE.IS_RECORDING_PAUSED;
    return t_AUDIO_STATE.IS_STOPPED;
  }

  FlutterSound() {
    initializeMediaPlayer();
  }

  void initializeMediaPlayer() async {
    if (soundPlayer == null) soundPlayer = FlutterSoundPlayer();
    if (soundRecorder == null) soundRecorder = FlutterSoundRecorder();
    await soundPlayer.initialize();
    await soundRecorder.initialize();
  }

  /// Resets the media player and cleans up the device resources. This must be
  /// called when the player is no longer needed.
  Future<void> releaseMediaPlayer() async {
    // Stop the player playback before releasing
    await soundPlayer.release();
    soundPlayer = null;
    await soundRecorder.release();
    soundRecorder = null;
  }


  Stream<RecordStatus> get onRecorderStateChanged => soundRecorder.onRecorderStateChanged;

  Stream<double> get onRecorderDbPeakChanged => soundRecorder.onRecorderDbPeakChanged;

  Future<String> setSubscriptionDuration(double sec) => soundPlayer.setSubscriptionDuration(sec);

  Future<String> setDbPeakLevelUpdate(double intervalInSecs) => soundRecorder.setDbPeakLevelUpdate(intervalInSecs);

  Future<String> setDbLevelEnabled(bool enabled) => soundRecorder.setDbLevelEnabled(enabled);

  Future<bool> iosSetCategory(t_IOS_SESSION_CATEGORY category, t_IOS_SESSION_MODE mode, int options) => soundPlayer.iosSetCategory(category, mode, options);

  Future<bool> androidAudioFocusRequest(int focusGain) => soundPlayer.androidAudioFocusRequest(focusGain);

  Future<bool> setActive(bool enabled) => soundPlayer.setActive(enabled);

  Future<String> startRecorder({
    String uri,
    int sampleRate = 16000,
    int numChannels = 1,
    int bitRate = 16000,
    t_CODEC codec = t_CODEC.CODEC_AAC,
    AndroidEncoder androidEncoder = AndroidEncoder.AAC,
    AndroidAudioSource androidAudioSource = AndroidAudioSource.MIC,
    AndroidOutputFormat androidOutputFormat = AndroidOutputFormat.DEFAULT,
    IosQuality iosQuality = IosQuality.LOW,
  }) =>
      soundRecorder.startRecorder(
        uri: uri,
        sampleRate: sampleRate,
        numChannels: numChannels,
        bitRate: bitRate,
        codec: codec,
        androidEncoder: androidEncoder,
        androidAudioSource: androidAudioSource,
        androidOutputFormat: androidOutputFormat,
        iosQuality: iosQuality,
      );

  Future<String> stopRecorder() => soundRecorder.stopRecorder();
  Future<String> pauseRecorder() => soundRecorder.pauseRecorder();
  Future<bool> resumeRecorder() => soundRecorder.resumeRecorder();

  Stream<PlayStatus> get onPlayerStateChanged => soundPlayer.onPlayerStateChanged;

  Future<String> startPlayer(
    String uri, {
    t_CODEC codec,
    whenFinished(),
  }) =>
      soundPlayer.startPlayer(uri, codec: codec, whenFinished: whenFinished);

  Future<String> startPlayerFromBuffer(
    Uint8List dataBuffer, {
    t_CODEC codec,
    whenFinished(),
  }) =>
      soundPlayer.startPlayerFromBuffer(dataBuffer, codec: codec, whenFinished: whenFinished);

  Future<String> stopPlayer() => soundPlayer.stopPlayer();

  Future<String> pausePlayer() => soundPlayer.pausePlayer();

  Future<String> resumePlayer() => soundPlayer.resumePlayer();

  Future<String> seekToPlayer(int milliSecs) => soundPlayer.seekToPlayer(milliSecs);

  Future<String> setVolume(double volume) => soundPlayer.setVolume(volume);

  Future<bool> isEncoderSupported(t_CODEC codec) => soundRecorder.isEncoderSupported(codec);

  Future<bool> isDecoderSupported(t_CODEC codec) => soundPlayer.isDecoderSupported(codec);
}
