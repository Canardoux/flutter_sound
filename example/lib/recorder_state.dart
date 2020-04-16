import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'active_codec.dart';
import 'common.dart';
import 'main.dart';
import 'media_path.dart';
import 'player_state.dart';

/// Tracks the Recoder UI's state.
class RecorderState {
  static final RecorderState _self = RecorderState._internal();

  /// primary recording moduel
  FlutterSoundRecorder recorderModule;

  /// secondary recording modue used to show that two recordings can occur
  /// concurrently.
  FlutterSoundRecorder recorderModule_2; // Used if REENTRANCE_CONCURENCY

  /// Factory ctor
  factory RecorderState() {
    return _self;
  }

  RecorderState._internal();

  /// [true] if we are currently recording.
  bool get isRecording => recorderModule != null && recorderModule.isRecording;

  /// [true] if we are recording but currently paused.
  bool get isPaused => recorderModule != null && recorderModule.isPaused;

  /// required to initialise the recording subsystem.
  void init() async {
    ActiveCodec().recorderModule = recorderModule;
  }

  /// Call this method if you have changed any of the recording
  /// options.
  /// Stops the recorder and cause the recording UI to refesh and update with
  /// any state changes.
  void reset() async {
    await RecorderState().stopRecorder();
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
      await recorderModule.stopRecorder();
      if (renetranceConcurrency) {
        await recorderModule_2.stopRecorder();
        await PlayerState().stopPlayer();
      }
    } on Object catch (err) {
      print('stopRecorder error: $err');
      rethrow;
    }
  }

  /// starts the recorder.
  void startRecorder(BuildContext context) async {
    try {
      await PlayerState().stopPlayer();
      var path = FlutterSoundRecorder.tempFile();
      await recorderModule.startRecorder(
        path: path,
        codec: ActiveCodec().codec,
      );

      print('startRecorder: $path');

      if (renetranceConcurrency) {
        try {
          var dataBuffer =
              (await rootBundle.load(assetSample[ActiveCodec().codec.index]))
                  .buffer
                  .asUint8List();
          await PlayerState().playerModule_2.startPlayerFromBuffer(dataBuffer,
              codec: ActiveCodec().codec, whenFinished: () {
            print('Secondary Play finished');
          });
        } on Object catch (e) {
          print('startRecorder error: $e');
          rethrow;
        }
        var secondaryPath = FlutterSoundRecorder.tempFile();
        await recorderModule_2.startRecorder(
          path: secondaryPath,
          codec: Codec.codecAac,
        );
        print("Secondary record is '$secondaryPath'");
      }

      MediaPath().setCodecPath(ActiveCodec().codec, path);
    } on RecorderException catch (err) {
      print('startRecorder error: $err');

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
        recorderModule.resumeRecorder();
        if (renetranceConcurrency) {
          recorderModule_2.resumeRecorder();
        }
      }
    } else {
      recorderModule.pauseRecorder();
      if (renetranceConcurrency) {
        recorderModule_2.pauseRecorder();
      }
    }
  }
}
