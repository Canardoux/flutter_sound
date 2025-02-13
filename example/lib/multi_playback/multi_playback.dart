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
 *
 * This is a very simple example for Flutter Sound beginners,
 * that show how to record, and then playback a file.
 *
 * This example is really basic.
 *
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
  FlutterSoundPlayer? _mPlayer2 = FlutterSoundPlayer();
  FlutterSoundPlayer? _mPlayer3 = FlutterSoundPlayer();
  bool _mPlayer2IsInited = false;
  bool _mPlayer3IsInited = false;
  Uint8List? buffer2;
  Uint8List? buffer3;
  String _playerTxt2 = '';
  String _playerTxt3 = '';
  StreamSubscription? _playerSubscription2;
  StreamSubscription? _playerSubscription3;

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
          buffer2 = value;
        }));
    _getAssetData(
      'assets/samples/sample.mp4',
    ).then((value) => setState(() {
          buffer3 = value;
        }));

    _mPlayer2!.openPlayer().then((value) {
      setState(() {
        _mPlayer2IsInited = true;
      });
    });
    _mPlayer3!.openPlayer().then((value) {
      setState(() {
        _mPlayer3IsInited = true;
      });
    });
  }

  @override
  void dispose() {
    // Be careful : you must `close` the audio session when you have finished with it.
    cancelPlayerSubscriptions2();
    _mPlayer2!.closePlayer();
    _mPlayer2 = null;
    cancelPlayerSubscriptions3();
    _mPlayer3!.closePlayer();
    _mPlayer3 = null;

    super.dispose();
  }
// -------  Player2 play a OPUS file -----------------------

  void play2() async {
    await _mPlayer2!.setSubscriptionDuration(const Duration(milliseconds: 10));
    _addListener2();
    await _mPlayer2!.startPlayer(
        fromDataBuffer: buffer2,
        codec: Codec.aacADTS,
        whenFinished: () {
          stopPlayer2();
          setState(() {});
        });
    setState(() {});
  }

  void cancelPlayerSubscriptions2() {
    if (_playerSubscription2 != null) {
      _playerSubscription2!.cancel();
      _playerSubscription2 = null;
    }
  }

  Future<void> stopPlayer2() async {
    cancelPlayerSubscriptions2();
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

  // -------  Player3 play a MP4 file -----------------------

  void play3() async {
    await _mPlayer3!.setSubscriptionDuration(const Duration(milliseconds: 10));
    _addListener3();
    await _mPlayer3!.startPlayer(
        fromDataBuffer: buffer3,
        codec: Codec.aacMP4,
        whenFinished: () {
          stopPlayer3();
          setState(() {});
        });
    setState(() {});
  }

  void cancelPlayerSubscriptions3() {
    if (_playerSubscription3 != null) {
      _playerSubscription3!.cancel();
      _playerSubscription3 = null;
    }
  }

  Future<void> stopPlayer3() async {
    cancelPlayerSubscriptions3();
    if (_mPlayer3 != null) {
      await _mPlayer3!.stopPlayer();
    }
    setState(() {});
  }

  Future<void> pause3() async {
    if (_mPlayer3 != null) {
      await _mPlayer3!.pausePlayer();
    }
    setState(() {});
  }

  Future<void> resume3() async {
    if (_mPlayer3 != null) {
      await _mPlayer3!.resumePlayer();
    }
    setState(() {});
  }

  // ------------------------------------------------------------------------------------


  void _addListener2() {
    cancelPlayerSubscriptions2();
    _playerSubscription2 = _mPlayer2!.onProgress!.listen((e) {
      var date = DateTime.fromMillisecondsSinceEpoch(e.position.inMilliseconds,
          isUtc: true);
      var txt = DateFormat('mm:ss:SS', 'en_GB').format(date);
      setState(() {
        _playerTxt2 = txt.substring(0, 8);
      });
    });
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

  void _addListener3() {
    cancelPlayerSubscriptions3();
    _playerSubscription3 = _mPlayer3!.onProgress!.listen((e) {
      var date = DateTime.fromMillisecondsSinceEpoch(e.position.inMilliseconds,
          isUtc: true);
      var txt = DateFormat('mm:ss:SS', 'en_GB').format(date);
      setState(() {
        _playerTxt3 = txt.substring(0, 8);
      });
    });
  }

  Fn? getPlaybackFn3() {
    if (!_mPlayer3IsInited || buffer3 == null) {
      return null;
    }
    return _mPlayer3!.isStopped
        ? play3
        : () {
            stopPlayer3().then((value) => setState(() {}));
          };
  }

  Fn? getPauseResumeFn3() {
    if (!_mPlayer3IsInited || _mPlayer3!.isStopped || buffer3 == null) {
      return null;
    }
    return _mPlayer3!.isPaused ? resume3 : pause3;
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
                onPressed: getPlaybackFn3(),
                //color: Colors.white,
                //disabledColor: Colors.grey,
                child: Text(_mPlayer3!.isStopped ? 'Play' : 'Stop'),
              ),
              const SizedBox(
                width: 20,
              ),
              ElevatedButton(
                onPressed: getPauseResumeFn3(),
                //color: Colors.white,
                //disabledColor: Colors.grey,
                child: Text(_mPlayer3!.isPaused ? 'Resume' : 'Pause'),
              ),
              const SizedBox(
                width: 20,
              ),
              Text(
                _playerTxt3,
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
