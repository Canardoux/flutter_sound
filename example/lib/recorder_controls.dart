import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';

import 'common.dart';
import 'grayed_out.dart';
import 'media_path.dart';
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
            stream:
                RecorderState().dispositionStream(Duration(milliseconds: 50)),
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
        stream: RecorderState().dispositionStream(Duration(milliseconds: 50)),
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
    return audioState == t_AUDIO_STATE.IS_RECORDING || isPaused();
  }

  bool isPaused() {
    return audioState == t_AUDIO_STATE.IS_RECORDING_PAUSED;
  }

  bool canRecord() {
    if (MediaPath().isAsset ||
        // MediaPath().isBuffer ||
        MediaPath().isExampleFile) return false;
    // Disable the button if the selected codec is not supported
    // Removed this test as felt it was better to display an error
    // when the user attempts to record so they know why they can't record.
    // if (!ActiveCodec().encoderSupported) return false;

    if (audioState != t_AUDIO_STATE.IS_RECORDING &&
        audioState != t_AUDIO_STATE.IS_RECORDING_PAUSED &&
        audioState != t_AUDIO_STATE.IS_STOPPED) return false;
    return true;
  }

  void startStopRecorder(BuildContext context) async {
    paused = false;
    try {
      if (RecorderState().isRecording || RecorderState().isPaused) {
        await RecorderState().stopRecorder();
      } else {
        await RecorderState().startRecorder(context);
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

  t_AUDIO_STATE get audioState {
    if (RecorderState().isPaused) {
      return t_AUDIO_STATE.IS_RECORDING_PAUSED;
    }
    if (RecorderState().isRecording) return t_AUDIO_STATE.IS_RECORDING;

    return t_AUDIO_STATE.IS_STOPPED;
  }

  void pauseResumeRecorder() async {
    paused = !paused;
    await RecorderState().pauseResumeRecorder();

    setState(() {});
  }
}
