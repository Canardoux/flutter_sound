import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';

import '../util/log.dart';
import '../util/temp_file.dart';
import 'demo_active_codec.dart';
import 'demo_media_path.dart';

/// Tracks the Recoder UI's state.
class RecorderState {
  static final RecorderState _self = RecorderState._internal();

  /// primary recording moduel
  SoundRecorder recorderModule;

  /// secondary recording modue used to show that two recordings can occur
  /// concurrently.
  SoundRecorder recorderModule_2; // Used if REENTRANCE_CONCURENCY

  /// Factory ctor
  factory RecorderState() {
    return _self;
  }

  RecorderState._internal() {
    recorderModule = SoundRecorder();
  }

  /// [true] if we are currently recording.
  bool get isRecording => recorderModule != null && recorderModule.isRecording;

  /// [true] if we are recording but currently paused.
  bool get isPaused => recorderModule != null && recorderModule.isPaused;

  /// required to initialize the recording subsystem.
  void init() async {
    ActiveCodec().recorderModule = recorderModule;
  }

  /// Call this method if you have changed any of the recording
  /// options.
  /// Stops the recorder and cause the recording UI to refesh and update with
  /// any state changes.
  void reset() async {
    if (RecorderState().isRecording) await RecorderState().stopRecorder();
  }

  /// Returns a stream of [RecordingDisposition] so you can
  /// display db and duration of the recording as it records.
  /// Use this with a StreamBuilder
  Stream<RecordingDisposition> dispositionStream(
      {Duration interval = const Duration(milliseconds: 10)}) {
    return recorderModule.dispositionStream(interval: interval);
  }

  /// stops the recorder.
  void stopRecorder() async {
    try {
      await recorderModule.stop();
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

      var track = Track.fromFile(await tempFile(), codec: ActiveCodec().codec);
      await recorderModule.record(track);

      Log.d('startRecorder: $track');

      MediaPath().setCodecPath(ActiveCodec().codec, track.url);
    } on RecorderException catch (err) {
      Log.d('startRecorder error: $err');

      var error = SnackBar(
          backgroundColor: Colors.red,
          content: Text('Failed to start recording: $err'));
      Scaffold.of(context).showSnackBar(error);

      stopRecorder();
    }
  }

  /// toggles the pause/resume start of the recorder
  void pauseResumeRecorder() {
    assert(recorderModule.isRecording || recorderModule.isPaused);
    if (recorderModule.isPaused) {
      {
        recorderModule.resume();
      }
    } else {
      recorderModule.pause();
    }
  }
}
