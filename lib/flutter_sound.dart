import 'dart:async';
import 'dart:core';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data' show Uint8List;
import 'package:flutter/services.dart';
import 'package:flutter_sound/android_encoder.dart';
import 'package:flutter_sound/ios_quality.dart';
import 'dart:io' show Platform;

// this enum MUST be synchronized with fluttersound/AudioInterface.java  and ios/Classes/FlutterSoundPlugin.h
enum t_CODEC
{
	DEFAULT,
	CODEC_AAC,
	CODEC_OPUS,
	CODEC_CAF_OPUS, // Apple encapsulates its bits in its own special envelope : .caf instead of a regular ogg/opus (.opus). This is completely stupid, this is Apple.
	CODEC_MP3,
	CODEC_VORBIS,
	CODEC_PCM,
}

enum t_AUDIO_STATE
{
        IS_STOPPED,
        IS_PAUSED,
        IS_PLAYING,
        IS_RECORDING,
}

const defaultPath = 'sound.aac';

final List<String> paths =
  [
  		defaultPath,	// DEFAULT
  		'sound.aac',	// CODEC_AAC
  		'sound.opus',	// CODEC_OPUS
  		'sound.caf',	// CODEC_CAF_OPUS
  		'sound.mp3',	// CODEC_MP3
  		'sound.ogg',	// CODEC_VORBIS
  		'sound.wav',	// CODEC_PCM
];

class FlutterSound {
  static const MethodChannel _channel = const MethodChannel('flutter_sound');
  static StreamController<RecordStatus> _recorderController;
  static StreamController<double> _dbPeakController;
  static StreamController<PlayStatus> _playerController;
  /// Value ranges from 0 to 120
  Stream<double> get onRecorderDbPeakChanged => _dbPeakController.stream;
  Stream<RecordStatus> get onRecorderStateChanged => _recorderController.stream;
  Stream<PlayStatus> get onPlayerStateChanged => _playerController.stream;
  @Deprecated('Prefer to use audio_state variable')
  bool get isPlaying => _isPlaying();
  bool get isRecording => _isRecording();
  t_AUDIO_STATE get audioState => _audio_state;

  bool _isRecording() => _audio_state == t_AUDIO_STATE.IS_RECORDING ;
  t_AUDIO_STATE _audio_state = t_AUDIO_STATE.IS_STOPPED;
  bool _isPlaying() => _audio_state == t_AUDIO_STATE.IS_PLAYING || _audio_state == t_AUDIO_STATE.IS_PAUSED;

  Future<bool> isEncoderSupported(t_CODEC codec) async {
      bool result =
          await _channel.invokeMethod('isEncoderSupported', <String, dynamic> { 'codec': codec.index } );
      return result;
  }

  Future<bool>  isDecoderSupported(t_CODEC codec) async {
    bool result =
        await _channel.invokeMethod('isDecoderSupported', <String, dynamic> { 'codec': codec.index } );
    return result;
  }

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
          if (_recorderController != null)
            _recorderController.add(new RecordStatus.fromJSON(result));
          break;
        case "updateDbPeakProgress":
        if (_dbPeakController!= null)
          _dbPeakController.add(call.arguments);
          break;
        default:
          throw new ArgumentError('Unknown method ${call.method} ');
      }
      return null;
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
          if (_playerController!=null)
            _playerController.add(new PlayStatus.fromJSON(result));
          break;
        case "audioPlayerDidFinishPlaying":
          Map<String, dynamic> result = jsonDecode(call.arguments);
          PlayStatus status = new PlayStatus.fromJSON(result);
          if (status.currentPosition != status.duration) {
            status.currentPosition = status.duration;
          }
          if (_playerController != null)
            _playerController.add(status);
          _audio_state = t_AUDIO_STATE.IS_STOPPED;
          _removePlayerCallback();
          break;
        default:
          throw new ArgumentError('Unknown method ${call.method}');
      }
      return null;
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

  Future<String> startRecorder(
      {
        String uri = defaultPath,
        int sampleRate = 16000, int numChannels = 1, int bitRate = 16000,
        t_CODEC codec = t_CODEC.CODEC_AAC,
        AndroidEncoder androidEncoder = AndroidEncoder.AAC,
        AndroidAudioSource androidAudioSource = AndroidAudioSource.MIC,
        AndroidOutputFormat androidOutputFormat = AndroidOutputFormat.DEFAULT,
        IosQuality iosQuality = IosQuality.LOW,
      }) async {
    if (_audio_state != t_AUDIO_STATE.IS_STOPPED) {
      throw new RecorderRunningException('Recorder is not stopped.');
    }
    if (! await isEncoderSupported(codec))
      throw new RecorderRunningException('Codec not supported.');
    try {
      var param = <String, dynamic>{
        'path': uri,
        'sampleRate': sampleRate,
        'numChannels': numChannels,
        'bitRate': bitRate,
        'codec': codec.index,
        'androidEncoder': androidEncoder?.value,
        'androidAudioSource': androidAudioSource?.value,
        'androidOutputFormat': androidOutputFormat?.value,
        'iosQuality': iosQuality?.value
      };

      String result = await _channel.invokeMethod('startRecorder', param);
      _setRecorderCallback();
        _audio_state = t_AUDIO_STATE.IS_RECORDING;
      return result;
    } catch (err) {
      throw new Exception(err);
    }
  }

  Future<String> stopRecorder() async {
    if (_audio_state != t_AUDIO_STATE.IS_RECORDING) {
      throw new RecorderStoppedException('Recorder is not recording.');
    }

    String result = await _channel.invokeMethod('stopRecorder');

    _audio_state = t_AUDIO_STATE.IS_STOPPED;
    _removeRecorderCallback();
    _removeDbPeakCallback();
    return result;
  }


  Future<String> _startPlayer(String method, Map <String, dynamic> what) async {
    if (_audio_state == t_AUDIO_STATE.IS_PAUSED) {
      this.resumePlayer();
      _audio_state = t_AUDIO_STATE.IS_PLAYING;
      return 'Player resumed';
      // throw PlayerRunningException('Player is already playing.');
    }
    if (_audio_state != t_AUDIO_STATE.IS_STOPPED) {
            throw PlayerRunningException('Player is not stopped.');
    }

    try {
      String result =
      await _channel.invokeMethod(method, what);

      if (result != null)
      {
        print ('startPlayer result: $result');
        _setPlayerCallback ();
        _audio_state = t_AUDIO_STATE.IS_PLAYING;
      }

      return result;
    } catch (err) {
      throw Exception(err);
    }
  }


  Future<String> startPlayer(String uri) async => _startPlayer('startPlayer', {'path': uri});
  Future<String> startPlayerFromBuffer(Uint8List dataBuffer) async => _startPlayer('startPlayerFromBuffer', {'dataBuffer': dataBuffer});


  Future<String> stopPlayer() async {

    if (_audio_state != t_AUDIO_STATE.IS_PAUSED && _audio_state != t_AUDIO_STATE.IS_PLAYING ) {
            throw PlayerRunningException('Player is not playing.');
    }

    _audio_state = t_AUDIO_STATE.IS_STOPPED;

    String result = await _channel.invokeMethod('stopPlayer');
    _removePlayerCallback();
    return result;
  }

  Future<String> pausePlayer() async {
  if (_audio_state != t_AUDIO_STATE.IS_PLAYING ) {
          throw PlayerRunningException('Player is not playing.');
  }

          try {
      String result = await _channel.invokeMethod('pausePlayer');
      if (result != null)
              _audio_state = t_AUDIO_STATE.IS_PAUSED;
      return result;
    } catch (err) {
      print('err: $err');
      _audio_state = t_AUDIO_STATE.IS_STOPPED; // In fact _audio_state is in an unknown state
      return err;
    }
  }

  Future<String> resumePlayer() async {
    if (_audio_state != t_AUDIO_STATE.IS_PAUSED ) {
          throw PlayerRunningException('Player is not paused.');
    }

    try {
      String result = await _channel.invokeMethod('resumePlayer');
      if (result != null)
              _audio_state = t_AUDIO_STATE.IS_PLAYING;
      return result;
    } catch (err) {
      print('err: $err');
      return err;
    }
  }

  Future<String> seekToPlayer(int milliSecs) async {
    try {
      String result =
          await _channel.invokeMethod('seekToPlayer', <String, dynamic>{
        'sec': milliSecs,
      });
      return result;
    } catch (err) {
      print('err: $err');
      return err;
    }
  }

  Future<String> setVolume(double volume) async {
    double indexedVolume = Platform.isIOS ? volume * 100 : volume;
    String result = '';
    if (volume < 0.0 || volume > 1.0) {
      result = 'Value of volume should be between 0.0 and 1.0.';
      return result;
    }

    result = await _channel.invokeMethod('setVolume', <String, dynamic>{
      'volume': indexedVolume,
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

class PlayerRunningException implements Exception {
  final String message;
  PlayerRunningException(this.message);
}

class PlayerStoppedException implements Exception {
  final String message;
  PlayerStoppedException(this.message);
}

class RecorderRunningException implements Exception {
  final String message;
  RecorderRunningException(this.message);
}

class RecorderStoppedException implements Exception {
  final String message;
  RecorderStoppedException(this.message);
}

