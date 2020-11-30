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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';

import '../demo_util/temp_file.dart';
import 'demo_active_codec.dart';
import 'demo_media_path.dart';

/// Tracks the Recoder UI's state.
class UtilRecorder {
  static final UtilRecorder _self = UtilRecorder._internal();

  /// primary recording module
  FlutterSoundRecorder recorderModule;

  /// secondary recording module used to show that two recordings can occur
  /// concurrently.
  FlutterSoundRecorder recorderModule_2; // Used if REENTRANCE_CONCURENCY

  /// Factory ctor
  factory UtilRecorder() {
    return _self;
  }

  UtilRecorder._internal() {
    recorderModule = FlutterSoundRecorder();
  }

  /// [true] if we are currently recording.
  bool get isRecording => recorderModule != null && recorderModule.isRecording;

  /// [true] if we are recording but currently paused.
  bool get isPaused => recorderModule != null && recorderModule.isPaused;

  /// required to initialize the recording subsystem.
  void init() async {
    await recorderModule.openAudioSession(
        focus: AudioFocus.requestFocusAndDuckOthers);
    ActiveCodec().recorderModule = recorderModule;
  }

  /// Call this method if you have changed any of the recording
  /// options.
  /// Stops the recorder and cause the recording UI to refesh and update with
  /// any state changes.
  void reset() async {
    if (UtilRecorder().isRecording) await UtilRecorder().stopRecorder();
  }

  /// Returns a stream of [RecordingDisposition] so you can
  /// display db and duration of the recording as it records.
  /// Use this with a StreamBuilder
  Stream<RecordingDisposition> dispositionStream(
      {Duration interval = const Duration(milliseconds: 10)}) {
    return recorderModule.dispositionStream(/* TODO interval: interval*/);
  }

  /// stops the recorder.
  void stopRecorder() async {
    try {
      await recorderModule.stopRecorder();
    } on Object catch (err) {
      Log.d('stopRecorder error: $err');
      rethrow;
    }
  }

  /// starts the recorder.
  void startRecorder(BuildContext context) async {
    try {
      /// TODO put this back iin
      /// await PlayerState().stopPlayer();

      var track =
          Track(trackPath: await tempFile(), codec: ActiveCodec().codec);
      await recorderModule.startRecorder(toFile: track.trackPath);

      Log.d('startRecorder: $track');

      MediaPath().setCodecPath(ActiveCodec().codec, track.trackPath);
    } on Exception catch (err) {
      Log.d('startRecorder error: $err');

      var error = SnackBar(
          backgroundColor: Colors.red,
          content: Text('Failed to start recording: $err'));
      ScaffoldMessenger.of(context).showSnackBar(error);

      stopRecorder();
    }
  }

  /// toggles the pause/resume start of the recorder
  void pauseResumeRecorder() {
    assert(recorderModule.isRecording || recorderModule.isPaused);
    if (recorderModule.isPaused) {
      {
        recorderModule.resumeRecorder();
      }
    } else {
      recorderModule.pauseRecorder();
    }
  }
}
