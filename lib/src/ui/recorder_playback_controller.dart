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
import '../flutter_sound_recorder.dart';
import '../flutter_sound_player.dart';
import '../util/log.dart';

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

  void _onRecorderStarted() {
    Log.d('_onRecorderStarted');
    if (_playerState != null) {
      _playerState.stop().then((_) {
        _playerState.playbackEnabled(enabled: false);

        // attach the player to the recorder stream so it can
        // show the duration updating
        connectPlayerToRecorderStream(_playerState, _localController.stream);
        // reset the duration and position of the player
        _localController.add(PlaybackDisposition.zero());
      });
    }
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

  void registerRecorder(SoundRecorderUIState recorderState) {
    _recorderState = recorderState;

    // wire our local stream to take events from the recording.
    _recorderState.dispositionStream.listen
    ((recorderDisposition) =>
        _localController.add(PlaybackDisposition(
            // TODO ? PlaybackDispositionState.recording,
            position: Duration.zero,
            duration: recorderDisposition.duration)
                             )
    );
  }
}

///
/// functions to hide internal api methods.
///

///
void registerRecorder(BuildContext context, SoundRecorderUIState recorder) {
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
void onRecordingStarted(BuildContext context) {
  RecorderPlaybackController.of(context)._state._onRecorderStarted();
}

///
void onRecordingStopped(BuildContext context, Duration duration) {
  RecorderPlaybackController.of(context)._state._onRecorderStopped(duration);
}

// ///
// void onRecorderProgress(
//     BuildContext context, SoundRecorderUIState recorder, Duration duration) {
//   recorderPlaybackControllerOf(context)?._state?._onProgress(duration);
// }
