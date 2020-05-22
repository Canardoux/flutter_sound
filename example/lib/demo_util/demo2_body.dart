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


import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../util/log.dart';
import 'demo_active_codec.dart';
import 'demo_asset_player.dart';
import 'demo_drop_downs.dart';
import 'recorder_controls.dart';
import 'recorder_state.dart';
import 'recording_player.dart';
import 'remote_player.dart';
import 'track_switched.dart';


///
class MainBody extends StatefulWidget {
  ///
  const MainBody({
    Key key,
  }) : super(key: key);

  @override
  _MainBodyState createState() => _MainBodyState();
}

class _MainBodyState extends State<MainBody> {
  bool _useOSUI = false;

  bool initialized = false;

  Future<bool> init() async {
    if (!initialized) {
      await initializeDateFormatting();
      await RecorderState().init();
      ActiveCodec().recorderModule = RecorderState().recorderModule;
      await ActiveCodec().setCodec(withUI: _useOSUI, codec: Codec.aacADTS);

      initialized = true;
    }
    return initialized;
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
                onCodecChanged: (codec) =>
                    ActiveCodec().setCodec(withUI: _useOSUI, codec: codec));
            final trackSwitch = TrackSwitch(
              isAudioPlayer: _useOSUI,
              switchPlayer: (allow) => switchPlayer(useOSUI: allow),
            );

            Widget recorderControls = RecorderControls();

            return ListView(
              children: <Widget>[
                recorderControls,
                dropdowns,
                buildPlayBars(),
                trackSwitch,
              ],
            );
          }
        });
  }

  void switchPlayer({bool useOSUI}) async {
    try {
      _useOSUI = useOSUI;
      await _switchModes(useOSUI);
      setState(() {});
    } on Object catch (err) {
      Log.d(err.toString());
      rethrow;
    }
  }

  /// Allows us to switch the player module
  Future<void> _switchModes(bool useTracks) async {
    RecorderState().reset();
  }

  Widget buildPlayBars() {
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Left("Recording Playback"),
            RecordingPlayer(),
            Left("Asset Playback"),
            AssetPlayer(),
            Left("Remote Track Playback"),
            RemotePlayer(),
          ],
        ));
  }
}

/// Left aligss text
class Left extends StatelessWidget {
  ///
  final String label;

  ///
  Left(this.label);
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 4, left: 8),
      child: Container(
          alignment: Alignment.centerLeft,
          child: Text(label, style: TextStyle(fontWeight: FontWeight.bold))),
    );
  }
}
