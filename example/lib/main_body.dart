import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'active_codec.dart';
import 'common.dart';
import 'drop_downs.dart';
import 'main.dart';
import 'media_path.dart';
import 'player_state.dart';
import 'recorder_controls.dart';
import 'recorder_state.dart';
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

  bool initialised = false;

  Future<bool> init() async {
    if (!initialised) {
      await PlayerState().init();
      await RecorderState().init();
      ActiveCodec().recorderModule = RecorderState().recorderModule;
      await ActiveCodec().setCodec(_useOSUI, Codec.aac);
      await initializeDateFormatting();

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
                onCodecChanged: (codec) =>
                    ActiveCodec().setCodec(_useOSUI, codec));
            final trackSwitch = TrackSwitch(
              isAudioPlayer: _useOSUI,
              switchPlayer: (allow) => switchPlayer(useOSUI: allow),
            );

            Widget recorderControls = RecorderControls();

            return ListView(
              children: <Widget>[
                recorderControls,
                buildPlayBar(),
                dropdowns,
                trackSwitch,
              ],
            );
          }
        });
  }

  void switchPlayer({bool useOSUI}) async {
    try {
      PlayerState().release();
      _useOSUI = useOSUI;
      await _switchModes(useOSUI);
      setState(() {});
    } on Object catch (err) {
      print(err);
      rethrow;
    }
  }

  /// Callback for the PlayBar so we can dynamically load a SoundPlayer after
  /// validating that all othe settings are correct.
  Future<Track> onLoad() async {
    Track track;
    var canPlay = true;

    // validate codec for example file
    if (MediaPath().isExampleFile) {
      if (ActiveCodec().codec != Codec.mp3) {
        canPlay = false;
        var error = SnackBar(
            backgroundColor: Colors.red,
            content: Text('You must set the Codec to MP3 to '
                'play the "Remote Example File"'));
        Scaffold.of(context).showSnackBar(error);
      }
    }

    /// validate codec if using asset.
    else if (!MediaPath().isAsset && !MediaPath().exists(ActiveCodec().codec)) {
      canPlay = false;
      var error = SnackBar(
          content: Text("Record a message first or select "
              "'Remote Example File' or 'Asset' from Media"));
      Scaffold.of(context).showSnackBar(error);
    }

    if (canPlay) {
      track = await createTrack();
      setState(() {});
    }
    return track;
  }

  Future<Track> createTrack() async {
    Track track;
    try {
      /// build player from asset
      if (MediaPath().isAsset) {
        track = await createAssetTrack();
      }

      /// build player from file
      else if (MediaPath().isFile) {
        // Do we want to play from buffer or from file ?
        track = await _createPathTrack();
      }

      /// build player from buffer.
      else if (MediaPath().isBuffer) {
        // Do we want to play from buffer or from file ?
        track = await _createBufferTrack();
      }

      /// build player from example URL
      else if (MediaPath().isExampleFile) {
        // We have to play an example audio file loaded via a URL
        track = await _createRemoteTrack();
      }
      if (track != null) {
        track.title = "Flutter at first Sight.";
        track.author = "By flutter_sound";

        if (MediaPath().isExampleFile) {
          track.albumArtUrl = albumArtPath;
        } else {
          if (Platform.isIOS) {
            track.albumArtAsset = 'AppIcon';
          } else if (Platform.isAndroid) {
            track.albumArtAsset = 'AppIcon.png';
          }
        }
        await _startConcurrentPlayer(track);
      }
    } on Object catch (err) {
      print('error: $err');
      rethrow;
    }

    return track;
  }

  Future _startConcurrentPlayer(Track track) async {
    if (renetranceConcurrency && !MediaPath().isExampleFile) {
      var dataBuffer =
          (await rootBundle.load(assetSample[ActiveCodec().codec.index]))
              .buffer
              .asUint8List();

      PlayerState().playerModule_2 =
          SoundPlayer.fromBuffer(dataBuffer, codec: ActiveCodec().codec);

      PlayerState().playerModule_2.onFinished =
          () => print('Secondary Play finished');

      await PlayerState().playerModule_2.play();
    }
  }

  Future<Track> _createRemoteTrack() async {
    // We have to play an example audio file loaded via a URL
    return Track.fromPath(exampleAudioFilePath, codec: ActiveCodec().codec);
  }

  Future<Track> _createBufferTrack() async {
    Track track;
    // Do we want to play from buffer or from file ?
    if (fileExists(MediaPath().pathForCodec(ActiveCodec().codec))) {
      var dataBuffer =
          await makeBuffer(MediaPath().pathForCodec(ActiveCodec().codec));
      if (dataBuffer == null) {
        throw Exception('Unable to create the buffer');
      }
      track = Track.fromBuffer(dataBuffer, codec: ActiveCodec().codec);
    }
    return track;
  }

  Future<Track> _createPathTrack() async {
    Track track;
    // Do we want to play from buffer or from file ?
    if (fileExists(MediaPath().pathForCodec(ActiveCodec().codec))) {
      var audioFilePath = MediaPath().pathForCodec(ActiveCodec().codec);
      track = Track.fromPath(audioFilePath, codec: ActiveCodec().codec);
    }
    return track;
  }

  Future<Track> createAssetTrack() async {
    Track track;
    var dataBuffer =
        (await rootBundle.load(assetSample[ActiveCodec().codec.index]))
            .buffer
            .asUint8List();
    track = Track.fromBuffer(
      dataBuffer,
      codec: ActiveCodec().codec,
    );
    return track;
  }

  /// Allows us to switch the player module
  Future<void> _switchModes(bool useTracks) async {
    RecorderState().reset();
  }

  Widget buildPlayBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Playbar.fromLoader(
        onLoad,
        showTitle: true,
      ),
    );
  }
}
