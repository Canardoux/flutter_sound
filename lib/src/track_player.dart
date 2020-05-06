/*
 * This file is part of Flutter-Sound.
 *
 *   Flutter-Sound is free software: you can redistribute it and/or modify
 *   it under the terms of the Lesser GNU General Public License
 *   version 3 (LGPL-3) as published by the Free Software Foundation.
 *
 *   Flutter-Sound is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the Lesser GNU General Public License
 *   along with Flutter-Sound.  If not, see <https://www.gnu.org/licenses/>.
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
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';

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
  Future<TrackPlayer> openAudioSession() async {
    if (isInited == Initialized.fullyInitialized) {
      return this;
    }
    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }

    isInited = Initialized.initializationInProgress;

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
    isInited = Initialized.fullyInitialized;
    return this;
  }

  /// Resets the media player and cleans up the device resources. This must be
  /// called when the player is no longer needed.
  Future<void> closeAudioSession() async {
    if (isInited == Initialized.notInitialized) {
      return this;
    }
    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    isInited = Initialized.initializationInProgress;
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
    isInited = Initialized.notInitialized;
  }

  void skipForward(Map call) {
    if (onSkipForward != null) onSkipForward();
  }

  void skipBackward(Map call) {
    if (onSkipBackward != null) onSkipBackward();
  }

  void pause(Map call) {
    bool b = call['arg'] as bool;
    if (onPaused != null) {
      // Probably always true
      onPaused(b);
    } else {
      if (b)
        pausePlayer();
      else
        resumePlayer();
    }
  }

  void audioPlayerFinished(Map call) {
    String args = call['arg'] as String;
    Map<String, dynamic> result = jsonDecode(args) as Map<String, dynamic>;
    PlayStatus status = PlayStatus.fromJSON(result);

    if (status.currentPosition != status.duration) {
      status.currentPosition = status.duration;
    }

    if (playerController != null) {
      playerController.add(status);
    }

    playerState = PlayerState.isStopped;
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
    //FlutterSoundCodec codec,
    TWhenFinished whenFinished,
    TonPaused onPaused,
    TonSkip onSkipForward,
    TonSkip onSkipBackward,
    //TonSkip onPause,
  }) async {
    // Check the current codec is not supported on this platform
    await openAudioSession();
    if (!await isDecoderSupported(track.codec)) {
      throw PlayerRunningException('The selected codec is not supported on '
          'this platform.');
    }

    if (needToConvert(track.codec)) {
      await _convertAudio(track);
    }
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
    await openAudioSession();
    final track = Track(trackPath: fileUri, codec: codec);
    return await startPlayerFromTrack(track, whenFinished: whenFinished);
  }

  /// Plays the audio file in [buffer] decoded according to [codec].
  Future<String> startPlayerFromBuffer(
    Uint8List dataBuffer, {
    Codec codec,
    TWhenFinished whenFinished,
  }) async {
    await openAudioSession();
    final track = Track(dataBuffer: dataBuffer, codec: codec);
    return await startPlayerFromTrack(track, whenFinished: whenFinished);
  }

  void _removePlayerCallback() {
    if (playerController != null) {
      playerController
        //..add(null)
        ..close();
      playerController = null;
    }
  }

  Future<void> _convertAudio(Track track) async {
    if (track.dataBuffer != null) {
      var tempDir = await getTemporaryDirectory();
      File inputFile = File('${tempDir.path}/$slotNo-flutter_sound-tmp');

      if (inputFile.existsSync()) {
        await inputFile.delete();
      }
      inputFile.writeAsBytesSync(
          track.dataBuffer); // Write the user buffer into the temporary file
      track.dataBuffer = null;
      track.trackPath = inputFile.path;
    }

    // If we want to play OGG/OPUS on iOS, we remux the OGG file format to a specific Apple CAF envelope before starting the player.
    // We use FFmpeg for that task.
    var tempDir = await getTemporaryDirectory();
    Codec codec = track.codec;
    Codec convert = (Platform.isIOS)
        ? FlutterSoundPlayer.tabIosConvert[codec.index]
        : FlutterSoundPlayer.tabAndroidConvert[codec.index];
    String fout =
        '${tempDir.path}/$slotNo-flutter_sound-tmp2${ext[convert.index]}';
    String path = track.trackPath;
    await flutterSoundHelper.convertFile(path, codec, fout, convert);

    track.trackPath =
        fout; // This is not good : here we modify the Track provided by the app
    track.codec =
        convert; // This is not good : here we modify the Track provided by the app
  }
}

/// The track to play in the audio player
class Track {
  /// The title of this track
  final String trackTitle;

  /// The buffer containing the audio file to play
  Uint8List dataBuffer;

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
  Codec codec;

  Track({
    this.trackPath,
    this.dataBuffer,
    this.trackTitle,
    this.trackAuthor,
    this.albumArtUrl,
    this.albumArtAsset,
    this.albumArtFile,
    this.codec = Codec.defaultCodec,
  }) {
    codec = codec == null ? Codec.defaultCodec : codec;
    assert(trackPath != null || dataBuffer != null,
        'You should provide a path or a buffer for the audio content to play.');
    assert(
        (trackPath != null && dataBuffer == null) ||
            (trackPath == null && dataBuffer != null),
        'You cannot provide both a path and a buffer.');
  }

  /// Convert this object to a [Map] containing the properties of this object
  /// as values.
  Map<String, dynamic> toMap() {
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
}

class _InitializationInProgress implements Exception {
  _InitializationInProgress() {
    print('An initialization is currently already in progress.');
  }
}
