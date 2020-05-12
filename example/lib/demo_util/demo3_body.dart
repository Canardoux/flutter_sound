import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'demo_active_codec.dart';
import 'demo_asset_player.dart';
import 'demo_drop_downs.dart';
import 'demo_player_state.dart';
import 'recorder_state.dart';
import 'remote_player.dart';

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
  bool initialized = false;

  String recordingFile;
  Track track;

  @override
  void initState() {
    super.initState();
    recordingFile = Track.tempFile(Codec.aacADTS);

    track = Track.fromFile(recordingFile);
    track.artist = 'Brett';
  }

  Future<bool> init() async {
    if (!initialized) {
      await initializeDateFormatting();
      await RecorderState().init();
      ActiveCodec().recorderModule = RecorderState().recorderModule;
      await ActiveCodec().setCodec(withUI: false, codec: Codec.aacADTS);

      initialized = true;
    }
    return initialized;
  }

  void dispose() {
    if (recordingFile != null) {
      File(recordingFile).delete();
    }
    super.dispose();
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
                    ActiveCodec().setCodec(withUI: false, codec: codec));

            return ListView(
              children: <Widget>[
                _buildRecorder(track),
                dropdowns,
                buildPlayBars(),
                buildHushOthers(),
              ],
            );
          }
        });
  }

  Widget buildPlayBars() {
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Left("Asset Playback"),
            AssetPlayer(),
            Left("Remote Track Playback"),
            RemotePlayer(),
          ],
        ));
  }

  Widget _buildRecorder(Track track) {
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: RecorderPlaybackController(
            child: Column(
          children: [
            SoundRecorderUI(track),
            Left("Recording Playback"),
            SoundPlayerUI.fromTrack(
              track,
              showTitle: true,
              audioFocus: PlayerState().hushOthers
                  ? AudioFocus.focusAndHushOthers
                  : AudioFocus.focusAndKeepOthers,
            ),
          ],
        )));
  }

  Widget buildHushOthers() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: Text('Hush Others:'),
          ),
          Switch(
            value: PlayerState().hushOthers,
            onChanged: (hushOthers) =>
                hushOthersSwitchChanged(hushOthers: hushOthers),
          ),
        ],
      ),
    );
  }

  void hushOthersSwitchChanged({bool hushOthers}) {
    PlayerState().setHush(hushOthers: hushOthers);
  }
}

///
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
