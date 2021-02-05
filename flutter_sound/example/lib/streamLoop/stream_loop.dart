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
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';

/*
 *
 * ```streamLoop()``` is a very simple example which connect the FlutterSoundRecorder sink
 * to the FlutterSoundPlayer Stream.
 * Of course, we do not play to the loudspeaker to avoid a very unpleasant Larsen effect.
 * This example does not use a new StreamController, but use directly `foodStreamController`
 * from flutter_sound_player.dart.
 *
 */

const int _sampleRateRecorder = 44000;
const int _sampleRatePlayer = 44000; // same speed than the recorder

///
typedef Fn = void Function();

/// Example app.
class StreamLoop extends StatefulWidget {
  @override
  _StreamLoopState createState() => _StreamLoopState();
}

class _StreamLoopState extends State<StreamLoop> {
  FlutterSoundPlayer _mPlayer = FlutterSoundPlayer();
  FlutterSoundRecorder _mRecorder = FlutterSoundRecorder();
  bool _isInited = false;

  Future<void> init() async {
    await _mRecorder.openAudioSession(
      device: AudioDevice.blueToothA2DP,
      audioFlags: allowHeadset | allowEarPiece | allowBlueToothA2DP,
      category: SessionCategory.playAndRecord,
    );
    await _mPlayer.openAudioSession(
      device: AudioDevice.blueToothA2DP,
      audioFlags: allowHeadset | allowEarPiece | allowBlueToothA2DP,
      category: SessionCategory.playAndRecord,
    );
  }

  @override
  void initState() {
    super.initState();
    // Be careful : openAudioSession return a Future.
    // Do not access your FlutterSoundPlayer or FlutterSoundRecorder before the completion of the Future
    init().then((value) {
      setState(() {
        _isInited = true;
      });
    });
  }

  Future<void> release() async {
    await stopPlayer();
    await _mPlayer.closeAudioSession();
    _mPlayer = null;

    await stopRecorder();
    await _mRecorder.closeAudioSession();
    _mRecorder = null;
  }

  @override
  void dispose() {
    release();
    super.dispose();
  }

  Future<void> stopRecorder() {
    if (_mRecorder != null) {
      return _mRecorder.stopRecorder();
    }
    return null;
  }

  Future<void> stopPlayer() {
    if (_mPlayer != null) {
      return _mPlayer.stopPlayer();
    }
    return null;
  }

  Future<void> record() async {
    await _mPlayer.startPlayerFromStream(
      codec: Codec.pcm16,
      numChannels: 1,
      sampleRate: _sampleRatePlayer,
    );

    await _mRecorder.startRecorder(
      codec: Codec.pcm16,
      toStream: _mPlayer.foodSink, // ***** THIS IS THE LOOP !!! *****
      sampleRate: _sampleRateRecorder,
      numChannels: 1,
    );
    setState(() {});
  }

  Future<void> stop() async {
    if (_mRecorder != null) {
      await _mRecorder.stopRecorder();
    }
    if (_mPlayer != null) {
      await _mPlayer.stopPlayer();
    }
    setState(() {});
  }

  Fn getRecFn() {
    if (!_isInited) {
      return null;
    }
    return _mRecorder.isRecording ? stop : record;
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
              color: Color(0xFFFAF0E6),
              border: Border.all(
                color: Colors.indigo,
                width: 3,
              ),
            ),
            child: Row(children: [
              ElevatedButton(
                onPressed: getRecFn(),
                //color: Colors.white,
                //disabledColor: Colors.grey,
                child: Text(_mRecorder.isRecording ? 'Stop' : 'Record'),
              ),
              SizedBox(
                width: 20,
              ),
              Text(_mRecorder.isRecording
                  ? 'Playback to your headset!'
                  : 'Recorder is stopped'),
            ]),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        title: const Text('Stream Loop'),
      ),
      body: makeBody(),
    );
  }
}
