/*
 * Copyright 2018, 2019, 2020 Dooboolab.
 * Copyright 2021, 2022, 2023, 2024 Canardoux.
 *
 * This file is part of Flutter-Sound.
 *
 * Flutter-Sound is free software: you can redistribute it and/or modify
 * it under the terms of the Mozilla Public License version 2 (MPL-2.0),
 * as published by the Mozilla organization.
 *
 * Flutter-Sound is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * MPL General Public License for more details.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */
/// ----------
///
/// FlutterSoundHelper module is for handling audio files and buffers.
///
/// Most of those utilities use FFmpeg, so are not available in the LITE flavor of Flutter Sound.
///
/// --------------------
///
/// {@category Utilities}
library helper;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:logger/logger.dart' show Level, Logger;
import 'package:flutter_sound_platform_interface/flutter_sound_platform_interface.dart'
    as FSCodec show Codec;

import 'wave_header.dart';

/// The FlutterSoundHelper singleton for accessing the helpers functions
FlutterSoundHelper flutterSoundHelper =
    FlutterSoundHelper._internal(); // Singleton

/// FlutterSoundHelper class is for handleing audio files and buffers.
/// Most of those utilities use FFmpeg, so are not available in the LITE flavor of Flutter Sound.
class FlutterSoundHelper {
  /// The FlutterSoundHelper Logger
  Logger logger = Logger(level: Level.debug);

// -------------------------------------------------------------------------------------------------------------

  /// The factory which returns the Singleton
  factory FlutterSoundHelper() {
    return flutterSoundHelper;
  }

  /// Private constructor of the Singleton
  /* ctor */ FlutterSoundHelper._internal();

//-------------------------------------------------------------------------------------------------------------

  void setLogLevel(Level theNewLogLevel) {
    logger = Logger(level: theNewLogLevel);
  }

  /// Convert a WAVE file to a Raw PCM file.
  ///
  /// Remove the WAVE header in front of the Wave file
  ///
  /// This verb is useful to convert a Wave file to a Raw PCM file.
  ///
  /// Note that this verb is not asynchronous and does not return a Future.
  Future<void> waveToPCM({
    required String inputFile,
    required String outputFile,
  }) async {
    var filIn = File(inputFile);
    var filOut = File(outputFile);
    var sink = filOut.openWrite();
    await filIn.open();
    var buffer = filIn.readAsBytesSync();
    sink.add(buffer.sublist(WaveHeader.headerLength));
    await sink.close();
  }

  /// Convert a WAVE buffer to a Raw PCM buffer.
  ///
  /// Remove WAVE header in front of the Wave buffer.
  ///
  /// Note that this verb is not asynchronous and does not return a Future.
  Uint8List waveToPCMBuffer({
    required Uint8List inputBuffer,
  }) {
    return inputBuffer.sublist(WaveHeader.headerLength);
  }

  /// Converts a raw PCM file to a WAVE file.
  ///
  /// Add a WAVE header in front of the PCM data
  /// This verb is usefull to convert a Raw PCM file to a Wave file.
  /// It adds a `Wave` envelop to the PCM file, so that the file can be played back with `startPlayer()`.
  ///
  /// Note: the parameters `numChannels` and `sampleRate` **are mandatory, and must match the actual PCM data**.
  ///
  /// [See here](doc/codec.md#note-on-raw-pcm-and-wave-files) a discussion about `Raw PCM` and `WAVE` file format.
  Future<void> pcmToWave({
    required String inputFile,
    required String outputFile,
    int numChannels = 1,
    int sampleRate = 16000,
    FSCodec.Codec codec = FSCodec.Codec.pcm16,
  }) async {
    if (codec != FSCodec.Codec.pcm16 && codec != FSCodec.Codec.pcmFloat32) {
      throw (Exception('Bad codec'));
    }
    var filIn = File(inputFile);
    var filOut = File(outputFile);
    var size = filIn.lengthSync();
    logger.i(
        'pcmToWave() : input = $inputFile,  output = $outputFile,  size = $size');
    var sink = filOut.openWrite();

    var header = WaveHeader(
      codec == FSCodec.Codec.pcm16
          ? WaveHeader.formatInt
          : WaveHeader.formatFloat,
      numChannels = numChannels, //
      sampleRate = sampleRate,
      codec == FSCodec.Codec.pcm16 ? 16 : 32, // 16 bits per byte
      size, // total number of bytes
    );
    header.write(sink);
    await filIn.open();
    var buffer = filIn.readAsBytesSync();
    sink.add(buffer.toList());
    await sink.close();
  }

  /// Convert a raw PCM buffer to a WAVE buffer.
  ///
  /// Adds a WAVE header in front of the PCM data
  /// It adds a `Wave` envelop in front of the PCM buffer, so that the file can be played back with `startPlayerFromBuffer()`.
  ///
  /// Note: the parameters `numChannels` and `sampleRate` **are mandatory, and must match the actual PCM data**. [See here](doc/codec.md#note-on-raw-pcm-and-wave-files) a discussion about `Raw PCM` and `WAVE` file format.
  Future<Uint8List> pcmToWaveBuffer({
    required Uint8List inputBuffer,
    int numChannels = 1,
    int sampleRate = 16000,
    FSCodec.Codec codec = FSCodec.Codec.pcm16,
    //int bitsPerSample,
  }) async {
    if (codec != FSCodec.Codec.pcm16 && codec != FSCodec.Codec.pcmFloat32) {
      throw (Exception('Bad codec'));
    }
    var size = inputBuffer.length;
    var header = WaveHeader(
      codec == FSCodec.Codec.pcm16
          ? WaveHeader.formatInt
          : WaveHeader.formatFloat,
      numChannels,
      sampleRate,
      codec == FSCodec.Codec.pcm16
          ? 16
          : 32, // 16 bits per sample for int16. 32 bits per sample for float32
      size, // total number of bytes
    );

    var buffer = <int>[];
    StreamController controller = StreamController<List<int>>();
    var sink = controller.sink as StreamSink<List<int>>;
    var stream = controller.stream as Stream<List<int>>;
    stream.listen((e) {
      var x = e.toList();
      buffer.addAll(x);
    });
    header.write(sink);
    sink.add(inputBuffer);
    await sink.close();
    await controller.close();
    return Uint8List.fromList(buffer);
  }

  uint8ListToFloat32List(List<Uint8List> buf, {Endian endian = Endian.little}) {
    List<Float32List> r = [];
    for (Uint8List channelData in buf) {
      int ln = ((channelData.length) / 4).floor();
      final bd = ByteData.sublistView(channelData);
      Float32List f32List = Float32List(ln);
      //int ix = 0;
      for (int offset = 0, ix = 0; offset < ln; offset += 4, ++ix) {
        f32List[ix] = bd.getFloat32(offset, endian);
      }
      r.add(f32List);
    }
    return r;
  }
}
