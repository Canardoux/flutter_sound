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
 * The purpose of this module is to offer higher level functionnalities, using MediaService/MediaBrowser.
 * This module may use flutter_sound module, but flutter_sound module may not depends on this module.
 */

import 'dart:async';
import 'dart:core';
import 'dart:io';
import 'dart:io' show Platform;
import 'dart:typed_data' show Uint8List;

import 'flutter_sound_player.dart';
import 'package:path_provider/path_provider.dart';

import 'src/flauto.dart';
import 'src/track_player_plugin.dart';

TrackPlayerPlugin trackPlayerPlugin; // Singleton, lazy initialized

class TrackPlayer extends FlutterSoundPlayer {
  //static const MethodChannel _channel = const MethodChannel( 'xyz.canardoux.track_player' );
  //StreamController<t_PLAYER_STATE> _playbackStateChangedController;
  TonSkip onSkipForward; // User callback "whenPaused:"
  TonSkip onSkipBackward; // User callback "whenPaused:"

  @override
  TrackPlayer();

  TrackPlayerPlugin getPlugin() => trackPlayerPlugin;

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
    if (!isInited) {
      isInited = true;

      if (trackPlayerPlugin == null) {
        trackPlayerPlugin = TrackPlayerPlugin(); // The lazy singleton
      }
      slotNo = getPlugin().lookupEmptyTrackPlayerSlot(this);

      try {
        await invokeMethod('initializeMediaPlayer', <String, dynamic>{});
        onSkipBackward = null;
        onSkipForward = null;

        // Add the method call handler
        //getChannel( ).setMethodCallHandler( channelMethodCallHandler );
      } catch (err) {
        rethrow;
      }
    }
    return this;
  }

  /// Resets the media player and cleans up the device resources. This must be
  /// called when the player is no longer needed.
  Future<void> release() async {
    if (isInited) {
      try {
        isInited = false;
        // Stop the player playback before releasing
        await stopPlayer();
        await invokeMethod('releaseMediaPlayer', <String, dynamic>{});

        removePlayerCallback(); // playerController is closed by this function

        //playerController?.close();

        onSkipBackward = null;
        onSkipForward = null;
      } catch (err) {
        print('err: $err');
        rethrow;
      }
      getPlugin().freeSlot(slotNo);
      slotNo = null;
    }
  }

  void skipForward(Map call) {
    if (onSkipForward != null) onSkipForward();
  }

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

    await track._adaptOggToIos();

    final trackMap = await track.toMap();

    audioPlayerFinishedPlaying = whenFinished;
    this.whenPause = whenPaused;
    this.onSkipForward = onSkipForward;
    this.onSkipBackward = onSkipBackward;
    setPlayerCallback();
    String result =
        await invokeMethod('startPlayerFromTrack', <String, dynamic>{
      'track': trackMap,
      'canPause': whenPaused != null,
      'canSkipForward': onSkipForward != null,
      'canSkipBackward': onSkipBackward != null,
    }) as String;

    if (result != null) {
      print('startPlayer result: $result');

      playerState = PlayerState.IS_PLAYING;
    }
    return result;
  }

  /// Plays the file that [fileUri] points to.
  Future<String> startPlayer(
    String fileUri, {
    Codec codec,
    TWhenFinished whenFinished,
  }) {
    initialize();
    final track = Track(trackPath: fileUri, codec: codec);
    return startPlayerFromTrack(track, whenFinished: whenFinished);
  }

  /// Plays the audio file in [buffer] decoded according to [codec].
  Future<String> startPlayerFromBuffer(
    Uint8List dataBuffer, {
    Codec codec,
    TWhenFinished whenFinished,
  }) {
    initialize();
    final track = Track(dataBuffer: dataBuffer, codec: codec);
    return startPlayerFromTrack(track, whenFinished: whenFinished);
  }
}

class PlayerNotInitializedException implements Exception {
  final String message;

  PlayerNotInitializedException(this.message);
}

/// The track to play in the audio player
class Track {
  /// The title of this track
  final String trackTitle;

  /// The buffer containing the audio file to play
  final Uint8List dataBuffer;

  /// The name of the author of this track
  final String trackAuthor;

  /// The path that points to the track audio file
  String trackPath;

  /// The URL that points to the album art of the track
  final String albumArtUrl;

  /// The asset that points to the album art of the track
  final String albumArtAsset;

  /// The image that points to the album art of the track
  //final String albumArtImage;

  /// The codec of the audio file to play. If this parameter's value is null
  /// it will be set to [Codec.DEFAULT].
  Codec codec;

  Track({
    this.trackPath,
    this.dataBuffer,
    this.trackTitle,
    this.trackAuthor,
    this.albumArtUrl,
    this.albumArtAsset,
    this.codec = Codec.DEFAULT,
  }) {
    codec = codec == null ? Codec.DEFAULT : codec;
    assert(trackPath != null || dataBuffer != null,
        'You should provide a path or a buffer for the audio content to play.');
    assert(
        (trackPath != null && dataBuffer == null) ||
            (trackPath == null && dataBuffer != null),
        'You cannot provide both a path and a buffer.');
  }

  /// Convert this object to a [Map] containing the properties of this object
  /// as values.
  Future<Map<String, dynamic>> toMap() async {
    final map = {
      "path": trackPath,
      "dataBuffer": dataBuffer,
      "title": trackTitle,
      "author": trackAuthor,
      "albumArtUrl": albumArtUrl,
      "albumArtAsset": albumArtAsset,
      "bufferCodecIndex": codec?.index,
    };

    return map;
  }

  Future<void> _adaptOggToIos() async {
    // If we want to play OGG/OPUS on iOS, we re-mux the OGG file format to a specific Apple CAF envelope before starting the player.
    // We use FFmpeg for that task.

    if ((Platform.isIOS) &&
        ((codec == Codec.CODEC_OPUS) ||
            (fileExtension(trackPath) == '.opus'))) {
      Directory tempDir = await getTemporaryDirectory();
      File fout = await File('${tempDir.path}/flutter_sound-tmp.caf');
      if (fout.existsSync()) {
        await fout.delete();
      }

      int rc;
      var inputFileName = trackPath;
      // The following ffmpeg instruction does not decode and re-encode the file.
      // It just remux the OPUS data into an Apple CAF envelope.
      // It is probably very fast and the user will not notice any delay,
      // even with a very large data.
      // This is the price to pay for the Apple stupidity.
      if (dataBuffer != null) {
        // Write the user buffer into the temporary file
        inputFileName = '${tempDir.path}/flutter_sound-tmp.opus';
        var fin = await File(inputFileName);
        fin.writeAsBytesSync(dataBuffer);
      }
      rc = await flutterSoundHelper.executeFFmpegWithArguments([
        '-y',
        '-loglevel',
        'error',
        '-i',
        inputFileName,
        '-c:a',
        'copy',
        fout.path,
      ]); // remux OGG to CAF
      if (rc != 0) {
        throw 'FFmpeg exited with code $rc';
      }
      // Now we can play Apple CAF/OPUS
      trackPath = fout.path;
    }
  }
}
