/*
 * Copyright 2018, 2019, 2020 Dooboolab.
 *
 * This file is part of Flutter-Sound.
 *
 * Flutter-Sound is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3, as published by
 * the Free Software Foundation.
 *
 * Flutter-Sound is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Flutter-Sound.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';

import 'demo_active_codec.dart';
import 'demo_common.dart';
import 'demo_player_state.dart';

class AssetPlayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SoundPlayerUI.fromLoader(
      (_) => createAssetTrack(),
      showTitle: true,
      audioFocus: PlayerState().hushOthers
          ? AudioFocus.focusAndHushOthers
          : AudioFocus.focusAndKeepOthers,
    );
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

    track.title = "Asset playback.";
    track.author = "By flutter_sound";

    if (Platform.isIOS) {
      track.albumArtAsset = 'AppIcon';
    } else if (Platform.isAndroid) {
      track.albumArtAsset = 'AppIcon.png';
    }
    return track;
  }
}
