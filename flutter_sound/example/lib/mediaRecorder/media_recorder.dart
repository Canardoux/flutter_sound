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
import 'package:flutter_sound_web/flutter_sound_web.dart' show mime_types;

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

/// Example app.
class MediaRecorderExample extends StatefulWidget {
  const MediaRecorderExample({super.key});

  @override
  State<MediaRecorderExample> createState() => _MediaRecorderExampleState();
}

class _MediaRecorderExampleState extends State<MediaRecorderExample> {
  FlutterSoundPlayer? _mPlayer = FlutterSoundPlayer();
  FlutterSoundRecorder? _mRecorder = FlutterSoundRecorder();
  bool _mPlayerIsInited = false;
  bool _mRecorderIsInited = false;

  bool _mplaybackReady = false;
  //String? _mPath;
  List<double> bufferF32 = [];
  List<int> bufferI16 = [];
  List<int> bufferU8 = [];
  int sampleRate = 0;
  Codec codecSelected = Codec.pcmFloat32;
  List<bool> encoderSupported = List.filled(mime_types.length, false);
  Future<void> _openRecorder() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }
    await _mRecorder!.openRecorder();

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
    sampleRate = await _mRecorder!.getSampleRate();
    for (int i = 0; i < encoderSupported.length; ++i) {
      encoderSupported[i] =
          await _mRecorder!.isEncoderSupported(Codec.values[i]);
    }

    setState(() {
      _mRecorderIsInited = true;
    });
  }

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

  /*
  Future<IOSink> createFile() async {
    var tempDir = await getTemporaryDirectory();
    _mPath = '${tempDir.path}/flutter_sound_example.pcm';
    var outputFile = File(_mPath!);
    if (outputFile.existsSync()) {
      await outputFile.delete();
    }
    return outputFile.openWrite();
  }
*/
  // ----------------------  Here is the code to record to a Stream ------------

  Future<void> recordFloat32() async {
    //var sink = await createFile();
    //controller = StreamController<Uint8List>()
    bufferF32 = [];
    var recordingDataController = StreamController<List<Float32List>>();
    recordingDataController.stream.listen((buf) {
      bufferF32.addAll(buf[0]);
    });
    await _mRecorder!.startRecorder(
      toStreamFloat32: recordingDataController.sink,
      codec: Codec.pcmFloat32,
      numChannels: 2,
      bufferSize: 8192,
    );
  }

  Future<void> recordInt16() async {
    bufferI16 = [];
    var recordingDataController = StreamController<List<Int16List>>();
    recordingDataController.stream.listen((buf) {
      bufferI16.addAll(buf[0]);
    });
    await _mRecorder!.startRecorder(
      toStreamInt16: recordingDataController.sink,
      codec: Codec.pcm16,
      numChannels: 2,
      bufferSize: 8192,
    );
  }

  Future<void> recordCodec() async {
    bufferU8 = [];
    var recordingDataController = StreamController<Uint8List>();
    recordingDataController.stream.listen((buf) {
      bufferU8.addAll(buf);
    });
    await _mRecorder!.startRecorder(
      toStream: recordingDataController.sink,
      codec: codecSelected,
      timeSlice: const Duration(milliseconds: 1000),
      numChannels: 1,
      bufferSize: 8192,
    );
  }

  Future<void> record() async {
    assert(_mRecorderIsInited && _mPlayer!.isStopped);
    if (codecSelected == Codec.pcmFloat32) {
      await recordFloat32();
    } else if (codecSelected == Codec.pcm16) {
      await recordInt16();
    } else {
      await recordCodec();
    }
    setState(() {});
  }

  Future<void> playFloat32() async {
    Uint8List buf = Uint8List(2 * bufferF32.length);
    for (int i = 1; i < bufferF32.length; ++i) {
      int v = (bufferF32[i] * 32768).floor();
      buf[2 * i + 1] = v >> 8;
      buf[2 * i] = v & 0xFF;
    }
    await _mPlayer!.startPlayer(
        fromDataBuffer: buf,
        sampleRate: sampleRate,
        codec: Codec.pcm16,
        numChannels: 1,
        whenFinished: () {
          setState(() {});
        });
  }

  Future<void> playInt16() async {
    Uint8List buf = Uint8List(2 * bufferI16.length);
    for (int i = 1; i < bufferI16.length; ++i) {
      buf[2 * i + 1] = bufferI16[i] >> 8;
      buf[2 * i] = bufferI16[i] & 0xFF;
    }
    await _mPlayer!.startPlayer(
        fromDataBuffer: buf,
        sampleRate: sampleRate,
        codec: Codec.pcm16,
        numChannels: 1,
        whenFinished: () {
          setState(() {});
        });
  }

  Future<void> playCodec() async {
    Uint8List buf = Uint8List(bufferU8.length);
    for (int i = 0; i < bufferU8.length; ++i) {
      buf[i] = bufferU8[i];
    }
    await _mPlayer!.startPlayer(
        fromDataBuffer: buf,
        //sampleRate: sampleRate,
        codec: codecSelected,
        numChannels: 1,
        whenFinished: () {
          setState(() {});
        });
  }

  void play() async {
    assert(_mPlayerIsInited &&
        _mplaybackReady &&
        _mRecorder!.isStopped &&
        _mPlayer!.isStopped);
    if (codecSelected == Codec.pcmFloat32) {
      await playFloat32();
    } else if (codecSelected == Codec.pcm16) {
      await playInt16();
    } else {
      await playCodec();
    }

    setState(() {});
  }

  // ----------------------------------------

  Future<void> stopRecorder() async {
    await _mRecorder!.stopRecorder();
    //if (_mRecordingDataSubscription != null) {
    //await _mRecordingDataSubscription!.cancel();
    //_mRecordingDataSubscription = null;
    //}
    _mplaybackReady = true;
  }

  _Fn? getRecorderFn() {
    if (!_mRecorderIsInited || !_mPlayer!.isStopped) {
      return null;
    }
    if (!encoderSupported[codecSelected.index]) {
      return null;
    }
    return _mRecorder!.isStopped
        ? record
        : () {
            stopRecorder().then((value) => setState(() {}));
          };
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

  void selectCodec(Codec codec) async {
    codecSelected = codec;
    setState(() {});
  }

  void setCodec(Codec? codec) {
    _mplaybackReady = false;
    setState(() {
      codecSelected = codec!;
    });
  }

  void requestData() {
    _mRecorder!.requestData();
  }
  // ----------------------------------------------------------------------------------------------------------------------

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
                child: Text(_mRecorder!.isRecording ? 'Stop' : 'Record'),
              ),
              const SizedBox(
                width: 20,
              ),
              Text(_mRecorder!.isRecording
                  ? 'Recording in progress'
                  : 'Recorder is stopped'),
              const SizedBox(
                width: 20,
              ),
              ElevatedButton(
                onPressed: _mRecorder!.isRecording &&
                        codecSelected != Codec.pcmFloat32 &&
                        codecSelected != Codec.pcm16
                    ? requestData
                    : null,
                //color: Colors.white,
                //disabledColor: Colors.grey,
                child: const Text('Request Data'),
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
                child: Text(_mPlayer!.isPlaying ? 'Stop' : 'Play'),
              ),
              const SizedBox(
                width: 20,
              ),
              Text(_mPlayer!.isPlaying
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
              textColor: encoderSupported[Codec.pcmFloat32.index]
                  ? Colors.green
                  : Colors.grey,
              leading: Radio<Codec>(
                value: Codec.pcmFloat32,
                groupValue: codecSelected,
                onChanged:
                    !encoderSupported[Codec.pcmFloat32.index] ? null : setCodec,
              ),
            ),
            ListTile(
              tileColor: const Color(0xFFFAF0E6),
              title: const Text('PCM-Int16'),
              dense: true,
              textColor: encoderSupported[Codec.pcm16.index]
                  ? Colors.green
                  : Colors.grey,
              leading: Radio<Codec>(
                value: Codec.pcm16,
                groupValue: codecSelected,
                onChanged:
                    !encoderSupported[Codec.pcm16.index] ? null : setCodec,
              ),
            ),

            //]),
            //Column (children:
            //[
            ListTile(
              tileColor: const Color(0xFFFAF0E6),
              title: Text('AAC-ADTS (${mime_types[Codec.aacADTS.index]})'),
              textColor: encoderSupported[Codec.aacADTS.index]
                  ? Colors.green
                  : Colors.grey,
              dense: true,
              leading: Radio<Codec>(
                value: Codec.aacADTS,
                groupValue: codecSelected,
                onChanged:
                    !encoderSupported[Codec.aacADTS.index] ? null : setCodec,
              ),
            ),
            ListTile(
              tileColor: const Color(0xFFFAF0E6),
              textColor: encoderSupported[Codec.opusOGG.index]
                  ? Colors.green
                  : Colors.grey,
              title: Text('OPUS-OGG (${mime_types[Codec.opusOGG.index]})'),
              dense: true,
              leading: Radio<Codec>(
                value: Codec.opusOGG,
                groupValue: codecSelected,
                onChanged:
                    !encoderSupported[Codec.opusOGG.index] ? null : setCodec,
              ),
            ),
            ListTile(
              tileColor: const Color(0xFFFAF0E6),
              textColor: encoderSupported[Codec.mp3.index]
                  ? Colors.green
                  : Colors.grey,
              title: Text('MPEG-MP3 (${mime_types[Codec.mp3.index]})'),
              dense: true,
              leading: Radio<Codec>(
                value: Codec.mp3,
                groupValue: codecSelected,
                onChanged: !encoderSupported[Codec.mp3.index] ? null : setCodec,
              ),
            ),
            ListTile(
              tileColor: const Color(0xFFFAF0E6),
              textColor: encoderSupported[Codec.vorbisOGG.index]
                  ? Colors.green
                  : Colors.grey,
              dense: true,
              title: Text('VORBIS-OGG (${mime_types[Codec.vorbisOGG.index]})'),
              leading: Radio<Codec>(
                value: Codec.vorbisOGG,
                groupValue: codecSelected,
                onChanged:
                    !encoderSupported[Codec.vorbisOGG.index] ? null : setCodec,
              ),
            ),
            ListTile(
              tileColor: const Color(0xFFFAF0E6),
              textColor: encoderSupported[Codec.pcm16WAV.index]
                  ? Colors.green
                  : Colors.grey,
              dense: true,
              title: Text('PCM16-WAV (${mime_types[Codec.pcm16WAV.index]})'),
              leading: Radio<Codec>(
                value: Codec.pcm16WAV,
                groupValue: codecSelected,
                onChanged:
                    !encoderSupported[Codec.pcm16WAV.index] ? null : setCodec,
              ),
            ),
            ListTile(
              tileColor: const Color(0xFFFAF0E6),
              dense: true,
              textColor: encoderSupported[Codec.flac.index]
                  ? Colors.green
                  : Colors.grey,
              title: Text('FLAC (${mime_types[Codec.flac.index]})'),
              leading: Radio<Codec>(
                value: Codec.flac,
                groupValue: codecSelected,
                onChanged:
                    !encoderSupported[Codec.flac.index] ? null : setCodec,
              ),
            ),
            ListTile(
              tileColor: const Color(0xFFFAF0E6),
              dense: true,
              textColor: encoderSupported[Codec.aacMP4.index]
                  ? Colors.green
                  : Colors.grey,
              title: Text('AAC-MP4 (${mime_types[Codec.aacMP4.index]})'),
              leading: Radio<Codec>(
                value: Codec.aacMP4,
                groupValue: codecSelected,
                onChanged:
                    !encoderSupported[Codec.aacMP4.index] ? null : setCodec,
              ),
            ),
            ListTile(
              tileColor: const Color(0xFFFAF0E6),
              dense: true,
              textColor: encoderSupported[Codec.opusWebM.index]
                  ? Colors.green
                  : Colors.grey,
              title: Text('OPUS-WEBM (${mime_types[Codec.opusWebM.index]})'),
              leading: Radio<Codec>(
                value: Codec.opusWebM,
                groupValue: codecSelected,
                onChanged:
                    !encoderSupported[Codec.opusWebM.index] ? null : setCodec,
              ),
            ),
            ListTile(
              tileColor: const Color(0xFFFAF0E6),
              dense: true,
              textColor: encoderSupported[Codec.vorbisWebM.index]
                  ? Colors.green
                  : Colors.grey,
              title: Text('VORBIS-WEBM(${mime_types[Codec.vorbisWebM.index]})'),
              leading: Radio<Codec>(
                value: Codec.vorbisWebM,
                groupValue: codecSelected,
                onChanged:
                    !encoderSupported[Codec.vorbisWebM.index] ? null : setCodec,
              ),
            ),
          ],
        )
      ]);
      //]),
      //]);
    }

    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        title: const Text('Media Recorder ex.'),
      ),
      body: makeBody(),
    );
  }
}
