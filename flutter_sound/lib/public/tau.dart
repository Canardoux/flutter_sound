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

// The three interfaces to the platform
// ------------------------------------

/// ------------------------------------------------------------------
/// # The Flutter Sound library
///
/// Flutter Sound is composed with six main modules/classes
/// - [FlutterSound]. This is the main Flutter Sound module.
/// - [FlutterSoundPlayer]. Everything about the playback functions
/// - [FlutterSoundRecorder]. Everything about the recording functions
/// - [FlutterSoundHelper]. Some utilities to manage audio data.
/// And two modules for the Widget UI
/// - [SoundPlayerUI]
/// - [SoundRecorderUI]
/// ------------------------------------------------------------------
/// {@category Main}
library tau;

import 'dart:typed_data' show Uint8List;
import 'package:flutter_sound_platform_interface/flutter_sound_platform_interface.dart';
import 'flutter_sound_player.dart';
import 'flutter_sound_recorder.dart';
import 'util/log.dart';

export 'package:flutter_sound_platform_interface/flutter_sound_platform_interface.dart';

/// For internal code. Do not use.
///
/// The possible states of the players and recorders
/// @nodoc
enum Initialized {
  /// The object has been created but is not initialized
  notInitialized,

  /// The object is initialized and can be fully used
  fullyInitialized,
}

/// The usual file extensions used for each codecs
const List<String> ext = [
  '.aac', // defaultCodec
  '.aac', // aacADTS
  '.opus', // opusOGG
  '_opus.caf', // opusCAF
  '.mp3', // mp3
  '.ogg', // vorbisOGG
  '.pcm', // pcm16
  '.wav', // pcm16WAV
  '.aiff', // pcm16AIFF
  '_pcm.caf', // pcm16CAF
  '.flac', // flac
  '.mp4', // aacMP4
  '.amr', // AMR-NB
  '.amr', // amr-WB
  '.pcm', // pcm8
  '.pcm', // pcmFloat32
  '.pcm', //codec.pcmWebM,
  '.opus', // codec.opusWebM,
];

/// Food is an abstract class which represents objects that can be sent
/// to a player when playing data from astream or received by a recorder
/// when recording to a Dart Stream.
///
/// This class is extended by
/// - [FoodData] and
/// - [FoodEvent].
abstract class Food {
  /// use internally by Flutter Sound
  Future<void> exec(FlutterSoundPlayer player);

  /// use internally by Flutter Sound
  void dummy(FlutterSoundPlayer player) {} // Just to satisfy `dartanalyzer`

}

/// FoodData are the regular objects received from a recorder when recording to a Dart Stream
/// or sent to a player when playing from a Dart Stream
class FoodData extends Food {
  /// the data to be sent (or received)
  Uint8List data;

  /// The constructor, specifying the data to be sent or that has been received
  /* ctor */ FoodData(this.data);

  /// Used internally by Flutter Sound
  @override
  Future<void> exec(FlutterSoundPlayer player) => player.feedFromStream(data);
}

/// foodEvent is a special kin of food which allows to re-synchronize a stream
/// with a player that play from a Dart Stream
class FoodEvent extends Food {
  /// The callback to fire when this food is synchronized with the player
  Function on;

  /// The constructor, specifying the callback which must be fired when synchronization is done
  /* ctor */ FoodEvent(this.on);

  /// Used internally by Flutter Sound
  @override
  Future<void> exec(FlutterSoundPlayer player) async => on();
}

/// This is **THE** main Flutter Sound class.
///
/// For future expansion. Do not use.
/// This class is not instanciable. Use the expression [FlutterSound()] when you want to get the Singleton.
///
/// This class is used to access the main functionalities of Flutter Sound. It declares also
/// a default [FlutterSoundPlayer] and a default [FlutterSoundRecorder] that can be used
/// by the App, without having to build such objects themselves.
/// @nodoc
class FlutterSound {
  AudioFocus _mFocus = AudioFocus.requestFocusAndKeepOthers;
  SessionMode _mSessionMode = SessionMode.modeDefault;
  SessionCategory _mSessionCategory = SessionCategory.playback;
  final _mAudioDevice = AudioDevice.speaker;
  final _mAudioFlags =
      outputToSpeaker | allowBlueTooth | allowBlueToothA2DP | allowEarPiece;
  final _mWithUI = false;

  // ---------------------------------------------------------------------------------------------------------------------

  /// the static Singleton
  static final FlutterSound _singleton = FlutterSound._internal();

  /// The factory which returns the Singleton
  factory FlutterSound() {
    return _singleton;
  }

  /// Private constructor of the Singleton
  /* ctor */ FlutterSound._internal();

  /// This instance of [FlutterSoundPlayer] is just to be smart for the App.
  /// The Apps can use this instance without having to create a [FlutterSoundPlayer] themselves.
  FlutterSoundPlayer thePlayer = FlutterSoundPlayer();

  /// TODO
  void internalOpenSessionForRecording() {
    //todo
  }

  // ----------------------------------------------------------------------------------------------------------------------

  /// setAudioFocus() is now a global function.
  /// (Before 6.5.0, the Focus was an attribute of the players and the recorders).
  /// It did not work very well, because iOS can have just one Session per App.
  ///
  /// The use of this verb is optional. If the App does not call `setAudioFocus()`
  /// The focus will be automatically aquired when calling `startPlayer()` and released when
  /// the player is Stopped. So very often, the APP will not use this verb.
  ///
  /// `setAudioFocus()` is a noop on Flutter Web
  Future<void> setAudioFocus(
    /// What to do if another App has the focus
    AudioFocus focus,
  ) async {
    Log.i('FS:---> setAudioFocus ');
    _mFocus = focus;

    // For legacy reason, we need to have an open player to set the Audio Focus
    // This is not very clean, and should be improved...
    if (!thePlayer.isOpen()) {
      await thePlayer.openAudioSession(
          focus: _mFocus,
          category: _mSessionCategory,
          device: _mAudioDevice,
          audioFlags: _mAudioFlags,
          mode: _mSessionMode,
          withUI: _mWithUI);
      await thePlayer.closeAudioSession();
    } else {
      await thePlayer.setAudioFocus(
          focus: _mFocus,
          category: _mSessionCategory,
          device: _mAudioDevice,
          audioFlags: _mAudioFlags,
          mode: _mSessionMode);
    }
    Log.i('FS:<--- setAudioFocus ');
  }

  /// setIOSSessionParameters() is for specifying the Audio session on iOS.
  /// The use of this verb is completely optional and most of the cases will
  /// not be called by the App. If not called, Flutter Sound will use
  /// default parameters for the Audio Session.
  ///
  /// `setIOSSessionParameters()` is a noop on Flutter Web and android
  Future<void> setIOSSessionParameters({
    /// The category is used by iOS and ignored on Android and Flutter Web
    SessionCategory category = SessionCategory.playback,

    /// The mode is used by iOS and ignored on Android and Flutter Web
    SessionMode mode = SessionMode.modeDefault,
  }) async {
    Log.i('FS:---> setIOSSessionParameters ');
    _mSessionCategory = category;
    _mSessionMode = mode;
    // For legacy reason, we need to have an open player to set the Audio Focus
    // This is not very clean, and should be improved...
    if (!thePlayer.isOpen()) {
      await thePlayer.openAudioSession(
          focus: AudioFocus.doNotRequestFocus,
          category: _mSessionCategory,
          device: _mAudioDevice,
          audioFlags: _mAudioFlags,
          mode: _mSessionMode,
          withUI: _mWithUI);
      await thePlayer.closeAudioSession();
    } else {
      await thePlayer.setAudioFocus(
        focus: _mFocus,
        category: _mSessionCategory,
        device: _mAudioDevice,
        audioFlags: _mAudioFlags,
        mode: _mSessionMode,
      );
    }
    Log.i('FS:<--- setIOSSessionParameters ');
  }
}
