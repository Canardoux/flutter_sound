/*
 * Copyright 2024 Canardoux.
 *
 * This file is part of the τ project.
 *
 * τ is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3 (GPL3), as published by
 * the Free Software Foundation.
 *
 * τ is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with τ.  If not, see <https://www.gnu.org/licenses/>.
 */

//import 'package:taudio/src/taudio_nat.dart';

import 'dart:typed_data' show Uint8List;

import '../../taudio.dart';

import '../src/dummy.dart'
    if (dart.library.html) '../src/taudio_web.dart'
    if (dart.library.io) '../src/taudio_nat.dart';

class TaudioBuffer {
  late AudioBuffer audioBuffer;
  late AudioContext context;

  int get numberOfChannels => audioBuffer.numberOfChannels;

  int get sampleRate => audioBuffer.sampleRate.floor();

  double get duration => audioBuffer.duration;

  int get length => audioBuffer.length;

  Float32List getChannelData({required int channelNumber}) =>
      audioBuffer.getChannelData(channelNumber).toDart;

  //void copyToChannel({ Float32List source, int channel }) { audioBuffer.copyToChannel(source, channel); }
  //void copyTFromhannel({ Float32List destination, int channel }) { audioBuffer.copyfromChannel(destination, channel); }

  /* ctor */
  TaudioBuffer.fromPCM32({
    required this.context,
    required int sampleRate,
    required List<Float32List> data,
  }) {
    var numberOfChannels = data.length;
    if (numberOfChannels == 0) {
      throw Exception('Number of channels is 0');
    }
    Float32List firstChannel = data[0];
    int length = firstChannel.length;
    for (int i = 1; i < numberOfChannels; ++i) {
      if (data[i].length != length) {
        throw Exception('Data length for each channel are not same');
      }
    }
    audioBuffer = context.createBuffer(numberOfChannels, length, sampleRate);
    for (int i = 0; i < numberOfChannels; ++i) {
      audioBuffer.copyToChannel(data[i].toJS, i);
    }
  }

  /* ctor */
  TaudioBuffer({required this.context, required this.audioBuffer});

  static Future<TaudioBuffer> decode({
    required AudioContext context,
    required Uint8List buffer,
    required TaudioCodec codec,
  }) async {
    // Codec is unused !!!!
    var b = context.decodeAudioData(buffer.buffer.toJS);
    var x = await b.toDart;
    return TaudioBuffer(context: context, audioBuffer: x);
    //taudioBuffer = TaudioBuffer(context: context, audioBuffer: x);
  }

  static Future<AudioBufferSourceNode> setBuf({
    required AudioContext context,
    required Uint8List buffer,
    required TaudioCodec codec,
  }) async {
    TaudioBuffer taudioBuffer = await TaudioBuffer.decode(
      context: context,
      buffer: buffer,
      codec: codec,
    );
    AudioBufferSourceNode n = context.createBufferSource();
    n.buffer = taudioBuffer.audioBuffer;
    return n;
  }
}

abstract class taudioBufferSource extends TaudioSource {
  TaudioBuffer? taudioBuffer;

  /* ctor */
  taudioBufferSource({required super.context});

  //Future<void> decode({ required Uint8List buffer, required TaudioCodec codec }) => TaudioBuffer.decode(context: context, buffer: buffer, codec: codec);

  Future<TaudioBuffer> setBuf({
    required Uint8List buffer,
    required TaudioCodec codec,
  }) async {
    taudioBuffer = await TaudioBuffer.decode(
      context: context,
      buffer: buffer,
      codec: codec,
    );
    AudioBufferSourceNode n = context.createBufferSource();
    n.buffer = taudioBuffer!.audioBuffer;
    node = n;
    return taudioBuffer!;
  }
}
