import 'dart:async';

import 'package:flutter/services.dart';

import 'platform_interface.dart';

/// The main class of the plugin(singleton)
/// This class is for the communication with the native code
class Equalizer {
  static final Equalizer _singleton = Equalizer._internal();

  // Singleton instance
  factory Equalizer() {
    return _singleton;
  }

  // Private constructor
  Equalizer._internal();

  /// Namespace for the equalizer
  static const String namespace = 'dev.offcode.equalizer';

  /// Method channel for communication with the native code
  static const MethodChannel methodChannel = MethodChannel('$namespace/method');

  /// Stream subscription for the event channel
  StreamSubscription? eventSubscription;

  /// Set Audio Session ID
  Future<String> setAudioSessionId(int sessionId) async {
    /// Call the native method
    return await methodChannel.invokeMethod('setAudioSessionId', {
      'sessionId': sessionId,
    });
  }

  /// Init darwin equalizer
  Future<String> init(InitDarwinEqualizerRequest request) async {
    return await methodChannel.invokeMethod('init', request.toMap());
  }
}
