/*
 * This file is part of Flutter-Sound (Flauto).
 *
 *   Flutter-Sound (Flauto) is free software: you can redistribute it and/or modify
 *   it under the terms of the Lesser GNU General Public License
 *   version 3 (LGPL3) as published by the Free Software Foundation.
 *
 *   Flutter-Sound (Flauto) is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the Lesser GNU General Public License
 *   along with Flutter-Sound (Flauto).  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:async';

import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_sound/flauto.dart';
import 'package:flutter_sound/flutter_sound_player.dart';
import 'package:flutter_sound/track_player.dart';

import 'package:flutter/material.dart';
import 'active_codec.dart';

import 'drop_downs.dart';
import 'player_controls.dart';
import 'player_state.dart';
import 'recorder_controls.dart';
import 'recorder_state.dart';
import 'track_switched.dart';

/// Boolean to specify if we want to test the Rentrance/Concurency feature.
/// If true, we start two instances of FlautoPlayer when
/// the user hit the "Play" button.
/// If true, we start two instances of FlautoRecorder and one instance of
/// FlautoPlayer when the user hit the Record button
const renetranceConcurrency = false;

/// path to remote auido file.
const String exampleAudioFilePath =
    "https://file-examples.com/wp-content/uploads/2017/11/file_example_MP3_700KB.mp3";

/// path to remote auido file artwork.
final String albumArtPath =
    "https://file-examples.com/wp-content/uploads/2017/10/file_example_PNG_500kB.png";

void main() {
  runApp(MyApp());
}

/// Example app.
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool initialised = false;

  // Whether the user wants to use the audio player features
  final bool _isTrackPlayer = false;

  /// Allows us to switch the player module
  Future<void> _resetModules(FlutterSoundPlayer module) async {
    PlayerState().reset(module);
    RecorderState().reset();

    await initializeDateFormatting();

    await PlayerState().setDuck(duckOthers: false);
  }

  Future<bool> init() async {
    if (!initialised) {
      await PlayerState().init();
      await RecorderState().init();
      await ActiveCodec().setCodec(t_CODEC.CODEC_AAC);
      await _resetModules(PlayerState().playerModule);

      initialised = true;
    }
    return initialised;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        initialData: false,
        future: init(),
        builder: (context, snapshot) {
          if (snapshot.data == false) {
            return Container(
              width: 0,
              height: 0,
              color: Colors.white,
            );
          } else {
            final dropdowns = Dropdowns(
                context: context,
                onCodecChanged: (codec) => ActiveCodec().setCodec(codec));
            final trackSwitch = TrackSwitch(
              isAudioPlayer: _isTrackPlayer,
              switchPlayer: (allow) => switchPlayer(allowTracks: allow),
            );

            Widget recorderControls = RecorderControls();

            Widget playerControls = PlayerControls();

            return MaterialApp(
              home: Scaffold(
                appBar: AppBar(
                  title: const Text('Flutter Sound'),
                ),
                body: ListView(
                  children: <Widget>[
                    recorderControls,
                    playerControls,
                    dropdowns,
                    trackSwitch,
                  ],
                ),
              ),
            );
          }
        });
  }

  @override
  void dispose() {
    super.dispose();
    PlayerState().cancelPlayerSubscriptions();
    RecorderState().cancelRecorderSubscriptions();
    releaseFlauto();
  }

  Future<void> releaseFlauto() async {
    try {
      await PlayerState().release();
      RecorderState().release();
    } on Object catch (e) {
      print('Released unsuccessful');
      print(e);
      rethrow;
    }
  }

  void switchPlayer({bool allowTracks}) async {
    try {
      PlayerState().release();

      if (allowTracks) {
        await _resetModules(TrackPlayer());
      } else {
        await _resetModules(FlutterSoundPlayer());
      }
      setState(() {});
    } on Object catch (err) {
      print(err);
      rethrow;
    }
  }
}
