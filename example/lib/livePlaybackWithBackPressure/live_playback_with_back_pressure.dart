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

An example showing how to play Live Data with back pressure.
It feeds a live stream, waiting that the futures are completed for each block.

This example get the data from an asset file, which is completely stupid :
if an App wants to play an asset file he must use `StartPlayer(fromBuffer:)`.

If you do not need any back pressure, you can see another simple example :
[LivePlaybackWithoutBackPressure.dart](fs-ex_playback_from_stream_1.html).
This other example is a little bit simpler because the App does not need to await
the playback for each block before playing another one.

## You can see also those examples:
- [Streams](ex_streams)
- [Record To Stream](ex_record_to_stream)
- [Live Playback Without Backpressure](fs-ex_playback_from_stream_1)

 */

///
const blockSize = 20480;

///
const int tSampleRate = 48000;

///
typedef Fn = void Function();

/// Example app.
class LivePlaybackWithBackPressure extends StatefulWidget {
  const LivePlaybackWithBackPressure({super.key});

  @override
  State<LivePlaybackWithBackPressure> createState() =>
      _LivePlaybackWithBackPressureState();
}

class _LivePlaybackWithBackPressureState
    extends State<LivePlaybackWithBackPressure> {
  FlutterSoundPlayer? _mPlayer = FlutterSoundPlayer();
  bool _mPlayerIsInited = false;

  @override
  void initState() {
    super.initState();
    // Be careful : openAudioSession return a Future.
    // Do not access your FlutterSoundPlayer or FlutterSoundRecorder before the completion of the Future
    _mPlayer!.openPlayer().then((value) {
      setState(() {
        _mPlayerIsInited = true;
      });
    });
  }

  @override
  void dispose() {
    //stopPlayer();
    _mPlayer!.closePlayer();
    _mPlayer = null;

    super.dispose();
  }

  // -----------------------  Here is the code to play Live data with back-pressure -----------------------

  /// Start the player from a Codec.pcm16 Stream, stereo
  void play() async {
    assert(_mPlayerIsInited && _mPlayer!.isStopped);
    await _mPlayer!.startPlayerFromStream(
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: tSampleRate,
    );
    setState(() {});
    var data = await getAssetData('assets/samples/sample.pcm');
    await feedHim(data);
    if (_mPlayer != null) {
      await stopPlayer();
      setState(() {});
    }
  }

  // Here we call the verb "await feedFromStream()" (with await!!!) for each block of BLOCK_SIZE size.
  // This is just for demonstration of calling sequentially several "await feedFromStream()" (with await!!!!).
  // Be very careful not calling a second `feedFromStream()` when the previous one has not completed his future.
  //
  // **You may not have two calls to `feedFromStream()` simultaneously.**
  // ********************************************************************
  // And, of course, you may not mix those verbs with the real output food Stream Sink.

  Future<void> feedHim(Uint8List buffer) async {
    var lnData = 0;
    var totalLength = buffer.length;
    while (totalLength > 0 && !_mPlayer!.isStopped) {
      var bsize = totalLength > blockSize ? blockSize : totalLength;
      await _mPlayer!
          .feedUint8FromStream(buffer.sublist(lnData, lnData + bsize)); // with await !!!!
      lnData += bsize;
      totalLength -= bsize;
    }
    _mPlayer?.logger.d('Finished');
  }

  // --------------------- (it was very simple, wasn't it ?) -------------------

  Future<Uint8List> getAssetData(String path) async {
    var asset = await rootBundle.load(path);
    return asset.buffer.asUint8List();
  }

  Future<void> stopPlayer() async {
    if (_mPlayer != null) {
      await _mPlayer!.stopPlayer();
    }
  }

  Fn? getPlaybackFn() {
    if (!_mPlayerIsInited) {
      return null;
    }
    return _mPlayer!.isStopped
        ? play
        : () {
            stopPlayer().then((value) => setState(() {}));
          };
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
                onPressed: getPlaybackFn(),
                //color: Colors.white,
                //disabledColor: Colors.grey,
                child: Text(_mPlayer!.isPlaying ? 'Stop' : 'Play'),
              ),
              const SizedBox(
                width: 20,
              ),
              Text(_mPlayer!.isPlaying
                  ? 'Playback in progress'
                  : 'Player is stopped'),
            ]),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        title: const Text('Live playback with back pressure'),
      ),
      body: makeBody(),
    );
  }
}
