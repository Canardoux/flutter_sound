/*
 * Copyright 2018, 2019, 2020 Dooboolab.
 * Copyright 2021, 2022, 2023, 2024 Canardoux.
 *
 * This file is part of Flutter-Sound.
 *
 * Flutter-Sound is free software: you can redistribute it and/or modify
 * it under the terms of the Mozilla Public License version 2 (MPL2.0),
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

@JS()
library flutter_sound;

import 'dart:async';
import 'dart:typed_data' show Uint8List, Float32List, Int16List;

import 'package:flutter_sound_advanced/src/fs_platform/flutter_sound_platform_interface.dart';
import 'package:flutter_sound_advanced/src/fs_platform/flutter_sound_player_platform_interface.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'dart:js_interop';
import 'package:flutter_sound_advanced/src/fs_logger_compat.dart' show Level;
import 'flutter_sound_media_player_web.dart';
import 'flutter_sound_web.dart';

// ====================================  JS  =======================================================

@JS('newPlayerInstance')
external FlutterSoundPlayer newPlayerInstance(
  JSBoxedDartObject flutterSoundPlayerCallback,
  JSArray<JSExportedDartFunction> callbackTable,
);

@JS()
extension type FlutterSoundPlayer._(JSObject _) {
  //@JS('releaseMediaPlayer')
  external int releaseMediaPlayer();

  //@JS('initializeMediaPlayer')
  external int initializeMediaPlayer();

  //@JS('setAudioFocus')
  external int setAudioFocus(
    int focus,
    int category,
    int mode,
    int? audioFlags,
    int device,
  );

  //@JS('getPlayerState')
  external int getPlayerState();

  //@JS('isDecoderSupported')
  external bool isDecoderSupported(int codec);

  //@JS('setSubscriptionDuration')
  external int setSubscriptionDuration(int duration);

  //@JS('startPlayer')
  external int startPlayer(
    int? codec,
    JSUint8Array? fromDataBuffer,
    String? fromURI,
    int? numChannels,
    int? sampleRate,
    int? bufferSize,
  );

  //@JS('feed')
  external int feed(JSUint8Array? data);

  //@JS('feedFloat32')
  external int feedFloat32(JSArray<JSUint8Array>? data);

  //@JS('feedInt16')
  external int feedInt16(JSArray<JSUint8Array>? data);

  /*
  //@JS('startPlayerFromTrack')
  external int startPlayerFromTrack(
    int progress,
    int duration,
    Map<String, dynamic> track,
    bool canPause,
    bool canSkipForward,
    bool canSkipBackward,
    bool defaultPauseResume,
    bool removeUIWhenStopped,
  );

  //@JS('nowPlaying')
  external int nowPlaying(
    int progress,
    int duration,
    Map<String, dynamic>? track,
    bool? canPause,
    bool? canSkipForward,
    bool? canSkipBackward,
    bool? defaultPauseResume,
  );
*/
  //@JS('stopPlayer')
  external int stopPlayer();

  //@JS('resumePlayer')
  external int pausePlayer();

  //@JS('')
  external int resumePlayer();

  //@JS('seekToPlayer')
  external int seekToPlayer(int duration);

  ///@JS('setVolume')
  external int setVolume(double? volume);

  //@JS('setVolumePan')
  external int setVolumePan(double? volume, double? pan);

  //@JS('setSpeed')
  external int setSpeed(double speed);

  //@JS('setUIProgressBar')
  external int setUIProgressBar(int duration, int progress);
}

List<JSExportedDartFunction> callbackTable = [
  (JSBoxedDartObject cb, int position, int duration) {
    (cb.toDart as FlutterSoundPlayerCallback).updateProgress(
      duration: duration,
      position: position,
    );
  }.toJS,
  (JSBoxedDartObject cb, int state) {
    (cb.toDart as FlutterSoundPlayerCallback).updatePlaybackState(state);
  }.toJS,
  (JSBoxedDartObject cb, int ln) {
    (cb.toDart as FlutterSoundPlayerCallback).needSomeFood(ln);
  }.toJS,
  (JSBoxedDartObject cb, int state) {
    (cb.toDart as FlutterSoundPlayerCallback).audioPlayerFinished(state);
  }.toJS,
  (JSBoxedDartObject cb, int state, bool success, int duration) {
    (cb.toDart as FlutterSoundPlayerCallback).startPlayerCompleted(
      state,
      success,
      duration,
    );
  }.toJS,
  (JSBoxedDartObject cb, int state, bool success) {
    (cb.toDart as FlutterSoundPlayerCallback).pausePlayerCompleted(
      state,
      success,
    );
  }.toJS,
  (JSBoxedDartObject cb, int state, bool success) {
    (cb.toDart as FlutterSoundPlayerCallback).resumePlayerCompleted(
      state,
      success,
    );
  }.toJS,
  (JSBoxedDartObject cb, int state, bool success) {
    (cb.toDart as FlutterSoundPlayerCallback).stopPlayerCompleted(
      state,
      success,
    );
  }.toJS,
  (JSBoxedDartObject cb, int state, bool success) {
    (cb.toDart as FlutterSoundPlayerCallback).openPlayerCompleted(
      state,
      success,
    );
  }.toJS,
  (JSBoxedDartObject cb, int level, String msg) {
    (cb.toDart as FlutterSoundPlayerCallback).log(Level.values[level], msg);
  }.toJS,
];

//=========================================================================================================

/// The web implementation of [FlutterSoundPlatform].
///
/// This class implements the `package:flutter_sound_player` functionality for the web.
///

class FlutterSoundPlayerWeb
    extends FlutterSoundPlayerPlatform //implements FlutterSoundPlayerCallback
{
  static List<String> defaultExtensions = [
    "flutter_sound.aac", // defaultCodec
    "flutter_sound.aac", // aacADTS
    "flutter_sound.opus", // opusOGG
    "flutter_sound_opus.caf", // opusCAF
    "flutter_sound.mp3", // mp3
    "flutter_sound.ogg", // vorbisOGG
    "flutter_sound.pcm", // pcm16
    "flutter_sound.wav", // pcm16WAV
    "flutter_sound.aiff", // pcm16AIFF
    "flutter_sound_pcm.caf", // pcm16CAF
    "flutter_sound.flac", // flac
    "flutter_sound.mp4", // aacMP4
    "flutter_sound.amr", // amrNB
    "flutter_sound.amr", // amrWB
    "flutter_sound.pcm", // pcm8
    "flutter_sound.pcm", // pcmFloat32
  ];

  /// Registers this class as the default instance of [FlutterSoundPlatform].
  static void registerWith(Registrar registrar) {
    FlutterSoundPlayerPlatform.instance = FlutterSoundPlayerWeb();
  }

  FlutterSoundMediaPlayerWeb? _mediaPlayerWeb;

  /* ctor */
  MethodChannelFlutterSoundPlayer() {}

  //============================================ Session manager ===================================================================

  List<FlutterSoundPlayer?> _slots = [];
  FlutterSoundPlayer? getWebSession(FlutterSoundPlayerCallback callback) {
    return _slots[findSession(callback)];
  }

  //==============================================================================================================================

  //static bool _alreadyInited = false;

  @override
  Future<bool> initPlugin() {
    return FlutterSoundPlugin.loadScripts();
  }

  @override
  Future<void>? resetPlugin(FlutterSoundPlayerCallback callback) {
    callback.log(Level.debug, '---> resetPlugin');
    for (int i = 0; i < _slots.length; ++i) {
      callback.log(Level.debug, "Releasing slot #$i");
      _slots[i]!.releaseMediaPlayer();
    }
    _slots = [];
    callback.log(Level.debug, '<--- resetPlugin');
    return null;
  }

  @override
  Future<int> openPlayer(
    FlutterSoundPlayerCallback callback, {
    required Level logLevel,
  }) async {
    // openAudioSessionCompleter = new Completer<bool>();
    // await invokeMethod( callback, 'initializeMediaPlayer', {'focus': focus.index, 'category': category.index, 'mode': mode.index, 'audioFlags': audioFlags, 'device': device.index, 'withUI': withUI ? 1 : 0 ,},) ;
    // return  openAudioSessionCompleter.future ;
    int slotno = findSession(callback);
    if (slotno < _slots.length) {
      assert(_slots[slotno] == null);
      _slots[slotno] = newPlayerInstance(callback.toJSBox, callbackTable.toJS);
    } else {
      assert(slotno == _slots.length);
      _slots.add(newPlayerInstance(callback.toJSBox, callbackTable.toJS));
    }
    return _slots[slotno]!.initializeMediaPlayer();
  }

  @override
  Future<int> closePlayer(FlutterSoundPlayerCallback callback) async {
    int slotno = findSession(callback);
    int r = _slots[slotno]!.releaseMediaPlayer();
    _slots[slotno] = null;
    return r;
  }

  @override
  Future<int> getPlayerState(FlutterSoundPlayerCallback callback) async {
    return getWebSession(callback)!.getPlayerState();
  }

  @override
  Future<Map<String, Duration>> getProgress(
    FlutterSoundPlayerCallback callback,
  ) async {
    // Map<String, int> m = await invokeMethod( callback, 'getPlayerState', null,) as Map;
    Map<String, Duration> r = {
      'duration': Duration.zero,
      'progress': Duration.zero,
    };
    return r;
  }

  @override
  Future<bool> isDecoderSupported(
    FlutterSoundPlayerCallback callback, {
    required Codec codec,
  }) async {
    return getWebSession(callback)!.isDecoderSupported(codec.index);
  }

  @override
  Future<int> setSubscriptionDuration(
    FlutterSoundPlayerCallback callback, {
    Duration? duration,
  }) async {
    return getWebSession(
      callback,
    )!
        .setSubscriptionDuration(duration!.inMilliseconds);
  }

  @override
  Future<int> startPlayer(
    FlutterSoundPlayerCallback callback, {
    Codec? codec,
    Uint8List? fromDataBuffer,
    String? fromURI,
    int? numChannels,
    bool interleaved = true,
    int? sampleRate,
    int bufferSize = 8192,
  }) async {
    // startPlayerCompleter = new Completer<Map>();
    // await invokeMethod( callback, 'startPlayer', {'codec': codec.index, 'fromDataBuffer': fromDataBuffer, 'fromURI': fromURI, 'numChannels': numChannels, 'sampleRate': sampleRate},) ;
    // return  startPlayerCompleter.future ;
    // String s = "https://file-examples-com.github.io/uploads/2017/11/file_example_MP3_700KB.mp3";
    if (codec == null) codec = Codec.defaultCodec;

    if (fromDataBuffer != null) {
      if (fromURI != null) {
        throw Exception(
          "You may not specify both 'fromURI' and 'fromDataBuffer' parameters",
        );
      }
    }
    callback.log(Level.debug, 'startPlayer FromURI : $fromURI');
    var r = await getWebSession(callback)!.startPlayer(
      codec.index,
      fromDataBuffer?.toJS,
      fromURI,
      numChannels,
      sampleRate,
      bufferSize,
    );
    return r;
  }

  @override
  @deprecated
  Future<int> startPlayerFromMic(
    FlutterSoundPlayerCallback callback, {
    int? numChannels,
    int? sampleRate,
    int bufferSize = 8192,
    bool enableVoiceProcessing = false,
  }) {
    throw Exception('StartPlayerFromMic() is not implemented on Flutter Web');
  }

  @override
  Future<int> startPlayerFromStream(
    FlutterSoundPlayerCallback callback, {
    Codec codec = Codec.pcm16,
    bool interleaved = true,
    int numChannels = 1,
    int sampleRate = 16000,
    int bufferSize = 8192,
    //TWhenFinished? whenFinished,
  }) {
    _mediaPlayerWeb = FlutterSoundMediaPlayerWeb();
    return _mediaPlayerWeb!.startPlayerFromStream(
      callback,
      codec: codec,
      interleaved: interleaved,
      numChannels: numChannels,
      sampleRate: sampleRate,
      bufferSize: bufferSize,
    );
  }

  @override
  Future<int> stopPlayer(FlutterSoundPlayerCallback callback) async {
    if (_mediaPlayerWeb != null) {
      var r = _mediaPlayerWeb!.stopPlayer();
      _mediaPlayerWeb = null;
      return r;
    } else {
      return getWebSession(callback)!.stopPlayer();
    }
  }

  @override
  Future<int> feed(
    FlutterSoundPlayerCallback callback, {
    required Uint8List data,
  }) async {
    if (_mediaPlayerWeb != null) {
      return _mediaPlayerWeb!.feed(data: data);
    } else {
      return getWebSession(callback)!.feed(data.toJS);
    }
  }

  // Return the length sent
  @override
  Future<int> feedFloat32(
    FlutterSoundPlayerCallback callback, {
    required List<Float32List> data,
  }) {
    if (_mediaPlayerWeb != null) {
      return _mediaPlayerWeb!.feedFloat32(data: data);
    } else {
      throw Exception(
        'You must start the player with [startPlayerFromStream()',
      );
    }
  }

  @override
  Future<int> feedInt16(
    FlutterSoundPlayerCallback callback, {
    required List<Int16List> data,
  }) {
    if (_mediaPlayerWeb != null) {
      return _mediaPlayerWeb!.feedInt16(data: data);
    } else {
      throw Exception(
        'You must start the player with [startPlayerFromStream()',
      );
    }
  }

  @override
  Future<int> pausePlayer(FlutterSoundPlayerCallback callback) async {
    if (_mediaPlayerWeb != null) {
      return _mediaPlayerWeb!.pausePlayer();
    } else {
      return getWebSession(callback)!.pausePlayer();
    }
  }

  @override
  Future<int> resumePlayer(FlutterSoundPlayerCallback callback) async {
    if (_mediaPlayerWeb != null) {
      return _mediaPlayerWeb!.resumePlayer();
    } else {
      return getWebSession(callback)!.resumePlayer();
    }
  }

  @override
  Future<int> seekToPlayer(
    FlutterSoundPlayerCallback callback, {
    Duration? duration,
  }) async {
    return getWebSession(callback)!.seekToPlayer(duration!.inMilliseconds);
  }

  Future<int> setVolume(
    FlutterSoundPlayerCallback callback, {
    required double volume,
  }) async {
    if (_mediaPlayerWeb != null) {
      return _mediaPlayerWeb!.setVolume(volume: volume);
    } else {
      return getWebSession(callback)!.setVolume(volume);
    }
  }

  Future<int> setVolumePan(
    FlutterSoundPlayerCallback callback, {
    double? volume,
    double? pan,
  }) async {
    if (_mediaPlayerWeb != null) {
      return _mediaPlayerWeb!.setVolumePan(volume: volume, pan: pan);
    } else {
      return getWebSession(callback)!.setVolumePan(volume, pan);
    }
  }

  Future<int> setSpeed(
    FlutterSoundPlayerCallback callback, {
    required double speed,
  }) async {
    if (_mediaPlayerWeb != null) {
      return _mediaPlayerWeb!.setSpeed(speed: speed);
    } else {
      return getWebSession(callback)!.setSpeed(speed);
    }
  }

  Future<String> getResourcePath(FlutterSoundPlayerCallback callback) async {
    return '';
  }
}
