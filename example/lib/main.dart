import 'dart:io';
import 'dart:typed_data' show Uint8List;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:intl/date_symbol_data_local.dart';

import 'dart:async';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter/services.dart' show rootBundle;

enum t_MEDIA
{
        FILE,
        BUFFER,
        ASSET,
        STREAM,
}

void main() {
  runApp(new MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isRecording = false;
  List <String> _path = [null, null, null, null, null, null, null];
  StreamSubscription _recorderSubscription;
  StreamSubscription _dbPeakSubscription;
  StreamSubscription _playerSubscription;
  FlutterSound flutterSound;

  String _recorderTxt = '00:00:00';
  String _playerTxt = '00:00:00';
  double _dbLevel;

  double sliderCurrentPosition = 0.0;
  double maxDuration = 1.0;
  t_MEDIA _media = t_MEDIA.FILE;
  t_CODEC _codec = t_CODEC.CODEC_AAC;
  bool _encoderSupported = true; // Optimist
  bool _decoderSupported = true; // Optimist


  @override
  void initState() {
    super.initState();
    flutterSound = new FlutterSound();
    flutterSound.setSubscriptionDuration(0.01);
    flutterSound.setDbPeakLevelUpdate(0.8);
    flutterSound.setDbLevelEnabled(true);
    initializeDateFormatting();
  }

  void startRecorder() async{
    try {
      // String path = await flutterSound.startRecorder
      // (
      //   paths[_codec.index],
      //   codec: _codec,
      //   sampleRate: 16000,
      //   bitRate: 16000,
      //   numChannels: 1,
      //   androidAudioSource: AndroidAudioSource.MIC,
      // );
      String path = await flutterSound.startRecorder( codec: _codec, );
      print('startRecorder: $path');

      _recorderSubscription = flutterSound.onRecorderStateChanged.listen((e) {
        assert(e != null);
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
        this._path[_codec.index] = path;
      });
    } catch (err) {
      print ('startRecorder error: $err');
      setState (()
                {
                  this._isRecording = false;
                });
    }
  }

  void stopRecorder() async {
    try {
      String result = await flutterSound.stopRecorder();
      print ('stopRecorder: $result');

      if ( _recorderSubscription != null ) {
        _recorderSubscription.cancel ();
        _recorderSubscription = null;
      }
      if ( _dbPeakSubscription != null ) {
        _dbPeakSubscription.cancel ();
        _dbPeakSubscription = null;
      }
    } catch ( err ) {
      print ('stopRecorder error: $err');
    }
    this.setState(() {
      this._isRecording = false;

    });

   }

  Future<bool> fileExists(String path) async {
          return await File(path).exists();
  }

  // In this simple example, we just load a file in memory.This is stupid but just for demonstration  of startPlayerFromBuffer()
  Future <Uint8List> makeBuffer(String path) async {
    try {
      if (!await fileExists(path))
              return null;
      File file = File(path);
      file.openRead();
      var contents = await file.readAsBytes ();
      print ('The file is ${contents.length} bytes long.');
      return contents;
    } catch (e) {
      print(e);
      return null;
    }
  }

  List<String>assetSample =
  [
    'assets/samples/sample.aac',
    'assets/samples/sample.aac',
    'assets/samples/sample.opus',
    'assets/samples/sample.caf',
    'assets/samples/sample.mp3',
    'assets/samples/sample.ogg',
    'assets/samples/sample.wav',
  ];

  void startPlayer() async{
    try {
      String path ;
      if (_media == t_MEDIA.ASSET) { // Do we want to play from Asset ?
          Uint8List buffer =  (await rootBundle.load(assetSample[_codec.index])).buffer.asUint8List();
          path = await flutterSound.startPlayerFromBuffer(buffer, codec: _codec,);
      } else
      if (_media == t_MEDIA.FILE) {// Do we want to play from  file ?
        if (await fileExists(_path[_codec.index]))
          path = await flutterSound.startPlayer(this._path[_codec.index]); // From file
      } else
      if (_media == t_MEDIA.BUFFER) { // Do we want to play from buffer ?
        if (await fileExists(_path[_codec.index])) {
                Uint8List buffer = await makeBuffer (this._path[_codec.index]);
                if ( buffer != null )
                        path = await flutterSound.startPlayerFromBuffer(buffer, codec: _codec,); // From buffer
        }
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
    setState(() {} );
  }

  void stopPlayer() async{
    try {
      String result = await flutterSound.stopPlayer();
      print('stopPlayer: $result');
      if (_playerSubscription != null) {
        _playerSubscription.cancel();
        _playerSubscription = null;
      }
      sliderCurrentPosition = 0.0;
      } catch (err) {
      print('error: $err');
    }
    this.setState(() {
      //this._isPlaying = false;
    });

  }

  void pausePlayer() async{
    String result;
    try {
      if ( flutterSound.audioState == t_AUDIO_STATE.IS_PAUSED ) {
        result = await flutterSound.resumePlayer ();
        print ('resumePlayer: $result');
      } else {
        result = await flutterSound.pausePlayer ();
        print ('pausePlayer: $result');
      }
    } catch(err) {
      print('error: $err');
    }
    setState(() {} );
  }

  void seekToPlayer(int milliSecs) async{
    String result = await flutterSound.seekToPlayer(milliSecs);
    print('seekToPlayer: $result');
  }


  onPausePlayerPressed() {
          return flutterSound.audioState == t_AUDIO_STATE.IS_PLAYING || flutterSound.audioState == t_AUDIO_STATE.IS_PAUSED ?  pausePlayer : null;
  }

  onStopPlayerPressed() {
          return flutterSound.audioState == t_AUDIO_STATE.IS_PLAYING  || flutterSound.audioState == t_AUDIO_STATE.IS_PAUSED ?  stopPlayer : null;
  }

  onStartPlayerPressed() {
        if (_media == t_MEDIA.FILE || _media == t_MEDIA.BUFFER)
        {
          if ( _path[_codec.index] == null )
            return null;
        }
       // Disable the button if the selected codec is not supported
        if ( ! _decoderSupported )
          return null;
        return  flutterSound.audioState == t_AUDIO_STATE.IS_STOPPED ? startPlayer : null;
  }

  onStartRecorderPressed() {
    if (_media == t_MEDIA.ASSET || _media == t_MEDIA.BUFFER)
      return null;
    if (flutterSound.audioState == t_AUDIO_STATE.IS_RECORDING)
            return stopRecorder;
    // Disable the button if the selected codec is not supported
    if ( ! _encoderSupported )
      return null;

    return  flutterSound.audioState == t_AUDIO_STATE.IS_STOPPED ? startRecorder : null;
  }

  AssetImage recorderAssetImage() {
    if (onStartRecorderPressed() == null)
      return  AssetImage('res/icons/ic_mic_disabled.png');
          return flutterSound.audioState == t_AUDIO_STATE.IS_STOPPED ?  AssetImage('res/icons/ic_mic.png') : AssetImage('res/icons/ic_stop.png');
  }

  setCodec (t_CODEC codec) async {
    _encoderSupported = await flutterSound.isEncoderSupported(codec);
    _decoderSupported = await flutterSound.isDecoderSupported(codec);

    setState
      (() {_codec = codec;});
  }

  Widget makeNavigationBar(BuildContext context) {
    return ButtonBar
      (
      mainAxisSize: MainAxisSize.max, // this will take space as minimum as posible(to center)
      children: <Widget>
      [
        Text('Media'),
        Container
          (
          margin: const EdgeInsets.all(0.0),
          padding: const EdgeInsets.all(0.0),
          decoration: BoxDecoration
            (
            color: Color(0xFFC6E5E2),
            border: Border.all (color: Color(0xFF2F2376), width: 3,),
            ),

          child: Row
            (
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children:
            [
              Radio
                (
                value: t_MEDIA.FILE,
                groupValue: _media,
                onChanged: (radioBtn)
                {
                  setState
                    (() {_media = radioBtn;});
                },
                ),
              new Text('File'),

              Radio
                (
                value: t_MEDIA.BUFFER,
                groupValue: _media,
                onChanged: (radioBtn)
                {
                  setState
                    (() {_media = radioBtn;});
                },
                ),
              new Text('Buffer'),

              Radio
                (
                value: t_MEDIA.ASSET,
                groupValue: _media,
                onChanged: (radioBtn)
                {
                  setState
                    (() {_media = radioBtn;});
                },
                ),
              new Text('Asset'),



            ],
            ),
          ),
        Divider(),

        Text('Codec'),
  Container
  (
    height:105,
    margin: const EdgeInsets.all(0.0),
    padding: const EdgeInsets.all(0.0),
    decoration: BoxDecoration
    (
      color: Color(0xFFC6E5E2),
      border: Border.all (color: Color(0xFF2F2376), width: 3,),
    ),

    child: Column
    (
        children:
        [
            Container
            (
            color: Color(0xFFC6E5E2),
            child: Row
              (
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children:
              [
                Radio
                  (
                  value: t_CODEC.CODEC_AAC,
                  groupValue: _codec,
                  onChanged: setCodec,
                  ),
                Text('AAC'),

                Radio
                  (
                  value: t_CODEC.CODEC_OPUS,
                  groupValue: _codec,
                  onChanged: setCodec,
                  ),
                Text('OGG/Opus'),

                Radio
                  (
                  value: t_CODEC.CODEC_CAF_OPUS,
                  groupValue: _codec,
                  onChanged: setCodec,
                  ),
                Text('CAF/Opus'),
              ],
              ),
            ),

        Container
          (
          color: Color(0xFFC6E5E2),
          child: Row
            (
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children:
            [
              Radio
                (
                value: t_CODEC.CODEC_MP3,
                groupValue: _codec,
                onChanged: setCodec,
                ),
              Text('MP3'),

              Radio
                (
                value: t_CODEC.CODEC_VORBIS,
                groupValue: _codec,
                onChanged: setCodec,
                ),
              Text('OGG/Vorbis'),

              Radio
                (
                value: t_CODEC.CODEC_PCM,
                groupValue: _codec,
                onChanged: setCodec,
                ),
              Text('PCM'),
            ],
            ),
          ),
    ],
      ),
    ),

      ],
      )
    ;

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
                  margin: EdgeInsets.only(top: 12.0, bottom:16.0),
                  child: Text(
                    this._recorderTxt,
                    style: TextStyle(
                      fontSize: 35.0,
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
              ],
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(top: 12.0, bottom:16.0),
                  child: Text(
                    this._playerTxt,
                    style: TextStyle(
                      fontSize: 35.0,
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
                  height: 50.0,
                  child: ClipOval(
                    child: FlatButton(
                      onPressed: onStartPlayerPressed(),
                      disabledColor: Colors.white,
                      padding: EdgeInsets.all(8.0),
                      child: Image(
                        image: AssetImage(onStartPlayerPressed() != null ? 'res/icons/ic_play.png' : 'res/icons/ic_play_disabled.png'),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 56.0,
                  height: 50.0,
                  child: ClipOval(
                    child: FlatButton(
                      onPressed: onPausePlayerPressed(),
                      disabledColor: Colors.white,
                      padding: EdgeInsets.all(8.0),
                      child: Image(
                        width: 36.0,
                        height: 36.0,
                        image: AssetImage(onPausePlayerPressed() != null ? 'res/icons/ic_pause.png' : 'res/icons/ic_pause_disabled.png'),
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
                        image: AssetImage(onStopPlayerPressed() != null ? 'res/icons/ic_stop.png' : 'res/icons/ic_stop_disabled.png'),
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
           ],
        ),
        bottomNavigationBar: makeNavigationBar(context),
      ),
    );
  }
}
