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
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audio_session/audio_session.dart';

/*

This is a very simple example for Flutter Sound beginners, that shows how to play a remote file.
It create a [Player object] and use the verb [startPlayer()].

This example is really basic.

 */

///
typedef Fn = void Function();

/// Example app.
class SimplePlayback extends StatefulWidget {
  const SimplePlayback({super.key});

  @override
  State<SimplePlayback> createState() => _SimplePlaybackState();
}

class _SimplePlaybackState extends State<SimplePlayback> {
  bool _mPlayerIsInited = false;
  static const isRunningWithWasm = bool.fromEnvironment('dart.tool.dart2wasm');

  Future<void> init() async {
    _mPlayer!.openPlayer().then((value) {
      setState(() {
        _mPlayerIsInited = true;
      });
    });
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
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    stopPlayer();
    // Be careful : you must `close` the recorder when you have finished with it.
    _mPlayer!.closePlayer();
    _mPlayer = null;

    super.dispose();
  }

  // -----------------------  Here is the code to playback a remote file -----------------------

  /// The remote sound
  static const _exampleAudioFilePathMP3 =
      'https://fs-doc.vercel.app/extract/05.mp3';

  /// Our player
  FlutterSoundPlayer? _mPlayer = FlutterSoundPlayer();

  /// Begin playing.
  /// This is our main function.
  /// We ask Flutter Sound to Play a remote URL
  void play() async {
    await _mPlayer!.startPlayer(
        fromURI: _exampleAudioFilePathMP3,
        codec: Codec.mp3,
        whenFinished: () {
          setState(() {});
        });
    setState(() {});
  }

  /// Stop playing
  Future<void> stopPlayer() async {
    if (_mPlayer != null) {
      await _mPlayer!.stopPlayer();
    }
  }

  // --------------------- UI -------------------

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

  @override
  Widget build(BuildContext context) {
    Widget makeBody() {
      return Column(
        children: [
          Container(
              margin: const EdgeInsets.all(3),
              padding: const EdgeInsets.all(3),
              height: 100,
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
                  Row(children: [
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
                  const Text(
                    isRunningWithWasm
                        ? 'Running WASM!'
                        : 'Not running under WASM :-(',
                    style: TextStyle(
                        color: isRunningWithWasm ? Colors.green : Colors.red),
                  ),
                ],
              )),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        title: const Text('Simple Playback'),
      ),
      body: makeBody(),
    );
  }
}
