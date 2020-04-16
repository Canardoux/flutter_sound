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

/*
 * The purpose of this module is to offer higher level functionnalities, 
 * using MediaService/MediaBrowser.
 * This module may use flutter_sound module, but flutter_sound module
 *  may not depends on this module.
 */

import 'dart:async';
import 'dart:core';
import 'dart:typed_data' show Uint8List;

import 'codec.dart';
import 'flutter_sound_player.dart';
import 'plugins/track_player_plugin.dart';
import 'track.dart';

///
class TrackPlayer extends FlutterSoundPlayer {
  //static const MethodChannel _channel
  // = const MethodChannel( 'xyz.canardoux.track_player' );
  //StreamController<t_PLAYER_STATE> _playbackStateChangedController;
  ///
  TonSkip onSkipForward; // User callback "whenPaused:"
  ///
  TonSkip onSkipBackward; // User callback "whenPaused:"

  bool _isInited = false;

  TrackPlayerPlugin getPlugin() => TrackPlayerPlugin();

  Future<dynamic> invokeMethod(
      String methodName, Map<String, dynamic> call) async {
    call['slotNo'] = slotNo;
    dynamic r = await getPlugin().invokeMethod(methodName, call);
    return r;
  }

  /// Initializes the media player and all the callbacks for the player and the
  /// recorder. This must be called before all other media player and recorder
  /// methods.
  ///
  /// If [includeAudioPlayerFeatures] is true, the audio player specific
  /// features will be included (eg. playback handling via hardware buttons,
  /// lock screen controls). If you initialized the media player with the
  /// audio player features, but you don't want them anymore, you must
  /// re-initialize it. Do the same if you initialized the media player without
  /// the audio player features, but you need them now.
  ///
  /// [skipForwardHandler] and [skipBackwardForward] are functions that are
  /// called when the user tries to skip forward or backward using the
  /// notification controls. They can be null.
  ///
  /// Media player and recorder controls should be displayed only after this
  /// method has finished executing.
  Future<TrackPlayer> initialize() async {
    if (!_isInited) {
      _isInited = true;

      slotNo =
          getPlugin().lookupEmptyTrackPlayerSlot(PlayerPluginConnector(this));

      try {
        await invokeMethod('initializeMediaPlayer', <String, dynamic>{});
        onSkipBackward = null;
        onSkipForward = null;

        // Add the method call handler
        //getChannel( ).setMethodCallHandler( channelMethodCallHandler );
      } on Object catch (_) {
        rethrow;
      }
    }
    return this;
  }

  /// Resets the media player and cleans up the device resources. This must be
  /// called when the player is no longer needed.
  Future<void> release() async {
    if (_isInited) {
      try {
        _isInited = false;
        // Stop the player playback before releasing
        await stopPlayer();
        await invokeMethod('releaseMediaPlayer', <String, dynamic>{});

        removePlayerCallback(); // playerController is closed by this function

        //playerController?.close();

        onSkipBackward = null;
        onSkipForward = null;
      } on Object catch (err) {
        print('err: $err');
        rethrow;
      }
      getPlugin().freeSlot(slotNo);
      slotNo = null;
    }
  }

  ///
  void skipForward(Map call) {
    if (onSkipForward != null) onSkipForward();
  }

  ///
  void skipBackward(Map call) {
    if (onSkipBackward != null) onSkipBackward();
  }

  /// Plays the given [track]. [canSkipForward] and [canSkipBackward] must be
  /// passed to provide information on whether the user can skip to the next
  /// or to the previous song in the lock screen controls.
  ///
  /// This method should only be used if the   player has been initialize
  /// with the audio player specific features.
  Future<String> startPlayerFromTrack(
    Track track, {
    Codec codec,
    TWhenFinished whenFinished,
    TwhenPaused whenPaused,
    TonSkip onSkipForward,
    TonSkip onSkipBackward,
  }) async {
    // Check the current codec is supported on this platform
    if (!await isDecoderSupported(track.codec)) {
      throw PlayerRunningException('The selected codec is not supported on '
          'this platform.');
    }
    await initialize();

    await track.adaptOggToIos();

    final trackMap = await track.toMap();

    audioPlayerFinishedPlaying = whenFinished;
    this.whenPaused = whenPaused;
    this.onSkipForward = onSkipForward;
    this.onSkipBackward = onSkipBackward;
    var result = await invokeMethod('startPlayerFromTrack', <String, dynamic>{
      'track': trackMap,
      'canPause': whenPaused != null,
      'canSkipForward': onSkipForward != null,
      'canSkipBackward': onSkipBackward != null,
    }) as String;

    if (result != null) {
      print('startPlayer result: $result');

      playerState = PlayerState.isPlaying;
    }
    return result;
  }

  /// Plays the file that [fileUri] points to.
  Future<String> startPlayer(
    String fileUri, {
    Codec codec,
    TWhenFinished whenFinished,
  }) async {
    await initialize();
    final track = Track(trackPath: fileUri, codec: codec);
    return startPlayerFromTrack(track, whenFinished: whenFinished);
  }

  /// Plays the audio file in [buffer] decoded according to [codec].
  Future<String> startPlayerFromBuffer(
    Uint8List dataBuffer, {
    Codec codec,
    TWhenFinished whenFinished,
  }) async {
    await initialize();
    final track = Track(dataBuffer: dataBuffer, codec: codec);
    return startPlayerFromTrack(track, whenFinished: whenFinished);
  }
}
