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
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

/*

This is an example showing how to record to a Dart Stream. It writes all the recorded data from a Stream to a File using It calls [startRecorder(toStream:)](/api/recorder/FlutterSoundRecorder/startRecorder.html) to fill a buffer from a stream, which is completely stupid: if an App wants to record something to a File, it must not use streams.
Then it can playback the file recorded.

The real interest of recording to a Stream is for example to feed a
Speech-to-Text engine, or for processing the Live data in Dart in real time.

 You can also refer to the following guide:
 - [Dart Streams](/tau/guides/guides_live_streams.html):

 */

///
typedef _Fn = void Function();

/// Example app.
class RecordToStreamExample extends StatefulWidget {
  const RecordToStreamExample({super.key});

  @override
  State<RecordToStreamExample> createState() => _RecordToStreamExampleState();
}

class _RecordToStreamExampleState extends State<RecordToStreamExample> {
  FlutterSoundPlayer? _mPlayer = FlutterSoundPlayer();
  FlutterSoundRecorder? _mRecorder = FlutterSoundRecorder();
  bool _mPlayerIsInited = false;
  bool _mRecorderIsInited = false;
  String? _mPath;
  StreamSubscription? _recorderSubscription;
  Codec codecSelected = Codec.pcmFloat32;

  bool _mplaybackReady = false;
  double _dbLevel = 0.0;
  StreamSubscription? _mRecordingDataSubscription;
  StreamController<List<int>> webStreamController = StreamController();

  @override
  void initState() {
    super.initState();
    setCodec(Codec.pcmFloat32);
    // Do not access your FlutterSoundPlayer or FlutterSoundRecorder before the completion of the Future
    _mPlayer!.openPlayer().then((value) {
      setState(() {
        _mPlayerIsInited = true;
      });
    });
    _openRecorder();
  }

  @override
  void dispose() {
    stopPlayer();
    _mPlayer!.closePlayer();
    _mPlayer = null;

    stopRecorder();
    _mRecorder!.closeRecorder();
    _mRecorder = null;
    super.dispose();
  }

  Future<IOSink> createFile() async {
    var tempDir = await getTemporaryDirectory();
    _mPath = '${tempDir.path}/flutter_sound_example.pcm';
    var outputFile = File(_mPath!);
    if (outputFile.existsSync()) {
      await outputFile.delete();
    }
    return outputFile.openWrite();
  }

  // ----------------------  Here is the code to record to a Stream ------------

  static const int cstSAMPLERATE = 16000;
  static const int cstCHANNELNB = 2;

  /// We have finished with the recorder. Release the subscription
  Future<void> cancelRecorderSubscriptions() async {
    if (_recorderSubscription != null) {
      await _recorderSubscription!.cancel();
      _recorderSubscription = null;
    }

    if (_mRecordingDataSubscription != null) {
      await _mRecordingDataSubscription!.cancel();
      _mRecordingDataSubscription = null;
    }
  }

  Future<void> _openRecorder() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }
    await _mRecorder!.openRecorder();

    _recorderSubscription = _mRecorder!.onProgress!.listen((e) {
      // pos = e.duration.inMilliseconds; // We do not need this information in this example.
      setState(() {
        _dbLevel = e.decibels as double;
      });
    });
    await _mRecorder!.setSubscriptionDuration(
        const Duration(milliseconds: 100)); // DO NOT FORGET THIS CALL !!!

    setState(() {
      _mRecorderIsInited = true;
    });

    setState(() {
      _mRecorderIsInited = true;
    });
  }

  Future<void> record() async {
    assert(_mRecorderIsInited && _mPlayer!.isStopped);
    StreamSink<List<int>>? sink;
    if (!kIsWeb) {
      sink = await createFile();
    } else {
      sink = webStreamController.sink;
    }

    var recordingDataController = StreamController<Uint8List>();
    _mRecordingDataSubscription =
        recordingDataController.stream.listen((buffer) {
      sink!.add(buffer);
    });
    await _mRecorder!.startRecorder(
      toStream: recordingDataController.sink,
      codec: codecSelected,
      numChannels: cstCHANNELNB,
      sampleRate: cstSAMPLERATE,
      bufferSize: 8192,
      audioSource: AudioSource.defaultSource,
    );
    setState(() {
      _dbLevel = 0.0;
    });
  }

  Future<void> stopRecorder() async {
    await _mRecorder!.stopRecorder();

    if (_mRecordingDataSubscription != null) {
      await _mRecordingDataSubscription!.cancel();
      _mRecordingDataSubscription = null;
    }

    _mplaybackReady = true;
  }
  // --------------------- (it was very simple, wasn't it ?) -------------------

  _Fn? getRecorderFn() {
    if (!_mRecorderIsInited || !_mPlayer!.isStopped) {
      return null;
    }
    return _mRecorder!.isStopped
        ? record
        : () {
            stopRecorder().then((value) => setState(() {}));
          };
  }

  void play() async {
    assert(_mPlayerIsInited &&
        _mplaybackReady &&
        _mRecorder!.isStopped &&
        _mPlayer!.isStopped);
    await _mPlayer!.startPlayer(
        fromURI: _mPath,
        sampleRate: cstSAMPLERATE,
        codec: codecSelected,
        numChannels: cstCHANNELNB,
        whenFinished: () {
          setState(() {});
        });
    setState(() {});
  }

  Future<void> stopPlayer() async {
    await _mPlayer!.stopPlayer();
  }

  _Fn? getPlaybackFn() {
    if (!_mPlayerIsInited || !_mplaybackReady || !_mRecorder!.isStopped) {
      return null;
    }
    return _mPlayer!.isStopped
        ? play
        : () {
            stopPlayer().then((value) => setState(() {}));
          };
  }

  // ----------------------------------------------------------------------------------------------------------------------

  void setCodec(Codec? codec) {
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
          height: 120,
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
                onPressed: getRecorderFn(),
                //color: Colors.white,
                //disabledColor: Colors.grey,
                child: Text(_mRecorder!.isRecording ? 'Stop' : 'Record'),
              ),
              const SizedBox(
                width: 20,
              ),
              Text(_mRecorder!.isRecording
                  ? 'Recording in progress'
                  : 'Recorder is stopped'),
            ]),
            const SizedBox(
              height: 20,
            ),
            _mRecorder!.isRecording
                ? LinearProgressIndicator(
                    value: _dbLevel / 100,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.indigo),
                    backgroundColor: Colors.limeAccent)
                : Container(),
          ]),
        ),
        Container(
            margin: const EdgeInsets.all(3),
            padding: const EdgeInsets.all(3),
            height: 120,
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
            ])),
        Container(
          margin: const EdgeInsets.all(3),
          padding: const EdgeInsets.all(3),
          height: 110,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFFAF0E6),
            border: Border.all(
              color: Colors.indigo,
              width: 3,
            ),
          ),
          child: Column(
            children: [
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
            ],
          ),
        ),
      ]);
    }

    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        title: const Text('Record to Stream ex.'),
      ),
      body: makeBody(),
    );
  }
}
