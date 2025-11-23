/*
 * Copyright 2018, 2019, 2020 Dooboolab.
 * Copyright 2021, 2022, 2023, 2024 Canardoux.
 *
 * This file is part of Flutter-Sound.
 *
 * Flutter-Sound is free software: you can redistribute it and/or modify
 * it under the terms of the Mozilla Public License version 2 (MPL-2.0),
 * as published by the Mozilla organization.
 *
 * Flutter-Sound is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * MPL General Public License for more details.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

// The three interfaces to the platform
// ------------------------------------

/// ------------------------------------------------------------------
/// # The Flutter Sound library
///
/// Flutter Sound is composed with three main modules/classes
/// - [FlutterSoundPlayer]. Everything about the playback functions
/// - [FlutterSoundRecorder]. Everything about the recording functions
/// - [FlutterSoundHelper]. Some utilities to manage audio data.
/// ------------------------------------------------------------------
library;

// The interfaces to the platforms specific implementations
// --------------------------------------------------------
//export 'package:flutter_sound_platform_interface/flutter_sound_platform_interface.dart';

// everything : no documentation
// @nodoc
// library;

export 'package:flutter_sound_platform_interface/flutter_sound_platform_interface.dart';

/// Main
///library tau;
export 'flutter_sound_player.dart';
export 'flutter_sound_recorder.dart';
export 'flutter_sound_helper.dart';
//export 'tau.dart';

import 'dart:typed_data' show Uint8List;
import 'package:logger/logger.dart' show Level, Logger;
import 'flutter_sound_player.dart';
import 'flutter_sound_recorder.dart';

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
  '', // defaultCodec
  '.aac', // aacADTS
  '.opus', // opusOGG
  '.caf', // opusCAF
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
  '.webm', // codec.opusWebM,
  '.webm', // codec.vorbisWebM,
  '.wav', // pcmFloat32WAV
];

/// The valid file extensions for each codecs
const List<List<String>> validExt = [
  [''], // defaultCodec
  ['.aac', '.adt', '.adts'], // aacADTS
  ['.opus', '.ogg'], // opusOGG
  ['.caf'], // opusCAF
  ['.mp3'], // mp3
  ['.ogg'], // vorbisOGG
  ['.pcm', '.aiff'], // pcm16
  ['.wav'], // pcm16WAV
  ['.aiff'], // pcm16AIFF
  ['.caf'], // pcm16CAF
  ['.flac'], // flac
  ['.mp4', '.aac', '.m4a'], // aacMP4
  ['.amr', '.3ga'], // AMR-NB
  ['.amr', '.3ga'], // amr-WB
  ['.pcm', '.aiff'], // pcm8
  ['.pcm', '.aiff'], // pcmFloat32
  ['.pcm', '.webm'], //codec.pcmWebM,
  ['.opus', '.webm'], // codec.opusWebM,
  ['.webm'], // codec.vorbisWebM,
  ['.wav'], // pcmFloat32WAV
];

/// Food is an abstract class which represents objects that can be sent
/// to a player when playing data from astream or received by a recorder
/// when recording to a Dart Stream.
///
@Deprecated('Don\'t use anymore Food, but directely your buffers')
/// @nodoc
abstract class Food {
  /// use internally by Flutter Sound
  Future<void> exec(FlutterSoundPlayer player);

  /// use internally by Flutter Sound
  void dummy(FlutterSoundPlayer player) {} // Just to satisfy `dartanalyzer`
}

/// FoodData are the regular objects received from a recorder when recording to a Dart Stream
/// or sent to a player when playing from a Dart Stream
@Deprecated('Don\'t use anymore Food, but directely your buffers')
/// @nodoc
class FoodData extends Food {
  /// the data to be sent (or received)
  Uint8List? data;

  /// The constructor, specifying the data to be sent or that has been received
  /* ctor */
  FoodData(this.data);

  /// Used internally by Flutter Sound
  @override
  Future<void> exec(FlutterSoundPlayer player) => player.feedFromStream(data!);
}

/// foodEvent is a special kind of food which allows to re-synchronize a stream
/// with a player that play from a Dart Stream
/// @nodoc
@Deprecated('Don\'t use anymore Food, but directely your buffers')
class FoodEvent extends Food {
  /// The callback to fire when this food is synchronized with the player
  Function on;

  /// The constructor, specifying the callback which must be fired when synchronization is done
  /* ctor */
  FoodEvent(this.on);

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
  Logger logger = Logger(level: Level.debug);

  /// The FlutterSound Logger getter
  //Logger get logger => _logger;

  /// The FlutterSound Logger setter
  //set logger(Logger aLogger) {
  //  _logger = aLogger;
  //  // TODO
  // Here we must call flutter_sound_core if necessary
  //}

  // ---------------------------------------------------------------------------------------------------------------------

  /// the static Singleton
  static final FlutterSound _singleton = FlutterSound._internal();

  /// The factory which returns the Singleton
  factory FlutterSound() {
    return _singleton;
  }

  /// Private constructor of the Singleton
  /* ctor */
  FlutterSound._internal();

  /// This instance of [FlutterSoundPlayer] is just to be smart for the App.
  /// The Apps can use this instance without having to create a [FlutterSoundPlayer] themselves.
  FlutterSoundPlayer thePlayer = FlutterSoundPlayer();

  /// TODO
  void internalOpenSessionForRecording() {
    //todo
  }

  // ----------------------------------------------------------------------------------------------------------------------
}
