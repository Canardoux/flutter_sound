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
import 'dart:io';
import 'dart:typed_data' show Uint8List;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:flutter_sound/flutter_sound.dart';

import 'demo_util/demo_audio_state.dart';
import 'demo_util/demo_common.dart';
import 'demo_util/remote_player.dart';

/// Demonstrates using multiple players in one ui.
void main() {
  runApp(MyApp());
}
///
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isRecording = false;
  final List<String> _path = [null, null, null, null, null, null, null];

  /// we keep our own local stream as the players come and go.
  /// This lets our StreamBuilder work with it worrying about
  /// the player's stream changing under it.
  StreamController<PlaybackDisposition> _localController;

  FlutterSoundPlayer playerModule;
  FlutterSoundRecorder recorder;

  double sliderCurrentPosition = 0.0;
  double maxDuration = 1.0;
  MediaStorage _media = MediaStorage.file;
  Codec _codec = Codec.aacADTS;

  bool _encoderSupported = true; // Optimist
  bool _decoderSupported = true; // Optimist

  // Whether the user wants to use the audio player features
  //bool _isAudioPlayer = false;
  //bool _duckOthers = false;

  double _duration;

  void setCodec(Codec codec) async {
    _encoderSupported = await recorder.isEncoderSupported(codec);
    _decoderSupported = await playerModule.isDecoderSupported(codec);

    setState(() {
      _codec = codec;
    });
  }

  Future<void> _initializeExample() async {
    if (playerModule != null) {
      playerModule.closeAudioSession();
      //playerModule = null;
    }
    //if (_isAudioPlayer) {
      //playerModule = await FlutterSoundPlayer().openAudioSessionWithUI();
    //} else {
      playerModule = await FlutterSoundPlayer().openAudioSession();
    //}

    // update the ui when we change state.
    // TODO ? playerModule.onPaused = ({wasUser}) => setState(() {});
    // TODO ? playerModule.onResumed = ({wasUser}) => setState(() {
          // audioState = AudioState.isPaused;
        //});

    playerModule.dispositionStream().listen(_localController.add);

    initializeDateFormatting();
    setCodec(_codec);
    //setDuck();
  }

  Future<void> init() async {
    initializeDateFormatting('en', null);
    initializeDateFormatting('en_US,', null);
    recorder = FlutterSoundRecorder();
    // update the ui when we change state.
    // this also handles app pause/resume transitions.
    // TODO ? recorder.onStarted = ({wasUser}) => setState(() {});
    // TODO ? recorder.onStopped = ({wasUser}) => setState(() {});
    _localController = StreamController<PlaybackDisposition>.broadcast();
    await recorder.openAudioSession();

    await _initializeExample();
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  // Returns a stream of [RecordingDisposition] so you can
  /// display db and duration of the recording as it records.
  /// Use this with a StreamBuilder
  Stream<RecordingDisposition> recorderDispositionStream(
      {Duration interval = const Duration(milliseconds: 10)}) {
    return recorder.dispositionStream();
  }

  // Returns a stream of [PlaybackDisposition] so you can
  /// Use this with a StreamBuilder
  Stream<PlaybackDisposition> playbackDispositionStream(
      {Duration interval = const Duration(milliseconds: 10)}) {
    return playerModule.dispositionStream();
  }

  AudioState get audioState {
    if (recorder != null) {
      if (recorder.isPaused) return AudioState.isRecordingPaused;
      if (recorder.isRecording) return AudioState.isRecording;
    }
    if (playerModule != null) {
      if (playerModule.isPlaying) return AudioState.isPlaying;
      if (playerModule.isPaused) return AudioState.isPaused;
    }
    return AudioState.isStopped;
  }

  void cancelRecorderSubscriptions() {
    //if (recorderStreamSubscription != null) {
    //recorderStreamSubscription.cancel();
    //recorderStreamSubscription = null;
    //}
    //if (_dbPeakSubscription != null) {
    //_dbPeakSubscription.cancel();
    //_dbPeakSubscription = null;
    //}
  }

  void cancelPlayerSubscriptions() {
    //if (playerStreamSubscription != null) {
    //playerStreamSubscription.cancel();
    // playerStreamSubscription = null;
    //}

    //if (_playbackStateSubscription != null) {
    //_playbackStateSubscription.cancel();
    //_playbackStateSubscription = null;
    //}
  }

  @override
  void dispose() {
    super.dispose();
    cancelPlayerSubscriptions();
    cancelRecorderSubscriptions();
    releaseFlauto();
  }

  Future<void> releaseFlauto() async {
    try {
      await playerModule.closeAudioSession();
      playerModule = null;
      await recorder.closeAudioSession();
      recorder = null;
    }
    // ignore: avoid_catches_without_on_clauses
    catch (e) {
      print('Released unsuccessful');
      print(e);
    }
  }

  static const List<String> paths = [
    'flutter_sound_example.aac', // DEFAULT
    'flutter_sound_example.aac', // CODEC_AAC
    'flutter_sound_example.opus', // CODEC_OPUS
    'flutter_sound_example.caf', // CODEC_CAF_OPUS
    'flutter_sound_example.mp3', // CODEC_MP3
    'flutter_sound_example.ogg', // CODEC_VORBIS
    'flutter_sound_example.pcm', // CODEC_PCM
  ];

  Future<void> getDuration() async {
    switch (_media) {
      case MediaStorage.file:
      case MediaStorage.buffer:

        //int d = await flutterSoundHelper.duration(this._path[_codec.index]);
        //_duration = d != null ? d / 1000.0 : null;
        break;
      case MediaStorage.asset:
        _duration = null;
        break;
      case MediaStorage.remoteExampleFile:
        _duration = null;
        break;
      case MediaStorage.stream:
        // TODO: Handle this case.
        break;
    }
    setState(() {});
  }

  void stopRecorder() async {
    try {
      await recorder.stopRecorder();
      cancelRecorderSubscriptions();
      getDuration();
    }
    // ignore: avoid_catches_without_on_clauses
     catch (err) {
      print('stopRecorder error: $err');
    }
    setState(() {
      _isRecording = false;
    });
  }

  void startRecorder() async {
    try {
      var tempDir = await getTemporaryDirectory();
      var slotNo = 0; // TODO
      var path = '${tempDir.path}/$slotNo-${paths[_codec.index]}';
      await recorder.startRecorder(toFile: path, codec: _codec);

      setState(() {
        _isRecording = true;
        _path[_codec.index] = path;
      });
    }
    // ignore: avoid_catches_without_on_clauses
     catch (err) {
      print('startRecorder error: $err');
      setState(() {
        stopRecorder();
        _isRecording = false;
        /*
        if (_recorderSubscription != null) {
          _recorderSubscription.cancel();
          _recorderSubscription = null;
        }
        if (_dbPeakSubscription != null) {
          _dbPeakSubscription.cancel();
          _dbPeakSubscription = null;
        }

         */
      });
    }
  }

  Future<bool> fileExists(String path) async {
    return await File(path).exists();
  }

  // In this simple example, we just load a file in memory.
  // This is stupid but just for demonstration  of startPlayerFromBuffer()
  Future<Uint8List> makeBuffer(String path) async {
    try {
      if (!await fileExists(path)) return null;
      var file = File(path);
      file.openRead();
      var contents = await file.readAsBytes();
      print('The file is ${contents.length} bytes long.');
      return contents;
    }
    // ignore: avoid_catches_without_on_clauses
    catch (e) {
      print(e);
      return null;
    }
  }

  List<String> assetSample = [
    'assets/samples/sample.aac',
    'assets/samples/sample.aac',
    'assets/samples/sample.opus',
    'assets/samples/sample.caf',
    'assets/samples/sample.mp3',
    'assets/samples/sample.ogg',
    'assets/samples/sample.pcm',
  ];

  void _addListeners() {
    /* TODO
    cancelPlayerSubscriptions();
    _playerSubscription = playerModule.onPlayerStateChanged.listen((e) {
      if (e != null) {
        maxDuration = e.duration;
        if (maxDuration <= 0) maxDuration = 0.0;

        sliderCurrentPosition = min(e.currentPosition, maxDuration);
        if (sliderCurrentPosition < 0.0) {
          sliderCurrentPosition = 0.0;
        }

        DateTime date = new DateTime.fromMillisecondsSinceEpoch(
          e.currentPosition.toInt(), isUtc: true);
        String txt = DateFormat('mm:ss:SS', 'en_GB').format(date);
        this.setState(() {
          //this._isPlaying = true;
          this._playerTxt = txt.substring(0, 8);
        });
      }
    });
     */
  }

  Future<void> startPlayer() async {
    try {
      //String path;
      Uint8List dataBuffer;
      String audioFilePath;
      if (_media == MediaStorage.asset) {
        dataBuffer = (await rootBundle.load(assetSample[_codec.index]))
            .buffer
            .asUint8List();
      } else if (_media == MediaStorage.file) {
        // Do we want to play from buffer or from file ?
        if (await fileExists(_path[_codec.index])) {
          audioFilePath = _path[_codec.index];
        }
      } else if (_media == MediaStorage.buffer) {
        // Do we want to play from buffer or from file ?
        if (await fileExists(_path[_codec.index])) {
          dataBuffer = await makeBuffer(_path[_codec.index]);
          if (dataBuffer == null) {
            throw Exception('Unable to create the buffer');
          }
        }
      } else if (_media == MediaStorage.remoteExampleFile) {
        // We have to play an example audio file loaded via a URL
        audioFilePath = exampleAudioFilePath;
      }

      // Check whether the user wants to use the audio player features
      String albumArtUrl;
      String albumArtAsset;
      String albumArtFile;
      if (_media == MediaStorage.remoteExampleFile) {
        albumArtUrl = albumArtPath;
      } else {

        if (Platform.isIOS) {
          albumArtAsset = 'AppIcon';
        } else if (Platform.isAndroid) {
          albumArtAsset = 'AppIcon.png';
        }
        //}
      }
      Track track;
      if (dataBuffer != null) {
        track = Track(
          dataBuffer: dataBuffer,
          codec: _codec,
        );
      } else {
        track = Track(
          trackPath: audioFilePath,
        );
      }

      track.trackTitle = "This is a record";
      track.trackAuthor = "from flutter_sound";
      track.albumArtUrl = albumArtUrl;
      track.albumArtAsset = albumArtAsset;
      track.albumArtFile = albumArtFile;

      await playerModule.startPlayer(
        fromURI: track.trackPath,
        fromDataBuffer: track.dataBuffer,
        whenFinished: () {
          print('I hope you enjoyed listening to this song');
          setState(() {});
        },

        /*
          whenFinished: () {
            print('I hope you enjoyed listening to this song');
            setState(() {});
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
          onPaused: (bool b) {
            if (b)
              playerModule.pausePlayer();
            else
              playerModule.resumePlayer();
          }

           */
      );
      /*
      } else {
        if (audioFilePath != null) {
          path = await playerModule.startPlayer(audioFilePath
          , codec: _codec, whenFinished: () {
            print('Play finished');
            setState(() {});
          });
        } else if (dataBuffer != null) {
          path = await playerModule.startPlayerFromBuffer(dataBuffer
          , codec: _codec, whenFinished: () {
            print('Play finished');
            setState(() {});
          });
        }
   }

          */
      _addListeners();

      print('startPlayer: $audioFilePath');
      // await flutterSoundModule.setVolume(1.0);
    }
    // ignore: avoid_catches_without_on_clauses
     catch (e) {
      print('error: $e');
    }
    setState(() {});
  }

  Future<void> stopPlayer() async {
    try {
      await playerModule.stopPlayer();
      //if (_playerSubscription != null) {
      //_playerSubscription.cancel();
      // _playerSubscription = null;
      //}
      sliderCurrentPosition = 0.0;

    }

    // ignore: avoid_catches_without_on_clauses
    catch (err) {
      print('error: $err');
    }

    setState(() {
      //this._isPlaying = false;
    });
  }

  Future<void> pauseResumePlayer() {
    if (playerModule.isPlaying) {
      return playerModule.pausePlayer();
    } else {
      return playerModule.resumePlayer();
    }
  }

  Future<void> pauseResumeRecorder() {
    if (recorder.isPaused) {
      {
        return recorder.resumeRecorder();
      }
    } else {
      return recorder.pauseRecorder();
    }
  }

  Future<void> seekToPlayer(int milliSecs) async {
    return playerModule.seekToPlayer(Duration(milliseconds: milliSecs));
  }

  /// formats a duration for printing.
  ///  mm:ss
  String formatDuration(Duration duration) {
    var date = DateTime.fromMillisecondsSinceEpoch(duration.inMilliseconds,
        isUtc: true);
    return DateFormat('mm:ss:SS', 'en_GB').format(date);
  }

  Widget buildDBIndicator() {
    return (audioState == AudioState.isRecording)
        ? StreamBuilder<RecordingDisposition>(
            stream:
                recorderDispositionStream(interval: Duration(milliseconds: 10)),
            initialData: RecordingDisposition.zero(),
            builder: (context, snapshot) {
              var recordingDisposition = snapshot.data;
              var dbLevel = recordingDisposition.decibels;
              return LinearProgressIndicator(
                  value: 100.0 / 160.0 * (dbLevel ?? 1) / 100,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  backgroundColor: Colors.red);
            })
        : Container();
  }

  Widget buildDurationText() {
    return StreamBuilder<RecordingDisposition>(
        stream: recorderDispositionStream(interval: Duration(milliseconds: 10)),
        initialData: RecordingDisposition.zero(),
        builder: (context, snapshot) {
          var disposition = snapshot.data;
          var txt = formatDuration(disposition.duration);

          return Container(
            margin: EdgeInsets.only(top: 12.0, bottom: 16.0),
            child: Text(
              txt,
              style: TextStyle(
                fontSize: 35.0,
                color: Colors.black,
              ),
            ),
          );
        });
  }

  Widget buildPlaybackDurationText() {
    return StreamBuilder<PlaybackDisposition>(
        stream: _localController.stream,
        initialData: PlaybackDisposition.zero(),
        builder: (context, snapshot) {
          var disposition = snapshot.data;
          return Text(
            formatDuration(disposition.position),
            style: TextStyle(
              fontSize: 35.0,
              color: Colors.black,
            ),
          );
        });
  }

  Widget buildPlaybackProgressBar() {
    return (audioState == AudioState.isPlaying)
        ? StreamBuilder<PlaybackDisposition>(
            stream: _localController.stream,
            initialData: PlaybackDisposition.zero(),
            builder: (context, snapshot) {
              var playbackDisposition = snapshot.data;
              var pos = playbackDisposition.position.inMilliseconds.toDouble();
              var max = playbackDisposition.duration.inMilliseconds.toDouble();
              if (max == 0) {
                pos = 0;
                max = 1;
              }
              return Slider(
                value: pos / max,
                max: 1.0,
                min: 0.0,
                onChanged: (value) async {
                  await playerModule
                      .seekToPlayer(Duration(milliseconds: (value * max).round()));
                },
              );
            })
        : Container();
  }

  Widget makeDropdowns(BuildContext context) {
    final mediaDropdown = Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Text('MediaStorage:'),
        ),
        DropdownButton<MediaStorage>(
          value: _media,
          onChanged: (newMedia) {
            if (newMedia == MediaStorage.remoteExampleFile) {
              _codec = Codec.mp3;
            } // Actually this is the only example we use in this example
            _media = newMedia;
            getDuration();
            setState(() {});
          },
          items: <DropdownMenuItem<MediaStorage>>[
            DropdownMenuItem<MediaStorage>(
              value: MediaStorage.file,
              child: Text('File'),
            ),
            DropdownMenuItem<MediaStorage>(
              value: MediaStorage.buffer,
              child: Text('Buffer'),
            ),
            DropdownMenuItem<MediaStorage>(
              value: MediaStorage.asset,
              child: Text('Asset'),
            ),
            DropdownMenuItem<MediaStorage>(
              value: MediaStorage.remoteExampleFile,
              child: Text('Remote Example File'),
            ),
          ],
        ),
      ],
    );

    final codecDropdown = Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Text('Codec:'),
        ),
        DropdownButton<Codec>(
          value: _codec,
          onChanged: (newCodec) {
            setCodec(newCodec);
            _codec = newCodec;
            getDuration();
            setState(() {});
          },
          items: <DropdownMenuItem<Codec>>[
            DropdownMenuItem<Codec>(
              value: Codec.aacADTS,
              child: Text('AAC'),
            ),
            DropdownMenuItem<Codec>(
              value: Codec.opusOGG,
              child: Text('OGG/Opus'),
            ),
            DropdownMenuItem<Codec>(
              value: Codec.opusCAF,
              child: Text('CAF/Opus'),
            ),
            DropdownMenuItem<Codec>(
              value: Codec.mp3,
              child: Text('MP3'),
            ),
            DropdownMenuItem<Codec>(
              value: Codec.vorbisOGG,
              child: Text('OGG/Vorbis'),
            ),
            DropdownMenuItem<Codec>(
              value: Codec.pcm16,
              child: Text('PCM'),
            ),
          ],
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: mediaDropdown,
          ),
          codecDropdown,
        ],
      ),
    );
  }

  void Function() onPauseResumePlayerPressed() {
    switch (audioState) {
      case AudioState.isPaused:
        return pauseResumePlayer;
        break;
      case AudioState.isPlaying:
        return pauseResumePlayer;
        break;
      case AudioState.isStopped:
        return null;
        break;
      case AudioState.isRecording:
        return null;
        break;
      case AudioState.isRecordingPaused:
        return null;
        break;
    }
    return null;
  }

  void Function() onPauseResumeRecorderPressed() {
    switch (audioState) {
      case AudioState.isPaused:
        return null;
        break;
      case AudioState.isPlaying:
        return null;
        break;
      case AudioState.isStopped:
        return null;
        break;
      case AudioState.isRecording:
        return pauseResumeRecorder;
        break;
      case AudioState.isRecordingPaused:
        return pauseResumeRecorder;
        break;
    }
    return null;
  }

  void Function() onStopPlayerPressed() {
    return audioState == AudioState.isPlaying ||
            audioState == AudioState.isPaused
        ? stopPlayer
        : null;
  }

  void Function() onStartPlayerPressed() {
    if (_media == MediaStorage.file ||
        _media ==
            MediaStorage.buffer) // A file must be already recorded to play it
    {
      if (_path[_codec.index] == null) return null;
    }
    if (_media == MediaStorage.remoteExampleFile && _codec != Codec.mp3) {
      return null;
    }

    // Disable the button if the selected codec is not supported
    if (!_decoderSupported) return null;
    return (isStopped()) ? startPlayer : null;
  }

  void startStopRecorder() {
    if (recorder.isRecording || recorder.isPaused) {
      stopRecorder();
    } else {
      startRecorder();
    }
  }

  void Function() onStartRecorderPressed() {
    if (_media == MediaStorage.asset ||
        _media == MediaStorage.buffer ||
        _media == MediaStorage.remoteExampleFile) return null;
    // Disable the button if the selected codec is not supported
    if (!_encoderSupported) return null;
    if (audioState != AudioState.isRecording &&
        audioState != AudioState.isRecordingPaused &&
        audioState != AudioState.isStopped) return null;
    return startStopRecorder;
  }

  bool isStopped() => (audioState == AudioState.isStopped);

  AssetImage recorderAssetImage() {
    if (onStartRecorderPressed() == null) {
      return AssetImage('res/icons/ic_mic_disabled.png');
    }
    return audioState == AudioState.isStopped
        ? AssetImage('res/icons/ic_mic.png')
        : AssetImage('res/icons/ic_stop.png');
  }

  @override
  Widget build(BuildContext context) {
    final dropdowns = makeDropdowns(context);
    final trackSwitch = Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 4),
            //child: Text('"Flauto":'),
          ),
         ],
      ),
    );

    Widget recorderSection = Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(top: 12.0, bottom: 16.0),
            child: buildDurationText(),
          ),
          _isRecording ? buildDBIndicator() : Container(),
          //LinearProgressIndicator(value: 100.0 / 160.0 * (this._dbLevel ?? 1) / 100, valueColor: AlwaysStoppedAnimation<Color>(Colors.green), backgroundColor: Colors.red) : Container(),
          Row(
            children: <Widget>[
              Container(
                width: 56.0,
                height: 50.0,
                child: ClipOval(
                  child: FlatButton(
                    onPressed: onStartRecorderPressed(),
                    padding: EdgeInsets.all(8.0),
                    child: Image(
                      image: recorderAssetImage(),
                    ),
                  ),
                ),
              ),
              Container(
                width: 56.0,
                height: 50.0,
                child: ClipOval(
                  child: FlatButton(
                    onPressed: onPauseResumeRecorderPressed(),
                    disabledColor: Colors.white,
                    padding: EdgeInsets.all(8.0),
                    child: Image(
                      width: 36.0,
                      height: 36.0,
                      image: AssetImage(onPauseResumeRecorderPressed() != null
                          ? 'res/icons/ic_pause.png'
                          : 'res/icons/ic_pause_disabled.png'),
                    ),
                  ),
                ),
              ),
            ],
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
          ),
        ]);

    Widget playerSection = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          margin: EdgeInsets.only(top: 12.0, bottom: 16.0),
          child: buildPlaybackDurationText(),
        ),
        Row(
          children: <Widget>[
            Container(
              width: 56.0,
              height: 50.0,
              child: ClipOval(
                child: FlatButton(
                  onPressed: onStartPlayerPressed(),
                  disabledColor: Colors.white,
                  padding: EdgeInsets.all(8.0),
                  child: Image(
                    image: AssetImage(onStartPlayerPressed() != null
                        ? 'res/icons/ic_play.png'
                        : 'res/icons/ic_play_disabled.png'),
                  ),
                ),
              ),
            ),
            Container(
              width: 56.0,
              height: 50.0,
              child: ClipOval(
                child: FlatButton(
                  onPressed: onPauseResumePlayerPressed(),
                  disabledColor: Colors.white,
                  padding: EdgeInsets.all(8.0),
                  child: Image(
                    width: 36.0,
                    height: 36.0,
                    image: AssetImage(onPauseResumePlayerPressed() != null
                        ? 'res/icons/ic_pause.png'
                        : 'res/icons/ic_pause_disabled.png'),
                  ),
                ),
              ),
            ),
            Container(
              width: 56.0,
              height: 50.0,
              child: ClipOval(
                child: FlatButton(
                  onPressed: onStopPlayerPressed(),
                  disabledColor: Colors.white,
                  padding: EdgeInsets.all(8.0),
                  child: Image(
                    width: 28.0,
                    height: 28.0,
                    image: AssetImage(onStopPlayerPressed() != null
                        ? 'res/icons/ic_stop.png'
                        : 'res/icons/ic_stop_disabled.png'),
                  ),
                ),
              ),
            ),
          ],
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
        ),
        Container(
          height: 30.0,
          child: buildPlaybackProgressBar(),
        ),
        Container(
          height: 30.0,
          child: Text(_duration != null ? "Duration: $_duration sec." : ''),
        ),
      ],
    );

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Sound'),
        ),
        body: ListView(
          children: <Widget>[
            recorderSection,
            playerSection,
            dropdowns,
            trackSwitch,
          ],
        ),
      ),
    );
  }
}
