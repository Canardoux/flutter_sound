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

import 'dart:async';
import 'package:flutter_sound_advanced/src/fs_platform/flutter_sound_platform_interface.dart';
import 'package:flutter_sound_advanced/src/fs_platform/flutter_sound_player_platform_interface.dart';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:web/web.dart';
//import 'dart:typed_data';
import 'package:flutter_sound_advanced/src/fs_logger_compat.dart' show Level;
import 'dart:typed_data' as t show Float32List, Uint8List, Int16List;
//import 'dart:js_util';

//import 'package:tau_web/tau_web.dart';
//import 'package:etau/etau.dart';

class FlutterSoundMediaPlayerWeb {
  bool javascriptScriptLoaded = false;
  AudioContext? audioCtx;
  int numChannels = 1;
  bool interleaved = true;
  Codec codec = Codec.pcmFloat32;
  int sampleRate = 16000;
  FlutterSoundPlayerCallback? callback;
  AudioWorkletNode? streamNode;

  void logMsg(Map msg) {
    int level = msg['level'];
    String message = msg['message'];
    callback!.log(Level.values[level], message);
  }

  void error(Map msg) {
    String message = msg['message'];
    callback!.log(Level.error, message);
    throw Exception(message);
  }

  Future<int> startPlayerFromStream(
    FlutterSoundPlayerCallback callback, {
    Codec codec = Codec.pcm16,
    bool interleaved = true,
    int numChannels = 1,
    int sampleRate = 16000,
    int bufferSize = 8192,
    //TWhenFinished? whenFinished,
  }) async {
    this.callback = callback;
    this.interleaved = interleaved;
    this.numChannels = numChannels;
    this.sampleRate = sampleRate;
    this.codec = codec;
    callback.log(Level.debug, 'Start startPlayerFromStream to Stream');
    //await AsyncWorkletNode.init();
    assert(audioCtx == null);
    AudioContextOptions audioCtxOptions = AudioContextOptions(
      sampleRate: sampleRate,
    );
    audioCtx = AudioContext(audioCtxOptions);
    if (!javascriptScriptLoaded) {
      await audioCtx!.audioWorklet
          .addModule(
            "./assets/packages/flutter_sound_advanced/web_assets/src/flutter_sound_stream_processor.js",
          )
          .toDart;
      javascriptScriptLoaded = true;
    }
    AudioWorkletNodeOptions options = AudioWorkletNodeOptions(
      channelCount: numChannels,
      numberOfInputs: 0,
      numberOfOutputs: 1,
      outputChannelCount: [numChannels.toJS].toJS,
    );
    streamNode = AudioWorkletNode(
      audioCtx!,
      "flutter-sound-stream-processor",
      options,
    );

    streamNode!.port.onmessage = (MessageEvent e) {
      //var x = e.type;
      //var y = e.origin;
      var d = e.data;
      var msg = d!.dartify() as Map;
      var msgType = msg['msgType'];
      switch (msgType) {
        case 'NEED_SOME_FOOD':
          callback.needSomeFood(0);
          break;
        case 'LOG':
          logMsg(msg);
          break;
        case 'BUFFER_UNDERFLOW':
          callback.audioPlayerFinished(1);
          break;
        case 'ERROR':
          error(msg);
      }
      //int inputNo = (d!.getProperty('inputNo'.toJS) as JSNumber).toDartInt;
      //print('zozo');
    }.toJS;

    JSObject obj = JSObject();
    obj['msgType'] = 'START_PLAYER'.toJS;
    //setProperty(obj, 'msgType', 'START_PLAYER');
    obj.setProperty('isFloat32'.toJS, (codec == Codec.pcmFloat32).toJS);
    //setProperty(obj, 'isFloat32', codec == Codec.pcmFloat32);
    obj.setProperty('nbrChannels'.toJS, numChannels.toJS);
    //setProperty(obj, 'nbrChannels', numChannels);
    obj.setProperty('isInterleaved'.toJS, interleaved.toJS);
    //setProperty(obj, 'isInterleaved', interleaved);
    streamNode!.port.postMessage(obj);

    streamNode!.connect(audioCtx!.destination);

    //streamNode!.onBufferUnderflow((int outputNo) {
    //callback.needSomeFood(0);
    //_logger.d('onBufferUnderflow($outputNo)');
    //});

    callback.startPlayerCompleted(1 /*PlayerState.playing.index*/, true, 0);
    return 1; //PlayerState.playing.index; // PlayerState.isPlaying;
  }

  void postMessage(String message, JSAny? data) {
    JSObject obj = JSObject();
    obj.setProperty('msgType'.toJS, message.toJS);
    obj.setProperty('data'.toJS, data);
    streamNode!.port.postMessage(obj);
  }

  Future<int> stopPlayer() async {
    //recordedChunks = [];
    //streamSink = null;
    //mediaRecorder = null;
    // mic.disconnect();
    //streamNode?.stop();
    //streamNode?.disconnect();
    streamNode!.disconnect();
    await audioCtx?.close().toDart;
    streamNode = null;
    audioCtx = null;
    //streamNode = null;
    callback!.log(Level.debug, 'stop');
    callback!.stopPlayerCompleted(0, true);
    return 0; // PlayerState.stopped.index; // PlayerState.isStopped;
  }

  Future<int> feed({required t.Uint8List data}) async {
    postMessage('SEND_FEED_UINT8', data.toJS);
    return 0;
  }

  Future<int> feedFloat32({required List<t.Float32List> data}) async {
    if (codec != Codec.pcmFloat32) {
      callback!.log(
        Level.error,
        'Cannot feed with Float32 on a Codec <> pcmFloat32',
      );
      throw Exception('Cannot feed with Float32 with interleaved mode');
    }
    if (interleaved) {
      callback!.log(
        Level.error,
        'Cannot feed with Float32 with interleaved mode',
      );
      throw Exception('Cannot feed with Float32 with interleaved mode');
    }
    if (data.length != numChannels) {
      callback!.log(
        Level.error,
        'feedFloat32() : data length (${data.length}) != the number of channels ($numChannels)',
      );
      throw Exception(
        'feedFloat32() : data length (${data.length}) != the number of channels ($numChannels)',
      );
    }
    List<JSAny> r = [];
    for (int channel = 0; channel < data.length; ++channel) {
      r.add(data[channel].toJS);
    }
    postMessage('SEND_FEED_F32', r.toJS);
    //callback!.needSomeFood(0); // temporary
    return 0; // Length written
  }

  Future<int> feedInt16({required List<t.Int16List> data}) async {
    if (codec != Codec.pcm16) {
      callback!.log(
        Level.error,
        'Cannot feed with feedInt16 on a Codec <> pcm16',
      );
      throw Exception('Cannot feed with Float32 with interleaved mode');
    }
    if (interleaved) {
      callback!.log(
        Level.error,
        'Cannot feed with feedInt16 with interleaved mode',
      );
      throw Exception('Cannot feed with Float32 with interleaved mode');
    }
    if (data.length != numChannels) {
      callback!.log(
        Level.error,
        'feedFloat32() : data length (${data.length}) != the number of channels ($numChannels)',
      );
      throw Exception(
        'feedFloat32() : data length (${data.length}) != the number of channels ($numChannels)',
      );
    }
    List<JSAny> r = [];
    for (int channel = 0; channel < data.length; ++channel) {
      r.add(data[channel].toJS);
    }
    postMessage('SEND_FEED_I16', r.toJS);

    return 0;
  }

  Future<int> pausePlayer() async {
    return -1;
  }

  Future<int> resumePlayer() async {
    return -1;
  }

  Future<int> setVolume({required double volume}) async {
    return -1;
  }

  Future<int> setVolumePan({double? volume, double? pan}) async {
    return -1;
  }

  Future<int> setSpeed({required double speed}) async {
    return -1;
  }
}
