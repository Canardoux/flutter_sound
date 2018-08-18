import 'dart:async';
import 'dart:core';
import 'package:flutter/services.dart';

class FlutterSound {
  static const MethodChannel _channel = const MethodChannel('flutter_sound');
  static StreamController<dynamic> _recorderController;
  static StreamController<dynamic> _playerController;
  Stream<dynamic> get onRecorderStateChanged => _recorderController.stream;
  Stream<dynamic> get onPlayerStateChanged => _playerController.stream;

  Future<void> _setRecorderCallback() async {
    if (_recorderController == null) {
      _recorderController = new StreamController.broadcast();
    }

    _channel.setMethodCallHandler((MethodCall call) {
      switch (call.method) {
        default:
          throw new ArgumentError('Unknown method ${call.method} ');
      }
    });
  }

  Future<void> _setPlayerCallback() async {
    if (_playerController == null) {
      _playerController = new StreamController.broadcast();
    }

    _channel.setMethodCallHandler((MethodCall call) {
      switch (call.method) {
        case "updateProgress":
          _playerController.add(call.arguments);
          break;
        case "audioPlayerDidFinishPlaying":
          _playerController.add(call.arguments);
          _removePlayerCallback();
          break;
        default:
          throw new ArgumentError('Unknown method ${call.method} ');
      }
    });
  }

  Future<void> _removeRecorderCallback() async {
    if (_recorderController != null) {
      _recorderController
        ..add(null)
        ..close();
      _recorderController = null;
    }
  }

  Future<void> _removePlayerCallback() async {
    if (_playerController != null) {
      _playerController
        ..add(null)
        ..close();
      _playerController = null;
    }
  }

  Future<String> startRecorder(String uri) async {
    String result = await _channel.invokeMethod('startRecorder', <String, dynamic> {
      'path': uri,
    });

    _setRecorderCallback();
    return result;
  }

  Future<String> stopRecorder() async {
    String result = await _channel.invokeMethod('stopRecorder');

    _removeRecorderCallback();
    return result;
  }

  Future<String> startPlayer(String uri) async {
    String result = await _channel.invokeMethod('startPlayer', <String, dynamic> {
      'path': uri,
    });

    _setPlayerCallback();
    return result;
  }

  Future<String> stopPlayer() async {
    String result = await _channel.invokeMethod('stopPlayer');
    _removePlayerCallback();
    return result;
  }

  Future<String> pausePlayer() async {
    String result = await _channel.invokeMethod('pausePlayer');
    return result;
  }

  Future<String> resumePlayer() async {
    String result= await _channel.invokeMethod('resumePlayer');
    return result;
  }

  Future<String> seekToPlayer(int sec) async {
    String result = await _channel.invokeMethod('startPlayer', <String, dynamic> {
      'sec': sec,
    });
    return result;
  }
}
