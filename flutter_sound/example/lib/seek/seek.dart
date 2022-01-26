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
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

/*
 *
 * This is a very simple example for Flutter Sound beginners,
 * that show how to record, and then playback a file.
 *
 * This example is really basic.
 *
 */

const _boum = 'assets/samples/sample2.aac';
const int duration = 42673;

///
typedef Fn = void Function();

/// Example app.
class Seek extends StatefulWidget {
  @override
  _SeekState createState() => _SeekState();
}

class _SeekState extends State<Seek> {
  final FlutterSoundPlayer _mPlayer = FlutterSoundPlayer();
  bool _mPlayerIsInited = false;
  Uint8List? _boumData;
  StreamSubscription? _mPlayerSubscription;
  int pos = 0;

  @override
  void initState() {
    super.initState();
    init().then((value) {
      setState(() {
        _mPlayerIsInited = true;
      });
    });
  }

  @override
  void dispose() {
    stopPlayer(_mPlayer);
    cancelPlayerSubscriptions();

    // Be careful : you must `close` the audio session when you have finished with it.
    _mPlayer.closePlayer();

    super.dispose();
  }

  void cancelPlayerSubscriptions() {
    if (_mPlayerSubscription != null) {
      _mPlayerSubscription!.cancel();
      _mPlayerSubscription = null;
    }
  }

  Future<void> init() async {
    await _mPlayer.openPlayer();
    await _mPlayer.setSubscriptionDuration(Duration(milliseconds: 50));
    _boumData = await getAssetData(_boum);
    _mPlayerSubscription = _mPlayer.onProgress!.listen((e) {
      setPos(e.position.inMilliseconds);
      setState(() {});
    });
  }

  Future<Uint8List> getAssetData(String path) async {
    var asset = await rootBundle.load(path);
    return asset.buffer.asUint8List();
  }

  void play(FlutterSoundPlayer? player) async {
    await player!.startPlayer(
        fromDataBuffer: _boumData,
        codec: Codec.aacADTS,
        whenFinished: () {
          setState(() {});
        });
    setState(() {});
  }

  Future<void> stopPlayer(FlutterSoundPlayer player) async {
    await player.stopPlayer();
  }

  Future<void> setPos(int d) async {
    if (d > duration) {
      d = duration;
    }
    setState(() {
      pos = d;
    });
  }

  Future<void> seek(double d) async {
    await _mPlayer.seekToPlayer(Duration(milliseconds: d.floor()));
    await setPos(d.floor());
  }

  // --------------------- UI -------------------

  Fn? getPlaybackFn(FlutterSoundPlayer? player) {
    if (!_mPlayerIsInited) {
      return null;
    }
    return player!.isStopped
        ? () {
            play(player);
          }
        : () {
            stopPlayer(player).then((value) => setState(() {}));
          };
  }

  @override
  Widget build(BuildContext context) {
    Widget makeBody() {
      //return Column(
      //children: [
      return Container(
        margin: const EdgeInsets.all(3),
        padding: const EdgeInsets.all(3),
        height: 140,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Color(0xFFFAF0E6),
          border: Border.all(
            color: Colors.indigo,
            width: 3,
          ),
        ),
        child: Column(children: [
          Row(children: [
            ElevatedButton(
              onPressed: getPlaybackFn(_mPlayer),
              child: Text(_mPlayer.isPlaying ? 'Stop' : 'Play'),
            ),
            SizedBox(
              width: 20,
            ),
            Text(_mPlayer.isPlaying
                ? 'Playback in progress'
                : 'Player is stopped'),
            SizedBox(
              width: 20,
            ),
            Text('Pos: $pos'),
          ]),
          Text('Position:'),
          Slider(
            value: pos + 0.0,
            min: 0.0,
            max: duration + 0.0,
            onChanged: seek,
            //divisions: 100
          ),
        ]),
        //),
        //],
      );
    }

    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        title: const Text('Seek Player'),
      ),
      body: makeBody(),
    );
  }
}
