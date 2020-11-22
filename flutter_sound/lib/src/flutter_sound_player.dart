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

/// Toto et titi
library flutter_sound;

import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:io' show Platform;
import 'dart:typed_data' show Uint8List;
import 'package:synchronized/synchronized.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_platform_interface.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_player_platform_interface.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../flutter_sound.dart';

///
const blockSize = 4096;

///
enum PlayerState {
  /// Player is stopped
  isStopped,

  /// Player is playing
  isPlaying,

  /// Player is paused
  isPaused,
}

///
typedef TWhenFinished = void Function();

///
typedef TonPaused = void Function(bool paused);

///
typedef TonSkip = void Function();

/// Return the file extension for the given path.
/// path can be null. We return null in this case.
String fileExtension(String path) {
  if (path == null) return null;
  var r = p.extension(path);
  return r;
}

//--------------------------------------------------------------------------------------------------------------------------------------------

///
class FlutterSoundPlayer implements FlutterSoundPlayerCallback {
  ///
  TonSkip onSkipForward; // User callback "onPaused:"
  ///
  TonSkip onSkipBackward; // User callback "onPaused:"
  ///
  TonPaused onPaused; // user callback "whenPause:"
  final _lock = Lock();

  ///
  StreamSubscription<Food> foodStreamSubscription;

  ///
  StreamController<Food> foodStreamController;

  ///
  Completer<int> needSomeFoodCompleter;

  ///
  Completer<FlutterSoundPlayer> openAudioSessionCompleter;

  ///
  Completer<Duration> startPlayerCompleter;

  ///
  static const List<Codec> tabAndroidConvert = [
    Codec.defaultCodec, // defaultCodec
    Codec.defaultCodec, // aacADTS
    Codec.defaultCodec, // opusOGG
    Codec.opusOGG, // opusCAF
    Codec.defaultCodec, // mp3
    Codec.defaultCodec, // vorbisOGG
    Codec.defaultCodec, // pcm16
    Codec.defaultCodec, // pcm16WAV
    Codec.pcm16WAV, // pcm16AIFF
    Codec.pcm16WAV, // pcm16CAF
    Codec.defaultCodec, // flac
    Codec.defaultCodec, // aacMP4
    Codec.defaultCodec, // amrNB
    Codec.defaultCodec, // amrWB
    Codec.defaultCodec, // pcm8
    Codec.defaultCodec, // pcmFloat32
    Codec.defaultCodec, // pcmWebM
    Codec.defaultCodec, // opusWebM
    Codec.defaultCodec, // vorbisWebM
  ];

  ///
  static const List<Codec> tabIosConvert = [
    Codec.defaultCodec, // defaultCodec
    Codec.defaultCodec, // aacADTS
    Codec.opusCAF, // opusOGG
    Codec.defaultCodec, // opusCAF
    Codec.defaultCodec, // mp3
    Codec.defaultCodec, // vorbisOGG
    Codec.defaultCodec, // pcm16
    Codec.defaultCodec, // pcm16WAV
    Codec.defaultCodec, // pcm16AIFF
    Codec.defaultCodec, // pcm16CAF
    Codec.defaultCodec, // flac
    Codec.defaultCodec, // aacMP4
    Codec.defaultCodec, // amrNB
    Codec.defaultCodec, // amrWB
    Codec.defaultCodec, // pcm8
    Codec.defaultCodec, // pcmFloat32
    Codec.defaultCodec, // pcmWebM
    Codec.defaultCodec, // opusWebM
    Codec.defaultCodec, // vorbisWebM
  ];

  ///
  static const List<Codec> tabWebConvert = [
    Codec.defaultCodec, // defaultCodec
    Codec.defaultCodec, // aacADTS
    Codec.defaultCodec, // opusOGG
    Codec.defaultCodec, // opusCAF
    Codec.defaultCodec, // mp3
    Codec.defaultCodec, // vorbisOGG
    Codec.defaultCodec, // pcm16
    Codec.defaultCodec, // pcm16WAV
    Codec.defaultCodec, // pcm16AIFF
    Codec.defaultCodec, // pcm16CAF
    Codec.defaultCodec, // flac
    Codec.defaultCodec, // aacMP4
    Codec.defaultCodec, // amrNB
    Codec.defaultCodec, // amrWB
    Codec.defaultCodec, // pcm8
    Codec.defaultCodec, // pcmFloat32
    Codec.defaultCodec, // pcmWebM
    Codec.defaultCodec, // opusWebM
    Codec.defaultCodec, // vorbisWebM
  ];

  //===================================  Callbacks ================================================================

  @override
  void updateProgress({
    int duration,
    int position,
  }) {
    if (duration < position) {
      print(' Duration = $duration,   Position = $position');
    }
    _playerController.add(
      PlaybackDisposition(
        position: Duration(milliseconds: position),
        duration: Duration(milliseconds: duration),
      ),
    );
  }

  @override
  void pause(int state) async {
    print('FS:---> pause ');
    await _lock.synchronized(() async {
      assert(state != null);
      playerState = PlayerState.values[state];
      if (onPaused != null) // Probably always true
      {
        onPaused(true);
      }
    });
    print('FS:<--- pause ');
  }

  @override
  void resume(int state) async {
    print('FS:---> pause ');
    await _lock.synchronized(() async {
      assert(state != null);
      playerState = PlayerState.values[state];
      if (onPaused != null) // Probably always true
      {
        onPaused(false);
      }
    });
    print('FS:<--- pause ');
  }

  @override
  void skipBackward(int state) async {
    print('FS:---> skipBackward ');
    await _lock.synchronized(() async {
      assert(state != null);
      playerState = PlayerState.values[state];

      if (onSkipBackward != null) {
        onSkipBackward();
      }
    });
    print('FS:<--- skipBackward ');
  }

  @override
  void skipForward(int state) async {
    print('FS:---> skipForward ');
    await _lock.synchronized(() async {
      assert(state != null);
      playerState = PlayerState.values[state];
      if (onSkipForward != null) {
        onSkipForward();
      }
    });
    print('FS:<--- skipForward ');
  }

  @override
  void updatePlaybackState(int state) {
    assert(state != null);
    playerState = PlayerState.values[state];
  }

  @override
  void needSomeFood(int ln) {
    assert(ln >= 0);
    if (needSomeFoodCompleter != null) {
      needSomeFoodCompleter.complete(ln);
    }
  }

  @override
  void audioPlayerFinished(int state) async {
    print('FS:---> audioPlayerFinished');
    await _lock.synchronized(() async {
      //playerState = PlayerState.isStopped;
      //int state = call['arg'] as int;
      assert(state != null);
      playerState = PlayerState.values[state];

      if (audioPlayerFinishedPlaying != null) {
        audioPlayerFinishedPlaying();
      }
    });
    print('FS:<--- audioPlayerFinished');
  }

  @override
  void openAudioSessionCompleted(bool success) {
    isInited =
        success ? Initialized.fullyInitialized : Initialized.notInitialized;
    if (success) {
      openAudioSessionCompleter.complete(this);
    } else {
      openAudioSessionCompleter.complete(null);
    }
  }

  @override
  void startPlayerCompleted(int duration) {
    startPlayerCompleter.complete(Duration(milliseconds: duration));
  }

  //===============================================================================================================

  ///
  Initialized isInited = Initialized.notInitialized;

  ///
  PlayerState playerState = PlayerState.isStopped;
  // The stream source
  StreamController<PlaybackDisposition> _playerController;

  ///
  StreamSink<Food> get foodSink =>
      foodStreamController != null ? foodStreamController.sink : null;

  ///
  Stream<PlaybackDisposition> get onProgress =>
      _playerController != null ? _playerController.stream : null;

  ///
  bool isOpen() {
    return (isInited == Initialized.fullyInitializedWithUI ||
        isInited == Initialized.fullyInitialized);
  }

  /// Provides a stream of dispositions which
  /// provide updated position and duration
  /// as the audio is played.
  /// The duration may start out as zero until the
  /// media becomes available.
  /// The `interval` dictates the minimum interval between events
  /// being sent to the stream.
  ///
  /// The minimum interval supported is 100ms.
  ///
  /// Note: the underlying stream has a minimum frequency of 100ms
  /// so multiples of 100ms will give you the most consistent timing
  /// source.
  ///
  /// Note: all calls to [dispositionStream] against this player will
  /// share a single interval which will controlled by the last
  /// call to this method.
  ///
  /// If you pause the audio then no updates will be sent to the
  /// stream.
  Stream<PlaybackDisposition> dispositionStream() {
    return _playerController != null ? _playerController.stream : null;
  }

  ///
  TWhenFinished audioPlayerFinishedPlaying; // User callback "whenFinished:"
  //TonPaused whenPause; // User callback "whenPaused:"
  //TupdateProgress onUpdateProgress;

  ///
  bool get isPlaying => playerState == PlayerState.isPlaying;

  ///
  bool get isPaused => playerState == PlayerState.isPaused;

  ///
  bool get isStopped => playerState == PlayerState.isStopped;

  ///
  FlutterSoundPlayer();

  ///
  Future<FlutterSoundPlayer> openAudioSession({
    AudioFocus focus = AudioFocus.requestFocusAndKeepOthers,
    SessionCategory category = SessionCategory.playAndRecord,
    SessionMode mode = SessionMode.modeDefault,
    AudioDevice device = AudioDevice.speaker,
    int audioFlags = outputToSpeaker | allowBlueToothA2DP | allowAirPlay,
    bool withUI = false,
  }) async {
    print('FS:---> openAudioSession ');
    await _lock.synchronized(() async {
      if (isInited == Initialized.fullyInitialized) {
        await closeAudioSession();
      }
      if (isInited == Initialized.initializationInProgress) {
        throw (_InitializationInProgress());
      }

      isInited = Initialized.initializationInProgress;

      FlutterSoundPlayerPlatform.instance.openSession(this);
      setPlayerCallback();
      openAudioSessionCompleter = Completer<FlutterSoundPlayer>();
      var state = await FlutterSoundPlayerPlatform.instance
          .initializeMediaPlayer(this,
              focus: focus,
              category: category,
              mode: mode,
              audioFlags: audioFlags,
              device: device,
              withUI: withUI);
      playerState = PlayerState.values[state];
      //isInited = success ?  Initialized.fullyInitialized : Initialized.notInitialized;
    });
    print('FS:<--- openAudioSession ');
    return openAudioSessionCompleter.future;
  }

  ///
  Future<FlutterSoundPlayer> openAudioSessionWithUI(
      {AudioFocus focus = AudioFocus.requestFocusAndKeepOthers,
      SessionCategory category = SessionCategory.playAndRecord,
      SessionMode mode = SessionMode.modeDefault,
      AudioDevice device = AudioDevice.speaker,
      int audioFlags = outputToSpeaker | allowBlueToothA2DP | allowAirPlay}) {
    return openAudioSession(
        focus: focus,
        category: category,
        mode: mode,
        device: device,
        withUI: true);
  }

  ///
  Future<void> setAudioFocus({
    AudioFocus focus = AudioFocus.requestFocusAndKeepOthers,
    SessionCategory category = SessionCategory.playback,
    SessionMode mode = SessionMode.modeDefault,
    AudioDevice device = AudioDevice.speaker,
    int audioFlags =
        outputToSpeaker | allowBlueTooth | allowBlueToothA2DP | allowEarPiece,
  }) async {
    print('FS:---> setAudioFocus ');
    await _lock.synchronized(() async {
      if (isInited == Initialized.initializationInProgress) {
        throw (_InitializationInProgress());
      }
      if (isInited != Initialized.fullyInitialized) {
        throw (_NotOpen());
      }

      var state = await FlutterSoundPlayerPlatform.instance.setAudioFocus(
        this,
        focus: focus,
        category: category,
        mode: mode,
        audioFlags: audioFlags,
        device: device,
      );
      playerState = PlayerState.values[state];
    });
    print('FS:<--- setAudioFocus ');
  }

  ///
  Future<void> closeAudioSession() async {
    print('FS:---> closeAudioSession ');
    await _lock.synchronized(() async {
      if (isInited == Initialized.notInitialized) {
        return this;
      }
      // probably better not to throw an exception here
      //if (isInited == Initialized.initializationInProgress) {
      //throw (_InitializationInProgress());
      //}

      isInited = Initialized.initializationInProgress;
      await stop();

      //_removePlayerCallback(); // playerController is closed by this function
      var state =
          await FlutterSoundPlayerPlatform.instance.releaseMediaPlayer(this);
      playerState = PlayerState.values[state];
      _removePlayerCallback();
      FlutterSoundPlayerPlatform.instance.closeSession(this);
      isInited = Initialized.notInitialized;
    });
    print('FS:<--- closeAudioSession ');
  }

  ///
  Future<PlayerState> getPlayerState() async {
    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (isInited != Initialized.fullyInitialized) {
      throw (_NotOpen());
    }
    var state = await FlutterSoundPlayerPlatform.instance.getPlayerState(this);
    playerState = PlayerState.values[state];
    return playerState;
  }

  ///
  Future<Map<String, Duration>> getProgress() async {
    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (isInited != Initialized.fullyInitialized) {
      throw (_NotOpen());
    }

    return FlutterSoundPlayerPlatform.instance.getProgress(this);
  }

  ///
  bool needToConvert(Codec codec) {
    print('FS:---> needToConvert ');
    if (codec == null) return false;
    var convert = (kIsWeb)
        ? tabWebConvert[codec.index]
        : (Platform.isIOS)
            ? tabIosConvert[codec.index]
            : (Platform.isAndroid)
                ? tabAndroidConvert[codec.index]
                : null;
    print('FS:<--- needToConvert ');
    return (convert != Codec.defaultCodec);
  }

  /// Returns true if the specified decoder is supported by flutter_sound on this platform
  Future<bool> isDecoderSupported(Codec codec) async {
    bool result;
    print('FS:---> isDecoderSupported ');

    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (isInited != Initialized.fullyInitialized) {
      throw (_NotOpen());
    }
    // For decoding ogg/opus on ios, we need to support two steps :
    // - remux OGG file format to CAF file format (with ffmpeg)
    // - decode CAF/OPPUS (with native Apple AVFoundation)

    if (needToConvert(codec)) {
      if (!await flutterSoundHelper.isFFmpegAvailable()) return false;
      var convert = kIsWeb
          ? tabWebConvert[codec.index]
          : (Platform.isIOS)
              ? tabIosConvert[codec.index]
              : (Platform.isAndroid)
                  ? tabAndroidConvert[codec.index]
                  : null;
      result = await FlutterSoundPlayerPlatform.instance
          .isDecoderSupported(this, codec: convert);
    } else {
      result = await FlutterSoundPlayerPlatform.instance
          .isDecoderSupported(this, codec: codec);
    }
    print('FS:<--- isDecoderSupported ');
    return result;
  }

  ///
  Future<void> setSubscriptionDuration(Duration duration) async {
    print('FS:---> setSubscriptionDuration ');
    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (isInited != Initialized.fullyInitialized) {
      throw (_NotOpen());
    }
    var state = await FlutterSoundPlayerPlatform.instance
        .setSubscriptionDuration(this, duration: duration);
    playerState = PlayerState.values[state];
    print('FS:<---- setSubscriptionDuration ');
  }

  ///
  void setPlayerCallback() {
    _playerController ??= StreamController<PlaybackDisposition>.broadcast();
  }

  void _removePlayerCallback() {
    if (_playerController != null) {
      _playerController
        //..add(null)
        ..close();
      _playerController = null;
    }
  }

  ///
  Future<void> _convertAudio(Map<String, dynamic> what) async {
    // If we want to play OGG/OPUS on iOS, we remux the OGG file format to a specific Apple CAF envelope before starting the player.
    // We use FFmpeg for that task.
    print('FS:---> _convertAudio ');
    var tempDir = await getTemporaryDirectory();
    var codec = what['codec'] as Codec;
    var convert = kIsWeb
        ? tabWebConvert[codec.index]
        : (Platform.isIOS)
            ? tabIosConvert[codec.index]
            : (Platform.isAndroid)
                ? tabAndroidConvert[codec.index]
                : null;
    var fout = '${tempDir.path}/flutter_sound-tmp2${ext[convert.index]}';
    var path = what['path'] as String;
    await flutterSoundHelper.convertFile(path, codec, fout, convert);

    // Now we can play Apple CAF/OPUS

    what['path'] = fout;
    what['codec'] = convert;
    print('FS:<--- _convertAudio ');
  }

  Future<void> _convert(Map<String, dynamic> what) async {
    print('FS:---> _convert ');
    var codec = what['codec'] as Codec;
    if (needToConvert(codec)) {
      var fromDataBuffer = what['fromDataBuffer'] as Uint8List;

      if (fromDataBuffer != null) {
        var tempDir = await getTemporaryDirectory();
        var inputFile = File('${tempDir.path}/flutter_sound-tmp');

        if (inputFile.existsSync()) {
          await inputFile.delete();
        }
        inputFile.writeAsBytesSync(
            fromDataBuffer); // Write the user buffer into the temporary file
        what['fromDataBuffer'] = null;
        what['path'] = inputFile.path;
      }
      await _convertAudio(what);
    }
    print('FS:<--- _convert ');
  }

  ///
  Future<Duration> startPlayer({
    String fromURI,
    Uint8List fromDataBuffer,
    Codec codec = Codec.aacADTS,
    int sampleRate = 16000, // Used only with codec == Codec.pcm16
    int numChannels = 1, // Used only with codec == Codec.pcm16
    TWhenFinished whenFinished,
  }) async {
    print('FS:---> startPlayer ');
    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (isInited != Initialized.fullyInitialized) {
      throw (_NotOpen());
    }

    if (codec == Codec.pcm16 && fromURI != null) {
      var tempDir = await getTemporaryDirectory();
      var path = '${tempDir.path}/flutter_sound_tmp.wav';
      await flutterSoundHelper.pcmToWave(
        inputFile: fromURI,
        outputFile: path,
        numChannels: 1,
        //bitsPerSample: 16,
        sampleRate: sampleRate,
      );
      fromURI = path;
      codec = Codec.pcm16WAV;
    } else if (codec == Codec.pcm16 && fromDataBuffer != null) {
      fromDataBuffer = await flutterSoundHelper.pcmToWaveBuffer(
          inputBuffer: fromDataBuffer,
          sampleRate: sampleRate,
          numChannels: numChannels);
      codec = Codec.pcm16WAV;
    }

    await _lock.synchronized(() async {
      await stop(); // Just in case

      //playerState = PlayerState.isPlaying;
      var what = <String, dynamic>{
        'codec': codec,
        'path': fromURI,
        'fromDataBuffer': fromDataBuffer,
      };
      await _convert(what);
      codec = what['codec'] as Codec;
      fromURI = what['path'] as String;
      fromDataBuffer = what['fromDataBuffer'] as Uint8List;
      if (playerState != PlayerState.isStopped) {
        throw Exception('Player is not stopped');
      }
      audioPlayerFinishedPlaying = () {
        print('FS: !whenFinished()');
        whenFinished();
      };
      startPlayerCompleter = Completer<Duration>();
      var state = await FlutterSoundPlayerPlatform.instance.startPlayer(
        this,
        codec: codec,
        fromDataBuffer: fromDataBuffer,
        fromURI: fromURI,
      );
      playerState = PlayerState.values[state];
    });
    //Duration duration = Duration(milliseconds: retMap['duration'] as int);
    print('FS:<--- startPlayer ');
    return startPlayerCompleter.future;
  }

  ///
  Future<void> startPlayerFromStream({
    Codec codec = Codec.pcm16,
    int numChannels = 1,
    int sampleRate = 16000,
  }) async {
    print('FS:---> startPlayerFromStream ');
    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (isInited != Initialized.fullyInitialized) {
      throw (_NotOpen());
    }

    await _lock.synchronized(() async {
      await stop(); // Just in case
      foodStreamController = StreamController();
      foodStreamSubscription = foodStreamController.stream.listen((food) {
        foodStreamSubscription.pause(food.exec(this));
      });
      var state = await FlutterSoundPlayerPlatform.instance.startPlayer(this,
          codec: codec,
          fromDataBuffer: null,
          fromURI: null,
          numChannels: numChannels,
          sampleRate: sampleRate);
      playerState = PlayerState.values[state];
    });
    print('FS:<--- startPlayerFromStream ');
  }

  ///
  Future<void> feedFromStream(Uint8List buffer) async {
    var lnData = 0;
    var totalLength = buffer.length;
    while (totalLength > 0 && !isStopped) {
      var bsize = totalLength > blockSize ? blockSize : totalLength;
      var ln = await feed(buffer.sublist(lnData, lnData + bsize));
      lnData += ln;
      totalLength -= ln;
    }
  }

  ///
  Future<int> feed(Uint8List data) async {
    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (isInited != Initialized.fullyInitialized) {
      throw (_NotOpen());
    }
    if (isStopped) {
      return 0;
    }
    needSomeFoodCompleter = Completer<int>();
    try {
      var ln = await FlutterSoundPlayerPlatform.instance.feed(
        this,
        data: data,
      );
      if (ln != 0) {
        needSomeFoodCompleter = null;
        return (ln);
      }
    } on Exception {
      needSomeFoodCompleter = null;
      if (isStopped) {
        return 0;
      }
      rethrow;
    }

    if (needSomeFoodCompleter != null) {
      return needSomeFoodCompleter.future;
    }
    return 0;
  }

  ///
  Future<Duration> startPlayerFromTrack(
    Track track, {
    TonSkip onSkipForward,
    TonSkip onSkipBackward,
    TonPaused onPaused,
    TWhenFinished whenFinished,
    Duration progress,
    Duration duration,
    bool defaultPauseResume,
    bool removeUIWhenStopped = true,
  }) async {
    print('FS:---> startPlayerFromTrack ');
    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (isInited != Initialized.fullyInitialized) {
      throw (_NotOpen());
    }
    //Map retMap;
    await _lock.synchronized(() async {
      try {
        await stop(); // Just in case
        audioPlayerFinishedPlaying = () {
          whenFinished();
        };
        this.onSkipForward = onSkipForward;
        this.onSkipBackward = onSkipBackward;
        this.onPaused = onPaused;
        var trackDico = track.toMap();
        var what = <String, dynamic>{
          'codec': track.codec,
          'path': track.trackPath,
          'fromDataBuffer': track.dataBuffer,
        };
        await _convert(what);
        var codec = what['codec'] as Codec;
        trackDico['bufferCodecIndex'] = codec.index;
        trackDico['path'] = what['path'];
        trackDico['dataBuffer'] = what['fromDataBuffer'];
        trackDico['codec'] = codec.index;

        defaultPauseResume ??= (onPaused == null);
        if (playerState != PlayerState.isStopped) {
          throw Exception('Player is not stopped');
        }
        startPlayerCompleter = Completer<Duration>();
        var state =
            await FlutterSoundPlayerPlatform.instance.startPlayerFromTrack(
          this,
          progress: progress,
          duration: duration,
          track: trackDico,
          canPause: (onPaused != null || defaultPauseResume),
          canSkipForward: (onSkipForward != null),
          canSkipBackward: (onSkipBackward != null),
          defaultPauseResume: defaultPauseResume,
          removeUIWhenStopped: removeUIWhenStopped,
        );
        playerState = PlayerState.values[state];
      } on Exception {
        rethrow;
      }
    });
    //Duration d = Duration(milliseconds: retMap['duration'] as int);
    //int state = retMap['state'] as int;
    //playerState = PlayerState.values[state];
    print('FS:<--- startPlayerFromTrack ');
    return startPlayerCompleter.future;
  }

  ///
  Future<void> nowPlaying(
    Track track, {
    Duration duration,
    Duration progress,
    TonSkip onSkipForward,
    TonSkip onSkipBackward,
    TonPaused onPaused,
    bool defaultPauseResume,
  }) async {
    print('FS:---> nowPlaying ');
    await _lock.synchronized(() async {
      if (isInited == Initialized.initializationInProgress) {
        throw (_InitializationInProgress());
      }
      if (isInited != Initialized.fullyInitialized) {
        throw (_NotOpen());
      }
      this.onSkipForward = onSkipForward;
      this.onSkipBackward = onSkipBackward;
      this.onPaused = onPaused;

      var trackDico = (track != null) ? track.toMap() : null;
      defaultPauseResume ??= (onPaused == null);
      var state = await FlutterSoundPlayerPlatform.instance.nowPlaying(
        this,
        track: trackDico,
        duration: duration,
        progress: progress,
        canPause: (onPaused != null || defaultPauseResume),
        canSkipForward: (onSkipForward != null),
        canSkipBackward: (onSkipBackward != null),
        defaultPauseResume: defaultPauseResume,
      );
      playerState = PlayerState.values[state];
      print('FS:<--- nowPlaying ');
    });
  }

  ///
  Future<void> stopPlayer() async {
    print('FS:---> stopPlayer ');
    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (isInited != Initialized.fullyInitialized) {
      throw (_NotOpen());
    }

    // REALLY ? // audioPlayerFinishedPlaying = null;

    try {
      //_removePlayerCallback(); // playerController is closed by this function
      await stop();
    } on Exception catch (e) {
      print(e);
    }
    print('FS:<--- stopPlayer ');
  }

  ///
  Future<void> stop() async {
    print('FS:---> stop ');
    if (foodStreamSubscription != null) {
      await foodStreamSubscription.cancel();
      foodStreamSubscription = null;
    }
    needSomeFoodCompleter = null;
    if (foodStreamController != null) {
      await foodStreamController.sink.close();
      //await foodStreamController.stream.drain<bool>();
      await foodStreamController.close();
      foodStreamController = null;
    }
    var state = await FlutterSoundPlayerPlatform.instance.stopPlayer(this);

    playerState = PlayerState.values[state];
    if (playerState != PlayerState.isStopped) {
      throw Exception('Player is not stopped');
    }

    print('FS:<--- stop ');
  }

  ///
  Future<void> pausePlayer() async {
    print('FS:---> pausePlayer ');
    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (isInited != Initialized.fullyInitialized) {
      throw (_NotOpen());
    }
    await _lock.synchronized(() async {
      playerState = PlayerState
          .values[await FlutterSoundPlayerPlatform.instance.pausePlayer(this)];
      if (playerState != PlayerState.isPaused) {
        //await _stopPlayerwithCallback( ); // To recover a clean state
        throw PlayerRunningException(
            'Player is not paused.'); // I am not sure that it is good to throw an exception here
      }
    });
    print('FS:<--- pausePlayer ');
  }

  ///
  Future<void> resumePlayer() async {
    print('FS:---> resumePlayer ');
    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (isInited != Initialized.fullyInitialized) {
      throw (_NotOpen());
    }
    await _lock.synchronized(() async {
      var state = await FlutterSoundPlayerPlatform.instance.resumePlayer(this);
      playerState = PlayerState.values[state];
      if (playerState != PlayerState.isPlaying) {
        //await _stopPlayerwithCallback( ); // To recover a clean state
        throw PlayerRunningException(
            'Player is not resumed.'); // I am not sure that it is good to throw an exception here
      }
    });
    print('FS:<--- resumePlayer ');
  }

  ///
  Future<void> seekToPlayer(Duration duration) async {
    //print('FS:---> seekToPlayer ');
    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (isInited != Initialized.fullyInitialized) {
      throw (_NotOpen());
    }
    await _lock.synchronized(() async {
      var state = await FlutterSoundPlayerPlatform.instance.seekToPlayer(
        this,
        duration: duration,
      );
      playerState = PlayerState.values[state];
    });
    //print('FS:<--- seekToPlayer ');
  }

  ///
  Future<void> setVolume(double volume) async {
    print('FS:---> setVolume ');
    await _lock.synchronized(() async {
      if (isInited == Initialized.initializationInProgress) {
        throw (_InitializationInProgress());
      }
      if (isInited != Initialized.fullyInitialized) {
        throw (_NotOpen());
      }
      var indexedVolume = (!kIsWeb) && Platform.isIOS ? volume * 100 : volume;
      if (volume < 0.0 || volume > 1.0) {
        throw RangeError('Value of volume should be between 0.0 and 1.0.');
      }

      var state = await FlutterSoundPlayerPlatform.instance.setVolume(
        this,
        volume: indexedVolume,
      );
      playerState = PlayerState.values[state];
    });
    print('FS:<--- setVolume ');
  }

  ///
  Future<void> setUIProgressBar({
    Duration duration,
    Duration progress,
  }) async {
    print('FS:---> setUIProgressBar : duration=$duration  progress=$progress');
    await _lock.synchronized(() async {
      var state = await FlutterSoundPlayerPlatform.instance
          .setUIProgressBar(this, duration: duration, progress: progress);
      playerState = PlayerState.values[state];
    });
    print('FS:<--- setUIProgressBar ');
  }

  ///
  Future<String> getResourcePath() async {
    if (kIsWeb) {
      return null;
    } else if (Platform.isIOS) {
      var s = await FlutterSoundPlayerPlatform.instance.getResourcePath(this);
      return s;
    } else {
      return (await getApplicationDocumentsDirectory()).path;
    }
  }
}

/// Used to stream data about the position of the
/// playback as playback proceeds.
class PlaybackDisposition {
  /// The duration of the media.
  final Duration duration;

  /// The current position within the media
  /// that we are playing.
  final Duration position;

  /// A convenience ctor. If you are using a stream builder
  /// you can use this to set initialData with both duration
  /// and postion as 0.
  PlaybackDisposition.zero()
      : position = Duration(seconds: 0),
        duration = Duration(seconds: 0);

  ///
  PlaybackDisposition({
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  @override
  String toString() {
    return 'duration: $duration, '
        'position: $position';
  }
}

///
class PlayerRunningException implements Exception {
  ///
  final String message;

  ///
  PlayerRunningException(this.message);
}

class _InitializationInProgress implements Exception {
  _InitializationInProgress() {
    print(
        'An initialization of this audio session is currently already in progress.');
  }
}

class _NotOpen implements Exception {
  _NotOpen() {
    print('Audio session is not open');
  }
}

/// The track to play in the audio player
class Track {
  /// The title of this track
  String trackTitle;

  /// The buffer containing the audio file to play
  Uint8List dataBuffer;

  /// The name of the author of this track
  String trackAuthor;

  /// The path that points to the track audio file
  String trackPath;

  /// The URL that points to the album art of the track
  String albumArtUrl;

  /// The asset that points to the album art of the track
  String albumArtAsset;

  /// The file that points to the album art of the track
  String albumArtFile;

  /// The image that points to the album art of the track
  //final String albumArtImage;

  /// The codec of the audio file to play. If this parameter's value is null
  /// it will be set to `t_CODEC.DEFAULT`.
  Codec codec;

  ///
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
    assert((!(trackPath != null && dataBuffer != null)),
        'You cannot provide both a path and a buffer.');
  }

  /// Convert this object to a [Map] containing the properties of this object
  /// as values.
  Map<String, dynamic> toMap() {
    final map = {
      'path': trackPath,
      'dataBuffer': dataBuffer,
      'title': trackTitle,
      'author': trackAuthor,
      'albumArtUrl': albumArtUrl,
      'albumArtAsset': albumArtAsset,
      'albumArtFile': albumArtFile,
      'bufferCodecIndex': codec?.index,
    };

    return map;
  }
}
