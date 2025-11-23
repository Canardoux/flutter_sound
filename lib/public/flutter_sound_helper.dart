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
/// --------------------
///
/// {@category flutter_sound}
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:logger/logger.dart' show Level, Logger;
import 'package:flutter_sound_platform_interface/flutter_sound_platform_interface.dart'
    as fs_codec
    show Codec;

/// The FlutterSoundHelper singleton for accessing the helpers functions
FlutterSoundHelper flutterSoundHelper =
    FlutterSoundHelper._internal(); // Singleton

/// `FlutterSoundHelper()` is a singleton which offers some utilities for handling audio files and buffers.
class FlutterSoundHelper {
  /// The FlutterSoundHelper Logger
  ///
  /// -------------------------------------
  ///
  /// ## example
  ///
  /// ```
  /// FlutterSoundHelper().logger.d('An information`);
  /// ```
  ///
  /// --------------------------------------
  Logger logger = Logger(level: Level.debug);

  // -------------------------------------------------------------------------------------------------------------

  /// The factory which returns the Singleton
  factory FlutterSoundHelper() {
    return flutterSoundHelper;
  }

  /// Private constructor of the Singleton
  /* ctor */
  FlutterSoundHelper._internal();

  //-------------------------------------------------------------------------------------------------------------

  /// Allows you to change the LogLevel.
  void setLogLevel(Level theNewLogLevel) {
    logger = Logger(level: theNewLogLevel);
  }

  /// Convert a WAVE file to a Raw PCM file.
  ///
  /// --------------------------------------------------
  /// Remove the WAVE header in front of the Wave file
  ///
  /// This verb is useful to convert a Wave file to a Raw PCM file.
  ///
  /// Note that this verb is not asynchronous and does not return a Future.
  /// [See here](/tau/guides/guides-pcm-wave.html) a discussion about `Raw PCM` and `WAVE` file format.
  ///
  /// ## Parameters
  ///
  /// - **_inputFile:_** is the path of your input file
  /// - **_outputFile:_** is the path to your output file
  ///
  /// ## Example
  ///
  /// ```
  /// FlutterSoundHelper().waveToPCM(inputFile: 'foo.wav', outputFile: 'bla.pcm');
  /// ```
  ///
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
  /// ---------------------------------------------
  ///
  /// Remove WAVE header in front of the Wave buffer.
  ///
  /// Note that this verb is not asynchronous and does not return a Future.
  /// [See here](/tau/guides/guides-pcm-wave.html) a discussion about `Raw PCM` and `WAVE` file format.
  ///
  /// ## Example
  /// ```
  /// Uint8List myPCMBuffer = waveToPCMBuffer(inputBuffer: myWavBuffer);
  /// ```
  /// ---------------------------------------------------
  Uint8List waveToPCMBuffer({required Uint8List inputBuffer}) {
    return inputBuffer.sublist(WaveHeader.headerLength);
  }

  /// Converts a raw PCM file to a WAVE file.
  ///
  /// -----------------------------------------------
  ///
  /// Add a WAVE header in front of the PCM data
  /// This verb is usefull to convert a Raw PCM file to a Wave file.
  /// It adds a `Wave` envelop to the PCM file, so that the file can be played back with `startPlayer()`.
  ///
  /// Note: the parameters `numChannels` and `sampleRate` **are mandatory, and must match the actual PCM data**.
  ///
  /// [See here](/tau/guides/guides-pcm-wave.html) a discussion about `Raw PCM` and `WAVE` file format.
  ///
  /// ## Parameters
  /// - **_inputFile:_** is a file path to your input file
  /// - **_outputFile:_** is a path to your output file
  /// - **_numChannels:_** is the number of channels of your file
  /// - **_sampleRate_** is the sample rate of your data
  /// - **_codec_** is either [fs_codec.Codec.pcm16] or [fs_codec.Codec.pcmFloat32]
  ///
  /// ## Example
  /// ```
  /// FlutterSoundHelper().pcmToWave (
  ///     inputFile: 'foo.pcm',
  ///     outputFile: 'foo.wav',
  ///     numChannels: 2 // stereo
  ///     samplerate: 48000,
  ///     codec: fs_codec.Codec.pcm16
  ///  );
  ///  ```
  ///  ---------------------------------------------------------
  ///
  Future<void> pcmToWave({
    required String inputFile,
    required String outputFile,
    int numChannels = 1,
    int sampleRate = 16000,
    fs_codec.Codec codec = fs_codec.Codec.pcm16,
  }) async {
    if (codec != fs_codec.Codec.pcm16 && codec != fs_codec.Codec.pcmFloat32) {
      throw (Exception('Bad codec'));
    }
    var filIn = File(inputFile);
    var filOut = File(outputFile);
    var size = filIn.lengthSync();
    logger.i(
      'pcmToWave() : input = $inputFile,  output = $outputFile,  size = $size',
    );
    var sink = filOut.openWrite();

    var header = WaveHeader(
      codec == fs_codec.Codec.pcm16
          ? WaveHeader.formatInt
          : WaveHeader.formatFloat,
      numChannels = numChannels, //
      sampleRate = sampleRate,
      codec == fs_codec.Codec.pcm16 ? 16 : 32, // 16 bits per byte
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
  ///
  /// ## Parameters
  /// - **_inputBuffer:_** is your input buffer
  /// - **_numChannels:_** is the number of channels of your file
  /// - **_sampleRate_** is the sample rate of your data
  /// - **_codec_** is either [fs_codec.Codec.pcm16] or [fs_codec.Codec.pcmFloat32]
  ///
  /// ## Return
  /// The Uint8List containing your wave buffer
  ///
  /// ## Example
  /// ```
  /// FlutterSoundHelper().pcmToWave (
  ///     inputFile: 'foo.pcm',
  ///     outputFile: 'foo.wav',
  ///     numChannels: 2 // stereo
  ///     samplerate: 48000,
  ///     codec: fs_codec.Codec.pcm16
  ///  );
  ///  ```
  ///  ---------------------------------------------------------
  ///
  Future<Uint8List> pcmToWaveBuffer({
    required Uint8List inputBuffer,
    int numChannels = 1,
    int sampleRate = 16000,
    fs_codec.Codec codec = fs_codec.Codec.pcm16,
    //int bitsPerSample,
  }) async {
    if (codec != fs_codec.Codec.pcm16 && codec != fs_codec.Codec.pcmFloat32) {
      throw (Exception('Bad codec'));
    }
    var size = inputBuffer.length;
    var header = WaveHeader(
      codec == fs_codec.Codec.pcm16
          ? WaveHeader.formatInt
          : WaveHeader.formatFloat,
      numChannels,
      sampleRate,
      codec == fs_codec.Codec.pcm16
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

  /// Transform a Uint8List to a Float32List
  ///
  /// ---------------------------------------------
  ///
  /// ## Parameters
  /// - **_buf:_** is the buffer you want to convert
  /// - **_endian:_** is the endianness of your data
  ///
  /// ## Return
  /// - a `Float32List` containing the transformed buffer
  ///
  /// ## Example
  /// ```
  /// List<Float32List> myFloat32List = uint8ListToFloat32List(myUint8List);
  /// ```
  /// ------------------------------
  List<Float32List> uint8ListToFloat32List(
    List<Uint8List> buf, {
    Endian endian = Endian.little,
  }) {
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

/// A Wave header.
///
/// -------------------------------------------------
///
/// This class represents the header of a WAVE format audio file, which usually
/// have a .wav suffix.  The following integer valued fields are contained:
/// <ul>
/// <li> format - usually PCM, ALAW or ULAW.
/// <li> numChannels - 1 for mono, 2 for stereo.
/// <li> sampleRate - usually 8000, 11025, 16000, 22050, or 44100 hz.
/// <li> bitsPerSample - usually 16 for PCM, 8 for ALAW, or 8 for ULAW.
/// <li> numBytes - size of audio data after this header, in bytes.
/// </ul>
/// -----------------------------------------------
///
class WaveHeader {
  /// follows WAVE format in http://ccrma.stanford.edu/courses/422/projects/WaveFormat
  static final String tag = 'WaveHeader';

  ///
  static final int headerLength = 44;

  /// Indicates PCM format.
  static final int formatInt = 1;

  /// Indicates PCM format.
  static final int formatFloat = 3;

  /// Indicates ALAW format.
  static final int formatALAW = 6;

  /// Indicates ULAW format.
  static final int formatULAW = 7;

  ///
  int mFormat;

  ///
  int mNumChannels;

  ///
  int mSampleRate;

  ///
  int mBitsPerSample;

  ///
  int mNumBytes;

  /// Construct a WaveHeader, with fields initialized.
  ///
  /// ------------------------------------
  ///
  /// ## Parameters
  ///
  /// - **_format:_** format of audio data. Can be:
  ///     - #FORMAT_PCM
  ///     - #FORMAT_ULAW
  ///     - #FORMAT_ALAW
  /// - **_numChannels:_** 1 for mono, 2 for stereo.
  /// - **_sampleRate:_** typically 8000, 11025, 16000, 22050, 44100 hz or 48000 hz.
  /// - **_bitsPerSample:_** usually 16 for PCM, 8 for ULAW or 8 for ALAW.
  /// - **_numBytes:_** size of audio data after this header, in bytes.
  ///
  WaveHeader(
    this.mFormat,
    this.mNumChannels,
    this.mSampleRate,
    this.mBitsPerSample,
    this.mNumBytes,
  );

  /// Write a WAVE file header.
  ///
  int write(EventSink<List<int>> out) {
    /* RIFF header */
    writeId(out, 'RIFF'); // Chunk ID
    writeInt32(out, 36 + mNumBytes); // Chunk Body Size
    writeId(out, 'WAVE'); // RIFF Form Type
    /* fmt chunk */
    writeId(out, 'fmt ');
    writeInt32(
      out,
      16,
    ); // Size of the rest of the Sub-chunk which follows this number. // 18???
    writeInt16(out, mFormat);
    writeInt16(out, mNumChannels);
    writeInt32(out, mSampleRate);
    writeInt32(
      out,
      (mNumChannels * mSampleRate * mBitsPerSample / 8).floor(),
    ); // Average Bytes per second
    writeInt16(
      out,
      (mNumChannels * mBitsPerSample / 8).floor(),
    ); // BlocK Align in bytes
    writeInt16(out, mBitsPerSample);
    /* data chunk */
    writeId(out, 'data');
    writeInt32(out, mNumBytes);

    return headerLength;
  }

  /// Push a String to the header
  static void writeId(EventSink<List<int>> out, String id) {
    out.add(id.codeUnits);
  }

  /// Push an int32 in the header
  static void writeInt32(EventSink<List<int>> out, int val) {
    out.add([val >> 0, val >> 8, val >> 16, val >> 24]);
  }

  /// Push an Int16 in the header
  static void writeInt16(EventSink<List<int>> out, int val) async {
    out.add([val >> 0, val >> 8]);
  }

  /// Push a String info of this header
  @override
  String toString() {
    return 'WaveHeader format=$mFormat numChannels=$mNumChannels sampleRate=$mSampleRate bitsPerSample=$mBitsPerSample numBytes=$mNumBytes';
  }
}
