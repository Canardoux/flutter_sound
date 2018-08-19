import 'dart:async';
import 'dart:core';
import 'dart:convert';
import 'package:flutter/services.dart';

class FlutterSound {
  static const MethodChannel _channel = const MethodChannel('flutter_sound');
  static StreamController<RecordStatus> _recorderController;
  static StreamController<PlayStatus> _playerController;
  Stream<RecordStatus> get onRecorderStateChanged => _recorderController.stream;
  Stream<PlayStatus> get onPlayerStateChanged => _playerController.stream;

  bool _isRecording = false;
  bool _isPlaying = false;

  Future<void> _setRecorderCallback() async {
    if (_recorderController == null) {
      _recorderController = new StreamController.broadcast();
    }

    _channel.setMethodCallHandler((MethodCall call) {
      switch (call.method) {
        case "updateRecorderProgress":
          Map<String, dynamic> result = json.decode(call.arguments);
          _recorderController.add(new RecordStatus.fromJSON(result));
          break;
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
          Map<String, dynamic> result = json.decode(call.arguments);
          _playerController.add(new PlayStatus.fromJSON(result));
          break;
        case "audioPlayerDidFinishPlaying":
          Map<String, dynamic> result = json.decode(call.arguments);
          _playerController.add(new PlayStatus.fromJSON(result));
          this._isPlaying = false;
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
    if (this._isRecording) {
      throw new Exception('Recorder is already recroding.');
    }

    this._isRecording = true;
    String result = await _channel.invokeMethod('startRecorder', <String, dynamic> {
      'path': uri,
    });

    _setRecorderCallback();
    return result;
  }

  Future<String> stopRecorder() async {
    if (!this._isRecording) {
      throw new Exception('Recorder already stopped.');
    }

    String result = await _channel.invokeMethod('stopRecorder');

    this._isRecording = false;
    _removeRecorderCallback();
    return result;
  }

  Future<String> startPlayer(String uri) async {
    if (this._isPlaying) {
      throw Exception('Player is already playing.');
    }
    this._isPlaying = true;

    String result = await _channel.invokeMethod('startPlayer', <String, dynamic> {
      'path': uri,
    });

    _setPlayerCallback();
    return result;
  }

  Future<String> stopPlayer() async {
    if (!this._isPlaying) {
      throw Exception('Player already stopped.');
    }
    this._isPlaying = false;

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

class RecordStatus {
  final double currentPosition;

  RecordStatus.fromJSON(Map<String, dynamic> json)
      : currentPosition = double.parse(json['current_position']);

  @override
  String toString() {
    return 'currentPosition: $currentPosition';
  }
}

class PlayStatus {
  final double duration;
  final double currentPosition;

  PlayStatus.fromJSON(Map<String, dynamic> json)
    : duration = double.parse(json['duration']),
      currentPosition = double.parse(json['current_position']);

  @override
  String toString() {
    return 'duration: $duration, '
        'currentPosition: $currentPosition';
  }
}
