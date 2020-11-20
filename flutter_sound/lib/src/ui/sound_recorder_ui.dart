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
/// # The Flutter Sound UIWidget3
///
///
/// ------------------------------------------------------------------

import 'dart:async';
import 'package:flutter/material.dart';
import '../../flutter_sound.dart';
import '../flutter_sound_player.dart';
import '../flutter_sound_recorder.dart';
import '../util/log.dart';
import 'sound_player_ui.dart';

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
      _registerRecorder(context, this);
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

      _onRecordingStopped(context, Duration(milliseconds: 2000)); // TODO
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

      _onRecordingPaused(context);
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
      _onRecordingResume(context);
    });
  }
}

///
/// Functions used to hide internal implementation details
///
void connectPlayerToRecorderStream(SoundPlayerUIState playerState,
    Stream<PlaybackDisposition> recorderStream) {
  playerState.connectRecorderStream(recorderStream);
}

/// This class is a Provider style widget designed to
/// co-ordinate a [SoundRecorderUI] and a [SoundPlayerUI]
/// so that a user can record and playback in a co-ordinated manner.
///
/// All instances of [SoundRecorderUI] and a [SoundPlayerUI] will
/// search the widget tree looking for a [RecorderPlaybackController].
/// This can cause unintended links. Always place the
/// [RecorderPlaybackController] as close to the [SoundRecorderUI] and
/// [SoundPlayerUI] as possible to avoid unintended links.
///
/// The [RecorderPlaybackController] will disable the [SoundPlayerUI]
/// whilst recording is running and re-enable it once recording has stopped.
///
/// If recording is started whilst the [SoundPlayerUI] is playing then the
/// recorder will cause the playback to stop.
///
/// The [RecorderPlaybackController] will also stream duration
/// updates to the Player so that it can show the duration of the recording
/// as it grows.
class RecorderPlaybackController extends InheritedWidget {
  final _RecordPlaybackControllerState _state;

  ///
  RecorderPlaybackController({@required Widget child, Key key})
      : _state = _RecordPlaybackControllerState(),
        super(child: child);

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return true;
  }

  /// stops both the player and the recorder.
  void stop() => _state.stop();

  /// of - find the nearest RecorderPlaybackController in the parent widget
  /// tree.
  static RecorderPlaybackController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RecorderPlaybackController>();
}

class _RecordPlaybackControllerState {
  SoundRecorderUIState _recorderState;
  SoundPlayerUIState _playerState;

  /// Proxies recording events into playback events.
  /// So we can have the SoundPlayerUI update as the
  /// recorded duration increases.
  final StreamController<PlaybackDisposition> _localController =
      StreamController<PlaybackDisposition>.broadcast();

  /// Stops both the player and the recorder.
  void stop() {
    _playerState?.stop();
    _recorderState?.stop();
  }

  void _onRecorderStopped(Duration duration) {
    Log.d('_onRecorderStopped');
    if (_playerState != null) {
      _playerState.playbackEnabled(enabled: true);

      /// detach the player stream from the recorder stream.
      /// The player will now re-attached to the AudioPlayer stream
      /// so that it can show playback progress.
      connectPlayerToRecorderStream(_playerState, null);
    }
  }

  void _onRecorderPaused() {
    Log.d('_onRecorderStopped');
    if (_playerState != null) {
      _playerState.playbackEnabled(enabled: false);
      // TODO ...
    }
  }

  void _onRecorderResume() {
    Log.d('_onRecorderStopped');
    if (_playerState != null) {
      _playerState.playbackEnabled(enabled: false);
      // TODO ...
    }
  }

  void registerRecorder(SoundRecorderUIState recorderState) {
    _recorderState = recorderState;

    // wire our local stream to take events from the recording.
    _recorderState.dispositionStream.listen(
        (recorderDisposition) => _localController.add(PlaybackDisposition(
            // TODO ? PlaybackDispositionState.recording,
            position: Duration.zero,
            duration: recorderDisposition.duration)));
  }
}

///
/// functions to hide internal api methods.
///

///
void _registerRecorder(BuildContext context, SoundRecorderUIState recorder) {
  RecorderPlaybackController.of(context)?._state?.registerRecorder(recorder);
}

///
void registerPlayer(BuildContext context, SoundPlayerUIState player) {
  var controller = RecorderPlaybackController.of(context)?._state;
  if (controller != null) {
    controller._playerState = player;
  }
}

///
void _onRecordingStopped(BuildContext context, Duration duration) {
  RecorderPlaybackController.of(context)._state._onRecorderStopped(duration);
}

///
void _onRecordingPaused(BuildContext context) {
  RecorderPlaybackController.of(context)._state._onRecorderPaused();
}

///
void _onRecordingResume(BuildContext context) {
  RecorderPlaybackController.of(context)._state._onRecorderResume();
}
