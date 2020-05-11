import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';

import 'demo_active_codec.dart';
import 'demo_common.dart';
import 'demo_media_path.dart';
import '../util/log.dart';

class RecordingPlayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SoundPlayerUI.fromLoader(
      (context) => createTrack(context),
      showTitle: true,
    );
  }

  Future<Track> createTrack(BuildContext context) async {
    Track track;

    String title;
    try {
      if (_recordingExist(context)) {
        /// build player from file
        if (MediaPath().isFile) {
          // Do we want to play from buffer or from file ?
          track = await _createPathTrack();
          title = 'Recording from file playback';
        }

        /// build player from buffer.
        else if (MediaPath().isBuffer) {
          // Do we want to play from buffer or from file ?
          track = await _createBufferTrack();
          title = 'Recording from buffer playback';
        }

        if (track != null) {
          track.title = title;
          track.author = "By flutter_sound";

          if (Platform.isIOS) {
            track.albumArtAsset = 'AppIcon';
          } else if (Platform.isAndroid) {
            track.albumArtAsset = 'AppIcon.png';
          }
        }
      } else {
        var error = SnackBar(
            backgroundColor: Colors.red,
            content: Text(
                'You must make a recording first with the selected codec first.'));
        Scaffold.of(context).showSnackBar(error);
      }
    } on Object catch (err) {
      Log.d('error: $err');
      rethrow;
    }

    return track;
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
    var audioFilePath = MediaPath().pathForCodec(ActiveCodec().codec);
    track = Track.fromPath(audioFilePath, codec: ActiveCodec().codec);
    return track;
  }

  bool _recordingExist(BuildContext context) {
    // Do we want to play from buffer or from file ?
    var path = MediaPath().pathForCodec(ActiveCodec().codec);
    return (path != null && fileExists(path));
  }
}
