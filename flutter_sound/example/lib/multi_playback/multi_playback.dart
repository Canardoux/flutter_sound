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

import 'dart:async';
import 'dart:typed_data';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter/services.dart' show rootBundle;

/*
 *
 * This is a very simple example for Flutter Sound beginners,
 * that show how to record, and then playback a file.
 *
 * This example is really basic.
 *
 */

final _exampleAudioFilePathMP3 =
    'https://file-examples-com.github.io/uploads/2017/11/file_example_MP3_700KB.mp3';

///
typedef Fn = void Function();

/// Example app.
class MultiPlayback extends StatefulWidget {
  @override
  _MultiPlaybackState createState() => _MultiPlaybackState();
}

class _MultiPlaybackState extends State<MultiPlayback> {
  FlutterSoundPlayer _mPlayer1 = FlutterSoundPlayer();
  FlutterSoundPlayer _mPlayer2 = FlutterSoundPlayer();
  FlutterSoundPlayer _mPlayer3 = FlutterSoundPlayer();
  bool _mPlayer1IsInited = false;
  bool _mPlayer2IsInited = false;
  bool _mPlayer3IsInited = false;
  Uint8List buffer2;
  Uint8List buffer3;
  String _playerTxt1 = '';
  String _playerTxt2 = '';
  String _playerTxt3 = '';
  StreamSubscription _playerSubscription1;
  StreamSubscription _playerSubscription2;
  StreamSubscription _playerSubscription3;

  Future<Uint8List> _getAssetData(String path) async {
    var asset = await rootBundle.load(path);
    return asset.buffer.asUint8List();
  }

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
    _getAssetData(
      'assets/samples/sample.opus',
    ).then((value) => setState(() {
          buffer2 = value;
        }));
    _getAssetData(
      'assets/samples/sample.mp4',
    ).then((value) => setState(() {
          buffer3 = value;
        }));
    _mPlayer1.openAudioSession().then((value) {
      setState(() {
        _mPlayer1IsInited = true;
      });
    });
    _mPlayer2.openAudioSession().then((value) {
      setState(() {
        _mPlayer2IsInited = true;
      });
    });
    _mPlayer3.openAudioSession().then((value) {
      setState(() {
        _mPlayer3IsInited = true;
      });
    });
  }

  @override
  void dispose() {
    // Be careful : you must `close` the audio session when you have finished with it.
    cancelPlayerSubscriptions1();
    _mPlayer1.closeAudioSession();
    _mPlayer1 = null;
    cancelPlayerSubscriptions2();
    _mPlayer2.closeAudioSession();
    _mPlayer2 = null;
    cancelPlayerSubscriptions3();
    _mPlayer3.closeAudioSession();
    _mPlayer3 = null;

    super.dispose();
  }

  // -------  Player1 play a remote file -----------------------

  void play1() async {
    await _mPlayer1.setSubscriptionDuration(Duration(milliseconds: 10));
    _addListener1();
    await _mPlayer1.startPlayer(
        fromURI: _exampleAudioFilePathMP3,
        codec: Codec.mp3,
        whenFinished: () {
          setState(() {});
        });
    setState(() {});
  }

  void cancelPlayerSubscriptions1() {
    if (_playerSubscription1 != null) {
      _playerSubscription1.cancel();
      _playerSubscription1 = null;
    }
  }

  Future<void> stopPlayer1() async {
    cancelPlayerSubscriptions1();
    if (_mPlayer1 != null) {
      await _mPlayer1.stopPlayer();
    }
    setState(() {});
  }

  Future<void> pause1() async {
    if (_mPlayer1 != null) {
      await _mPlayer1.pausePlayer();
    }
    setState(() {});
  }

  Future<void> resume1() async {
    if (_mPlayer1 != null) {
      await _mPlayer1.resumePlayer();
    }
    setState(() {});
  }

  // -------  Player2 play a OPUS file -----------------------

  void play2() async {
    await _mPlayer2.setSubscriptionDuration(Duration(milliseconds: 10));
    _addListener2();
    await _mPlayer2.startPlayer(
        fromDataBuffer: buffer2,
        codec: Codec.opusOGG,
        whenFinished: () {
          setState(() {});
        });
    setState(() {});
  }

  void cancelPlayerSubscriptions2() {
    if (_playerSubscription2 != null) {
      _playerSubscription2.cancel();
      _playerSubscription2 = null;
    }
  }

  Future<void> stopPlayer2() async {
    cancelPlayerSubscriptions2();
    if (_mPlayer2 != null) {
      await _mPlayer2.stopPlayer();
    }
    setState(() {});
  }

  Future<void> pause2() async {
    if (_mPlayer2 != null) {
      await _mPlayer2.pausePlayer();
    }
    setState(() {});
  }

  Future<void> resume2() async {
    if (_mPlayer2 != null) {
      await _mPlayer2.resumePlayer();
    }
    setState(() {});
  }

  // -------  Player3 play a MP4 file -----------------------

  void play3() async {
    await _mPlayer3.setSubscriptionDuration(Duration(milliseconds: 10));
    _addListener3();
    await _mPlayer3.startPlayer(
        fromDataBuffer: buffer3,
        codec: Codec.aacMP4,
        whenFinished: () {
          setState(() {});
        });
    setState(() {});
  }

  void cancelPlayerSubscriptions3() {
    if (_playerSubscription3 != null) {
      _playerSubscription3.cancel();
      _playerSubscription3 = null;
    }
  }

  Future<void> stopPlayer3() async {
    cancelPlayerSubscriptions3();
    if (_mPlayer3 != null) {
      await _mPlayer3.stopPlayer();
    }
    setState(() {});
  }

  Future<void> pause3() async {
    if (_mPlayer3 != null) {
      await _mPlayer3.pausePlayer();
    }
    setState(() {});
  }

  Future<void> resume3() async {
    if (_mPlayer3 != null) {
      await _mPlayer3.resumePlayer();
    }
    setState(() {});
  }

  // ------------------------------------------------------------------------------------

  void _addListener1() {
    cancelPlayerSubscriptions1();
    _playerSubscription1 = _mPlayer1.onProgress.listen((e) {
      if (e != null) {
        var date = DateTime.fromMillisecondsSinceEpoch(
            e.position.inMilliseconds,
            isUtc: true);
        var txt = DateFormat('mm:ss:SS', 'en_GB').format(date);
        setState(() {
          _playerTxt1 = txt.substring(0, 8);
        });
      }
    });
  }

  Fn getPlaybackFn1() {
    if (!_mPlayer1IsInited) {
      return null;
    }
    return _mPlayer1.isStopped
        ? play1
        : () {
            stopPlayer1().then((value) => setState(() {}));
          };
  }

  Fn getPauseResumeFn1() {
    if (!_mPlayer1IsInited || _mPlayer1.isStopped) {
      return null;
    }
    return _mPlayer1.isPaused ? resume1 : pause1;
  }

  void _addListener2() {
    cancelPlayerSubscriptions2();
    _playerSubscription2 = _mPlayer2.onProgress.listen((e) {
      if (e != null) {
        var date = DateTime.fromMillisecondsSinceEpoch(
            e.position.inMilliseconds,
            isUtc: true);
        var txt = DateFormat('mm:ss:SS', 'en_GB').format(date);
        setState(() {
          _playerTxt2 = txt.substring(0, 8);
        });
      }
    });
  }

  Fn getPlaybackFn2() {
    if (!_mPlayer2IsInited || buffer2 == null) {
      return null;
    }
    return _mPlayer2.isStopped
        ? play2
        : () {
            stopPlayer2().then((value) => setState(() {}));
          };
  }

  Fn getPauseResumeFn2() {
    if (!_mPlayer2IsInited || _mPlayer2.isStopped || buffer2 == null) {
      return null;
    }
    return _mPlayer2.isPaused ? resume2 : pause2;
  }

  void _addListener3() {
    cancelPlayerSubscriptions3();
    _playerSubscription3 = _mPlayer3.onProgress.listen((e) {
      if (e != null) {
        var date = DateTime.fromMillisecondsSinceEpoch(
            e.position.inMilliseconds,
            isUtc: true);
        var txt = DateFormat('mm:ss:SS', 'en_GB').format(date);
        setState(() {
          _playerTxt3 = txt.substring(0, 8);
        });
      }
    });
  }

  Fn getPlaybackFn3() {
    if (!_mPlayer3IsInited || buffer3 == null) {
      return null;
    }
    return _mPlayer3.isStopped
        ? play3
        : () {
            stopPlayer3().then((value) => setState(() {}));
          };
  }

  Fn getPauseResumeFn3() {
    if (!_mPlayer3IsInited || _mPlayer3.isStopped || buffer3 == null) {
      return null;
    }
    return _mPlayer3.isPaused ? resume3 : pause3;
  }

  @override
  Widget build(BuildContext context) {
    Widget makeBody() {
      return Column(
        children: [
          Container(
            margin: const EdgeInsets.all(3),
            padding: const EdgeInsets.all(3),
            height: 80,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Color(0xFFFAF0E6),
              border: Border.all(
                color: Colors.indigo,
                width: 3,
              ),
            ),
            child: Row(children: [
              ElevatedButton(
                onPressed: getPlaybackFn1(),
                //color: Colors.white,
                //disabledColor: Colors.grey,
                child: Text(_mPlayer1.isStopped ? 'Play' : 'Stop'),
              ),
              SizedBox(
                width: 20,
              ),
              ElevatedButton(
                onPressed: getPauseResumeFn1(),
                //color: Colors.white,
                //disabledColor: Colors.grey,
                child: Text(_mPlayer1.isPaused ? 'Resume' : 'Pause'),
              ),
              SizedBox(
                width: 20,
              ),
              Text(
                _playerTxt1,
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
            ]),
          ),
          Container(
            margin: const EdgeInsets.all(3),
            padding: const EdgeInsets.all(3),
            height: 80,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Color(0xFFFAF0E6),
              border: Border.all(
                color: Colors.indigo,
                width: 3,
              ),
            ),
            child: Row(children: [
              ElevatedButton(
                onPressed: getPlaybackFn2(),
                //color: Colors.white,
                //disabledColor: Colors.grey,
                child: Text(_mPlayer2.isStopped ? 'Play' : 'Stop'),
              ),
              SizedBox(
                width: 20,
              ),
              ElevatedButton(
                onPressed: getPauseResumeFn2(),
                //color: Colors.white,
                //disabledColor: Colors.grey,
                child: Text(_mPlayer2.isPaused ? 'Resume' : 'Pause'),
              ),
              SizedBox(
                width: 20,
              ),
              Text(
                _playerTxt2,
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
            ]),
          ),
          Container(
            margin: const EdgeInsets.all(3),
            padding: const EdgeInsets.all(3),
            height: 80,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Color(0xFFFAF0E6),
              border: Border.all(
                color: Colors.indigo,
                width: 3,
              ),
            ),
            child: Row(children: [
              ElevatedButton(
                onPressed: getPlaybackFn3(),
                //color: Colors.white,
                //disabledColor: Colors.grey,
                child: Text(_mPlayer3.isStopped ? 'Play' : 'Stop'),
              ),
              SizedBox(
                width: 20,
              ),
              ElevatedButton(
                onPressed: getPauseResumeFn3(),
                //color: Colors.white,
                //disabledColor: Colors.grey,
                child: Text(_mPlayer3.isPaused ? 'Resume' : 'Pause'),
              ),
              SizedBox(
                width: 20,
              ),
              Text(
                _playerTxt3,
                style: TextStyle(
                  color: Colors.black,
                ),
              ),
            ]),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        title: const Text('Multi Playback'),
      ),
      body: makeBody(),
    );
  }
}
