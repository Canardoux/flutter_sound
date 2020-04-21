/*
 * This file is part of Flutter-Sound (Flauto).
 *
 *   Flutter-Sound (Flauto) is free software: you can redistribute it and/or modify
 *   it under the terms of the Lesser GNU General Public License
 *   version 3 (LGPL3) as published by the Free Software Foundation.
 *
 *   Flutter-Sound (Flauto) is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the Lesser GNU General Public License
 *   along with Flutter-Sound (Flauto).  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:async';
import 'dart:typed_data' show Uint8List;

import 'package:flutter/foundation.dart';

import 'audio_session.dart';
import 'codec.dart';
import 'track.dart';

/// Provides the ability to playback audio from
/// a variety of sources including:
/// File
/// Buffer
/// Assets
/// URL.
class SoundPlayer {
  AudioSession _session;
  Track _track;

  /// Creates a SoundPlayer from a Track.
  /// Use the [play] method to play the track
  /// The [session] controls how the track is played.
  /// By default the player is created to play without a UI.
  /// Pass [AudioSession.withUI] to [session] to play the
  /// audio using the OS' audio player.
  /// see [Playbar] to present the user with a Widget based UI.
  SoundPlayer.fromTrack(this._track, {AudioSession session}) {
    _session = session ?? AudioSession.noUI();
  }

  /// The [uri] of the file to download and playback
  /// The [codec] of the file the [uri] points to. The default
  /// value is [Codec.fromExtension].
  /// If the default [Codec.fromExtension] is used then
  /// [SoundPlayer] will use the files extension to guess the codec.
  /// If the file extension doesn't match a known codec then
  /// [SoundPlayer] will throw an [CodecNotSupportedException] in which
  /// case you need pass one of the known codecs.
  ///
  SoundPlayer.fromPath(String uri,
      {Codec codec = Codec.fromExtension, AudioSession session}) {
    _session = session ?? AudioSession.noUI();

    _track = Track.fromPath(uri, codec: codec);
  }

  /// Create a audio play from an in memory buffer.
  /// The [dataBuffer] contains the media to be played.
  /// The [codec] of the file the [dataBuffer] points to.
  /// You MUST pass a codec.
  SoundPlayer.fromBuffer(Uint8List dataBuffer,
      {@required Codec codec, AudioSession session}) {
    _session = session ?? AudioSession.noUI();
    _track = Track.fromBuffer(dataBuffer, codec: codec);
  }

  /// call this method once you are down with the player
  /// so that it can release all of the attached resources.
  Future<void> release() async => _session.release();

  /// Starts playback.

  Future<void> play() async => _session.play(_track);

  /// Stops playback.
  Future<void> stop() async => _session.stop();

  /// Pauses playback.
  /// If you call this and the audio is not playing
  /// a [PlayerInvalidStateException] will be thrown.
  Future<void> pause() async => _session.pause();

  /// Resumes playback.
  /// If you call this when audio is not paused
  /// then a [PlayerInvalidStateException] will be thrown.
  Future<void> resume() async => _session.resume();

  /// Moves the current playback position to the given offset in the
  /// recording.
  /// [position] is the position in the recording to set the playback
  /// location from.
  /// You may call this before [play] or whilst the audio is playing.
  /// If you call [seekTo] before calling [play] then when you call
  /// [play] we will start playing the recording from the [position]
  /// passed to [seekTo].
  Future<void> seekTo(Duration position) async => _session.seekTo(position);

  /// Sets the playback volume
  /// The [volume] must be in the range 0.0 to 1.0.
  Future<void> setVolume(double volume) async => _session.setVolume(volume);

  /// [true] if the player is currently playing audio
  bool get isPlaying => _session.isPlaying;

  /// [true] if the player is playing but the audio is paused
  bool get isPaused => _session.isPaused;

  /// [true] if the player is stopped.
  bool get isStopped => _session.isStopped;

  /// Instructs the OS to reduce the volume of other audio
  /// whilst we play this audio file.
  /// The exact effect of this is OS dependant.
  /// The effect is only applied when we start the audio play.
  /// Changing this value whilst audio is play will have no affect.
  bool get hushOthers => _session.hushOthers;

  /// Instructs the OS to reduce the volume of other audio
  /// whilst we play this audio file.
  /// The exact effect of this is OS dependant.
  /// The effect is only applied when we start the audio play.
  /// Changing this value whilst audio is play will have no affect.
  set hushOthers(bool hushOthers) {
    _session.hushOthers = hushOthers;
  }

  /// Pass a callback if you want to be notified when
  /// a track finishes to completion.
  /// see [onStopped] for events when the user or system stops playback.
  // ignore: avoid_setters_without_getters
  set onFinished(PlayerEvent onFinished) {
    _session.onFinished = onFinished;
  }

  ///
  /// Pass a callback if you want to be notified when
  /// playback is paused.
  /// The [wasUser] argument in the callback will
  /// be true if the user clicked the pause button
  /// on the OS UI.
  ///
  /// [wasUser] will be false if you paused the audio
  /// via a call to [pause].
  // ignore: avoid_setters_without_getters
  set onPaused(PlayerEventWithCause onPaused) {
    _session.onPaused = onPaused;
  }

  ///
  /// Pass a callback if you want to be notified when
  /// playback is resumed.
  /// The [wasUser] argument in the callback will
  /// be true if the user clicked the resume button
  /// on the OS UI.
  ///
  /// [wasUser] will be false if you resumed the audio
  /// via a call to [resume].
  // ignore: avoid_setters_without_getters
  set onResumed(PlayerEventWithCause onResumed) {
    _session.onResumed = onResumed;
  }

  /// Pass a callback if you want to be notified
  /// that audio has started playing.
  ///
  /// If the player has to download or transcribe
  /// the audio then this method won't return
  /// util the audio actually starts to play.
  ///
  /// This can occur if you called [play]
  /// or the user click the start button on the
  /// OS UI.
  // ignore: avoid_setters_without_getters
  set onStarted(PlayerEventWithCause onStarted) {
    _session.onStarted = onStarted;
  }

  /// Pass a callback if you want to be notified
  /// that audio has stopped playing.
  /// This is different from [onFinished] which
  /// is called when the auido plays to completion.
  ///
  /// [onStoppped]  can occur if you called [stop]
  /// or the user click the stop button on the

  // ignore: avoid_setters_without_getters
  set onStopped(PlayerEventWithCause onStopped) {
    _session.onStopped = onStopped;
  }
}
