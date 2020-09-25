import 'dart:async';

import 'package:flutter/services.dart';

import 'flutter_sound_platform_interface.dart';

const MethodChannel _channel = MethodChannel('plugins.flutter.io/url_launcher');

/// An implementation of [UrlLauncherPlatform] that uses method channels.
class MethodChannelUrlLauncher extends FlutterSoundPlatform {
  @override
  Future<bool> launch(String url) {
    return _channel.invokeMethod<bool>(
      'launch',
      <String, Object>{
        'url': url,
      },
    );
  }
}