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

class AndroidEncoder {
  final _value;
  const AndroidEncoder._internal(this._value);
  toString() => 'AndroidEncoder.$_value';
  int get value => _value;

  static const DEFAULT =  AndroidEncoder._internal(0);

  /// AMR (Narrowband) audio codec
  static const AMR_NB =  AndroidEncoder._internal(1);

  /// AMR (Wideband) audio codec
  static const AMR_WB =  AndroidEncoder._internal(2);

  /// AAC Low Complexity (AAC-LC) audio codec
  static const AAC =  AndroidEncoder._internal(3);

  /// High Efficiency AAC (HE-AAC) audio codec
  static const HE_AAC =  AndroidEncoder._internal(4);

  /// Enhanced Low Delay AAC (AAC-ELD) audio codec
  static const AAC_ELD =  AndroidEncoder._internal(5);

  /// Enhanced Low Delay AAC (AAC-ELD) audio codec
  static const VORBIS =  AndroidEncoder._internal(6);
  static const OPUS =  AndroidEncoder._internal(7);
}

class AndroidAudioSource {
  final _value;
  const AndroidAudioSource._internal(this._value);
  toString() => 'AndroidAudioSource.$_value';
  int get value => _value;

  static const DEFAULT =  AndroidAudioSource._internal(0);
  static const MIC =  AndroidAudioSource._internal(1);
  static const VOICE_UPLINK =  AndroidAudioSource._internal(2);
  static const VOICE_DOWNLINK =  AndroidAudioSource._internal(3);
  static const CAMCORDER =  AndroidAudioSource._internal(4);
  static const VOICE_RECOGNITION =  AndroidAudioSource._internal(5);
  static const VOICE_COMMUNICATION =  AndroidAudioSource._internal(6);
  static const REMOTE_SUBMIX =  AndroidAudioSource._internal(7);
  static const UNPROCESSED =  AndroidAudioSource._internal(8);
  static const RADIO_TUNER =  AndroidAudioSource._internal(9);
  static const HOTWORD =  AndroidAudioSource._internal(10);
}

class AndroidOutputFormat {
  final _value;
  const AndroidOutputFormat._internal(this._value);
  toString() => 'AndroidOutputFormat.$_value';
  int get value => _value;

  static const DEFAULT =  AndroidOutputFormat._internal(0);
  static const THREE_GPP =  AndroidOutputFormat._internal(1);
  static const MPEG_4 =  AndroidOutputFormat._internal(2);
  static const AMR_NB =  AndroidOutputFormat._internal(3);
  static const AMR_WB =  AndroidOutputFormat._internal(4);
  static const AAC_ADTS =  AndroidOutputFormat._internal(6);
  static const OUTPUT_FORMAT_RTP_AVP =  AndroidOutputFormat._internal(7);
  static const MPEG_2_TS =  AndroidOutputFormat._internal(8);
  static const WEBM =  AndroidOutputFormat._internal(9);
  static const OGG =  AndroidOutputFormat._internal(11);
}
