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

/
class _RecordPlaybackControllerState
{
        SoundRecorderUIState _recorderState;
        SoundPlayerUIState _playerState;

        /// Proxies recording events into playback events.
        /// So we can have the SoundPlayerUI update as the
        /// recorded duration increases.
        final StreamController<PlaybackDisposition> _localController =
            StreamController<PlaybackDisposition>.broadcast();

        /// Stops both the player and the recorder.
        void stop()
        {
                _playerState?.stop();
                _recorderState?.stop();
        }

        void _onRecorderStarted()
        {
                Log.d('_onRecorderStarted');
                if (_playerState != null)
                {
                        _playerState.stop().then((_)
                        {
                                _playerState.playbackEnabled(enabled: false);

                                // attach the player to the recorder stream so it can
                                // show the duration updating
                                connectPlayerToRecorderStream(_playerState, _localController.stream);
                                // reset the duration and position of the player
                                _localController.add(PlaybackDisposition.zero());
                        });
                }
        }

        void _onRecorderStopped(Duration duration)
        {
                Log.d('_onRecorderStopped');
                if (_playerState != null)
                {
                        _playerState.playbackEnabled(enabled: true);

                        /// detach the player stream from the recorder stream.
                        /// The player will now re-attached to the AudioPlayer stream
                        /// so that it can show playback progress.
                        connectPlayerToRecorderStream(_playerState, null);
                }
        }


        void _onRecorderPaused()
        {
                Log.d('_onRecorderStopped');
                if (_playerState != null)
                {
                        _playerState.playbackEnabled(enabled: false);
                        // TODO ...
                }
        }


        void _onRecorderResume()
        {
                Log.d('_onRecorderStopped');
                if (_playerState != null)
                {
                        _playerState.playbackEnabled(enabled: false);
                        // TODO ...
                }
        }

        void registerRecorder(SoundRecorderUIState recorderState)
        {
                _recorderState = recorderState;

                // wire our local stream to take events from the recording.
                _recorderState.dispositionStream.listen
                ((recorderDisposition) =>
                        _localController.add
                        (
                                PlaybackDisposition
                                (
                                    // TODO ? PlaybackDispositionState.recording,
                                    position: Duration.zero,
                                    duration: recorderDisposition.duration
                                )
                        )
                );
        }
}
