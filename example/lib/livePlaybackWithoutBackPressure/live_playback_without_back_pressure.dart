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

## You can see also those examples:
- [Streams](ex_streams)
- [Record To Stream](ex_record_to_stream)
- [Live Playback With Backpressure](fs-ex_playback_from_stream_2)

 */

///
const String kASSET16 =
    'assets/samples/sample_s16_2ch.raw'; // 'assets/samples/sample_f32_2ch.raw'; // 'assets/samples/sample_f32_2ch.raw' // 'assets/samples/sample_f32.raw'
const String kASSET32 =
    'assets/samples/sample_f32.raw'; // 'assets/samples/sample_f32_2ch.raw'; // 'assets/samples/sample_f32_2ch.raw' // 'assets/samples/sample_f32.raw'

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
  Codec codecSelected = Codec.pcmFloat32;
  double _mSpeed = 100.0;
  late Uint8List data16;
  late Uint8List data32;
  late Uint8List data;
  late int sampleRate;
  late bool stereo;

  @override
  void initState() {
    super.initState();
    initPlayer().then((void _) {
      setState(() {
        _mPlayerIsInited = true;
      });
    });
  }

  @override
  void dispose() {
    //stopPlayer();
    _mPlayer.closePlayer();
    super.dispose();
  }

  // --------------------------------  The Player stuff  ---------------------------

  Future<void> initPlayer() async {
    await _mPlayer.openPlayer();
    _mPlayerIsInited = false;
    data16 = await getAssetData(kASSET16);
    data32 = await getAssetData(kASSET32);
    setCodec(Codec.pcmFloat32);
  }

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

  // --------------------------  Here is the code to play Live data without back-pressure ----------------------

  /// In this example we give the data to Flutter Sound chunk by chunk. We feed the sink without waiting,
  void feedHim(Uint8List data) {
    var start = 0;
    var totalLength = data.length;
    while (totalLength > 0 && !_mPlayer.isStopped) {
      var ln = totalLength > cstBLOCKSIZE ? cstBLOCKSIZE : totalLength;
      _mPlayer.uint8ListSink!.add(data.sublist(start, start + ln));
      //_mPlayer.foodSink!.add(FoodData(data.sublist(start, start + ln)));
      totalLength -= ln;
      start += ln;
    }
  }

  /// Start the player from a Codec.pcm16 Stream, Stereo
  void play() async {
    await _mPlayer.startPlayerFromStream(
        codec: codecSelected, // Codec.pcm16
        numChannels: stereo ? 2 : 1,
        interleaved: true, // This is the default
        sampleRate: sampleRate, // Sample rate is 8000
        bufferSize: 1024
        //bufferSize: cstBLOCKSIZE,
        );
    feedHim(data);
    _mPlayer.logger.d('Finished');

    setState(() {});
  }

  // --------------------- (it was very simple, wasn't it ?) -------------------

  void setCodec(Codec? codec) {
    if (codec == Codec.pcm16) {
      data = data16;
      sampleRate = 8000;
      stereo = true;
    } else {
      data = data32;
      sampleRate = 8000;
      stereo = false;
    }
    setState(() {
      codecSelected = codec!;
    });
  }

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
                onPressed: _mPlayerIsInited
                    ? () {
                        _mPlayer.isPlaying ? stopPlayer() : play();
                      }
                    : null,
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
        ListTile(
          tileColor: const Color(0xFFFAF0E6),
          title: const Text('PCM-Float32'),
          dense: true,

          //textColor: encoderSupported[Codec.pcmFloat32.index]
          //? Colors.green
          //: Colors.grey,
          leading: Radio<Codec>(
            value: Codec.pcmFloat32,
            groupValue: codecSelected,
            onChanged: setCodec,
          ),
        ),
        ListTile(
          tileColor: const Color(0xFFFAF0E6),
          title: const Text('PCM-Int16'),
          dense: true,

          ///textColor: encoderSupported[Codec.pcm16.index]
          ///? Colors.green
          //: Colors.grey,
          leading: Radio<Codec>(
            value: Codec.pcm16,
            groupValue: codecSelected,
            onChanged: setCodec,
          ),
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
