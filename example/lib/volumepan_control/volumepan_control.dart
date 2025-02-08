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

/*
 *
 * This is a very simple example for Flutter Sound beginners,
 * that show how to record, and then playback a file.
 *
 * This example is really basic.
 *
 */

const _exampleAudioFilePathMP3_1 =
    'https://flutter-sound.canardoux.xyz/extract/leftright.mp3';

///
typedef Fn = void Function();

/// Example app.
class VolumePanControl extends StatefulWidget {
  const VolumePanControl({super.key});

  @override
  State<VolumePanControl> createState() => _VolumePanControlState();
}

class _VolumePanControlState extends State<VolumePanControl> {
  final FlutterSoundPlayer _mPlayer1 = FlutterSoundPlayer();
  final FlutterSoundPlayer _mPlayer2 = FlutterSoundPlayer();
  bool _mPlayerIsInited1 = false;
  bool _mPlayerIsInited2 = false;
  double _mVolume1 = 100.0;
  double _mPan1 = 0.0;

  @override
  void initState() {
    super.initState();
    _mPlayer1.openPlayer().then((value) {
      setState(() {
        _mPlayerIsInited1 = true;
      });
    });

    _mPlayer2.openPlayer().then((value) {
      setState(() {
        _mPlayerIsInited2 = true;
      });
    });
  }

  @override
  void dispose() {
    stopPlayer(_mPlayer1);
    stopPlayer(_mPlayer2);

    // Be careful : you must `close` the audio session when you have finished with it.
    _mPlayer1.closePlayer();
    _mPlayer2.closePlayer();

    super.dispose();
  }

  // -------  Here is the code to playback a remote file -----------------------

  void play(FlutterSoundPlayer? player, String uri) async {
    await player!.startPlayer(
        fromURI: uri,
        codec: Codec.mp3,
        whenFinished: () {
          setState(() {});
        });
    setState(() {});
  }

  Future<void> stopPlayer(FlutterSoundPlayer player) async {
    await player.stopPlayer();
  }

  Future<void> setVolume1(double v) async // v is between 0.0 and 100.0
  {
    v = v > 100.0 ? 100.0 : v;
    _mVolume1 = v;
    setState(() {});
    //await _mPlayer!.setVolume(v / 100, fadeDuration: Duration(milliseconds: 5000));
    await _mPlayer1.setVolumePan(
      _mVolume1 / 100,
      _mPan1 / 100,
    );
  }

  Future<void> setPan1(double p) async // v is between 0.0 and 100.0
  {
    p = p > 100.0 ? 100.0 : p;
    p = p < -100.0 ? -100.0 : p;
    _mPan1 = p;
    setState(() {});
    //await _mPlayer!.setVolume(v / 100, fadeDuration: Duration(milliseconds: 5000));
    await _mPlayer1.setVolumePan(
      _mVolume1 / 100,
      _mPan1 / 100,
    );
  }

  // --------------------- UI -------------------

  Fn? getPlaybackFn(FlutterSoundPlayer? player, String uri) {
    if (!(_mPlayerIsInited1 && _mPlayerIsInited2)) {
      return null;
    }
    return player!.isStopped
        ? () {
            play(player, uri);
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
        height: 200,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFFAF0E6),
          border: Border.all(
            color: Colors.indigo,
            width: 3,
          ),
        ),
        child: Column(children: [
          Row(children: [
            ElevatedButton(
              onPressed: getPlaybackFn(_mPlayer1, _exampleAudioFilePathMP3_1),
              //color: Colors.white,
              //disabledColor: Colors.grey,
              child: Text(_mPlayer1.isPlaying ? 'Stop' : 'Play'),
            ),
            const SizedBox(
              width: 20,
            ),
            Text(_mPlayer1.isPlaying
                ? 'Playback #1 in progress'
                : 'Player #1 is stopped'),
          ]),
          const Text('Volume and Pan:'),
          Slider(
              value: _mVolume1,
              min: 0.0,
              max: 100.0,
              onChanged: setVolume1,
              divisions: 100),
          Slider(
              value: _mPan1,
              min: -100.0,
              max: 100.0,
              onChanged: setPan1,
              divisions: 200),
        ]),
        //),
        //],
      );
    }

    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        title: const Text('Volume Pan Control'),
      ),
      body: makeBody(),
    );
  }
}
