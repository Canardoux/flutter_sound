import 'dart:io';
import 'dart:typed_data' show Uint8List;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:intl/date_symbol_data_local.dart';

import 'dart:async';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound/android_encoder.dart';

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
  // bool _isPlaying = false;
  StreamSubscription _recorderSubscription;
  StreamSubscription _dbPeakSubscription;
  StreamSubscription _playerSubscription;
  FlutterSound flutterSound;

  String _recorderTxt = '00:00:00';
  String _playerTxt = '00:00:00';
  double _dbLevel;

  double sliderCurrentPosition = 0.0;
  double maxDuration = 1.0;
  int _playFromBuffer = 0;
  t_CODEC _codec = t_CODEC.CODEC_AAC;

  @override
  void initState() {
    super.initState();
    flutterSound = new FlutterSound();
    flutterSound.setSubscriptionDuration(0.01);
    flutterSound.setDbPeakLevelUpdate(0.8);
    flutterSound.setDbLevelEnabled(true);
    initializeDateFormatting();
  }

  static const List<String> paths =
  [
  		'sound.aac',	// DEFAULT
  		'sound.aac',	// CODEC_AAC
  		'sound.opus',	// CODEC_OPUS 
  		'sound.caf',	// CODEC_CAF_OPUS 
  		'sound.mp3',	// CODEC_MP3 
  		'sound.ogg',	// CODEC_VORBIS
  		'sound.wav',	// CODEC_PCM 
];
  void startRecorder() async{
    try {
      String path = await flutterSound.startRecorder
      (
        paths[_codec.index],
        codec: _codec,
        sampleRate: 16000,
        bitRate: 16000,
        numChannels: 1,
        //androidEncoder: AndroidEncoder.AAC, // Kept for ascendant compatibility. But it conflits with "codec:" parameter
        androidAudioSource: AndroidAudioSource.MIC,
      );
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

  void stopRecorder() async{
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

  Future <Uint8List> makeBuffer(String path) async
  {

    try
    {
      File file = File(path);
      file.openRead();
      var contents = await file.readAsBytes ();
      print ('The file is ${contents.length} bytes long.');
      return contents;
    } catch (e)
    {
      print(e);
      return null;
    }
  }

  void startPlayer() async{
    try {
      String path = null;
      if (_playFromBuffer == 0) { // Do we want to play from buffer or from file ?
        path = await flutterSound.startPlayer(this._path); // From file

      } else {
        Uint8List buffer = await makeBuffer(this._path);
        if (buffer != null)
          path = await flutterSound.startPlayerFromBuffer(buffer); // From buffer
      }
      if (path == null) {
        print ('Error starting player');
        return;
      }
       print('startPlayer: $path');
       await flutterSound.setVolume(1.0);

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

  void stopPlayer() async{
    try {
      String result = await flutterSound.stopPlayer();
      print('stopPlayer: $result');
      if (_playerSubscription != null) {
        _playerSubscription.cancel();
        _playerSubscription = null;
      }

      this.setState(() {
        //this._isPlaying = false;
      });
    } catch (err) {
      print('error: $err');
    }
  }

  void pausePlayer() async{
    String result = await flutterSound.pausePlayer();
    print('pausePlayer: $result');
  }

  void resumePlayer() async{
    String result = await flutterSound.resumePlayer();
    print('resumePlayer: $result');
  }

  void seekToPlayer(int milliSecs) async{
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
            Visibility(
              visible: (!Platform.isAndroid) ,
            child: Container
              (
              color: Color(0xFFC0C0C0),
              child: Row
                (
                children:
                [
                  Radio
                    (
                    value: t_CODEC.CODEC_AAC,
                    groupValue: _codec,
                    onChanged: (radioBtn)
                    {
                      setState
                        (() {_codec = radioBtn;});
                    },
                    ),
                  Text('AAC'),
                  Radio
                    (
                    value: t_CODEC.CODEC_CAF_OPUS,
                    groupValue: _codec,
                    onChanged: (radioBtn)
                    {
                      setState
                        (() {_codec = radioBtn;});
                    },
                    ),
                  Text('caf/opus'),
                ],
                ),
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(top: 24.0, bottom:16.0),
                  child: Text(
                    this._recorderTxt,
                    style: TextStyle(
                      fontSize: 48.0,
                      color: Colors.black,
                    ),
                  ),
                ),
                _isRecording ? LinearProgressIndicator(
                  value: 100.0 / 160.0 * (this._dbLevel ?? 1) / 100,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  backgroundColor: Colors.red,
                ) : Container()
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
                        image: this._isRecording ? AssetImage('res/icons/ic_stop.png') : AssetImage('res/icons/ic_mic.png'),
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
                  margin: EdgeInsets.only(top: 30.0, bottom:16.0),
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
            Row(
              children: <Widget>[
                Container(
                  width: 56.0,
                  height: 56.0,
                  child: ClipOval(
                    child: FlatButton(
                      onPressed: () {
                        startPlayer();
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
                onChanged: (double value) async{
                  await flutterSound.seekToPlayer(value.toInt());
                },
                divisions: maxDuration.toInt()
              )
            ),
            Container
              (
              color: Color(0xFFC0C0C0),
              child: Row
                (
                children:
                    [
                Radio
                  (
                  value: 0,
                  groupValue: _playFromBuffer,
                  onChanged: (radioBtn)
                  {
                    setState
                      (() {_playFromBuffer = radioBtn;});
                    },
                  ),
              new Text('Play from file'),
                Radio
                  (
                  value: 1,
                  groupValue: _playFromBuffer,
                  onChanged: (radioBtn)
                  {
                    setState
                      (() {_playFromBuffer = radioBtn;});
                  },
                  ),
                new Text('Play from buffer'),

                    ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
