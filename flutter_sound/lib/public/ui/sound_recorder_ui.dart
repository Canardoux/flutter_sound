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

/// ------------------------------------------------------------------
/// # The Flutter Sound UI recorder
///
/// The SoundRecorderUI  widget provide a simple UI for recording audio.
///
/// The audio is recorded to a [Track](../api/track.md).
///
// TODO: add image here.
///
/// ------------------------------------------------------------------
/// {@category UI_Widgets}
library ui_recorder;

import 'dart:async';
import 'package:flutter/material.dart';
import '../../flutter_sound.dart';
import '../flutter_sound_player.dart';
import '../flutter_sound_recorder.dart';

/// Callback fn type
typedef OnStart = void Function();

/// Callback fn type
typedef OnDelete = void Function();

/// Callback fn type
typedef OnProgress = void Function(RecordedAudio media);

/// Callback fn type
typedef OnStop = void Function(RecordedAudio media);

/// Callback fn type
typedef OnPaused = void Function(RecordedAudio media, bool isPaused);

/// The states possible of the recorder
enum _RecorderState {
  /// Is Stopped
  isStopped,

  /// Is recording
  isRecording,

  /// Is paused
  isPaused,
}

/// [RecordedAudio] is used to track the audio media
/// created during a recording session via the SoundRecorderUI.
///
class RecordedAudio {
  /// The length of the recording (so far)
  Duration duration = Duration.zero;

  /// The track we are recording audio to.
  Track track;

  /// Creates a [RecordedAudio] that will store
  /// the recording to the given pay.
  RecordedAudio.toTrack(this.track);
}

/// The `requestPermissions` callback allows you to provide an
/// UI informing the user that we are about to ask for a permission.
///
typedef UIRequestPermission = Future<bool> Function(
    BuildContext context, Track track);

/// A UI for recording audio.
class SoundRecorderUI extends StatefulWidget {
  static const int _barHeight = 60;

  ///
  final Color backgroundColor;

  ///
  final String pausedTitle;

  ///
  final String recordingTitle;

  ///
  final String stoppedTitle;

  /// Callback to be notified when the recording stops
  final OnStop onStopped;

  /// Callback to be notified when the recording starts.
  final OnStart onStart;

  /// Callback to be notified when the recording pause.
  final OnPaused onPaused;

  ///
  final OnDelete onDelete;

  /// Stores and Tracks the recorded audio.
  final RecordedAudio audio;

  ///
  final bool showTrashCan;

  /// The `requestPermissions` callback allows you to request
  /// the necessary permissions to record a track.
  ///
  /// If `requestPermissions` is null then no permission checks
  /// will be performed.
  ///
  /// It is sometimes useful to explain to the user why we are asking
  /// for permission before showing the OSs permission request.
  /// This callback gives you the opportunity to display a suitable
  /// notice and then request permissions.
  ///
  /// Return `true` to indicate that the user has given permission
  /// to record and that you have made the necessary calls to
  /// grant those permissions.
  ///
  /// If `true` is returned the recording will proceed.
  /// If `false` is returned then recording will not start.
  ///
  /// This method will be called even if we have the necessary permissions
  /// as we make no checks.
  ///
  final UIRequestPermission requestPermissions;

  ///
  /// Records audio from the users microphone into the given media file.
  ///
  /// The user is presented with a UI that allows them to start/stop recording
  /// and provides some basic feed back on the volume as the recording
  ///  progresses.
  ///
  /// The [track] specifies the file we are recording to.
  /// At the moment the [track] must be constructued using `Track.fromFile` as
  /// recording to a databuffer is not currently supported.
  ///
  /// The [onStart] callback is called user starts recording. This method will
  /// be called each time the user clicks the 'record' button.
  ///
  /// The `onStopped` callback is called when the user stops recording. This
  /// method will be each time the user clicks the 'stop' button. It can
  /// also be called if the `stop` method is called.
  ///
  /// The `requestPermissions` callback allows you to request
  /// permissions just before they are required and if desired
  /// display your own dialog explaining why the permissions are required.
  ///
  /// If you do not provide `requestPermissions` then you must ensure
  /// that all required permissions are granted before the
  /// [SoundRecorderUI] widgets starts recording.
  ///
  ///
  /// ```dart
  ///   SoundRecorderIU(track,
  ///       informUser: (context, track)
  ///           {
  ///               // pseudo code
  ///               String reason;
  ///               if (!microphonePermission.granted)
  ///                 reason += 'please allow microphone';
  ///               if (!requestingStoragePermission.granted)
  ///                 reason += 'please allow storage';
  ///               if (Dialog.show(reason) == Dialog.OK)
  ///               {
  ///                 microphonePermission.request == granted;
  ///                 storagePermission.request == granted;
  ///                 return true;
  ///               }
  ///
  ///           });
  ///
  /// ```
  SoundRecorderUI(
    Track track, {
    this.backgroundColor,
    this.onStart,
    this.onStopped,
    this.onPaused,
    this.onDelete,
    this.requestPermissions,
    this.showTrashCan = true,
    this.pausedTitle = 'Recorder is paused',
    this.recordingTitle = 'Recorder is recording',
    this.stoppedTitle = 'Recorder is stopped',
    Key key,
  })  : audio = RecordedAudio.toTrack(track),
        super(key: key);

  @override
  State<StatefulWidget> createState() {
    return SoundRecorderUIState(backgroundColor ?? Color(0xFFFAF0E6));
  }
}

///
class SoundRecorderUIState extends State<SoundRecorderUI> {
  _RecorderState _state = _RecorderState.isStopped;

  FlutterSoundRecorder _recorder;

  ///
  Color backgroundColor;

  ///
  SoundRecorderUIState(
    this.backgroundColor,
  );

  ///
  @override
  void initState() {
    _recorder = FlutterSoundRecorder();
    _recorder
        .openAudioSession(
            focus: AudioFocus.requestFocusAndDuckOthers,
            category: SessionCategory.playAndRecord,
            mode: SessionMode.modeDefault,
            device: AudioDevice.speaker,
            audioFlags: outputToSpeaker | allowBlueToothA2DP | allowAirPlay)
        .then((toto) {
      registerRecorder(context, this);
    });
    super.initState();
  }

  ///
  @override
  void deactivate() {
    _recorder.stopRecorder();
    super.deactivate();
  }

  ///
  @override
  Widget build(BuildContext context) {
    return _buildButtons();
  }

  ///
  @override
  void dispose() {
    _recorder.closeAudioSession();
    super.dispose();
  }

  Widget _buildButtons() {
    return Container(
        //height: 70,
        decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius:
                BorderRadius.circular(SoundRecorderUI._barHeight / 2)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            //SizedBox(width: 20,),
            _buildMicrophone(),
            _buildStartStopButton(),
            widget.showTrashCan != null ? _buildTrashButton() : SizedBox(),
            Text(_isPaused
                ? widget.pausedTitle
                : _isRecording
                    ? widget.recordingTitle
                    : widget.stoppedTitle),
          ],
          //Expanded(child: Column(children: rows))
        ));
  }

  ///
  Stream<RecordingDisposition> get dispositionStream =>
      _recorder.dispositionStream();

  static const _minDbCircle = 15;

  Widget _buildMicrophone() {
    return SizedBox(
        height: 50,
        width: 50,
        child: StreamBuilder<RecordingDisposition>(
            stream: _recorder.dispositionStream(),
            initialData: RecordingDisposition.zero(), // was START_DECIBELS
            builder: (_, streamData) {
              var disposition = streamData.data;
              var min = _minDbCircle;
              if (disposition.decibels == 0) {
                min = 0;
              }
              //      onRecorderProgress(context, this, disposition.duration);
              return Stack(alignment: Alignment.center, children: [
                Visibility(
                  visible: _isRecording || _isPaused,
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 20),
                    // + MIN_DB_CIRCLE so the animated circle is always a
                    // reasonable size (db ranges is typically 45 - 80db)
                    width: disposition.decibels + min,
                    height: disposition.decibels + min,
                    constraints: BoxConstraints(
                        maxHeight: 80.0 + min, maxWidth: 80.0 + min),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: Colors.red),
                  ),
                ),
                InkWell(
                  onTap: _onTapStartStop,
                  child: Icon(_isStopped ? Icons.brightness_1 : Icons.stop,
                      color: _isStopped ? Colors.red : Colors.black),
                ),
              ]);
            }));
  }

  Widget _buildStartStopButton() {
    return SizedBox(
        height: 50,
        width: 30,
        child: InkWell(
            onTap: _isStopped ? null : (_isPaused ? _resume : _pause),
            child: Icon(
              !_isPaused ? Icons.pause : Icons.play_arrow,
              //size: 30,
              color: !_isStopped ? Colors.black : Colors.grey,
            )));
  }

  Widget _buildTrashButton() {
    return SizedBox(
        height: 50,
        width: 30,
        child: InkWell(
            onTap:
                _isStopped && widget.onDelete != null ? widget.onDelete : null,
            child: Icon(
              Icons.delete_outline,
              //size: 30,
              color: _isStopped && widget.onDelete != null
                  ? Colors.black
                  : Colors.grey,
            )));
  }

  void _onTapStartStop() {
    if (_isRecording || _isPaused) {
      _stop();
    } else {
      _onRecord();
    }
  }

  bool get _isRecording => _state == _RecorderState.isRecording;
  bool get _isPaused => _state == _RecorderState.isPaused;
  bool get _isStopped => _state == _RecorderState.isStopped;

  /// The `stop` methods stops the recording and calls
  /// the `onStopped` callback.
  ///
  void stop() {
    _stop();
  }

  ///
  void pause() {
    _pause();
  }

  ///
  void resume() {
    _resume();
  }

  void _onRecord() async {
    if (!_isRecording) {
      await _recorder.setSubscriptionDuration(Duration(milliseconds: 100));
      await _recorder.startRecorder(
        toFile: widget.audio.track.trackPath,
      );
      _onStarted(wasUser: true);
      //Log.d(widget.audio.track.identity);
    }
  }

  void _stop() async {
    if (_recorder.isRecording || _recorder.isPaused) {
      await _recorder.stopRecorder();
      _onStopped(wasUser: true);
    }
  }

  void _pause() async {
    if (_recorder.isRecording) {
      await _recorder.pauseRecorder();
      _onPaused(wasUser: true);
    }
  }

  void _resume() async {
    if (_recorder.isPaused) {
      await _recorder.resumeRecorder();
      _onResume(wasUser: true);
    }
  }

  void _onStarted({bool wasUser}) async {
    //Log.d(green('started Recording to: '
    //'${await (await widget.audio).track.identity})'));

    setState(() {
      _state = _RecorderState.isRecording;

      if (widget.onStart != null) {
        widget.onStart();
      }
      //controller(context);
    });
  }

  void _onStopped({bool wasUser}) {
    setState(() {
      // TODO _updateDuration(_recorder.duration);
      _state = _RecorderState.isStopped;

      if (widget.onStopped != null) {
        widget.onStopped(widget.audio);
      }

      onRecordingStopped(context, Duration(milliseconds: 2000)); // TODO
    });
  }

  void _onPaused({bool wasUser}) async {
    //Log.d(green('started Recording to: '
    //'${await (await widget.audio).track.identity})'));

    setState(() {
      _state = _RecorderState.isPaused;

      if (widget.onPaused != null) {
        widget.onPaused(widget.audio, true);
      }

      onRecordingPaused(context);
    });
  }

  void _onResume({bool wasUser}) async {
    //Log.d(green('started Recording to: '
    //'${await (await widget.audio).track.identity})'));

    setState(() {
      _state = _RecorderState.isRecording;

      if (widget.onPaused != null) {
        widget.onPaused(widget.audio, false);
      }
      onRecordingResume(context);
    });
  }
}
