import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/android_encoder.dart';
import 'package:flutter_sound/ios_quality.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:intl/date_symbol_data_local.dart';

import 'dart:io';
import 'dart:async';
import 'package:flutter_sound/flutter_sound.dart';

void main() {
  runApp(new MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isRecording = false;
  bool _isPlaying = false;
  StreamSubscription _recorderSubscription;
  StreamSubscription _dbPeakSubscription;
  StreamSubscription _playerSubscription;
  FlutterSound flutterSound;

  String _recorderTxt = '00:00:00';
  String _playerTxt = '00:00:00';
  double _dbLevel;

  double slider_current_position = 0.0;
  double max_duration = 1.0;

  TextEditingController _sampleRateController =
      TextEditingController(text: '44100');
  TextEditingController _numChannelsController =
      TextEditingController(text: '2');
  TextEditingController _bitRateController = TextEditingController(text: '');
  AndroidEncoder _androidEncoder = AndroidEncoder.DEFAULT;
  IosQuality _iosQuality = IosQuality.LOW;

  @override
  void initState() {
    super.initState();
    flutterSound = new FlutterSound();
    flutterSound.setSubscriptionDuration(0.01);
    flutterSound.setDbPeakLevelUpdate(0.8);
    flutterSound.setDbLevelEnabled(true);
    initializeDateFormatting();
  }

  void startRecorder() async {
    try {
      String path = await flutterSound.startRecorder(
        null,
        sampleRate: int.tryParse(_sampleRateController.text) ?? 44100,
        numChannels: int.tryParse(_numChannelsController.text) ?? 2,
        bitRate: int.tryParse(_bitRateController.text),
        androidEncoder: _androidEncoder,
        iosQuality: _iosQuality,
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
    String path = await flutterSound.startPlayer(null);
    await flutterSound.setVolume(1.0);
    print('startPlayer: $path');

    try {
      _playerSubscription = flutterSound.onPlayerStateChanged.listen((e) {
        if (e != null) {
          slider_current_position = e.currentPosition;
          max_duration = e.duration;

          DateTime date = new DateTime.fromMillisecondsSinceEpoch(
              e.currentPosition.toInt(),
              isUtc: true);
          String txt = DateFormat('mm:ss:SS', 'en_GB').format(date);
          this.setState(() {
            this._isPlaying = true;
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
      if (_playerSubscription != null) {
        _playerSubscription.cancel();
        _playerSubscription = null;
      }

      this.setState(() {
        this._isPlaying = false;
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
    int secs = Platform.isIOS ? milliSecs / 1000 : milliSecs;

    String result = await flutterSound.seekToPlayer(secs);
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
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Builder(
                builder: (context) {
                  return FlatButton(
                    child: Text('CHANGE RECORDER SETTINGS'),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return _buildRecordingSettingsDialog();
                        },
                      );
                    },
                  );
                },
              ),
            ),
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
                    value: slider_current_position,
                    min: 0.0,
                    max: max_duration,
                    onChanged: (double value) async {
                      await flutterSound.seekToPlayer(value.toInt());
                    },
                    divisions: max_duration.toInt()))
          ],
        ),
      ),
    );
  }

  AlertDialog _buildRecordingSettingsDialog() {
    const Map<String, AndroidEncoder> androidEncoderMap = {
      'Default': AndroidEncoder.DEFAULT,
      'AMR_NB': AndroidEncoder.AMR_NB,
      'AMR_WB': AndroidEncoder.AMR_WB,
      'AAC': AndroidEncoder.AAC,
      'HE_AAC': AndroidEncoder.HE_AAC,
      'AAC_ELD': AndroidEncoder.AAC_ELD,
      'VORBIS': AndroidEncoder.VORBIS,
    };

    const Map<String, IosQuality> iosQualityMap = {
      'Min': IosQuality.MIN,
      'Low': IosQuality.LOW,
      'Medium': IosQuality.MEDIUM,
      'High': IosQuality.HIGH,
      'Max': IosQuality.MAX,
    };

    return AlertDialog(
      title: Text('Recording Settings'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('Sample Rate'),
            TextField(
              controller: _sampleRateController,
              inputFormatters: [
                WhitelistingTextInputFormatter(RegExp(r'[0-9]')),
              ],
              keyboardType: TextInputType.number,
            ),
            Divider(),
            Text('Num Channels'),
            TextField(
              controller: _numChannelsController,
              inputFormatters: [
                WhitelistingTextInputFormatter(RegExp(r'[0-9]')),
              ],
              keyboardType: TextInputType.number,
            ),
            Divider(),
            Text('Bitrate'),
            TextField(
              controller: _bitRateController,
              inputFormatters: [
                WhitelistingTextInputFormatter(RegExp(r'[0-9]')),
              ],
              keyboardType: TextInputType.number,
            ),
            Divider(),
            Text('Audio Codec (Android)'),
            DropdownButton<AndroidEncoder>(
              value: _androidEncoder,
              items: androidEncoderMap.keys.map(
                (e) {
                  return DropdownMenuItem(
                    child: Text(e),
                    value: androidEncoderMap[e],
                  );
                },
              ).toList(),
              onChanged: (e) {
                setState(() {
                  _androidEncoder = e;
                });
              },
            ),
            Divider(),
            Text('Recording Quality (iOS)'),
            DropdownButton<IosQuality>(
              value: _iosQuality,
              items: iosQualityMap.keys.map(
                (e) {
                  return DropdownMenuItem(
                    child: Text(e),
                    value: iosQualityMap[e],
                  );
                },
              ).toList(),
              onChanged: (e) {
                setState(() {
                  _iosQuality = e;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
