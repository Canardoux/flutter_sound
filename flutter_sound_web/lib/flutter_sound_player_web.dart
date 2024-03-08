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

@JS()
library flutter_sound;

import 'dart:async';
//import 'dart:html' as html;
import 'dart:typed_data' show Uint8List;

//import 'package:meta/meta.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_platform_interface.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_player_platform_interface.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
//import 'dart:io';
import 'package:js/js.dart';
import 'package:logger/logger.dart' show Level;

// ====================================  JS  =======================================================

@JS('newPlayerInstance')
external FlutterSoundPlayer newPlayerInstance(
    FlutterSoundPlayerCallback theCallBack, List<Function> callbackTable);

@JS('FlutterSoundPlayer')
class FlutterSoundPlayer {
  @JS('releaseMediaPlayer')
  external int releaseMediaPlayer();

  @JS('initializeMediaPlayer')
  external int initializeMediaPlayer();

  @JS('setAudioFocus')
  external int setAudioFocus(
    int focus,
    int category,
    int mode,
    int? audioFlags,
    int device,
  );

  @JS('getPlayerState')
  external int getPlayerState();

  @JS('isDecoderSupported')
  external bool isDecoderSupported(
    int codec,
  );

  @JS('setSubscriptionDuration')
  external int setSubscriptionDuration(int duration);

  @JS('startPlayer')
  external int startPlayer(int? codec, Uint8List? fromDataBuffer,
      String? fromURI, int? numChannels, int? sampleRate, int? bufferSize);

  @JS('feed')
  external int feed(
    Uint8List? data,
  );

  @JS('startPlayerFromTrack')
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

  @JS('nowPlaying')
  external int nowPlaying(
    int progress,
    int duration,
    Map<String, dynamic>? track,
    bool? canPause,
    bool? canSkipForward,
    bool? canSkipBackward,
    bool? defaultPauseResume,
  );

  @JS('stopPlayer')
  external int stopPlayer();

  @JS('resumePlayer')
  external int pausePlayer();

  @JS('')
  external int resumePlayer();

  @JS('seekToPlayer')
  external int seekToPlayer(int duration);

  @JS('setVolume')
  external int setVolume(double? volume);

  @JS('setSpeed')
  external int setSpeed(double speed);

  @JS('setUIProgressBar')
  external int setUIProgressBar(int duration, int progress);
}

List<Function> callbackTable = [
  allowInterop((FlutterSoundPlayerCallback cb, int position, int duration) {
    cb.updateProgress(
      duration: duration,
      position: position,
    );
  }),
  allowInterop((FlutterSoundPlayerCallback cb, int state) {
    cb.updatePlaybackState(
      state,
    );
  }),
  allowInterop((FlutterSoundPlayerCallback cb, int ln) {
    cb.needSomeFood(
      ln,
    );
  }),
  allowInterop((FlutterSoundPlayerCallback cb, int state) {
    cb.audioPlayerFinished(
      state,
    );
  }),
  allowInterop(
      (FlutterSoundPlayerCallback cb, int state, bool success, int duration) {
    cb.startPlayerCompleted(
      state,
      success,
      duration,
    );
  }),
  allowInterop((FlutterSoundPlayerCallback cb, int state, bool success) {
    cb.pausePlayerCompleted(state, success);
  }),
  allowInterop((FlutterSoundPlayerCallback cb, int state, bool success) {
    cb.resumePlayerCompleted(state, success);
  }),
  allowInterop((FlutterSoundPlayerCallback cb, int state, bool success) {
    cb.stopPlayerCompleted(state, success);
  }),
  allowInterop((FlutterSoundPlayerCallback cb, int state, bool success) {
    cb.openPlayerCompleted(state, success);
  }),
  allowInterop((FlutterSoundPlayerCallback cb, int state, bool success) {
    cb.closePlayerCompleted(state, success);
  }),
  allowInterop((FlutterSoundPlayerCallback cb, int level, String msg) {
    cb.log(Level.values[level], msg);
  }),
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

  /* ctor */ MethodChannelFlutterSoundPlayer() {}

//============================================ Session manager ===================================================================

  List<FlutterSoundPlayer?> _slots = [];
  FlutterSoundPlayer? getWebSession(FlutterSoundPlayerCallback callback) {
    return _slots[findSession(callback)];
  }

//==============================================================================================================================

  @override
  Future<void>? resetPlugin(
    FlutterSoundPlayerCallback callback,
  ) {
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
  Future<int> openPlayer(FlutterSoundPlayerCallback callback,
      {required Level logLevel}) async {
    // openAudioSessionCompleter = new Completer<bool>();
    // await invokeMethod( callback, 'initializeMediaPlayer', {'focus': focus.index, 'category': category.index, 'mode': mode.index, 'audioFlags': audioFlags, 'device': device.index, 'withUI': withUI ? 1 : 0 ,},) ;
    // return  openAudioSessionCompleter.future ;
    int slotno = findSession(callback);
    if (slotno < _slots.length) {
      assert(_slots[slotno] == null);
      _slots[slotno] = newPlayerInstance(callback, callbackTable);
    } else {
      assert(slotno == _slots.length);
      _slots.add(newPlayerInstance(callback, callbackTable));
    }
    return _slots[slotno]!.initializeMediaPlayer();
  }

  @override
  Future<int> closePlayer(
    FlutterSoundPlayerCallback callback,
  ) async {
    int slotno = findSession(callback);
    int r = _slots[slotno]!.releaseMediaPlayer();
    _slots[slotno] = null;
    return r;
  }

  @override
  Future<int> getPlayerState(
    FlutterSoundPlayerCallback callback,
  ) async {
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
    return getWebSession(callback)!
        .setSubscriptionDuration(duration!.inMilliseconds);
  }

  @override
  Future<int> startPlayer(FlutterSoundPlayerCallback callback,
      {Codec? codec,
      Uint8List? fromDataBuffer,
      String? fromURI,
      int? numChannels,
      int? sampleRate,
      int bufferSize = 8192}) async {
    // startPlayerCompleter = new Completer<Map>();
    // await invokeMethod( callback, 'startPlayer', {'codec': codec.index, 'fromDataBuffer': fromDataBuffer, 'fromURI': fromURI, 'numChannels': numChannels, 'sampleRate': sampleRate},) ;
    // return  startPlayerCompleter.future ;
    // String s = "https://file-examples-com.github.io/uploads/2017/11/file_example_MP3_700KB.mp3";
    if (codec == null) codec = Codec.defaultCodec;
    if (fromDataBuffer != null) {
      if (fromURI != null) {
        throw Exception(
            "You may not specify both 'fromURI' and 'fromDataBuffer' parameters");
      }
      //js.context.callMethod('playAudioFromBuffer', [fromDataBuffer]);
      //playAudioFromBuffer(fromDataBuffer);
      // .......................return getWebSession(callback).playAudioFromBuffer(fromDataBuffer);
      //playAudioFromBuffer3(fromDataBuffer);
      //Directory tempDir = await getTemporaryDirectory();
      /*
                        String path = defaultExtensions[codec.index];
                        File filOut = File(path);
                        IOSink sink = filOut.openWrite();
                        sink.add(fromDataBuffer.toList());
                        fromURI = path;
                         */
    }
    //js.context.callMethod('playAudioFromURL', [fromURI]);
    callback.log(Level.debug, 'startPlayer FromURI : $fromURI');
    return getWebSession(callback)!.startPlayer(codec.index, fromDataBuffer,
        fromURI, numChannels, sampleRate, bufferSize);
  }

  @override
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
  Future<int> feed(
    FlutterSoundPlayerCallback callback, {
    Uint8List? data,
  }) async {
    return getWebSession(callback)!.feed(data);
  }

  @override
  Future<int> stopPlayer(
    FlutterSoundPlayerCallback callback,
  ) async {
    return getWebSession(callback)!.stopPlayer();
  }

  @override
  Future<int> pausePlayer(
    FlutterSoundPlayerCallback callback,
  ) async {
    return getWebSession(callback)!.pausePlayer();
  }

  @override
  Future<int> resumePlayer(
    FlutterSoundPlayerCallback callback,
  ) async {
    return getWebSession(callback)!.resumePlayer();
  }

  @override
  Future<int> seekToPlayer(FlutterSoundPlayerCallback callback,
      {Duration? duration}) async {
    return getWebSession(callback)!.seekToPlayer(duration!.inMilliseconds);
  }

  Future<int> setVolume(FlutterSoundPlayerCallback callback,
      {double? volume}) async {
    return getWebSession(callback)!.setVolume(volume);
  }

  Future<int> setSpeed(FlutterSoundPlayerCallback callback,
      {required double speed}) async {
    return getWebSession(callback)!.setSpeed(speed);
  }

  Future<String> getResourcePath(
    FlutterSoundPlayerCallback callback,
  ) async {
    return '';
  }

  //@override
  //Future<void>?   setLogLeve(FlutterSoundPlayerCallback callback, Level loglevel)
  //{
  //        return null;
  //
  //}
}
