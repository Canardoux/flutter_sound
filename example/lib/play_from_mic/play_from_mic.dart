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
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_session/audio_session.dart';

/*

This is a very simple example for Flutter Sound beginners,
hat shows how to record, and then playback a file.

This example is really basic.

 */

typedef _Fn = void Function();

const theSource = AudioSource.microphone;

// Example app.
class PlayFromMic extends StatefulWidget {
  const PlayFromMic({super.key});

  @override
  State<PlayFromMic> createState() => _PlayFromMic();
}

class _PlayFromMic extends State<PlayFromMic> {
  /// Our player
  final FlutterSoundPlayer _mPlayer = FlutterSoundPlayer();

  /// Our recorder
  final FlutterSoundRecorder _mRecorder = FlutterSoundRecorder();

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

    _mPlayer.openPlayer().then((value) {
      setState(() {
        _mPlayerIsInited = true;
      });
    });

    openTheRecorder().then((value) {
      setState(() {
        _mRecorderIsInited = true;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    _mPlayer.closePlayer();

    _mRecorder.closeRecorder();
    super.dispose();
  }

  // ------------------------------ This is the recorder stuff -----------------------------

  static const Codec _codec = Codec.pcmFloat32;
  static const int _sampleRate = 48000;

  bool _mRecorderIsInited = false;
  double _dbLevel = 0.0;
  //StreamSubscription? _recorderSubscription;
  bool bNoiseSuppression = false;
  bool bEchoCancellation = false;

  /// Request permission to record something and open the recorder
  Future<void> openTheRecorder() async {
    if (!kIsWeb) {
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw RecordingPermissionException('Microphone permission not granted');
      }
    }
    await _mRecorder.openRecorder();

    /*_recorderSubscription = */ _mRecorder.onProgress!.listen((e) {
      // pos = e.duration.inMilliseconds; // We do not need this information in this example.
      setState(() {
        _dbLevel = e.decibels as double;
      });
    });
    await _mRecorder.setSubscriptionDuration(
        const Duration(milliseconds: 100)); // DO NOT FORGET THIS CALL !!!

    _mRecorderIsInited = true;
  }

  /// Begin to record.
  /// This is our main function.
  /// We ask Flutter Sound to record to a File.
  void record() async {
    assert(_mPlayerIsInited && _mRecorder.isStopped && _mPlayer.isStopped);

    await _mPlayer.startPlayerFromStream(
      codec: _codec,
      sampleRate: _sampleRate,
      interleaved: false,
      bufferSize: 1024,
      numChannels: 2,
    );

    await _mRecorder.startRecorder(
      codec: _codec,
      audioSource: theSource,
      toStreamFloat32: _mPlayer.float32Sink,
      sampleRate: _sampleRate,
      numChannels: 2,
      enableNoiseSuppression: bNoiseSuppression,
      enableEchoCancellation: bEchoCancellation,
    );
    setState(() {});
  }

  /// Stop the recorder
  void stopRecorder() async {
    await _mPlayer.stopPlayer();
    await _mRecorder.stopRecorder().then((value) {
      setState(() {
        //var url = value;
      });
    });
  }

// ----------------------------- This is the player stuff ---------------------------------

  bool _mPlayerIsInited = false;

  /// Begin to play the recorded sound
  void play() {}

  /// Stop the player
  void stopPlayer() {
    _mPlayer.stopPlayer().then((value) {
      setState(() {});
    });
  }

// ----------------------------- UI --------------------------------------------

  // The user changed its selection. Reset the 3 buffers
  Future<void> reinit() async {
    await _mPlayer.stopPlayer();
    await _mRecorder.stopRecorder();
    setState(() {});
  }

  _Fn? getRecorderFn() {
    if (!_mRecorderIsInited || !_mPlayerIsInited) {
      return null;
    }
    return _mRecorder.isStopped ? record : stopRecorder;
  }

  @override
  Widget build(BuildContext context) {
    Widget makeBody() {
      return Column(
        children: [
          Container(
            margin: const EdgeInsets.all(3),
            padding: const EdgeInsets.all(3),
            height: 200,
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
              CheckboxListTile(
                tileColor: const Color(0xFFFAF0E6),
                title: const Text("Noise Suppression"),
                value: bNoiseSuppression,
                onChanged: (newValue) {
                  reinit();
                  setState(() {
                    bNoiseSuppression = newValue!;
                  });
                },
              ),
              CheckboxListTile(
                tileColor: const Color(0xFFFAF0E6),
                title: const Text("Echo Cancellation"),
                value: bEchoCancellation,
                onChanged: (newValue) {
                  reinit();
                  setState(() {
                    bEchoCancellation = newValue!;
                  });
                },
              ),
            ]),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        title: const Text('Play from Mic'),
      ),
      body: makeBody(),
    );
  }
}
