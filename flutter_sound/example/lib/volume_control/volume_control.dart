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

final _exampleAudioFilePathMP3_1 =
    'https://flutter-sound.canardoux.xyz/web_example/assets/extract/05.mp3';
final _exampleAudioFilePathMP3_2 =
    'https://flutter-sound.canardoux.xyz/web_example/assets/extract/13.wav';

///
typedef Fn = void Function();

/// Example app.
class VolumeControl extends StatefulWidget {
  @override
  _VolumeControlState createState() => _VolumeControlState();
}

class _VolumeControlState extends State<VolumeControl> {
  final FlutterSoundPlayer _mPlayer1 = FlutterSoundPlayer();
  final FlutterSoundPlayer _mPlayer2 = FlutterSoundPlayer();
  bool _mPlayerIsInited1 = false;
  bool _mPlayerIsInited2 = false;
  double _mVolume1 = 100.0;
  double _mVolume2 = 100.0;

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
    await _mPlayer1.setVolume(
      v / 100,
    );
  }

  Future<void> setVolume2(double v) async // v is between 0.0 and 100.0
  {
    v = v > 100.0 ? 100.0 : v;
    _mVolume2 = v;
    setState(() {});
    //await _mPlayer!.setVolume(v / 100, fadeDuration: Duration(milliseconds: 5000));
    await _mPlayer2.setVolume(
      v / 100,
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
        height: 240,
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
              onPressed: getPlaybackFn(_mPlayer1, _exampleAudioFilePathMP3_1),
              //color: Colors.white,
              //disabledColor: Colors.grey,
              child: Text(_mPlayer1.isPlaying ? 'Stop' : 'Play'),
            ),
            SizedBox(
              width: 20,
            ),
            Text(_mPlayer1.isPlaying
                ? 'Playback #1 in progress'
                : 'Player #1 is stopped'),
          ]),
          Text('Volume:'),
          Slider(
              value: _mVolume1,
              min: 0.0,
              max: 100.0,
              onChanged: setVolume1,
              divisions: 100),
          Row(children: [
            ElevatedButton(
              onPressed: getPlaybackFn(_mPlayer2, _exampleAudioFilePathMP3_2),
              //color: Colors.white,
              //disabledColor: Colors.grey,
              child: Text(_mPlayer2.isPlaying ? 'Stop' : 'Play'),
            ),
            SizedBox(
              width: 20,
            ),
            Text(_mPlayer2.isPlaying
                ? 'Playback #2 in progress'
                : 'Player #2 is stopped'),
          ]),
          Text('Volume:'),
          Slider(
              value: _mVolume2,
              min: 0.0,
              max: 100.0,
              onChanged: setVolume2,
              divisions: 100),
        ]),
        //),
        //],
      );
    }

    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        title: const Text('Volume Control'),
      ),
      body: makeBody(),
    );
  }
}
