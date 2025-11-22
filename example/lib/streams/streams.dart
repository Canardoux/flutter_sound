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
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_session/audio_session.dart';

/*

The real interest of recording to a Stream is for example to feed a Speech-to-Text engine,
or for processing the Live data in Dart in real time.

This example can record something to a Stream. It handle the stream to store the data in memory.

Then, the user can play a Stream that read the data store in memory.

The example is just a little bit complicated because there are inside both a player stream and a recorder stream,
because the user can select if he/she wants to use streams interleaved or planed,
and because he/she can select to use Float32 PCM or Int16 PCM

 */

typedef _Fn = void Function();

/// The sample rate
const int kSampleRate = 48000; // 16000;

/// The block size of our audio data
const int kBlockSize = 1024; //1000;

/// Stereo
const int cstNUMBEROFCHANNELS = 2;

/// Example app.
class StreamsExample extends StatefulWidget {
  const StreamsExample({super.key});

  @override
  State<StreamsExample> createState() => _StreamsExampleState();
}

class _StreamsExampleState extends State<StreamsExample> {
  final FlutterSoundPlayer _mPlayer = FlutterSoundPlayer();
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
  double _dbLevel = 0.0;
  double _mVolume = 100.0;
  double _mPan = 100.0;

  Future<void> init() async {
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

    setCodec(Codec.pcmFloat32);
    // Do not access your FlutterSoundPlayer or FlutterSoundRecorder before the completion of the Future
    _mPlayer.openPlayer().then((value) {
      setState(() {
        _mPlayerIsInited = true;
      });
      _openRecorder();
    });
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    stopPlayer();
    _mPlayer.closePlayer();

    stopRecorder();
    _mRecorder.closeRecorder();
    super.dispose();
    cancelRecorderSubscriptions();
  }

  // ----------------------------------- The recorder stuff ---------------------------------

  /// The recorder
  final FlutterSoundRecorder _mRecorder = FlutterSoundRecorder();

  /// A subscription
  StreamSubscription? _recorderSubscription;

  /// Request the permission to record something and open the recorder
  Future<void> _openRecorder() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }
    await _mRecorder.openRecorder();
    _recorderSubscription = _mRecorder.onProgress!.listen((e) {
      // pos = e.duration.inMilliseconds; // We do not need this information in this example.
      setState(() {
        _dbLevel = e.decibels as double;
      });
    });
    await _mRecorder.setSubscriptionDuration(
        const Duration(milliseconds: 100)); // DO NOT FORGET THIS CALL !!!

    setState(() {
      _mRecorderIsInited = true;
    });
  }

  /// We have finished with the recorder. Release the subscription
  void cancelRecorderSubscriptions() {
    if (_recorderSubscription != null) {
      _recorderSubscription!.cancel();
      _recorderSubscription = null;
    }
  }

  /// This is our main function where we begin to record to a dart stream
  Future<void> recordBtn() async {
    _dbLevel = 0.0;

    // When interleaved, the Recorder gives the audio data as a Uint8List
    if (interleaved) {
      bufferUint8 = [];
      recordingDataControllerUint8.close();
      recordingDataControllerUint8 = StreamController<Uint8List>();
      recordingDataControllerUint8.stream.listen((Uint8List buf) {
        bufferUint8.add(buf);
      });
      await _mRecorder.startRecorder(
        codec: codecSelected,
        sampleRate: kSampleRate,
        numChannels: cstNUMBEROFCHANNELS,
        audioSource: AudioSource.defaultSource,
        toStream: recordingDataControllerUint8.sink,
        bufferSize: 8192,
      );
    } else

    // When not interleaved, the Recorder gives the audio data
    // as pcmFloat32 or Int16List, depending of the codec
    if (codecSelected == Codec.pcmFloat32) {
      bufferF32 = [];
      recordingDataControllerF32.close();
      recordingDataControllerF32 = StreamController<List<Float32List>>();
      recordingDataControllerF32.stream.listen((buf) {
        bufferF32.add(buf);
      });
      await _mRecorder.startRecorder(
          codec: codecSelected,
          sampleRate: kSampleRate,
          numChannels: cstNUMBEROFCHANNELS,
          audioSource: AudioSource.defaultSource,
          toStreamFloat32: recordingDataControllerF32.sink);
    } else if (codecSelected == Codec.pcm16) {
      // The recorder gives the data as Int16List
      bufferInt16 = [];
      recordingDataControllerInt16.close();
      recordingDataControllerInt16 = StreamController<List<Int16List>>();
      recordingDataControllerInt16.stream.listen((buf) {
        bufferInt16.add(buf);
      });
      await _mRecorder.startRecorder(
          codec: codecSelected,
          sampleRate: kSampleRate,
          numChannels: cstNUMBEROFCHANNELS,
          audioSource: AudioSource.defaultSource,
          toStreamInt16: recordingDataControllerInt16.sink);
    }

    setState(() {});
  }

  static int ixs = 0;
  static int ps = 0;

  List<double>? next32(List<List<Float32List>> source) {
    while (ixs < source.length) {
      List<Float32List> curBlk = source[ixs];
      while (ps >= curBlk[0].length) {
        ++ixs;
        ps = 0;
        if (ixs >= source.length) return null;
      }
      List<double> r = [];
      int nbrChannels = curBlk.length;
      for (int channel = 0; channel < nbrChannels; ++channel) {
        r.add(curBlk[channel][ps]);
      }
      ++ps;
      return r;
    }
    return null;
  }

  List<int>? next16(List<List<Int16List>> source) {
    while (ixs < source.length) {
      List<Int16List> curBlk = source[ixs];
      while (ps >= curBlk[0].length) {
        ++ixs;
        ps = 0;
        if (ixs >= source.length) return null;
      }
      List<int> r = [];
      int nbrChannels = curBlk.length;
      for (int channel = 0; channel < nbrChannels; ++channel) {
        r.add(curBlk[channel][ps]);
      }
      ++ps;
      return r;
    }
    return null;
  }

  // This function repack the audio data received with another blocksize.
  // This is just to check that everything working correctly.
  List<List<Float32List>> repackF32(List<List<Float32List>> source) {
    ixs = 0;
    ps = 0;
    if (source.isEmpty) {
      return source;
    }
    int nbrChannels = source[0].length;
    List<List<Float32List>> dest = [];
    while (true) {
      List<Float32List> r = [];
      for (int channel = 0; channel < nbrChannels; ++channel) {
        r.add(Float32List(kBlockSize));
      }

      for (int ixd = 0; ixd < kBlockSize; ++ixd) {
        List<double>? nextRec = next32(source);
        if (nextRec == null) {
          dest.add(r);
          return dest;
        }
        for (int channel = 0; channel < nbrChannels; ++channel) {
          r[channel][ixd] = nextRec[channel];
        }
      }
      dest.add(r);
    }
  }

  // This function repack the audio data received with another blocksize.
  // This is just to check that everything working correctly.
  List<List<Int16List>> repackI16(List<List<Int16List>> source) {
    ixs = 0;
    ps = 0;
    if (source.isEmpty) {
      return source;
    }

    int nbrChannels = source[0].length;
    List<List<Int16List>> dest = [];
    while (true) {
      List<Int16List> r = [];
      for (int channel = 0; channel < nbrChannels; ++channel) {
        r.add(Int16List(kBlockSize));
      }

      for (int ixd = 0; ixd < kBlockSize; ++ixd) {
        List<int>? nextRec = next16(source);
        if (nextRec == null) {
          dest.add(r);
          return dest;
        }
        for (int channel = 0; channel < nbrChannels; ++channel) {
          r[channel][ixd] = nextRec[channel];
        }
      }
      dest.add(r);
    }
  }

  Future<void> stopRecorder() async {
    await _mRecorder.stopRecorder();
    if (!interleaved) {
      if (codecSelected == Codec.pcmFloat32) {
        bufferF32 = repackF32(bufferF32);
      } else {
        bufferInt16 = repackI16(bufferInt16);
      }
    }
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

  void pause() async {
    await _mRecorder.pauseRecorder();
    setState(() {});
  }

  void resume() async {
    await _mRecorder.resumeRecorder();
    setState(() {});
  }
  // ----------------------  Here is the code to play from a Stream -----------------------

  /// This is our main function where we begin to play
  /// the audio data stored in our buffer
  Future<void> playBtn() async {
    if (_mPlayer.isStopped) {
      await _mPlayer.startPlayerFromStream(
        codec: codecSelected,
        sampleRate: kSampleRate,
        numChannels: cstNUMBEROFCHANNELS,
        interleaved: interleaved,
        bufferSize: 1024,
      );
      setState(() {});

      // When interleaved, we feed the stream with the Uint8List audio data
      // which has been buffered by the recorder in bufferUint8
      if (interleaved) {
        for (var d in bufferUint8) {
          await _mPlayer.feedUint8FromStream(d);
          //_mPlayer.uint8ListSink!.add(d); // Another way to feed the stream
        }
      } else

      // When the codec selected is Codec.pcmFloat32, we feed the stream
      // with the audio data buffered in bufferF32
      if (codecSelected == Codec.pcmFloat32) {
        for (var d in bufferF32) {
          await _mPlayer.feedF32FromStream(d);
          //_mPlayer.float32Sink!.add(d); // Another way to feed the stream
        }
      } else

      // When the codec selected is Codec.pcm16, we feed the stream
      // with the audio data buffered in bufferInt16
      if (codecSelected == Codec.pcm16) {
        for (var d in bufferInt16) {
          await _mPlayer.feedInt16FromStream(d);
          //_mPlayer.int16Sink!.add(d); // Another way to feed the stream
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

  // Does not handle when > 100db
  Future<void> setVolume(double v) async // v is between 0.0 and 100.0
  {
    v = v > 100.0 ? 100.0 : v;
    _mVolume = v;
    setState(() {});
    //await _mPlayer!.setVolume(v / 100, fadeDuration: Duration(milliseconds: 5000));
    await _mPlayer.setVolume(
      v / 100,
    );
  }

  // We are in stereo mode
  Future<void> setPan(double v) async // v is between 0.0 and 100.0
  {
    v = v > 100.0 ? 100.0 : v;
    _mPan = v;
    setState(() {});
    //await _mPlayer!.setVolume(v / 100, fadeDuration: Duration(milliseconds: 5000));
    await _mPlayer.setVolumePan(v / 100, 0);
  }

  // ----------------------------------------------------------------------------------------------------------------------

  // The user changed its selection. Reset the 3 buffers
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
          height: 130,
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
              ElevatedButton(
                onPressed: _mRecorder.isRecording ? pause : null,
                //color: Colors.white,
                //disabledColor: Colors.grey,
                child: const Text('Pause'),
              ),
              ElevatedButton(
                onPressed: _mRecorder.isPaused ? resume : null,
                //color: Colors.white,
                //disabledColor: Colors.grey,
                child: const Text('Resume'),
              ),
            ]),
            const SizedBox(
              height: 20,
            ),
            _mRecorder.isRecording
                ? LinearProgressIndicator(
                    value: _dbLevel / 100,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.indigo),
                    backgroundColor: Colors.limeAccent)
                : Container(),
            Text(_mRecorder.isRecording
                ? 'Recording in progress'
                : 'Recorder is stopped'),
            const SizedBox(
              width: 20,
            ),
          ]),
        ),
        Container(
          margin: const EdgeInsets.all(3),
          padding: const EdgeInsets.all(3),
          height: 220,
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
                child: Text(_mPlayer.isPlaying ? 'Stop' : 'Play'),
              ),
              const SizedBox(
                width: 20,
              ),
              Text(_mPlayer.isPlaying
                  ? 'Playback in progress'
                  : 'Player is stopped'),
            ]),
            const Text('Volume:'),
            Slider(
                value: _mVolume,
                min: 0.0,
                max: 100.0,
                onChanged: setVolume,
                divisions: 100),
            const Text('Pan:'),
            Slider(
                value: _mPan,
                min: 0.0,
                max: 100.0,
                onChanged: setPan,
                divisions: 100),
          ]),
        ),
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
