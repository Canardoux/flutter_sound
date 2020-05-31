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
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:io' show Platform;
import 'dart:typed_data' show Uint8List;

import 'package:flutter/services.dart';
import 'flutter_sound_player.dart';
import 'flauto.dart';
import 'package:path_provider/path_provider.dart';

TrackPlayerPlugin trackPlayerPlugin; // Singleton, lazy initialized

class TrackPlayerPlugin extends FlautoPlayerPlugin {
  MethodChannel channel;

  //List<TrackPlayer> trackPlayerSlots = [];
  TrackPlayerPlugin() {
    setCallback();
  }

  void setCallback() {
    channel = const MethodChannel('com.dooboolab.flutter_sound_track_player');
    channel.setMethodCallHandler((MethodCall call) {
      // This lambda function is necessary because channelMethodCallHandler
      // is a virtual function (polymorphism)
      return channelMethodCallHandler(call);
    });
  }

  int lookupEmptyTrackPlayerSlot(TrackPlayer aTrackPlayer) {
    for (int i = 0; i < slots.length; ++i) {
      if (slots[i] == null) {
        slots[i] = aTrackPlayer;
        return i;
      }
    }
    slots.add(aTrackPlayer);
    return slots.length - 1;
  }

  void freeSlot(int slotNo) {
    slots[slotNo] = null;
  }

  MethodChannel getChannel() => channel;

  Future<dynamic> invokeMethod(String methodName, Map<String, dynamic> call) {
    return getChannel().invokeMethod<dynamic>(methodName, call);
  }

  Future<dynamic> channelMethodCallHandler(MethodCall call) {
    int slotNo = call.arguments['slotNo'] as int;
    TrackPlayer aTrackPlayer = slots[slotNo] as TrackPlayer;
    // for the methods that don't have return values
    // we still need to return a future.
    Future<dynamic> result = Future<dynamic>.value(null);
    switch (call.method) {
      case 'audioPlayerFinishedPlaying':
        {
           aTrackPlayer.audioPlayerFinished(call.arguments as Map);
        }
        break;

      case 'skipForward':
        {
          aTrackPlayer.skipForward(call.arguments as Map);
        }
        break;

      case 'skipBackward':
        {
          aTrackPlayer.skipBackward(call.arguments as Map);
        }
        break;

      case 'pause':
        {
          aTrackPlayer.pause(call.arguments as Map);
        }
        break;

      default:
        result = super.channelMethodCallHandler(call);
    }

    return result;
  }
}

class TrackPlayer extends FlutterSoundPlayer {
  TonSkip onSkipForward; // User callback "onPaused:"
  TonSkip onSkipBackward; // User callback "onPaused:"
  TonPaused onPaused; // user callback "whenPause:"

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
    if (isInited == t_INITIALIZED.FULLY_INITIALIZED) {
      return this;
    }
    if (isInited == t_INITIALIZED.INITIALIZATION_IN_PROGRESS) {
      throw(InitializationInProgress());
    }

    isInited = t_INITIALIZED.INITIALIZATION_IN_PROGRESS;

    if (trackPlayerPlugin == null) {
        trackPlayerPlugin = TrackPlayerPlugin(); // The lazy singleton
      }
      slotNo = getPlugin().lookupEmptyTrackPlayerSlot(this);

      try {
        await invokeMethod('initializeMediaPlayer', <String, dynamic>{});
        onSkipBackward = null;
        onSkipForward = null;
        onPaused = null;

        // Add the method call handler
        //getChannel( ).setMethodCallHandler( channelMethodCallHandler );
      } catch (err) {
        rethrow;
      }
    isInited = t_INITIALIZED.FULLY_INITIALIZED;
    return this;
  }

  /// Resets the media player and cleans up the device resources. This must be
  /// called when the player is no longer needed.
  Future<void> release() async {
    if (isInited == t_INITIALIZED.NOT_INITIALIZED) {
      return this;
    }
    if (isInited == t_INITIALIZED.INITIALIZATION_IN_PROGRESS) {
      throw(InitializationInProgress());
    }
    isInited = t_INITIALIZED.INITIALIZATION_IN_PROGRESS;
    try {
        // Stop the player playback before releasing
        await stopPlayer();
        await invokeMethod('releaseMediaPlayer', <String, dynamic>{});

        _removePlayerCallback(); // playerController is closed by this function

        //playerController?.close();

        onSkipBackward = null;
        onSkipForward = null;
        onPaused = null;
      } catch (err) {
        print('err: $err');
        rethrow;
      }
      getPlugin().freeSlot(slotNo);
      slotNo = null;
    isInited = t_INITIALIZED.NOT_INITIALIZED;
  }

  void skipForward(Map call) {
    if (onSkipForward != null) onSkipForward();
  }

  void skipBackward(Map call) {
    if (onSkipBackward != null) onSkipBackward();
  }

  void pause(Map call) {
    bool b = call['arg'] as bool;
    if (onPaused != null) { // Probably always true
      onPaused( b );
    } else {
      if (b)
        pausePlayer();
      else
        resumePlayer();
    }
  }

  void audioPlayerFinished(Map call) {
    String args = call['arg'] as String;
    Map<String, dynamic> result =
    jsonDecode(args) as Map<String, dynamic>;
    PlayStatus status = PlayStatus.fromJSON(result);

    if (status.currentPosition != status.duration) {
      status.currentPosition = status.duration;
    }

    if (playerController != null) {
      playerController.add(status);
    }

    playerState = t_PLAYER_STATE.IS_STOPPED;
    if (audioPlayerFinishedPlaying != null) {
      audioPlayerFinishedPlaying();
      audioPlayerFinishedPlaying = null;
    }
    _removePlayerCallback(); // playerController is closed by this function
  }

  /// Plays the given [track]. [onPaused], [canSkipForward] and [canSkipBackward] must be
  /// passed to provide information on whether the user can handle the pause button, skip to the next
  /// or to the previous song in the lock screen controls.
  ///
  /// This method should only be used if the   player has been initialize
  /// with the audio player specific features.
  Future<String> startPlayerFromTrack(
    Track track, {
    t_CODEC codec,
    TWhenFinished whenFinished,
    TonPaused onPaused,
    TonSkip onSkipForward,
    TonSkip onSkipBackward,
    //TonSkip onPause,
  }) async {
    // Check the current codec is not supported on this platform
    await initialize();
    if (!await isDecoderSupported(track.codec)) {
      throw PlayerRunningException('The selected codec is not supported on '
          'this platform.');
    }
    playerState = t_PLAYER_STATE.IS_PLAYING;
    await track._adaptOggToIos();
    if (playerState != t_PLAYER_STATE.IS_PLAYING) return null; // Patch [LARPOUX] to handle the case where the App did a stopPlayer()

    final trackMap = await track.toMap();

    audioPlayerFinishedPlaying = whenFinished;
    this.onPaused = onPaused;
    this.onSkipForward = onSkipForward;
    this.onSkipBackward = onSkipBackward;
    this.onUpdateProgress = onUpdateProgress;
    setPlayerCallback();
    String result =
        await invokeMethod('startPlayerFromTrack', <String, dynamic>{
      'track': trackMap,
      'canPause': onPaused != null,
      'canSkipForward': onSkipForward != null,
      'canSkipBackward': onSkipBackward != null,
    }) as String;

    if (result != null) {
      print('startPlayer result: $result');

      }
    return result;
  }

  /// Plays the file that [fileUri] points to.
  Future<String> startPlayer(
    String fileUri, {
    t_CODEC codec,
    TWhenFinished whenFinished,
  }) async {
    await initialize();
    final track = Track(trackPath: fileUri, codec: codec);
    return await startPlayerFromTrack(track, whenFinished: whenFinished);
  }

  Future<void> setUIProgressBar ( {
    Duration duration,
    Duration progress,
  }) async {
  return invokeMethod('setUIProgressBar', <String, dynamic>{'duration': duration.inMilliseconds, 'progress': progress.inMilliseconds});
  }

  /// Plays the audio file in [buffer] decoded according to [codec].
  Future<String> startPlayerFromBuffer(
    Uint8List dataBuffer, {
    t_CODEC codec,
    TWhenFinished whenFinished,
  }) async {
    await initialize();
    final track = Track(dataBuffer: dataBuffer, codec: codec);
    return await startPlayerFromTrack(track, whenFinished: whenFinished);
  }

  void _removePlayerCallback() {
    if (playerController != null) {
      playerController
        ..add(null)
        ..close();
      playerController = null;
    }
  }
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

  /// The file that points to the album art of the track
  final String albumArtFile;

  /// The image that points to the album art of the track
  //final String albumArtImage;

  /// The codec of the audio file to play. If this parameter's value is null
  /// it will be set to [t_CODEC.DEFAULT].
  t_CODEC codec;

  Track({
    this.trackPath,
    this.dataBuffer,
    this.trackTitle,
    this.trackAuthor,
    this.albumArtUrl,
    this.albumArtAsset,
    this.albumArtFile,
    this.codec = t_CODEC.DEFAULT,
  }) {
    codec = codec == null ? t_CODEC.DEFAULT : codec;
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
      "albumArtFile": albumArtFile,
      "bufferCodecIndex": codec?.index,
    };

    return map;
  }

  Future<void> _adaptOggToIos() async {
    // If we want to play OGG/OPUS on iOS, we re-mux the OGG file format to a specific Apple CAF envelope before starting the player.
    // We use FFmpeg for that task.

    if ((Platform.isIOS) &&
        ((codec == t_CODEC.CODEC_OPUS) ||
            (fileExtension(trackPath) == '.opus'))) {
      var tempDir = await getTemporaryDirectory();
      var fout = await File('${tempDir.path}/flutter_sound-tmp.caf');
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
