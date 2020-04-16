import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound_player.dart';
import 'package:flutter_sound/track_player.dart';

import 'active_codec.dart';
import 'common.dart';
import 'main.dart';
import 'media_path.dart';

class PlayerState {
  static final PlayerState _self = PlayerState._internal();

  bool _duckOthers = false;

  StreamSubscription _playerSubscription;
  // StreamSubscription _playbackStateSubscription;

  FlutterSoundPlayer playerModule;

  FlutterSoundPlayer playerModule_2; // Used if REENTRANCE_CONCURENCY

  final StreamController<PlayStatus> _playStatusController =
      StreamController<PlayStatus>.broadcast();

  factory PlayerState() {
    return _self;
  }

  PlayerState._internal();

  bool get duckOthers => _duckOthers;

  Stream<PlayStatus> get playStatusStream {
    return _playStatusController.stream;
  }

  bool get canStart {
    if (MediaPath().isFile ||
        MediaPath().isBuffer) // A file must be already recorded to play it
    {
      if (!MediaPath().exists(ActiveCodec().codec)) return false;
    }

    // Disable the button if the selected codec is not supported
    if (!ActiveCodec().decoderSupported) return false;

    if (!isStopped) return false;

    return true;
  }

  bool get isPlayingOrPaused {
    return isPlaying || isPaused;
  }

  bool get isStopped => playerModule != null && playerModule.isStopped;

  bool get isPlaying => playerModule != null && playerModule.isPlaying;

  bool get isPaused => playerModule != null && playerModule.isPaused;

  void reset(FlutterSoundPlayer module) async {
    playerModule = module;
    await module.initialize();
    await playerModule.setSubscriptionDuration(0.01);
  }

  void init() async {
    playerModule = await FlutterSoundPlayer().initialize();
    ActiveCodec().playerModule = playerModule;

    if (renetranceConcurrency) {
      playerModule_2 = await FlutterSoundPlayer().initialize();
      await playerModule_2.setSubscriptionDuration(0.01);
      await playerModule_2.setSubscriptionDuration(0.01);
    }
  }

  void cancelPlayerSubscriptions() {
    if (_playerSubscription != null) {
      _playerSubscription.cancel();
      _playerSubscription = null;
    }
  }

  Future<void> setDuck({bool duckOthers}) async {
    _duckOthers = duckOthers;
    if (_duckOthers) {
      if (Platform.isIOS) {
        await playerModule.iosSetCategory(
            t_IOS_SESSION_CATEGORY.PLAY_AND_RECORD,
            t_IOS_SESSION_MODE.DEFAULT,
            IOS_DUCK_OTHERS | IOS_DEFAULT_TO_SPEAKER);
      } else if (Platform.isAndroid) {
        await playerModule.androidAudioFocusRequest(
            ANDROID_AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK);
      }
    } else {
      if (Platform.isIOS) {
        await playerModule.iosSetCategory(
            t_IOS_SESSION_CATEGORY.PLAY_AND_RECORD,
            t_IOS_SESSION_MODE.DEFAULT,
            IOS_DEFAULT_TO_SPEAKER);
      } else if (Platform.isAndroid) {
        await playerModule.androidAudioFocusRequest(ANDROID_AUDIOFOCUS_GAIN);
      }
    }
  }

  void release() async {
    if (playerModule != null) {
      await playerModule.release();
    }
    if (playerModule_2 != null) {
      await playerModule_2.release();
    }
  }

  void addListeners() {
    _playerSubscription = playerModule.onPlayerStateChanged.listen((e) {
      if (e != null) {
        _playStatusController.add(e);
      }
    });
  }

  Future<void> startPlayer({void Function() whenFinished}) async {
    try {
      //final albumArtPath =
      //"https://file-examples.com/wp-content/uploads/2017/10/file_example_PNG_500kB.png";

      String path;
      Uint8List dataBuffer;
      String audioFilePath;
      if (MediaPath().isAsset) {
        dataBuffer =
            (await rootBundle.load(assetSample[ActiveCodec().codec.index]))
                .buffer
                .asUint8List();
      } else if (MediaPath().isFile) {
        // Do we want to play from buffer or from file ?
        if (await fileExists(MediaPath().pathForCodec(ActiveCodec().codec))) {
          audioFilePath = MediaPath().pathForCodec(ActiveCodec().codec);
        }
      } else if (MediaPath().isBuffer) {
        // Do we want to play from buffer or from file ?
        if (await fileExists(MediaPath().pathForCodec(ActiveCodec().codec))) {
          dataBuffer =
              await _makeBuffer(MediaPath().pathForCodec(ActiveCodec().codec));
          if (dataBuffer == null) {
            throw Exception('Unable to create the buffer');
          }
        }
      } else if (MediaPath().isExampleFile) {
        // We have to play an example audio file loaded via a URL
        audioFilePath = exampleAudioFilePath;
      }

      // Check whether the user wants to use the audio player features
      if (PlayerState().playerModule is TrackPlayer) {
        String albumArtUrl;
        String albumArtAsset;
        if (MediaPath().isExampleFile) {
          albumArtUrl = albumArtPath;
        } else {
          if (Platform.isIOS) {
            albumArtAsset = 'AppIcon';
          } else if (Platform.isAndroid) {
            albumArtAsset = 'AppIcon.png';
          }
        }

        final track = Track(
          trackPath: audioFilePath,
          dataBuffer: dataBuffer,
          codec: ActiveCodec().codec,
          trackTitle: "This is a record",
          trackAuthor: "from flutter_sound",
          albumArtUrl: albumArtUrl,
          albumArtAsset: albumArtAsset,
        );

        var f = playerModule as TrackPlayer;
        path = await f.startPlayerFromTrack(
          track,
          /*canSkipForward:true, canSkipBackward:true,*/
          whenFinished: () {
            print('I hope you enjoyed listening to this song');
            if (whenFinished != null) whenFinished();
          },
          onSkipBackward: () {
            print('Skip backward');
            stopPlayer();
            startPlayer();
          },
          onSkipForward: () {
            print('Skip forward');
            stopPlayer();
            startPlayer();
          },
        );
      } else {
        if (audioFilePath != null) {
          path = await playerModule.startPlayer(audioFilePath,
              codec: ActiveCodec().codec, whenFinished: () {
            print('Play finished');
            if (whenFinished != null) whenFinished();
          });
        } else if (dataBuffer != null) {
          path = await playerModule.startPlayerFromBuffer(dataBuffer,
              codec: ActiveCodec().codec, whenFinished: () {
            print('Play finished');
            if (whenFinished != null) whenFinished();
          });
        }

        if (path == null) {
          print('Error starting player');
          return;
        }
      }
      addListeners();
      if (renetranceConcurrency && !MediaPath().isExampleFile) {
        var dataBuffer =
            (await rootBundle.load(assetSample[ActiveCodec().codec.index]))
                .buffer
                .asUint8List();
        await playerModule_2.startPlayerFromBuffer(dataBuffer,
            codec: ActiveCodec().codec, whenFinished: () {
          print('Secondary Play finished');
        });
      }

      print('startPlayer: $path');
      // await flutterSoundModule.setVolume(1.0);
    } catch (err) {
      print('error: $err');
    }
  }

  Future<void> stopPlayer() async {
    try {
      var result = await playerModule.stopPlayer();
      print('stopPlayer: $result');

      /// signal
      _playStatusController.add(PlayStatus.zero());
      if (_playerSubscription != null) {
        await _playerSubscription.cancel();
        _playerSubscription = null;
      }
    } catch (err) {
      print('error: $err');
    }
    if (renetranceConcurrency) {
      try {
        var result = await playerModule_2.stopPlayer();
        print('stopPlayer_2: $result');
      } catch (err) {
        print('error: $err');
      }
    }
  }

  void pauseResumePlayer() {
    if (playerModule.isPlaying) {
      playerModule.pausePlayer();
      if (renetranceConcurrency) {
        playerModule_2.pausePlayer();
      }
    } else {
      playerModule.resumePlayer();
      if (renetranceConcurrency) {
        playerModule_2.resumePlayer();
      }
    }
  }

  void seekToPlayer(int milliSecs) async {
    var result = await playerModule.seekToPlayer(milliSecs);
    print('seekToPlayer: $result');
  }

  // In this simple example, we just load a file in memory.
  // This is stupid but just for demonstration  of startPlayerFromBuffer()
  Future<Uint8List> _makeBuffer(String path) async {
    try {
      if (!await fileExists(path)) return null;
      var file = File(path);
      file.openRead();
      var contents = await file.readAsBytes();
      print('The file is ${contents.length} bytes long.');
      return contents;
    } catch (e) {
      print(e);
      return null;
    }
  }
}
