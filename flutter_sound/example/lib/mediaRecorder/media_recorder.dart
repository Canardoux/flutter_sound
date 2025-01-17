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


var mime_types = [
  'audio/webm\;codecs=opus', // defaultCodec,
  'audio/aac', // aacADTS, //*
  'audio/opus\;codecs=opus', // opusOGG, // 'audio/ogg' 'audio/opus'
  'audio/x-caf', // opusCAF,
  'audio/mpeg', // mp3, //*
  'audio/ogg\;codecs=vorbis', // vorbisOGG,// 'audio/ogg' // 'audio/vorbis'
  'audio/pcm', // pcm16,
  'audio/wav\;codecs=1', // pcm16WAV,
  'audio/aiff', // pcm16AIFF,
  'audio/x-caf', // pcm16CAF,
  'audio/x-flac', // flac, // 'audio/flac'
  'audio/mp4', // aacMP4, //*
  'audio/AMR', // amrNB, //*
  'audio/AMR-WB', // amrWB, //*
  'audio/pcm', // pcm8,
  'audio/pcm', // pcmFloat32,
  'audio/webm\;codecs=pcm', // pcmWebM,
  'audio/webm\;codecs=opus', // opusWebM,
  'audio/webm\;codecs=vorbis', // vorbisWebM
];

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
  List<Float32List> bufferF32 = [];
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
    sampleRate = 48000; //await _mRecorder!.getSampleRate();
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
    var recordingDataController = StreamController<List<Uint8List>>();
    recordingDataController.stream.listen((buf) {



      // It is not necessary to convert the UInt8List to a Float32List.
      // We do that, here, just as an example
      List<Float32List> r = FlutterSoundHelper().uint8ListToFloat32List(buf);
      bufferF32.add(r[0]); // In this example we keep only the left channel
      List<Uint8List> b = []; // We re-convert to List<Uint8List>> (this is dummy, we get back the original buffer);

      /*
      List<Float32List> r = [];
      for (Uint8List channelData in buf) {
        int ln = ((channelData.length)/4).floor();
        final bd = ByteData.sublistView(channelData);
        Float32List f32List = Float32List(ln);
        //int ix = 0;
        for (int offset = 0, ix = 0; offset < ln; offset += 4, ++ix) {
          f32List[ix] = bd.getFloat32(offset, Endian.little);
        }
        r.add(f32List);
      }
      Uint8List b0 = buf[0];
      Uint8List b1 = buf[1];
      var uint8ListExample0 = b0.buffer.asFloat32List();
      var uint8ListExample1= b1.buffer.asFloat32List();

      ByteData byteData = b0.buffer.asByteData();
      var f0 = byteData.getFloat32(0, Endian.big);
      var f1 = byteData.getFloat32(4, Endian.big);
      var f2 = byteData.getFloat32(0, Endian.little);
      var f3 = byteData.getFloat32(4, Endian.little);

      final bd = ByteData.sublistView(b0);
      var ff0 = bd.getFloat32(0, Endian.big);
      var ff1 = bd.getFloat32(4, Endian.big);
      var ff2 = bd.getFloat32(0, Endian.little);
      var ff3 = bd.getFloat32(4, Endian.little);

      final bbd  = ByteData.view(b0.buffer);
      var ffx0 = bbd.getFloat32(0, Endian.big);
      var ffx1 = bbd.getFloat32(4, Endian.big);
      var ffx2 = bbd.getFloat32(0, Endian.little);
      var fff3 = bbd.getFloat32(4, Endian.little);

      var buf0 = b0.buffer;
      var buf1 = b1.buffer;
      var floatListExample0 = b0.buffer.asFloat32List();
      var floatListExample1 = b1.buffer.asFloat32List();
      var uintListExample0 = b0.buffer.asInt8List();
      var uintListExample1 = b1.buffer.asInt8List();
      var lnb0 = b0.buffer.lengthInBytes;
      var lnb1 = b1.buffer.lengthInBytes;
      var lnf0 = buf[0].length;
      var lnf1 = buf[1].length;


       */



    });
    await _mRecorder!.startRecorder(
      toStreamFloat32: recordingDataController.sink,
      codec: Codec.pcmFloat32,
      numChannels: 2,
      bufferSize: 8192,
    );
    setState(() {});

  }

  /*
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


   */
  Future<void> playFloat32() async {
    List<int> buf = [];
    for (Float32List b in bufferF32) {
      for (int i = 0; i < b.length; ++i) {
        int v = (b[i] * 32768).toInt();
        buf.add( (v >> 8 ) & 0xFF );
        buf.add( v & 0xFF );
      }
    }

    Uint8List b =  Uint8List.fromList(buf);
    await _mPlayer!.startPlayer(
        fromDataBuffer: b,
        sampleRate: sampleRate,
        codec: Codec.pcm16,
        numChannels: 1,
        whenFinished: () {
           _mPlayer!.stopPlayer().then( (_){setState(() {});});

        });
  }

  void play() async {
    assert(_mPlayerIsInited &&
        _mplaybackReady &&
        _mRecorder!.isStopped &&
        _mPlayer!.isStopped);
      await playFloat32();

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
        ? recordFloat32
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
