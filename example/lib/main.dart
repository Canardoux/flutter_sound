import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' show DateFormat;

void main() {
  runApp(new MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isRecording = false;
  String _path;
  StreamSubscription _recorderSubscription;
  StreamSubscription _dbPeakSubscription;
  StreamSubscription _playerSubscription;
  StreamSubscription _playbackStateSubscription;
  FlutterSound flutterSound;

  String _recorderTxt = '00:00:00';
  String _playerTxt = '00:00:00';
  double _dbLevel;

  double sliderCurrentPosition = 0.0;
  double maxDuration = 1.0;

  // Whether the media player has been initialized and the UI controls can
  // be displayed.
  bool _canDisplayPlayerControls = false;
  PlaybackState _playbackState;
  bool _sliderIsChanging = false;

  @override
  void initState() {
    super.initState();
    flutterSound = new FlutterSound();
    flutterSound.setSubscriptionDuration(0.01);
    flutterSound.setDbPeakLevelUpdate(0.8);
    flutterSound.setDbLevelEnabled(true);
    initializeDateFormatting();

    flutterSound.initialize(
      skipForwardHandler: () {
        print("Skip forward successfully called!");
      },
      skipBackwardForward: () {
        print("Skip backward successfully called!");
      },
    ).then((_) {
      print('media player initialization successful');
      setState(() {
        _canDisplayPlayerControls = true;
      });
    }).catchError((_) {
      print('media player initialization unsuccessful');
    });
  }

  @override
  void dispose() {
    super.dispose();

    if (_playerSubscription != null) {
      _playerSubscription.cancel();
      _playerSubscription = null;
    }

    if (_playbackStateSubscription != null) {
      _playbackStateSubscription.cancel();
      _playbackStateSubscription = null;
    }

    flutterSound.releaseMediaPlayer();
  }

  void startRecorder() async {
    try {
      String path = await flutterSound
          .startRecorder(Platform.isIOS ? 'ios.m4a' : 'android.mp4');
      print('startRecorder: $path');

      _recorderSubscription = flutterSound.onRecorderStateChanged.listen((e) {
        DateTime date = new DateTime.fromMillisecondsSinceEpoch(
            e.currentPosition.toInt(),
            isUtc: true);
        String txt = DateFormat('mm:ss:SS', 'en_GB').format(date);

        this.setState(() {
          this._recorderTxt = txt.substring(0, 8);
        });
      });
      _dbPeakSubscription =
          flutterSound.onRecorderDbPeakChanged.listen((value) {
        print("got update -> $value");
        setState(() {
          this._dbLevel = value;
        });
      });

      this.setState(() {
        this._isRecording = true;
        this._path = path;
      });
    } catch (err) {
      print('startRecorder error: $err');
    }
  }

  void stopRecorder() async {
    try {
      String result = await flutterSound.stopRecorder();
      print('stopRecorder: $result');

      if (_recorderSubscription != null) {
        _recorderSubscription.cancel();
        _recorderSubscription = null;
      }
      if (_dbPeakSubscription != null) {
        _dbPeakSubscription.cancel();
        _dbPeakSubscription = null;
      }

      this.setState(() {
        this._isRecording = false;
      });
    } catch (err) {
      print('stopRecorder error: $err');
    }
  }

  void startPlayer() async {
    try {
      final audioPath =
          "https://file-examples.com/wp-content/uploads/2017/11/file_example_MP3_700KB.mp3";
      final albumArtPath =
          "https://file-examples.com/wp-content/uploads/2017/10/file_example_PNG_500kB.png";

      final track = Track(
        trackPath: _path ?? audioPath,
        trackTitle: "Song Title",
        trackAuthor: "Song Author",
        albumArtUrl: albumArtPath,
      );
      String path = await flutterSound.startPlayer(track, true, false);
      // await flutterSound.setVolume(1.0);
      print('startPlayer: $path');

      _playbackStateSubscription =
          flutterSound.onPlaybackStateChanged.listen((newState) {
        _playbackState = newState;
        print('The new playack state is: $newState');
      });

      _playerSubscription = flutterSound.onPlayerStateChanged.listen((e) {
        if (e != null) {
          sliderCurrentPosition = e.currentPosition;
          maxDuration = e.duration;

          DateTime date = new DateTime.fromMillisecondsSinceEpoch(
              e.currentPosition.toInt(),
              isUtc: true);
          String txt = DateFormat('mm:ss:SS', 'en_GB').format(date);
          this.setState(() {
            //this._isPlaying = true;
            this._playerTxt = txt.substring(0, 8);
          });
        }
      });
    } catch (err) {
      print('error: $err');
    }
  }

  void stopPlayer() async {
    try {
      String result = await flutterSound.stopPlayer();
      print('stopPlayer: $result');

      this.setState(() {
        //this._isPlaying = false;
      });
    } catch (err) {
      print('error: $err');
    }
  }

  void pausePlayer() async {
    String result = await flutterSound.pausePlayer();
    print('pausePlayer: $result');
  }

  void resumePlayer() async {
    String result = await flutterSound.resumePlayer();
    print('resumePlayer: $result');
  }

  void seekToPlayer(int milliSecs) async {
    String result = await flutterSound.seekToPlayer(milliSecs);
    print('seekToPlayer: $result');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Sound'),
        ),
        body: ListView(
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(top: 24.0, bottom: 16.0),
                  child: Text(
                    this._recorderTxt,
                    style: TextStyle(
                      fontSize: 48.0,
                      color: Colors.black,
                    ),
                  ),
                ),
                _isRecording
                    ? LinearProgressIndicator(
                        value: 100.0 / 160.0 * (this._dbLevel ?? 1) / 100,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                        backgroundColor: Colors.red,
                      )
                    : Container()
              ],
            ),
            Row(
              children: <Widget>[
                Container(
                  width: 56.0,
                  height: 56.0,
                  child: ClipOval(
                    child: FlatButton(
                      onPressed: () {
                        if (!this._isRecording) {
                          return this.startRecorder();
                        }
                        this.stopRecorder();
                      },
                      padding: EdgeInsets.all(8.0),
                      child: Image(
                        image: this._isRecording
                            ? AssetImage('res/icons/ic_stop.png')
                            : AssetImage('res/icons/ic_mic.png'),
                      ),
                    ),
                  ),
                ),
              ],
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(top: 60.0, bottom: 16.0),
                  child: Text(
                    this._playerTxt,
                    style: TextStyle(
                      fontSize: 48.0,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
            !_canDisplayPlayerControls
                ? Container(
                    child: Container(child: CircularProgressIndicator()))
                : Row(
                    children: <Widget>[
                      Container(
                        width: 56.0,
                        height: 56.0,
                        child: ClipOval(
                          child: FlatButton(
                            onPressed: () {
                              if (_playbackState == PlaybackState.PAUSED) {
                                resumePlayer();
                              } else {
                                startPlayer();
                              }
                            },
                            padding: EdgeInsets.all(8.0),
                            child: Image(
                              image: AssetImage('res/icons/ic_play.png'),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 56.0,
                        height: 56.0,
                        child: ClipOval(
                          child: FlatButton(
                            onPressed: () {
                              pausePlayer();
                            },
                            padding: EdgeInsets.all(8.0),
                            child: Image(
                              width: 36.0,
                              height: 36.0,
                              image: AssetImage('res/icons/ic_pause.png'),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 56.0,
                        height: 56.0,
                        child: ClipOval(
                          child: FlatButton(
                            onPressed: () {
                              stopPlayer();
                            },
                            padding: EdgeInsets.all(8.0),
                            child: Image(
                              width: 28.0,
                              height: 28.0,
                              image: AssetImage('res/icons/ic_stop.png'),
                            ),
                          ),
                        ),
                      ),
                    ],
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                  ),
            Container(
              height: 56.0,
              child: Slider(
                  value: sliderCurrentPosition,
                  min: 0.0,
                  max: maxDuration,
                  onChanged: (double value) async {
                    await flutterSound.seekToPlayer(value.toInt());
                  },
                  divisions: maxDuration.toInt()),
            ),
          ],
        ),
      ),
    );
  }
}
