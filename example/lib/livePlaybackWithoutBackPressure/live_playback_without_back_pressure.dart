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
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter/services.dart' show rootBundle;
//import 'package:logger/logger.dart';

/*

An example showing how to play Live Data without back pressure. It feeds a live stream,
without waiting that the futures are completed for each block.
This is simpler than playing buffers synchronously because the App does not need to await
that the playback for each block is completed before playing another one.

This example get the data from an asset file, which is completely stupid :
if an App wants to play a long asset file he must use `startPlayer(fromBuffer:)`.

Feeding Flutter Sound without back pressure is very simple but you can have two problems :

* If your App is too fast feeding the audio channel, it can have problems with the Stream memory used.
* The App does not have any knowledge of when the block given to Flutter Sound is really played.
For example, if it does a `stopPlayer()` it will loose all the buffered data not yet played.

 */

///
const int cstSAMPLERATE = 8000; // 8000; // 48000
const int cstCHANNELNB = 2; // 2 // 1;
const Codec cstCODEC = Codec.pcm16; // Codec.pcm16 /// Codec.pcmFloat32;
const String cstASSET =
    'assets/samples/sample_s16_2ch.raw'; // 'assets/samples/sample_f32_2ch.raw'; // 'assets/samples/sample_f32_2ch.raw' // 'assets/samples/sample_f32.raw'

///
const int cstBLOCKSIZE = 4096;

///
typedef Fn = void Function();

/// Example app.
class LivePlaybackWithoutBackPressure extends StatefulWidget {
  const LivePlaybackWithoutBackPressure({super.key});

  @override
  State<LivePlaybackWithoutBackPressure> createState() =>
      _LivePlaybackWithoutBackPressureState();
}

class _LivePlaybackWithoutBackPressureState
    extends State<LivePlaybackWithoutBackPressure> {
  final FlutterSoundPlayer _mPlayer = FlutterSoundPlayer();
  bool _mPlayerIsInited = false;
  double _mSpeed = 100.0;
  late Uint8List data;

  Future<void> initPlayer() async {
    await _mPlayer.openPlayer();
    _mPlayerIsInited = false;
    data = await getAssetData(cstASSET);

    setState(() {
      _mPlayerIsInited = true;
    });
  }

  @override
  void initState() {
    super.initState();
    // Be careful : openAudioSession return a Future.
    // Do not access your FlutterSoundPlayer or FlutterSoundRecorder before the completion of the Future
//    _mPlayer.openPlayer().then((value) {
//      setState(() {
//        _mPlayerIsInited = true;
//      });
//    });
    initPlayer();
  }

  @override
  void dispose() {
    //stopPlayer();
    _mPlayer.closePlayer();
    super.dispose();
  }

  // -------  Here is the code to play Live data without back-pressure ------------

  void feedHim(Uint8List data) {
    var start = 0;
    var totalLength = data.length;
    while (totalLength > 0 && !_mPlayer.isStopped) {
      var ln = totalLength > cstBLOCKSIZE ? cstBLOCKSIZE : totalLength;
      _mPlayer.foodSink!.add(FoodData(data.sublist(start, start + ln)));
      totalLength -= ln;
      start += ln;
    }
  }

  void play() async {
    await _mPlayer.startPlayerFromStream(
      codec: cstCODEC,
      numChannels: cstCHANNELNB,
      interleaved: true,
      sampleRate: cstSAMPLERATE,
      bufferSize: 20480,
      //whenFinished: () {
      // FlutterSoundPlayer().logger.i("FINISHED!");
      //}
    );

    feedHim(data);
    //if (_mPlayer != null) {
    // We must not do stopPlayer() directely //await stopPlayer();
    //_mPlayer.foodSink!.add(FoodEvent(() async {
    //await _mPlayer.stopPlayer();
    //FlutterSoundPlayer().logger.i("MARKER!");

    setState(() {});
    //}));
    //}
  }

  // --------------------- (it was very simple, wasn't it ?) -------------------

  Future<Uint8List> getAssetData(String path) async {
    var asset = await rootBundle.load(path);
    return asset.buffer.asUint8List();
  }

  Future<void> stopPlayer() async {
    //if (_mPlayer != null) {
    await _mPlayer.stopPlayer();
    setState(() {});
  }

  Future<void> setSpeed(double v) async // v is between 0.0 and 100.0
  {
    v = v > 200.0 ? 200.0 : v;
    _mSpeed = v;
    setState(() {});
    await _mPlayer.setSpeed(
      v / 100,
    );
  }

  Fn? getPlaybackFn() {
    if (!_mPlayerIsInited) {
      return null;
    }
    return _mPlayer.isPlaying
        ? () {
            stopPlayer().then((value) => setState(() {}));
          }
        : play;
  }

  // ----------------------------------------------------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    Widget makeBody() {
      return Column(children: [
        Container(
          margin: const EdgeInsets.all(3),
          padding: const EdgeInsets.all(3),
          height: 180,
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
                onPressed: getPlaybackFn(),
                //color: Colors.white,
                //disabledColor: Colors.grey,
                child: Text(_mPlayer.isPlaying ? 'stop' : 'Play'),
              ),
              const SizedBox(
                width: 20,
              ),
              Text(_mPlayer.isPlaying
                  ? 'Playback in progress'
                  : 'Player is stopped'),
            ]),
            const Text('Speed:'),
            Slider(
              value: _mSpeed,
              min: 0.0,
              max: 200.0,
              onChanged: setSpeed,
              //divisions: 100
            ),
          ]),
        ),
      ]);
    }

    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        title: const Text('Live playback from stream'),
      ),
      body: makeBody(),
    );
  }
}
