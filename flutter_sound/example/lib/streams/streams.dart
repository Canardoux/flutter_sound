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
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
//import 'package:flutter_sound_web/flutter_sound_web.dart' show mime_types;

/*
 * This is an example showing how to record to a Dart Stream.
 * It writes all the recorded data from a Stream to a File, which is completely stupid:
 * if an App wants to record something to a File, it must not use Streams.
 *
 * The real interest of recording to a Stream is for example to feed a
 * Speech-to-Text engine, or for processing the Live data in Dart in real time.
 *
 */

///
typedef _Fn = void Function();
const int cstSampleRate = 16000;
const int cstNUMBEROFCHANNELS = 2;

/// Example app.
class StreamsExample extends StatefulWidget {
  const StreamsExample({super.key});

  @override
  State<StreamsExample> createState() => _StreamsExampleState();
}

class _StreamsExampleState extends State<StreamsExample> {
  final FlutterSoundPlayer _mPlayer = FlutterSoundPlayer();
  final FlutterSoundRecorder _mRecorder = FlutterSoundRecorder();
  bool _mPlayerIsInited = false;
  bool _mRecorderIsInited = false;
  Codec codecSelected = Codec.pcmFloat32;
  bool interleaved = false;
  List<List<Float32List>> bufferF32 = [];
  List<List<Int16List>> bufferInt16 = [];
  List<Uint8List> bufferUint8 = [];
  var recordingDataControllerF32 = StreamController<List<Float32List>>();
  var recordingDataControllerInt16 = StreamController<List<Int16List>>();
  var recordingDataControllerUint8 = StreamController<Uint8List>();

  bool _mplaybackReady = false;

  Future<void> _openRecorder() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }
    await _mRecorder.openRecorder();

    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.allowBluetooth |
              AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      avAudioSessionRouteSharingPolicy:
          AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.voiceCommunication,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));

    setState(() {
      _mRecorderIsInited = true;
    });
  }

  @override
  void initState() {
    super.initState();
    // Be careful : openAudioSession return a Future.
    // Do not access your FlutterSoundPlayer or FlutterSoundRecorder before the completion of the Future
    _mPlayer.openPlayer().then((value) {
      setState(() {
        _mPlayerIsInited = true;
      });
    });
    _openRecorder().then((value) {
      setState(() {
        _mRecorderIsInited = true;
      });
    });
  }

  @override
  void dispose() {
    stopPlayer();
    _mPlayer.closePlayer();

    stopRecorder();
    _mRecorder.closeRecorder();
    super.dispose();
  }

  // ----------------------  Here is the code to record to a Stream -----------------

  Future<void> recordBtn() async {
    if (interleaved) {
      bufferUint8 = [];
      recordingDataControllerUint8.close();
      recordingDataControllerUint8 = StreamController<Uint8List>();
      recordingDataControllerUint8.stream.listen((Uint8List buf) {
        bufferUint8.add(buf);
      });
      await _mRecorder.startRecorder(
        codec: codecSelected,
        sampleRate: cstSampleRate,
        numChannels: cstNUMBEROFCHANNELS,
        audioSource: AudioSource.defaultSource,
        toStream: recordingDataControllerUint8.sink,
      );
    } else if (codecSelected == Codec.pcmFloat32) {
      bufferF32 = [];
      recordingDataControllerF32.close();
      recordingDataControllerF32 = StreamController<List<Float32List>>();
      recordingDataControllerF32.stream.listen((buf) {
        bufferF32.add(buf);
      });
      await _mRecorder.startRecorder(
          codec: codecSelected,
          sampleRate: cstSampleRate,
          numChannels: cstNUMBEROFCHANNELS,
          audioSource: AudioSource.defaultSource,
          toStreamFloat32: recordingDataControllerF32.sink);
    } else if (codecSelected == Codec.pcm16) {
      bufferInt16 = [];
      recordingDataControllerInt16.close();
      recordingDataControllerInt16 = StreamController<List<Int16List>>();
      recordingDataControllerInt16.stream.listen((buf) {
        bufferInt16.add(buf);
      });
      await _mRecorder.startRecorder(
          codec: codecSelected,
          sampleRate: cstSampleRate,
          numChannels: cstNUMBEROFCHANNELS,
          audioSource: AudioSource.defaultSource,
          toStreamInt16: recordingDataControllerInt16.sink);
    }

    setState(() {});
  }

  Future<void> stopRecorder() async {
    await _mRecorder.stopRecorder();
    _mplaybackReady = true;
  }

  _Fn? getRecorderFn() {
    if (!_mRecorderIsInited || !_mPlayer.isStopped) {
      return null;
    }

    return _mRecorder.isStopped
        ? recordBtn
        : () {
            stopRecorder().then((value) => setState(() {}));
          };
  }

  // ----------------------  Here is the code to play from a Stream -----------------------

  Future<void> playBtn() async {
    if (_mPlayer.isStopped) {
        await _mPlayer.startPlayerFromStream(
        codec: codecSelected,
        sampleRate: cstSampleRate,
        numChannels: cstNUMBEROFCHANNELS,
        //whenFinished: () { stopPlayer().then((v){ setState(() {
        //});});},
        interleaved: interleaved,
        );

      if (interleaved) {
        for (var d in bufferUint8) {
          await _mPlayer.feedUint8FromStream(d);
          //_mPlayer.uint8ListSink!.add(d);
        }
      } else if (codecSelected == Codec.pcmFloat32) {
        for (var d in bufferF32) {
          await _mPlayer.feedF32FromStream(d);
          ///_mPlayer.float32Sink!.add(d);
        }
      } else if (codecSelected == Codec.pcm16) {
        for (var d in bufferInt16) {
          await _mPlayer.feedInt16FromStream(d);
          //_mPlayer.int16Sink!.add(d);
        }
      }
    } else {
      await stopPlayer();
    }
    setState(() {});
    }

  Future<void> stopPlayer() async {
    await _mPlayer.stopPlayer();
  }

  _Fn? getPlaybackFn() {
    if (!_mPlayerIsInited || !_mplaybackReady || !_mRecorder.isStopped) {
      return null;
    }
    return playBtn;
  }

  // ----------------------------------------------------------------------------------------------------------------------

  Future<void> reinit() async {
    await _mPlayer.stopPlayer();
    await _mRecorder.stopRecorder();
    bufferF32 = [];
    bufferInt16 = [];
    bufferUint8 = [];
    setState(() {
      _mplaybackReady = false;
    });
  }

  void setCodec(Codec? codec) {
    reinit();
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
          height: 60,
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
                child: Text(_mRecorder.isRecording ? 'Stop' : 'Record'),
              ),
              const SizedBox(
                width: 20,
              ),
              Text(_mRecorder.isRecording
                  ? 'Recording in progress'
                  : 'Recorder is stopped'),
              const SizedBox(
                width: 20,
              ),
            ]),
          ]),
        ),
        Container(
            margin: const EdgeInsets.all(3),
            padding: const EdgeInsets.all(3),
            height: 60,
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
                child: Text(_mPlayer.isPlaying ? 'Stop' : 'Play'),
              ),
              const SizedBox(
                width: 20,
              ),
              Text(_mPlayer.isPlaying
                  ? 'Playback in progress'
                  : 'Player is stopped'),
            ])),

        //Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        //children:
        //[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            CheckboxListTile(
              tileColor: const Color(0xFFFAF0E6),
              title: const Text("Interleaved"),
              value: interleaved,
              onChanged: (newValue) {
                reinit();
                setState(() {
                  interleaved = newValue!;
                });
              },
            )
          ],
        ),
      ]);
      //]),
      //]);
    }

    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        title: const Text('Streams ex.'),
      ),
      body: makeBody(),
    );
  }
}
