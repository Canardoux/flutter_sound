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

import 'dart:async';
import 'dart:typed_data' show Uint8List;

import 'package:flutter/foundation.dart';

import 'codec.dart';
import 'audio_player.dart';
import 'track.dart';

/// Provides the ability to playback a single
/// audio file from a variety of sources.
///  - Track
///  - File
///  - Buffer
///  - Assets
///  - URL.
///
/// The audio file plays to completion and then
/// resources are automatically cleanedup.
/// You have no control over the audio once it starts playing.
///
/// This is intended for playing short audio files.
///
/// ```dart
/// QuickPlay.fromPath('path to file);
///
/// QuickPlay.fromTrack(track, volume: 1.0, withUI: true);

class QuickPlay {
  AudioPlayer _player;
  Track _track;

  /// Creates a QuickPlay from a Track and immediately plays it.
  /// By default no UI is displayed.
  /// If you pass [withUI]=true then the OSs' media player is displayed
  /// but all of the UI controls are disabled.
  /// You can control the playback [volume]. The valid range is 0.0 to 1.0
  /// and the default is 0.5.
  QuickPlay.fromTrack(this._track, {double volume, bool withUI = false}) {
    QuickPlay._internal(volume, withUI);
  }

  QuickPlay._internal(double volume, bool withUI) {
    if (withUI) {
      _player = AudioPlayer.withUI(
          canPause: false, canSkipBackward: false, canSkipForward: false);
    } else {
      _player = AudioPlayer.noUI();
    }

    volume ??= 0.5;

    _play(volume);
  }

  /// Plays audio from a local file path such as an asset.
  ///
  /// The [path] of the file to play.
  ///
  /// An [TrackFileMustExistException] exception will be thrown
  /// if the file doesn't exist.
  ///
  /// The [codec] of the file the [path] points to. The default
  /// value is [Codec.fromExtension].
  /// If the default [Codec.fromExtension] is used then
  /// [QuickPlay] will use the files extension to guess the codec.
  /// If the file extension doesn't match a known codec then
  /// [QuickPlay] will throw an [CodecNotSupportedException] in which
  /// case you need pass one of the known codecs.
  ///
  /// By default no UI is displayed.
  ///
  /// If you pass [withUI]=true then the OSs' media player is displayed
  /// but all of the UI controls are disabled.
  ///
  /// The [volume] must be in the range 0.0 to 1.0. Defaults to 0.5
  QuickPlay.fromPath(String path,
      {double volume, Codec codec = Codec.fromExtension, bool withUI = false}) {
    _track = Track.fromPath(path, codec: codec);
    QuickPlay._internal(volume, withUI);
  }

  /// Allows you to play an audio file stored at a givenURL.
  ///  Both HTTP and HTTPS are supported.
  /// The [url] of the file to download and playback
  ///
  /// The [codec] of the file the [url] points to. The default
  /// value is [Codec.fromExtension].
  /// If the default [Codec.fromExtension] is used then
  /// [QuickPlay] will use the files extension to guess the codec.
  /// If the file extension doesn't match a known codec then
  /// [QuickPlay] will throw an [CodecNotSupportedException] in which
  /// case you need pass one of the known codecs.
  /// By default no UI is displayed.
  ///
  /// If you pass [withUI]=true then the OSs' media player is displayed
  /// but all of the UI controls are disabled.
  ///
  /// The [volume] must be in the range 0.0 to 1.0. Defaults to 0.5
  QuickPlay.fromURL(String url,
      {double volume, Codec codec = Codec.fromExtension, bool withUI = false}) {
    _track = Track.fromURL(url, codec: codec);
    QuickPlay._internal(volume, withUI);
  }

  /// Create a audio play from an in memory buffer.
  /// The [dataBuffer] contains the media to be played.
  /// The [codec] of the file the [dataBuffer] points to.
  /// You MUST pass a codec.
  /// By default no UI is displayed.
  /// If you pass [withUI]=true then the OSs' media player is displayed
  /// but all of the UI controls are disabled.
  /// The [volume] must be in the range 0.0 to 1.0. Defaults to 0.5
  QuickPlay.fromBuffer(Uint8List dataBuffer,
      {double volume, @required Codec codec, bool withUI = false}) {
    _track = Track.fromBuffer(dataBuffer, codec: codec);
    QuickPlay._internal(volume, withUI);
  }

  /// Starts playback.

  Future<void> _play(double volume) async {
    _player.setVolume(volume);
    _player.hushOthers = true;
    _player.onFinished = () => _player.release();
    _player.onStopped = ({wasUser}) => _player.release();
    return _player.play(_track);
  }
}
