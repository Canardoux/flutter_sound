/*
 * This file is part of Flutter-Sound.
 *
 *   Flutter-Sound is free software: you can redistribute it and/or modify
 *   it under the terms of the Lesser GNU General Public License
 *   version 3 (LGPL3) as published by the Free Software Foundation.
 *
 *   Flutter-Sound is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the Lesser GNU General Public License
 *   along with Flutter-Sound.  If not, see <https://www.gnu.org/licenses/>.
 */

export 'src/album.dart';
export 'src/android/android_audio_focus_gain.dart';
export 'src/codec.dart' show Codec, CodecNotSupportedException;

export 'src/ffmpeg/ffmpeg_util.dart';
export 'src/ios/ios_session_category.dart';
export 'src/ios/ios_session_category_option.dart';
export 'src/ios/ios_session_mode.dart';

export 'src/playback_disposition.dart' show PlaybackDisposition;

export 'src/quick_play.dart' show QuickPlay;
export 'src/recording_disposition.dart' show RecordingDisposition;
export 'src/audio_player.dart'
    show AudioPlayer
    hide
        updateProgress,
        audioPlayerFinished,
        onSystemPaused,
        onSystemResumed,
        onSystemSkipForward,
        onSystemSkipBackward;

export 'src/sound_recorder.dart'
    show SoundRecorder, RecorderException, RecorderRunningException;

export 'src/track.dart' show Track;
export 'src/ui/recorder_playback_controller.dart'
    show RecorderPlaybackController;
export 'src/ui/sound_player_ui.dart' show SoundPlayerUI;
export 'src/ui/sound_recorder_ui.dart' show SoundRecorderUI;
