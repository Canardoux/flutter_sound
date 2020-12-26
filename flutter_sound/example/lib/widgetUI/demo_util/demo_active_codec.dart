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

import 'package:flutter_sound/flutter_sound.dart';

/// Factory used to track what codec is currently selected.
class ActiveCodec {
  static final ActiveCodec _self = ActiveCodec._internal();

  Codec _codec = Codec.aacADTS;
  bool _encoderSupported = false;
  bool _decoderSupported = false;

  ///
  FlutterSoundRecorder recorderModule;

  /// Factory to access the active codec.
  factory ActiveCodec() {
    return _self;
  }
  ActiveCodec._internal();

  /// Set the active code for the the recording and player modules.
  void setCodec({bool withUI, Codec codec}) async {
    var player = FlutterSoundPlayer();
    if (withUI) {
      await player.openAudioSession(
          focus: AudioFocus.requestFocusAndDuckOthers, withUI: true);
      _encoderSupported = await recorderModule.isEncoderSupported(codec);
      _decoderSupported = await player.isDecoderSupported(codec);
    } else {
      await player.openAudioSession(
          focus: AudioFocus.requestFocusAndDuckOthers);
      _encoderSupported = await recorderModule.isEncoderSupported(codec);
      _decoderSupported = await player.isDecoderSupported(codec);
    }
    _codec = codec;
  }

  /// [true] if the active coded is supported by the recorder
  bool get encoderSupported => _encoderSupported;

  /// [true] if the active coded is supported by the player
  bool get decoderSupported => _decoderSupported;

  /// returns the active codec.
  Codec get codec => _codec;
}
