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

/*

Play from stream can be very efficient to play sound effects in real time. For example in a game App.
In this example, the App open three [players](/api/player/FlutterSoundPlayer-class.html)
and call [startPlayerFromStream()](/api/player/FlutterSoundPlayer/startPlayerFromStream.html) during initialization.
When it want to play a noise, it has just to call the synchronous verb [feed](/api/player/FlutterSoundPlayer/feedInt16FromStream.html). Very fast.

 */

const int _tSampleRate = 44100;
const int _tNumChannels = 1;
const _bam = 'assets/noises/bam.wav';
const _boum = 'assets/noises/boum.wav';

/// Example app.
class SoundEffect extends StatefulWidget {
  const SoundEffect({super.key});

  @override
  State<SoundEffect> createState() => _SoundEffectState();
}

class _SoundEffectState extends State<SoundEffect> {
  FlutterSoundPlayer? _mPlayer = FlutterSoundPlayer();
  late bool _mPlayerIsInited;
  Uint8List? bimData;
  Uint8List? bamData;
  Uint8List? boumData;
  bool busy = false;

  Future<Uint8List> getAssetData(String path) async {
    var asset = await rootBundle.load(path);
    return asset.buffer.asUint8List();
  }

  @override
  void initState() {
    super.initState();
    initPlayer().then((value) => setState(() {
          _mPlayerIsInited = true;
        }));
  }

  @override
  void dispose() {
    disposePlayer();
    super.dispose();
  }
  // ------------------------------  The real code ----------------------------------

  Future<void> initPlayer() async {
    await _mPlayer!.openPlayer();
    bimData = await getAssetData('assets/samples/sample.pcm');
    bamData = FlutterSoundHelper().waveToPCMBuffer(
      inputBuffer: await getAssetData(_bam),
    );
    boumData = FlutterSoundHelper().waveToPCMBuffer(
      inputBuffer: await getAssetData(_boum),
    );
    await _mPlayer!.startPlayerFromStream(
      codec: Codec.pcm16,
      numChannels: _tNumChannels,
      sampleRate: _tSampleRate,
      bufferSize: 1024,
      interleaved: true,
    );
  }

  void disposePlayer() {
    _mPlayer!.stopPlayer();
    _mPlayer!.closePlayer();
    _mPlayer = null;
  }

  void play(Uint8List? data) async {
    if (!busy && _mPlayerIsInited) {
      busy = true;
      await _mPlayer!.feedUint8FromStream(data!).then((value) => busy = false);
    }
  }

  // ----------------------------------------------------------------------------------------------------------------------

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
                onPressed: () {
                  play(bimData);
                },
                //color: Colors.white,
                child: const Text('Bim!'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  play(bamData);
                },
                //color: Colors.white,
                child: const Text('Bam!'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  play(boumData);
                },
                //color: Colors.white,
                child: const Text('Boum!'),
              ),
            ]),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        title: const Text('Noise Effect'),
      ),
      body: makeBody(),
    );
  }
}
