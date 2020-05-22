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


import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';

import '../util/grayed_out.dart';
import 'demo_audio_state.dart';
import 'demo_common.dart';

import 'demo_media_path.dart';
import 'recorder_state.dart';

/// UI for the Recorder example controls
class RecorderControls extends StatefulWidget {
  /// ctor
  const RecorderControls({
    Key key,
  }) : super(key: key);

  @override
  _RecorderControlsState createState() => _RecorderControlsState();
}

class _RecorderControlsState extends State<RecorderControls> {
  bool paused = false;

  /// detect hot reloads and stop the recorder
  void reassemble() {
    super.reassemble();
    RecorderState().stopRecorder();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          buildDurationText(),
          buildDBIndicator(),
          Row(
            children: <Widget>[
              buildStartStopButton(),
              buildRecorderPauseButton(),
            ],
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
          ),
        ]);
  }

  Widget buildDBIndicator() {
    return RecorderState().isRecording
        ? StreamBuilder<RecordingDisposition>(
            stream: RecorderState()
                .dispositionStream(interval: Duration(milliseconds: 50)),
            initialData: RecordingDisposition.zero(),
            builder: (context, snapshot) {
              var recordingDisposition = snapshot.data;
              var dbLevel = recordingDisposition.decibels;
              return LinearProgressIndicator(
                  value: 100.0 / 160.0 * (dbLevel ?? 1) / 100,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  backgroundColor: Colors.red);
            })
        : Container();
  }

  Widget buildDurationText() {
    return StreamBuilder<RecordingDisposition>(
        stream: RecorderState()
            .dispositionStream(interval: Duration(milliseconds: 50)),
        initialData: RecordingDisposition.zero(),
        builder: (context, snapshot) {
          var disposition = snapshot.data;
          var txt = formatDuration(disposition.duration);

          return Container(
            margin: EdgeInsets.only(top: 12.0, bottom: 16.0),
            child: Text(
              txt,
              style: TextStyle(
                fontSize: 35.0,
                color: Colors.black,
              ),
            ),
          );
        });
  }

  Container buildStartStopButton() {
    return Container(
      width: 56.0,
      height: 50.0,
      child: ClipOval(
          child: GrayedOut(
        grayedOut: !canRecord(),
        child: FlatButton(
          onPressed: () => startStopRecorder(context),
          padding: EdgeInsets.all(8.0),
          child: Image(
            image: recorderAssetImage(),
          ),
        ),
      )),
    );
  }

  Container buildRecorderPauseButton() {
    return Container(
      width: 56.0,
      height: 50.0,
      child: ClipOval(
        child: GrayedOut(
            grayedOut: !isRecording(),
            child: FlatButton(
              onPressed: pauseResumeRecorder,
              disabledColor: Colors.white,
              padding: EdgeInsets.all(8.0),
              child: Image(
                width: 36.0,
                height: 36.0,
                image: AssetImage(paused
                    ? 'res/icons/ic_play.png'
                    : 'res/icons/ic_pause.png'),
              ),
            )),
      ),
    );
  }

  bool isRecording() {
    return audioState == AudioState.isRecording || isPaused();
  }

  bool isPaused() {
    return audioState == AudioState.isRecordingPaused;
  }

  bool canRecord() {
    if (audioState != AudioState.isRecording &&
        audioState != AudioState.isRecordingPaused &&
        audioState != AudioState.isStopped) {
      return false;
    }
    return true;
  }

  bool checkPreconditions() {
    var passed = true;
    if (MediaPath().isAsset ||
        // MediaPath().isBuffer ||
        MediaPath().isExampleFile) {
      var error = SnackBar(
          backgroundColor: Colors.red,
          content:
              Text('You must select a Media type of File or Buffer to record'));
      Scaffold.of(context).showSnackBar(error);
      passed = false;
    }
    // Disable the button if the selected codec is not supported
    // Removed this test as felt it was better to display an error
    // when the user attempts to record so they know why they can't record.
    // if (!ActiveCodec().encoderSupported) return false;

    return passed;
  }

  void startStopRecorder(BuildContext context) async {
    paused = false;
    try {
      if (RecorderState().isRecording || RecorderState().isPaused) {
        await RecorderState().stopRecorder();
      } else {
        if (checkPreconditions()) {
          await RecorderState().startRecorder(context);
        }
      }
    } finally {
      setState(() {});
    }
  }

  AssetImage recorderAssetImage() {
    if (!canRecord()) return AssetImage('res/icons/ic_mic_disabled.png');
    return (RecorderState().isRecording || RecorderState().isPaused)
        ? AssetImage('res/icons/ic_stop.png')
        : AssetImage('res/icons/ic_mic.png');
  }

  AudioState get audioState {
    if (RecorderState().isPaused) {
      return AudioState.isRecordingPaused;
    }
    if (RecorderState().isRecording) return AudioState.isRecording;

    return AudioState.isStopped;
  }

  void pauseResumeRecorder() async {
    paused = !paused;
    await RecorderState().pauseResumeRecorder();

    setState(() {});
  }
}
