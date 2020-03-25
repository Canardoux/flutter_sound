/*
 * This is a flutter_sound module.
 * flutter_sound is distributed with a MIT License
 *
 * Copyright (c) 2018 dooboolab
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 */

class AndroidEncoder {
  final _value;
  const AndroidEncoder._internal(this._value);
  toString() => 'AndroidEncoder.$_value';
  int get value => _value;

  static const DEFAULT = const AndroidEncoder._internal(0);

  /// AMR (Narrowband) audio codec
  static const AMR_NB = const AndroidEncoder._internal(1);

  /// AMR (Wideband) audio codec
  static const AMR_WB = const AndroidEncoder._internal(2);

  /// AAC Low Complexity (AAC-LC) audio codec
  static const AAC = const AndroidEncoder._internal(3);

  /// High Efficiency AAC (HE-AAC) audio codec
  static const HE_AAC = const AndroidEncoder._internal(4);

  /// Enhanced Low Delay AAC (AAC-ELD) audio codec
  static const AAC_ELD = const AndroidEncoder._internal(5);

  /// Enhanced Low Delay AAC (AAC-ELD) audio codec
  static const VORBIS = const AndroidEncoder._internal(6);
  static const OPUS = const AndroidEncoder._internal(7);
}

class AndroidAudioSource {
  final _value;
  const AndroidAudioSource._internal(this._value);
  toString() => 'AndroidAudioSource.$_value';
  int get value => _value;

  static const DEFAULT = const AndroidAudioSource._internal(0);
  static const MIC = const AndroidAudioSource._internal(1);
  static const VOICE_UPLINK = const AndroidAudioSource._internal(2);
  static const VOICE_DOWNLINK = const AndroidAudioSource._internal(3);
  static const CAMCORDER = const AndroidAudioSource._internal(4);
  static const VOICE_RECOGNITION = const AndroidAudioSource._internal(5);
  static const VOICE_COMMUNICATION = const AndroidAudioSource._internal(6);
  static const REMOTE_SUBMIX = const AndroidAudioSource._internal(7);
  static const UNPROCESSED = const AndroidAudioSource._internal(8);
  static const RADIO_TUNER = const AndroidAudioSource._internal(9);
  static const HOTWORD = const AndroidAudioSource._internal(10);
}

class AndroidOutputFormat {
  final _value;
  const AndroidOutputFormat._internal(this._value);
  toString() => 'AndroidOutputFormat.$_value';
  int get value => _value;

  static const DEFAULT = const AndroidOutputFormat._internal(0);
  static const THREE_GPP = const AndroidOutputFormat._internal(1);
  static const MPEG_4 = const AndroidOutputFormat._internal(2);
  static const AMR_NB = const AndroidOutputFormat._internal(3);
  static const AMR_WB = const AndroidOutputFormat._internal(4);
  static const AAC_ADTS = const AndroidOutputFormat._internal(6);
  static const OUTPUT_FORMAT_RTP_AVP = const AndroidOutputFormat._internal(7);
  static const MPEG_2_TS = const AndroidOutputFormat._internal(8);
  static const WEBM = const AndroidOutputFormat._internal(9);
  static const OGG = const AndroidOutputFormat._internal(11);
}
