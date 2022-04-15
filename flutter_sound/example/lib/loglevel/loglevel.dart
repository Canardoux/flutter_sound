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
import 'package:logger/logger.dart' show Level;

/*
 *
 * This is a very simple example for Flutter Sound beginners,
 * that show how to record, and then playback a file.
 *
 * This example is really basic.
 *
 */

final _exampleAudioFilePathMP3 =
    'https://flutter-sound.canardoux.xyz/web_example/assets/extract/05.mp3';

///
typedef Fn = void Function();

/// Example app.
class LogLevel extends StatefulWidget {
  @override
  _LogLevelState createState() => _LogLevelState();
}

class _LogLevelState extends State<LogLevel> {
  FlutterSoundPlayer? _mPlayer = FlutterSoundPlayer(logLevel: Level.debug);
  bool _mPlayerIsInited = false;
  Level theLogLevel = Level.debug;

  @override
  void initState() {
    super.initState();
    _mPlayer!.openPlayer().then((value) {
      setState(() {
        _mPlayerIsInited = true;
      });
    });
  }

  @override
  void dispose() {
    stopPlayer();
    // Be careful : you must `close` the audio session when you have finished with it.
    _mPlayer!.closePlayer();
    _mPlayer = null;

    super.dispose();
  }

  // -------  Here is the code to playback a remote file -----------------------

  void play() async {
    await _mPlayer!.startPlayer(
        fromURI: _exampleAudioFilePathMP3,
        codec: Codec.mp3,
        whenFinished: () {
          setState(() {});
        });
    setState(() {});
  }

  Future<void> stopPlayer() async {
    if (_mPlayer != null) {
      await _mPlayer!.stopPlayer();
    }
  }

  void setMode(aLevel) {
    _mPlayer?.setLogLevel(aLevel);
    setState(() {
      theLogLevel = aLevel;
    });
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
    List<Widget> makeRadioButton() {
      List<Widget> r;
      r = [];

      r.add(
        Container(
          height: 30,
          child: Row(
            children: [
              Radio(
                value: Level.verbose,
                groupValue: theLogLevel,
                onChanged: setMode,
                activeColor: Colors.blue,
                focusColor: Colors.blue,
                hoverColor: Colors.blue,
              ),
              Text(
                'Verbose',
                style: TextStyle(color: Colors.black),
              ),
            ],
          ),
        ),
      );

      r.add(
        Container(
          height: 30,
          child: Row(
            children: [
              //Icon(DiglotFont.candle),
              Radio(
                value: Level.debug,
                groupValue: theLogLevel,
                onChanged: setMode,
                activeColor: Colors.blue,
                focusColor: Colors.blue,
                hoverColor: Colors.blue,
              ),
              Text(
                'Debug',
                style: TextStyle(color: Colors.black),
              ),
            ],
          ),
        ),
      );

      r.add(
        Container(
          height: 30,
          child: Row(
            children: [
              Radio(
                value: Level.info,
                groupValue: theLogLevel,
                onChanged: setMode,
                activeColor: Colors.blue,
                focusColor: Colors.blue,
                hoverColor: Colors.blue,
              ),
              Text(
                'Info',
                style: TextStyle(color: Colors.black),
              ),
            ],
          ),
        ),
      );

      r.add(
        Container(
          height: 30,
          child: Row(
            children: [
              Radio(
                value: Level.warning,
                groupValue: theLogLevel,
                onChanged: setMode,
                activeColor: Colors.blue,
                focusColor: Colors.blue,
                hoverColor: Colors.blue,
              ),
              Text(
                'Warning',
                style: TextStyle(color: Colors.black),
              ),
            ],
          ),
        ),
      );

      r.add(
        Container(
          height: 30,
          child: Row(
            children: [
              Radio(
                value: Level.error,
                groupValue: theLogLevel,
                onChanged: setMode,
                activeColor: Colors.blue,
                focusColor: Colors.blue,
                hoverColor: Colors.blue,
              ),
              Text(
                'Error',
                style: TextStyle(color: Colors.black),
              ),
            ],
          ),
        ),
      );

      r.add(
        Container(
          height: 30,
          child: Row(
            children: [
              Radio(
                value: Level.wtf,
                groupValue: theLogLevel,
                onChanged: setMode,
                activeColor: Colors.blue,
                focusColor: Colors.blue,
                hoverColor: Colors.blue,
              ),
              Text(
                'Wtf',
                style: TextStyle(color: Colors.black),
              ),
            ],
          ),
        ),
      );

      r.add(
        Container(
          height: 30,
          child: Row(
            children: [
              Radio(
                value: Level.nothing,
                groupValue: theLogLevel,
                onChanged: setMode,
                activeColor: Colors.blue,
                focusColor: Colors.blue,
                hoverColor: Colors.blue,
              ),
              Text(
                'Nothing',
                style: TextStyle(color: Colors.black),
              ),
            ],
          ),
        ),
      );

      return r;
    }

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
                onPressed: getPlaybackFn(),
                //color: Colors.white,
                //disabledColor: Colors.grey,
                child: Text(_mPlayer!.isPlaying ? 'Stop' : 'Play'),
              ),
              SizedBox(
                width: 20,
              ),
              Text(_mPlayer!.isPlaying
                  ? 'Playback in progress'
                  : 'Player is stopped'),
            ]),
          ),
          Text(
            'Log Level',
          ),
          Expanded(
            child: Container(
              width: 120,
              margin: const EdgeInsets.all(3.0),
              padding: const EdgeInsets.all(0.0),
              decoration: BoxDecoration(
                color: Color(0xFFFAF0E6),
                border: Border.all(
                  color: Colors.indigo,
                  width: 3,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: makeRadioButton(),
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        title: const Text('Log Level'),
      ),
      body: makeBody(),
    );
  }
}
