/*
 * Copyright 2018, 2019, 2020, 2021 Dooboolab.
 *
 * This file is part of Flutter-Sound.
 *
 * Flutter-Sound is free software: you can redistribute it and/or modify
 * it under the terms of the Mozilla Public License version 2 (MPL2.0),
 * as published by the Mozilla organization.
 *
 * Flutter-Sound is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * MPL General Public License for more details.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:typed_data';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter/services.dart' show rootBundle;

/*

This is a simple example doing several playbacks at the same time.
It creates two [Player objects](/api/player/FlutterSoundPlayer-class.html) and use the verb [startPlayer()](/api/player/FlutterSoundPlayer/startPlayer.html) to play them.

This example shows also :
- The [Pause](/api/player/FlutterSoundPlayer/pausePlayer.html)/[Resume](/api/player/FlutterSoundPlayer/resumePlayer.html) feature.
- The Display of the elapsed time

 */

///
typedef Fn = void Function();

/// Example app.
class MultiPlayback extends StatefulWidget {
  const MultiPlayback({super.key});

  @override
  State<MultiPlayback> createState() => _MultiPlaybackState();
}

class _MultiPlaybackState extends State<MultiPlayback> {
  FlutterSoundPlayer? _mPlayer1 = FlutterSoundPlayer();
  FlutterSoundPlayer? _mPlayer2 = FlutterSoundPlayer();
  bool _mPlayer1IsInited = false;
  bool _mPlayer2IsInited = false;
  Uint8List? buffer1;
  Uint8List? buffer2;
  String _playerTxt1 = '';
  String _playerTxt2 = '';
  StreamSubscription? _playerSubscription1;
  StreamSubscription? _playerSubscription2;

  Future<Uint8List> _getAssetData(String path) async {
    var asset = await rootBundle.load(path);
    return asset.buffer.asUint8List();
  }

  @override
  void initState() {
    super.initState();
    initializeDateFormatting();
    _getAssetData(
      'assets/samples/sample.aac',
    ).then((value) => setState(() {
          buffer1 = value;
        }));
    _getAssetData(
      'assets/samples/sample.mp4',
    ).then((value) => setState(() {
          buffer2 = value;
        }));

    _mPlayer1!.openPlayer().then((value) {
      setState(() {
        _mPlayer1IsInited = true;
      });
    });
    _mPlayer2!.openPlayer().then((value) {
      setState(() {
        _mPlayer2IsInited = true;
      });
    });
  }

  @override
  void dispose() {
    // Be careful : you must `close` the audio session when you have finished with it.
    cancelPlayerSubscriptions1();
    _mPlayer1!.closePlayer();
    _mPlayer1 = null;
    cancelPlayerSubscriptions3();
    _mPlayer2!.closePlayer();
    _mPlayer2 = null;

    super.dispose();
  }
// -------------------------  Player1 play an AAC file -----------------------

  void play1() async {
    await _addListener1();
    await _mPlayer1!.startPlayer(
        fromDataBuffer: buffer1,
        codec: Codec.aacADTS,
        whenFinished: () {
          stopPlayer1();
          setState(() {});
        });
    setState(() {});
  }

  void cancelPlayerSubscriptions1() {
    if (_playerSubscription1 != null) {
      _playerSubscription1!.cancel();
      _playerSubscription1 = null;
    }
  }

  Future<void> stopPlayer1() async {
    cancelPlayerSubscriptions1();
    if (_mPlayer1 != null) {
      await _mPlayer1!.stopPlayer();
    }
    setState(() {});
  }

  Future<void> pause1() async {
    if (_mPlayer1 != null) {
      await _mPlayer1!.pausePlayer();
    }
    setState(() {});
  }

  Future<void> resume1() async {
    if (_mPlayer1 != null) {
      await _mPlayer1!.resumePlayer();
    }
    setState(() {});
  }

  // --------------------  Player2 play a MP4 file -----------------------

  void play2() async {
    await _addListener2();
    await _mPlayer2!.startPlayer(
        fromDataBuffer: buffer2,
        codec: Codec.aacMP4,
        whenFinished: () {
          stopPlayer2();
          setState(() {});
        });
    setState(() {});
  }

  void cancelPlayerSubscriptions3() {
    if (_playerSubscription2 != null) {
      _playerSubscription2!.cancel();
      _playerSubscription2 = null;
    }
  }

  Future<void> stopPlayer2() async {
    cancelPlayerSubscriptions3();
    if (_mPlayer2 != null) {
      await _mPlayer2!.stopPlayer();
    }
    setState(() {});
  }

  Future<void> pause2() async {
    if (_mPlayer2 != null) {
      await _mPlayer2!.pausePlayer();
    }
    setState(() {});
  }

  Future<void> resume2() async {
    if (_mPlayer2 != null) {
      await _mPlayer2!.resumePlayer();
    }
    setState(() {});
  }

  // ------------------------------------------------------------------------------------

  Future<void> _addListener1() async {
    cancelPlayerSubscriptions1();
    _playerSubscription1 = _mPlayer1!.onProgress!.listen((e) {
      var date = DateTime.fromMillisecondsSinceEpoch(e.position.inMilliseconds,
          isUtc: true);
      var txt = DateFormat('mm:ss:SS', 'en_GB').format(date);
      setState(() {
        _playerTxt1 = txt.substring(0, 8);
      });
    });
    await _mPlayer1!.setSubscriptionDuration(
        const Duration(milliseconds: 10)); // DON'T FORGET THIS CALL
  }

  Fn? getPlaybackFn1() {
    if (!_mPlayer1IsInited || buffer1 == null) {
      return null;
    }
    return _mPlayer1!.isStopped
        ? play1
        : () {
            stopPlayer1().then((value) => setState(() {}));
          };
  }

  Fn? getPauseResumeFn1() {
    if (!_mPlayer1IsInited || _mPlayer1!.isStopped || buffer1 == null) {
      return null;
    }
    return _mPlayer1!.isPaused ? resume1 : pause1;
  }

  Future<void> _addListener2() async {
    cancelPlayerSubscriptions3();
    _playerSubscription2 = _mPlayer2!.onProgress!.listen((e) {
      var date = DateTime.fromMillisecondsSinceEpoch(e.position.inMilliseconds,
          isUtc: true);
      var txt = DateFormat('mm:ss:SS', 'en_GB').format(date);
      setState(() {
        _playerTxt2 = txt.substring(0, 8);
      });
    });
    await _mPlayer2!.setSubscriptionDuration(
        const Duration(milliseconds: 10)); // DON'T FORGET THIS CALL
  }

  Fn? getPlaybackFn2() {
    if (!_mPlayer2IsInited || buffer2 == null) {
      return null;
    }
    return _mPlayer2!.isStopped
        ? play2
        : () {
            stopPlayer2().then((value) => setState(() {}));
          };
  }

  Fn? getPauseResumeFn2() {
    if (!_mPlayer2IsInited || _mPlayer2!.isStopped || buffer2 == null) {
      return null;
    }
    return _mPlayer2!.isPaused ? resume2 : pause2;
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
              color: const Color(0xFFFAF0E6),
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
                child: Text(_mPlayer1!.isStopped ? 'Play' : 'Stop'),
              ),
              const SizedBox(
                width: 20,
              ),
              ElevatedButton(
                onPressed: getPauseResumeFn1(),
                //color: Colors.white,
                //disabledColor: Colors.grey,
                child: Text(_mPlayer1!.isPaused ? 'Resume' : 'Pause'),
              ),
              const SizedBox(
                width: 20,
              ),
              Text(
                _playerTxt1,
                style: const TextStyle(
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
              color: const Color(0xFFFAF0E6),
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
                child: Text(_mPlayer2!.isStopped ? 'Play' : 'Stop'),
              ),
              const SizedBox(
                width: 20,
              ),
              ElevatedButton(
                onPressed: getPauseResumeFn2(),
                //color: Colors.white,
                //disabledColor: Colors.grey,
                child: Text(_mPlayer2!.isPaused ? 'Resume' : 'Pause'),
              ),
              const SizedBox(
                width: 20,
              ),
              Text(
                _playerTxt2,
                style: const TextStyle(
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
