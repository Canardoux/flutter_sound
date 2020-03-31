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
  FlutterSoundPlayer soundPlayer;
  FlutterSoundRecorder soundRecorder;

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
