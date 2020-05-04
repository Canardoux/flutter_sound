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

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data' show Uint8List;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart' ;
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:flutter_sound/flutter_sound.dart';

enum Media {
  file,
  buffer,
  asset,
  stream,
  remoteExampleFile,
}
enum AudioState {
  isPlaying,
  isPaused,
  isStopped,
  isRecording,
  isRecordingPaused,
}

/// Boolean to specify if we want to test the Rentrance/Concurency feature.
/// If true, we start two instances of FlautoPlayer when the user hit the "Play" button.
/// If true, we start two instances of FlautoRecorder and one instance of FlautoPlayer when the user hit the Record button
final exampleAudioFilePath = "https://file-examples.com/wp-content/uploads/2017/11/file_example_MP3_700KB.mp3";
final albumArtPath = "https://file-examples.com/wp-content/uploads/2017/10/file_example_PNG_500kB.png";

void main() {
  runApp(new MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isRecording = false;
  List<String> _path = [null, null, null, null, null, null, null, null, null, null, null, null,];
  StreamSubscription _recorderSubscription;
  StreamSubscription _dbPeakSubscription;
  StreamSubscription _playerSubscription;
  StreamSubscription _playbackStateSubscription;

  FlutterSoundPlayer playerModule;
  FlutterSoundRecorder recorderModule;

  String _recorderTxt = '00:00:00';
  String _playerTxt = '00:00:00';
  double _dbLevel;

  double sliderCurrentPosition = 0.0;
  double maxDuration = 1.0;
  Media _media = Media.file;
  FlutterSoundCodec _codec = FlutterSoundCodec.aacADTS;

  bool _encoderSupported = true; // Optimist
  bool _decoderSupported = true; // Optimist

  // Whether the user wants to use the audio player features
  bool _isAudioPlayer = false;
  bool _duckOthers = false;

  double _duration = null;

  Future<void> _initializeExample(FlutterSoundPlayer module) async {
    playerModule = module;

    await module.initialize();
    await playerModule.setSubscriptionDuration(0.01);
    await recorderModule.setSubscriptionDuration(0.01);
    initializeDateFormatting();
    setCodec(_codec);
    setDuck();
  }

  Future<void> init() async {
    playerModule = await FlutterSoundPlayer().initialize();
    recorderModule = await FlutterSoundRecorder().initialize();
    await _initializeExample(playerModule);

    await recorderModule.setDbPeakLevelUpdate(0.8);
    await recorderModule.setDbLevelEnabled(true);
    await recorderModule.setDbLevelEnabled(true);
    if (Platform.isAndroid) {
      copyAssets();
    }


  }

  Future<void>copyAssets() async {
    Uint8List dataBuffer = (await rootBundle.load("assets/canardo.png" )).buffer.asUint8List( );
    String path = await playerModule.getResourcePath() + "/assets";
    if (!await Directory(path).exists()) {
      await Directory(path).create(recursive: true);
    }
    await File(path + '/canardo.png').writeAsBytes(dataBuffer);
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  AudioState get audioState {
    if (playerModule != null) {
      if (playerModule.isPlaying) return AudioState.isPlaying;
      if (playerModule.isPaused) return AudioState.isPaused;
    }
    if (recorderModule != null) {
      if (recorderModule.isPaused) return AudioState.isRecordingPaused;
      if (recorderModule.isRecording) return AudioState.isRecording;
    }
    return AudioState.isStopped;
  }

  void cancelRecorderSubscriptions() {
    if (_recorderSubscription != null) {
      _recorderSubscription.cancel();
      _recorderSubscription = null;
    }
    if (_dbPeakSubscription != null) {
      _dbPeakSubscription.cancel();
      _dbPeakSubscription = null;
    }
  }

  void cancelPlayerSubscriptions() {
    if (_playerSubscription != null) {
      _playerSubscription.cancel();
      _playerSubscription = null;
    }

    if (_playbackStateSubscription != null) {
      _playbackStateSubscription.cancel();
      _playbackStateSubscription = null;
    }
  }

  @override
  void dispose() {
    super.dispose();
    cancelPlayerSubscriptions();
    cancelRecorderSubscriptions();
    releaseFlauto();
  }

  Future<void> setDuck() async {
    if (_duckOthers) {
      if (Platform.isIOS)
        await playerModule.iosSetCategory(SessionCategory.playAndRecord, SessionMode.defaultSessionMode, iosDuckOthers | iosDefaultToSpeaker);
      else if (Platform.isAndroid) await playerModule.androidAudioFocusRequest(AndroidFocusGain.audioFocusGainTransientMayDuck.index);
    } else {
      if (Platform.isIOS)
        await playerModule.iosSetCategory(SessionCategory.playAndRecord, SessionMode.defaultSessionMode, iosDefaultToSpeaker);
      else if (Platform.isAndroid) await playerModule.androidAudioFocusRequest(AndroidFocusGain.audioFocusGain.index);
    }
  }

  Future<void> releaseFlauto() async {
    try {
      await playerModule.release();
      await recorderModule.release();
    } catch (e) {
      print('Released unsuccessful');
      print(e);
    }
  }




  void startRecorder() async {
    try {
      // String path = await flutterSoundModule.startRecorder
      // (
      //   paths[_codec.index],
      //   codec: _codec,
      //   sampleRate: 16000,
      //   bitRate: 16000,
      //   numChannels: 1,
      //   androidAudioSource: AndroidAudioSource.MIC,
      // );
      Directory tempDir = await getTemporaryDirectory();

      String path = await recorderModule.startRecorder(
        uri: '${tempDir.path}/${recorderModule.slotNo}-flutter_sound${ext[_codec.index]}',
        codec: _codec,
      );
      print('startRecorder: $path');

      _recorderSubscription = recorderModule.onRecorderStateChanged.listen((e) {
        if (e != null && e.currentPosition != null) {
          DateTime date = new DateTime.fromMillisecondsSinceEpoch(e.currentPosition.toInt(), isUtc: true);
          String txt = DateFormat('mm:ss:SS', 'en_GB').format(date);

          this.setState(() {
            this._recorderTxt = txt.substring(0, 8);
          });
        }
      });
      _dbPeakSubscription = recorderModule.onRecorderDbPeakChanged.listen((value) {
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
      print('startRecorder error: $err');
      setState(() {
        stopRecorder();
        this._isRecording = false;
        if (_recorderSubscription != null) {
          _recorderSubscription.cancel();
          _recorderSubscription = null;
        }
        if (_dbPeakSubscription != null) {
          _dbPeakSubscription.cancel();
          _dbPeakSubscription = null;
        }
      });
    }
  }

  Future<void> getDuration() async {
    switch (_media) {
      case Media.file:
      case Media.buffer:
        int d = await flutterSoundHelper.duration(this._path[_codec.index]);
        _duration = d != null ? d / 1000.0 : null;
        break;
      case Media.asset:
        _duration = null;
        break;
      case Media.remoteExampleFile:
        _duration = null;
        break;
    }
    setState(() {});
  }

  void stopRecorder() async {
    try {
      String result = await recorderModule.stopRecorder();
      print('stopRecorder: $result');
      cancelRecorderSubscriptions();
      getDuration();
    } catch (err) {
      print('stopRecorder error: $err');
    }
    this.setState(() {
      this._isRecording = false;
    });
  }

  Future<bool> fileExists(String path) async {
    return await File(path).exists();
  }

  // In this simple example, we just load a file in memory.This is stupid but just for demonstration  of startPlayerFromBuffer()
  Future<Uint8List> makeBuffer(String path) async {
    try {
      if (!await fileExists(path)) return null;
      File file = File(path);
      file.openRead();
      var contents = await file.readAsBytes();
      print('The file is ${contents.length} bytes long.');
      return contents;
    } catch (e) {
      print(e);
      return null;
    }
  }

  List<String> assetSample = [
    'assets/samples/sample.aac',
    'assets/samples/sample.aac',
    'assets/samples/sample.opus',
    'assets/samples/sample_opus.caf',
    'assets/samples/sample.mp3',
    'assets/samples/sample.ogg',
    'assets/samples/sample.pcm',
    'assets/samples/sample.wav',
    'assets/samples/sample.aiff',
    'assets/samples/sample_pcm.caf',
    'assets/samples/sample.flac',
    'assets/samples/sample.mp4',
    'assets/samples/sample.3gp',
  ];



  void _addListeners() {
    cancelPlayerSubscriptions();
    _playerSubscription = playerModule.onPlayerStateChanged.listen((e) {
      if (e != null) {
        maxDuration = e.duration;
        if (maxDuration <= 0) maxDuration = 0.0;

        sliderCurrentPosition = min(e.currentPosition, maxDuration);
        if (sliderCurrentPosition < 0.0) {
          sliderCurrentPosition = 0.0;
        }

        DateTime date = new DateTime.fromMillisecondsSinceEpoch(e.currentPosition.toInt(), isUtc: true);
        String txt = DateFormat('mm:ss:SS', 'en_GB').format(date);
        this.setState(() {
          //this._isPlaying = true;
          this._playerTxt = txt.substring(0, 8);
        });
      }
    });
  }

  Future<void> startPlayer() async {
    try {
      String path;
      Uint8List dataBuffer;
      String audioFilePath;
      if (_media == Media.asset) {
        dataBuffer = (await rootBundle.load(assetSample[_codec.index])).buffer.asUint8List();
      } else if (_media == Media.file) {
        // Do we want to play from buffer or from file ?
        if (await fileExists(_path[_codec.index])) audioFilePath = this._path[_codec.index];
      } else if (_media == Media.buffer) {
        // Do we want to play from buffer or from file ?
        if (await fileExists(_path[_codec.index])) {
          dataBuffer = await makeBuffer(this._path[_codec.index]);
          if (dataBuffer == null) {
            throw Exception('Unable to create the buffer');
          }
        }
      } else if (_media == Media.remoteExampleFile) {
        // We have to play an example audio file loaded via a URL
        audioFilePath = exampleAudioFilePath;
      }

      // Check whether the user wants to use the audio player features
      if (_isAudioPlayer) {
        String albumArtUrl;
        String albumArtAsset;
        String albumArtFile;
        if (_media == Media.remoteExampleFile)
          albumArtUrl = albumArtPath;
        else {

          if (true) {
            albumArtFile = await playerModule.getResourcePath() + "/assets/canardo.png";
            print(albumArtFile);
          } else {

            if (Platform.isIOS) {
              albumArtAsset = 'AppIcon';
            } else if (Platform.isAndroid) {
              albumArtAsset = 'AppIcon.png';
            }
          }
        }

        final track = Track(
          trackPath: audioFilePath,
          dataBuffer: dataBuffer,
          codec: _codec,
          trackTitle: "This is a record",
          trackAuthor: "from flutter_sound",
          albumArtUrl: albumArtUrl,
          albumArtAsset: albumArtAsset,
          albumArtFile: albumArtFile,
        );

        TrackPlayer f = playerModule as TrackPlayer;
        path = await f.startPlayerFromTrack(
          track,
          /*canSkipForward:true, canSkipBackward:true,*/
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
        );
      } else {
        if (audioFilePath != null) {
          path = await playerModule.startPlayer(audioFilePath, codec: _codec, whenFinished: () {
            print('Play finished');
            setState(() {});
          });
        } else if (dataBuffer != null) {
          path = await playerModule.startPlayerFromBuffer(dataBuffer, codec: _codec, whenFinished: () {
            print('Play finished');
            setState(() {});
          });
        }

        if (path == null) {
          print('Error starting player');
          return;
        }
      }
      _addListeners();
       print('startPlayer: $path');
      // await flutterSoundModule.setVolume(1.0);
    } catch (err) {
      print('error: $err');
    }
    setState(() {});
  }

  Future<void> stopPlayer() async {
    try {
      String result = await playerModule.stopPlayer();
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

  void pauseResumePlayer() {
    if (playerModule.isPlaying) {
      playerModule.pausePlayer();
     } else {
      playerModule.resumePlayer();
     }
  }

  void pauseResumeRecorder() {
    if (recorderModule.isPaused) {
      {
        recorderModule.resumeRecorder();
       }
    } else {
      recorderModule.pauseRecorder();
     }
  }

  void seekToPlayer(int milliSecs) async {
    String result = await playerModule.seekToPlayer(milliSecs);
    print('seekToPlayer: $result');
  }

  Widget makeDropdowns(BuildContext context) {
    final mediaDropdown = Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Text('Media:'),
        ),
        DropdownButton<Media>(
          value: _media,
          onChanged: (newMedia) {
            if (newMedia == Media.remoteExampleFile) _codec = FlutterSoundCodec.mp3; // Actually this is the only example we use in this example
            _media = newMedia;
            getDuration();
            setState(() {});
          },
          items: <DropdownMenuItem<Media>>[
            DropdownMenuItem<Media>(
              value: Media.file,
              child: Text('File'),
            ),
            DropdownMenuItem<Media>(
              value: Media.buffer,
              child: Text('Buffer'),
            ),
            DropdownMenuItem<Media>(
              value: Media.asset,
              child: Text('Asset'),
            ),
            DropdownMenuItem<Media>(
              value: Media.remoteExampleFile,
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
        DropdownButton<FlutterSoundCodec>(
          value: _codec,
          onChanged: (newCodec) {
            setCodec(newCodec);
            _codec = newCodec;
            getDuration();
            setState(() {});
          },

          items: <DropdownMenuItem<FlutterSoundCodec>>[
            DropdownMenuItem<FlutterSoundCodec>(
              value: FlutterSoundCodec.aacADTS,
              child: Text('AAC/ADTS'),
            ),
            DropdownMenuItem<FlutterSoundCodec>(
              value: FlutterSoundCodec.opusOGG,
              child: Text('Opus/OGG'),
            ),
            DropdownMenuItem<FlutterSoundCodec>(
              value: FlutterSoundCodec.opusCAF,
              child: Text('Opus/CAF'),
            ),
            DropdownMenuItem<FlutterSoundCodec>(
              value: FlutterSoundCodec.mp3,
              child: Text('MP3'),
            ),
            DropdownMenuItem<FlutterSoundCodec>(
              value: FlutterSoundCodec.vorbisOGG,
              child: Text('Vorbis/OGG'),
            ),
            DropdownMenuItem<FlutterSoundCodec>(
              value: FlutterSoundCodec.pcm16,
              child: Text('PCM16'),
            ),
            DropdownMenuItem<FlutterSoundCodec>(
              value: FlutterSoundCodec.pcm16WAV,
              child: Text('PCM16/WAV'),
            ),
            DropdownMenuItem<FlutterSoundCodec>(
              value: FlutterSoundCodec.pcm16AIFF,
              child: Text('PCM16/AIFF'),
            ),
            DropdownMenuItem<FlutterSoundCodec>(
              value: FlutterSoundCodec.pcm16CAF,
              child: Text('PCM16/CAF'),
            ),
            DropdownMenuItem<FlutterSoundCodec>(
              value: FlutterSoundCodec.flac,
              child: Text('FLAC'),
            ),
            DropdownMenuItem<FlutterSoundCodec>(
              value: FlutterSoundCodec.aacMP4,
              child: Text('AAC/MP4'),
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

 void Function()  onPauseResumePlayerPressed() {
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
  }

 void Function()  onStopPlayerPressed() {
    return audioState == AudioState.isPlaying || audioState == AudioState.isPaused ? stopPlayer : null;
  }

  void Function() onStartPlayerPressed() {
    if (_media == Media.file || _media == Media.buffer) // A file must be already recorded to play it
    {
      if (_path[_codec.index] == null) return null;
    }
    if (_media == Media.remoteExampleFile && _codec != FlutterSoundCodec.mp3) // in this example we use just a remote mp3 file
      return null;

    // Disable the button if the selected codec is not supported
    if (!_decoderSupported) return null;
    return (isStopped()) ? startPlayer : null;
  }

  void startStopRecorder() {
    if (recorderModule.isRecording || recorderModule.isPaused)
      stopRecorder();
    else
      startRecorder();
  }

  void Function() onStartRecorderPressed() {
    if (_media == Media.asset || _media == Media.buffer || _media == Media.remoteExampleFile) return null;
    // Disable the button if the selected codec is not supported
    if (!_encoderSupported) return null;
    if (audioState != AudioState.isRecording && audioState != AudioState.isRecordingPaused && audioState != AudioState.isStopped) return null;
    return startStopRecorder;
  }

  bool isStopped() => (audioState == AudioState.isStopped);

  AssetImage recorderAssetImage() {
    if (onStartRecorderPressed() == null) return AssetImage('res/icons/ic_mic_disabled.png');
    return audioState == AudioState.isStopped ? AssetImage('res/icons/ic_mic.png') : AssetImage('res/icons/ic_stop.png');
  }

  void setCodec(FlutterSoundCodec codec) async {
    _encoderSupported = await recorderModule.isEncoderSupported(codec);
    _decoderSupported = await playerModule.isDecoderSupported(codec);

    setState(() {
      _codec = codec;
    });
  }

 void Function(bool) audioPlayerSwitchChanged() {
    if (!isStopped()) return null;
    return ((bool newVal) async {
      try {
        if (playerModule != null) await playerModule.release();

        _isAudioPlayer = newVal;
        if (!newVal) {
          _initializeExample(FlutterSoundPlayer());
        } else {
          _initializeExample(TrackPlayer());
        }
        setState(() {});
      } catch (err) {
        print(err);
      }
    });
  }

 void Function(bool) duckOthersSwitchChanged() {
    return ((bool newVal) async {
      _duckOthers = newVal;

      try {
        setDuck();
        setState(() {});
      } catch (err) {
        print(err);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final recorderProgressIndicator = _isRecording
        ? LinearProgressIndicator(
            value: 100.0 / 160.0 * (this._dbLevel ?? 1) / 100,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            backgroundColor: Colors.red,
          )
        : Container();
    final playerControls = Row(
      children: <Widget>[
        Container(
          width: 56.0,
          height: 56.0,
          child: ClipOval(
            child: FlatButton(
              onPressed: onStartPlayerPressed(),
              padding: EdgeInsets.all(8.0),
              child: Image(
                image: AssetImage(onStartPlayerPressed() != null ? 'res/icons/ic_play.png' : 'res/icons/ic_play_disabled.png'),
              ),
            ),
          ),
        ),
        Container(
          width: 56.0,
          height: 56.0,
          child: ClipOval(
            child: FlatButton(
              onPressed: onPauseResumePlayerPressed(),
              padding: EdgeInsets.all(8.0),
              child: Image(
                width: 36.0,
                height: 36.0,
                image: AssetImage(onPauseResumePlayerPressed() != null ? 'res/icons/ic_pause.png' : 'res/icons/ic_pause_disabled.png'),
              ),
            ),
          ),
        ),
        Container(
          width: 56.0,
          height: 56.0,
          child: ClipOval(
            child: FlatButton(
              onPressed: onStopPlayerPressed(),
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
    );
    final playerSlider = Container(
        height: 56.0,
        child: Slider(
            value: min(sliderCurrentPosition, maxDuration),
            min: 0.0,
            max: maxDuration,
            onChanged: (double value) async {
              await playerModule.seekToPlayer(value.toInt());
            },
            divisions: maxDuration == 0.0 ? 1 : maxDuration.toInt()));

    final dropdowns = makeDropdowns(context);
    final trackSwitch = Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text('"Flauto":'),
          ),
          Switch(
            value: _isAudioPlayer,
            onChanged: audioPlayerSwitchChanged(),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: Text('Duck Others:'),
          ),
          Switch(
            value: _duckOthers,
            onChanged: duckOthersSwitchChanged(),
          ),
        ],
      ),
    );

    Widget recorderSection = Column(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
      Container(
        margin: EdgeInsets.only(top: 12.0, bottom: 16.0),
        child: Text(
          this._recorderTxt,
          style: TextStyle(
            fontSize: 35.0,
            color: Colors.black,
          ),
        ),
      ),
      _isRecording ? LinearProgressIndicator(value: 100.0 / 160.0 * (this._dbLevel ?? 1) / 100, valueColor: AlwaysStoppedAnimation<Color>(Colors.green), backgroundColor: Colors.red) : Container(),
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
                  image: AssetImage(onPauseResumeRecorderPressed() != null ? 'res/icons/ic_pause.png' : 'res/icons/ic_pause_disabled.png'),
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
          child: Text(
            this._playerTxt,
            style: TextStyle(
              fontSize: 35.0,
              color: Colors.black,
            ),
          ),
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
                  onPressed: onPauseResumePlayerPressed(),
                  disabledColor: Colors.white,
                  padding: EdgeInsets.all(8.0),
                  child: Image(
                    width: 36.0,
                    height: 36.0,
                    image: AssetImage(onPauseResumePlayerPressed() != null ? 'res/icons/ic_pause.png' : 'res/icons/ic_pause_disabled.png'),
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
                value: min(sliderCurrentPosition, maxDuration),
                min: 0.0,
                max: maxDuration,
                onChanged: (double value) async {
                  await playerModule.seekToPlayer(value.toInt());
                },
                divisions: maxDuration == 0.0 ? 1 : maxDuration.toInt())),
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
