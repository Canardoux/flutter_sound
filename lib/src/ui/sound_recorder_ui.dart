import 'dart:async';

import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

import '../android/android_encoder.dart';
import '../recording_disposition.dart';
import '../sound_recorder.dart';
import '../track.dart';
import '../util/ansi_color.dart';
import '../util/log.dart';
import '../util/recorded_audio.dart';
import 'recorder_playback_controller.dart';

typedef OnStart = void Function();
typedef OnProgress = void Function(RecordedAudio media);
typedef OnStop = void Function(RecordedAudio media);

/// The [informUser] callback allows you to provide an
/// UI informing the user that we are about to ask for a permission.
typedef InformUser = Future<bool> Function(
    BuildContext context, List<Permission> permissions);

/// A UI for recording audio.
class SoundRecorderUI extends StatefulWidget {
  /// Callback to be notified when the recording stops
  final OnStop onStop;

  /// Callback to be notified when the recording starts.
  final OnStart onStart;

  /// Stores and Tracks the recorded audio.
  final RecordedAudio audio;

  /// The [informUser] callback allows you to provide an
  /// UI informing the user that we are about to ask for a permission.
  ///
  /// It is sometimes useful to explain to the user why we are asking
  /// for permission before showing the OSs permission request.
  ///
  /// This callback allows you to do just that.
  ///
  /// Return [true] to indicate that the user has given permission for
  /// us to ask for permission.
  ///
  /// If [true] is returned then we will show the OSs permission UI.
  ///
  /// This method will not be called if we already have the necessary
  /// permissions.
  ///
  final InformUser informUser;

  ///
  /// Records audio from the users microphone into the given media file.
  ///
  /// The user is presented with a UI that allows them to start/stop recording
  /// and provides some basic feed back on the volume as the recording
  ///  progresses.
  ///
  /// The [track] specifies the file we are recording to.
  /// At the moment the [track] must be constructued using [Track.fromPath] as
  /// recording to a databuffer is not currently supported.
  ///
  /// The [onStart] callback is called user starts recording. This method will
  /// be called each time the user clicks the 'record' button.
  ///
  /// The [onStopped] callback is called when the user stops recording. This
  /// method will be each time the user clicks the 'stop' button. It can
  /// also be called if the [stop] method is called.
  ///
  /// The [informUser] callback allows you to provide an
  /// UI informing the user that we are about to ask for a permission.
  /// This gives you a chance to explain to the user why we are asking
  /// for permission before we show the OSs permission UI.
  ///
  SoundRecorderUI(
    Track track, {
    this.onStart,
    this.onStop,
    this.informUser,
    Key key,
  })  : audio = RecordedAudio.toTrack(track),
        super(key: key);

  @override
  State<StatefulWidget> createState() {
    return SoundRecorderUIState();
  }
}

///
class SoundRecorderUIState extends State<SoundRecorderUI> {
  bool _isRecording = false;

  SoundRecorder _recorder;

  ///
  SoundRecorderUIState() {
    _recorder = SoundRecorder();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    registerRecorder(context, this);
    return _buildButtons();
  }

  Widget _buildButtons() {
    return Column(
      children: <Widget>[
        _buildMicrophone(),
        _buildStopButton(),
      ],
    );
  }

  ///
  Stream<RecordingDisposition> get dispositionStream =>
      _recorder.dispositionStream();

  Widget _buildMicrophone() {
    return SizedBox(
        height: 120,
        width: 120,
        child: StreamBuilder<RecordingDisposition>(
            stream: _recorder.dispositionStream(),
            initialData: RecordingDisposition.zero(), // was START_DECIBELS
            builder: (_, streamData) {
              var disposition = streamData.data;
              //      onRecorderProgress(context, this, disposition.duration);
              return Stack(alignment: Alignment.center, children: [
                AnimatedContainer(
                  duration: Duration(milliseconds: 20),
                  // + 30 so the animated circle is always a reasonable
                  // size (db ranges is typically 45 - 80db)
                  width: disposition.decibels + 30,
                  height: disposition.decibels + 30,
                  constraints:
                      BoxConstraints(maxHeight: 80.0 + 30, maxWidth: 80.0 + 30),
                  decoration:
                      BoxDecoration(shape: BoxShape.circle, color: Colors.red),
                ),
                InkWell(onTap: _onRecord, child: Icon(Icons.mic, size: 60))
              ]);
            }));
  }

  Widget _buildStopButton() {
    return InkWell(
        onTap: _recorder.isRecording ? stop : _onRecord,
        child: Icon(
          _recorder.isRecording ? Icons.stop : Icons.play_circle_filled,
          size: 60,
          color: Colors.red,
        ));
  }

  void dispose() {
    stop();
    super.dispose();
  }

  void _onRecord() {
    if (!_isRecording) {
      _requestPermission(context).then((accepted) async {
        Log.e(green('started Recording to: '
            '${await (await widget.audio).track.identity})'));
        await _recorder.record(widget.audio.track,
            androidEncoder: AndroidEncoder.amrWbCodec);

        Log.d(widget.audio.track.identity);

        _isRecording = true;
        setState(() {});

        Log.d(green('started Recording to: '
            '${await (await widget.audio).track.identity})'));

        if (widget.onStart != null) {
          widget.onStart();
        }

        recorderPlaybackControllerOf(context).start(widget.audio);
      });
    }
  }

  /// The [stop] methods stops the recording and calls
  /// the onStop callback.
  ///
  void stop() {
    setState(() {});
    if (_recorder.isRecording) {
      _isRecording = false;
      _recorder.stop().then<void>((_) async {
        // cause the  player to pick up the newly recorded file.
        setState(() {
          _updateDuration(_recorder.duration);

          if (widget.onStop != null) {
            widget.onStop(widget.audio);
          }

          onRecordingStopped(context, _recorder.duration);
        });
      });
    }
  }

  /// as recording progresses we update the media's duration.
  void _updateDuration(Duration duration) {
    widget.audio.duration = _recorder.duration;
  }

  /// If requried displays the OSs permission UI to request
  /// permissions required for recording.
  ///
  Future<bool> _requestPermission(BuildContext context) async {
    var requesting = Completer<bool>();

    var storagePermission = await Permission.storage.status;

    var microphonePermission = await Permission.microphone.status;

    var storageAllowed = storagePermission.isGranted;
    var microphoneAllowed = microphonePermission.isGranted;

    var permissionRequests = <Permission>[];

    Future<bool> inform;

    if (widget.informUser != null) {
      /// ask the user before we actually ask the OS so
      /// the dev has a chance to inform the user as to why we need
      /// permissions.
      inform = widget.informUser(context, permissionRequests);
    } else {
      inform = Future.value(true);
    }

    inform.then((inform) async {
      /// only request what we don't have.
      if (!microphoneAllowed) {
        permissionRequests.add(Permission.microphone);
      }
      if (!storageAllowed) {
        permissionRequests.add(Permission.storage);
      }

      var results = await permissionRequests.request();

      var accepted = true;
      // check that each permission was granted.
      results.forEach((permission, status) => accepted &= status.isGranted);

      requesting.complete(accepted);
    });
    return requesting.future;
  }
}
