import 'dart:async';
import 'dart:core';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_sound/android_encoder.dart';
import 'package:flutter_sound/ios_quality.dart';

class FlutterSound {
  static const MethodChannel _channel = const MethodChannel('flutter_sound');
  static StreamController<RecordStatus> _recorderController;
  static StreamController<double> _dbPeakController;
  static StreamController<PlayStatus> _playerController;
  /// Value ranges from 0 to 120
  Stream<double> get onRecorderDbPeakChanged => _dbPeakController.stream;
  Stream<RecordStatus> get onRecorderStateChanged => _recorderController.stream;
  Stream<PlayStatus> get onPlayerStateChanged => _playerController.stream;
  bool get isPlaying => _isPlaying;
  bool get isRecording => _isRecording;

  bool _isRecording = false;
  bool _isPlaying = false;

  Future<String> setSubscriptionDuration(double sec) async {
    String result = await _channel
        .invokeMethod('setSubscriptionDuration', <String, dynamic>{
      'sec': sec,
    });
    return result;
  }

  Future<void> _setRecorderCallback() async {
    if (_recorderController == null) {
      _recorderController = new StreamController.broadcast();
    }
    if (_dbPeakController == null) {
      _dbPeakController = new StreamController.broadcast();
    }

    _channel.setMethodCallHandler((MethodCall call) {
      switch (call.method) {
        case "updateRecorderProgress":
          Map<String, dynamic> result = json.decode(call.arguments);
          _recorderController.add(new RecordStatus.fromJSON(result));
          break;
        case "updateDbPeakProgress":
          _dbPeakController.add(call.arguments);
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
          Map<String, dynamic> result = jsonDecode(call.arguments);
          _playerController.add(new PlayStatus.fromJSON(result));
          break;
        case "audioPlayerDidFinishPlaying":
          Map<String, dynamic> result = jsonDecode(call.arguments);
          PlayStatus status = new PlayStatus.fromJSON(result);
          if (status.currentPosition != status.duration) {
            status.currentPosition = status.duration;
          }
          _playerController.add(status);
          this._isPlaying = false;
          _removePlayerCallback();
          break;
        default:
          throw new ArgumentError('Unknown method ${call.method}');
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

    Future<void> _removeDbPeakCallback() async {
    if (_dbPeakController != null) {
      _dbPeakController
        ..add(null)
        ..close();
      _dbPeakController = null;
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

  Future<String> startRecorder(String uri,
      {int sampleRate = 44100, int numChannels = 2, int bitRate,
        AndroidEncoder androidEncoder = AndroidEncoder.AAC,
        IosQuality iosQuality = IosQuality.LOW
      }) async {
    try {
      String result =
      await _channel.invokeMethod('startRecorder', <String, dynamic>{
        'path': uri,
        'sampleRate': sampleRate,
        'numChannels': numChannels,
        'bitRate': bitRate,
        'androidEncoder': androidEncoder?.value,
        'iosQuality': iosQuality?.value
      });
      _setRecorderCallback();

      if (this._isRecording) {
        throw new Exception('Recorder is already recording.');
      }
      this._isRecording = true;
      return result;
    } catch (err) {
      throw new Exception(err);
    }
  }

  Future<String> stopRecorder() async {
    if (!this._isRecording) {
      throw new Exception('Recorder already stopped.');
    }

    String result = await _channel.invokeMethod('stopRecorder');

    this._isRecording = false;
    _removeRecorderCallback();
    _removeDbPeakCallback();
    return result;
  }

  Future<String> startPlayer(String uri) async {
    try {
      String result =
          await _channel.invokeMethod('startPlayer', <String, dynamic>{
        'path': uri,
      });
      print('result: $result');

      _setPlayerCallback();

      if (this._isPlaying) {
        throw Exception('Player is already playing.');
      }
      this._isPlaying = true;

      return result;
    } catch (err) {
      throw Exception(err);
    }
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
    String result = await _channel.invokeMethod('resumePlayer');
    return result;
  }

  Future<String> seekToPlayer(int milliSecs) async {
    String result =
        await _channel.invokeMethod('seekToPlayer', <String, dynamic>{
      'sec': milliSecs,
    });
    return result;
  }

  Future<String> setVolume(double volume) async {
    String result = '';
    if (volume < 0.0 || volume > 1.0) {
      result = 'Value of volume should be between 0.0 and 1.0.';
      return result;
    }

    result = await _channel
        .invokeMethod('setVolume', <String, dynamic>{
      'volume': volume,
    });
    return result;
  }

  /// Defines the interval at which the peak level should be updated.
  /// Default is 0.8 seconds
  Future<String> setDbPeakLevelUpdate(double intervalInSecs) async {
    String result = await _channel
      .invokeMethod('setDbPeakLevelUpdate', <String, dynamic>{
    'intervalInSecs': intervalInSecs,
    });
    return result;
  }

  /// Enables or disables processing the Peak level in db's. Default is disabled
  Future<String> setDbLevelEnabled(bool enabled) async {
    String result = await _channel
      .invokeMethod('setDbLevelEnabled', <String, dynamic>{
    'enabled': enabled,
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
  double currentPosition;

  PlayStatus.fromJSON(Map<String, dynamic> json)
      : duration = double.parse(json['duration']),
        currentPosition = double.parse(json['current_position']);

  @override
  String toString() {
    return 'duration: $duration, '
        'currentPosition: $currentPosition';
  }
}
