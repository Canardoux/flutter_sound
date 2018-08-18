import 'dart:async';

import 'package:flutter/services.dart';

class FlutterSound {
  static const MethodChannel _channel =
      const MethodChannel('flutter_sound');

  static Future<dynamic> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<String> startRecorder(String uri) async {
    String result = await _channel.invokeMethod('startRecorder', <String, dynamic> {
      'path': uri,
    });

    return result;
  }

  static Future<String> stopRecorder() async {
    String result = await _channel.invokeMethod('stopRecorder');
    return result;
  }

  static Future<String> startPlayer(String uri) async {
    String result = await _channel.invokeMethod('startPlayer', <String, dynamic> {
      'path': uri,
    });

    return result;
  }

  static Future<String> stopPlayer() async {
    String result = await _channel.invokeMethod('stopPlayer');
    return result;
  }

  static Future<String> pausePlayer() async {
    String result = await _channel.invokeMethod('pausePlayer');
    return result;
  }

  static Future<String> resumePlayer() async {
    String result= await _channel.invokeMethod('resumePlayer');
    return result;
  }

  static Future<String> seekToPlayer(int sec) async {
    String result = await _channel.invokeMethod('startPlayer', <String, dynamic> {
      'sec': sec,
    });
    return result;
  }
}
