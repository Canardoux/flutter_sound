import 'dart:async';

import 'package:flutter/material.dart';
import '../playback_disposition.dart';
import '../util/recorded_audio.dart';

import 'sound_player_ui.dart';
import 'sound_recorder_ui.dart';

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
///
class RecorderPlaybackController extends InheritedWidget {
  final _RecordPlaybackControllerState _state;

  ///
  RecorderPlaybackController({@required Widget child, Key key})
      : _state = _RecordPlaybackControllerState(),
        super(child: child);

  // /// Provides a stream with the status of the recording
  // /// Including the current duration
  // Stream<double> duration() async* {}

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return true;
  }

  /// Starts recording.
  void start(RecordedAudio media) {
    _state.startRecording(media);
  }

  /// Stops both the recording and player.
  void stop() {
    _state.stop();

    /// detach the stream
    connectPlayerToRecorderStream(_state._playerState, null);
  }

  // void _onProgress(Duration duration) {
  //   _state._onProgress(duration);
  // }
}

class _RecordPlaybackControllerState {
  SoundRecorderUIState _recorderState;
  SoundPlayerUIState _playerState;

  /// Proxies recording events into playback events.
  /// So we can have the SoundPlayerUI update as the
  /// recorded duration increases.
  final StreamController<PlaybackDisposition> _localController =
      StreamController<PlaybackDisposition>.broadcast();

  void startRecording(RecordedAudio media) {
    // attach the stream.
    connectPlayerToRecorderStream(_playerState, _localController.stream);

    // reset the duration and position of the player
    _localController.add(PlaybackDisposition.zero());

    _playerState.playbackEnabled(enabled: false);
  }

  void _onRecorderStopped(Duration duration) {
    _playerState.playbackEnabled(enabled: true);
  }

  void stop() {
    if (_playerState != null) {
      _playerState.stop();
    }

    if (_recorderState != null) {
      _recorderState.stop();
    }
  }

  void registerRecorder(SoundRecorderUIState recorderState) {
    _recorderState = recorderState;

    // wire our local stream to take events from the recording.
    _recorderState.dispositionStream.listen((recorderDisposition) =>
        _localController.add(
            PlaybackDisposition(Duration.zero, recorderDisposition.duration)));
  }
}

///
/// functions to hide internal api methods.
///

///
void registerRecorder(BuildContext context, SoundRecorderUIState recorder) {
  recorderPlaybackControllerOf(context)?._state?.registerRecorder(recorder);
}

///
void registerPlayer(BuildContext context, SoundPlayerUIState player) {
  recorderPlaybackControllerOf(context)?._state?._playerState = player;
}

///
void onRecordingStopped(BuildContext context, Duration duration) {
  recorderPlaybackControllerOf(context)._state._onRecorderStopped(duration);
}

/// of - find the nearest RecorderPlaybackController in the parent widget
/// tree.
RecorderPlaybackController recorderPlaybackControllerOf(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<RecorderPlaybackController>();


// ///
// void onRecorderProgress(
//     BuildContext context, SoundRecorderUIState recorder, Duration duration) {
//   recorderPlaybackControllerOf(context)?._state?._onProgress(duration);
// }
