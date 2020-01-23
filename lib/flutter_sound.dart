import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:io' show Platform;
import 'dart:typed_data' show Uint8List;

import 'package:flutter/services.dart';
import 'package:flutter_sound/android_encoder.dart';
import 'package:flutter_sound/ios_quality.dart';

// this enum MUST be synchronized with fluttersound/AudioInterface.java  and ios/Classes/FlutterSoundPlugin.h
enum t_CODEC {
  DEFAULT,
  CODEC_AAC,
  CODEC_OPUS,
  CODEC_CAF_OPUS, // Apple encapsulates its bits in its own special envelope : .caf instead of a regular ogg/opus (.opus). This is completely stupid, this is Apple.
  CODEC_MP3,
  CODEC_VORBIS,
  CODEC_PCM,
}

enum t_AUDIO_STATE {
  IS_STOPPED,
  IS_PAUSED,
  IS_PLAYING,
  IS_RECORDING,
}

class FlutterSound {
  static const MethodChannel _channel = const MethodChannel('flutter_sound');
  static StreamController<RecordStatus> _recorderController;
  static StreamController<double> _dbPeakController;
  static StreamController<PlayStatus> _playerController;
  static StreamController<PlaybackState> _playbackStateChangedController;

  /// Value ranges from 0 to 120
  Stream<double> get onRecorderDbPeakChanged => _dbPeakController.stream;
  Stream<RecordStatus> get onRecorderStateChanged => _recorderController.stream;
  Stream<PlayStatus> get onPlayerStateChanged => _playerController.stream;

  /// Notifies the listeners whenever the playback state of the audio player changes.
  ///
  /// This stream stops working when releaseMediaPlayer() is called.
  Stream<PlaybackState> get onPlaybackStateChanged =>
      _playbackStateChangedController.stream;

  @Deprecated('Prefer to use audio_state variable')
  bool get isPlaying => _isPlaying();
  bool get isRecording => _isRecording();
  t_AUDIO_STATE get audioState => _audio_state;

  /// The current state of the playback
  PlaybackState _playbackState;

  // Whether the handler for when the user tries to skip forward was set
  bool _skipTrackForwardHandlerSet = false;
  // Whether the handler for when the user tries to skip backward was set
  bool _skipTrackBackwardHandlerSet = false;

  // The handlers for when a Dart method is invoked from the native code
  Map<String, Function(MethodCall)> _callHandlers =
      <String, Function(MethodCall)>{};

  bool _isRecording() => _audio_state == t_AUDIO_STATE.IS_RECORDING;
  t_AUDIO_STATE _audio_state = t_AUDIO_STATE.IS_STOPPED;
  bool _isPlaying() =>
      _audio_state == t_AUDIO_STATE.IS_PLAYING ||
      _audio_state == t_AUDIO_STATE.IS_PAUSED;

  Future<bool> isEncoderSupported(t_CODEC codec) async {
    bool result = await _channel.invokeMethod(
        'isEncoderSupported', <String, dynamic>{'codec': codec.index});
    return result;
  }

  Future<bool> isDecoderSupported(t_CODEC codec) async {
    bool result = await _channel.invokeMethod(
        'isDecoderSupported', <String, dynamic>{'codec': codec.index});
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
    _callHandlers.addAll({
      "updateRecorderProgress": (call) {
        Map<String, dynamic> result = json.decode(call.arguments);
        if (_recorderController != null)
          _recorderController.add(new RecordStatus.fromJSON(result));
      },
      "updateDbPeakProgress": (call) {
        if (_dbPeakController != null) _dbPeakController.add(call.arguments);
      }
    });
  }

  Future<void> _setPlayerCallback() async {
    _callHandlers.addAll({
      'updateProgress': (call) {
        Map<String, dynamic> result = jsonDecode(call.arguments);
        if (_playerController != null)
          _playerController.add(new PlayStatus.fromJSON(result));
      },
      'audioPlayerDidFinishPlaying': (call) {
        Map<String, dynamic> result = jsonDecode(call.arguments);
        PlayStatus status = new PlayStatus.fromJSON(result);
        if (status.currentPosition != status.duration) {
          status.currentPosition = status.duration;
        }
        if (_playerController != null) _playerController.add(status);
        _audio_state = t_AUDIO_STATE.IS_STOPPED;
        if (_playbackStateChangedController != null)
          _playbackStateChangedController.add(PlaybackState.COMPLETED);
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

  void _removePlaybackStateCallback() {
    if (_playbackStateChangedController != null) {
      _playbackStateChangedController.close();
      _playbackStateChangedController = null;
    }
  }

  Future<String> startRecorder(
    String uri, {
    int sampleRate,
    int numChannels,
    int bitRate,
    t_CODEC codec = t_CODEC.DEFAULT,
    AndroidEncoder androidEncoder = AndroidEncoder.AAC,
    AndroidAudioSource androidAudioSource = AndroidAudioSource.MIC,
    AndroidOutputFormat androidOutputFormat = AndroidOutputFormat.DEFAULT,
    IosQuality iosQuality = IosQuality.LOW,
  }) async {
    if (_audio_state != t_AUDIO_STATE.IS_STOPPED) {
      throw new RecorderRunningException('Recorder is not stopped.');
    }
    if (!await isEncoderSupported(codec))
      throw new RecorderRunningException('Codec not supported.');
    try {
      String result =
          await _channel.invokeMethod('startRecorder', <String, dynamic>{
        'path': uri,
        'sampleRate': sampleRate,
        'numChannels': numChannels,
        'bitRate': bitRate,
        'codec': codec.index,
        'androidEncoder': androidEncoder?.value,
        'androidAudioSource': androidAudioSource?.value,
        'androidOutputFormat': androidOutputFormat?.value,
        'iosQuality': iosQuality?.value
      });

      if (_recorderController == null) {
        _recorderController = new StreamController.broadcast();
      }
      if (_dbPeakController == null) {
        _dbPeakController = new StreamController.broadcast();
      }

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

  /// Starts playing the given [track], knowing whether the user can skip
  /// forward or backward from this track.
  Future<String> startPlayer(
      Track track, bool canSkipForward, bool canSkipBackward) async {
    // Check whether we can start the player
    if (_playbackState != null &&
        _playbackState != PlaybackState.STOPPED &&
        _playbackState != PlaybackState.COMPLETED) {
      throw PlayerRunningException(
          'Cannot start player in playback state "$_playbackState". The player '
          'must be just initialized or in "${PlaybackState.STOPPED}" '
          'state');
    }

    // Check the current codec is not supported on this platform
    if (!await isDecoderSupported(track.codec)) {
      throw PlayerRunningException('The selected codec is not supported on '
          'this platform.');
    }

    try {
      final trackMap = track.toMap();
      String result =
          await _channel.invokeMethod('startPlayer', <String, dynamic>{
        'track': trackMap,
        'canSkipForward': _skipTrackForwardHandlerSet && canSkipForward,
        'canSkipBackward': _skipTrackBackwardHandlerSet && canSkipBackward,
      });

      _audio_state = t_AUDIO_STATE.IS_PLAYING;

      return result;
    } catch (err) {
      throw Exception(err);
    }
  }

  /// Stops the media player.
  ///
  /// If you would like to continue using the audio player you have to release
  /// and initialize it again.
  Future<String> stopPlayer() async {
    if (_playbackState == null || _playbackState == PlaybackState.STOPPED) {
      throw PlayerRunningException('Player is not playing.');
    }

    _audio_state = t_AUDIO_STATE.IS_STOPPED;

    return await _channel.invokeMethod('stopPlayer');
  }

  Future<String> pausePlayer() async {
    if (_playbackState != PlaybackState.PLAYING) {
      throw PlayerRunningException('Player is not playing.');
    }

    try {
      String result = await _channel.invokeMethod('pausePlayer');
      if (result != null) _audio_state = t_AUDIO_STATE.IS_PAUSED;
      return result;
    } catch (err) {
      print('err: $err');
      _audio_state = t_AUDIO_STATE
          .IS_STOPPED; // In fact _audio_state is in an unknown state
      return err;
    }
  }

  Future<String> resumePlayer() async {
    if (_playbackState != PlaybackState.PAUSED) {
      throw PlayerRunningException('Player is not paused.');
    }

    try {
      String result = await _channel.invokeMethod('resumePlayer');
      if (result != null) _audio_state = t_AUDIO_STATE.IS_PLAYING;
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
    String result =
        await _channel.invokeMethod('setDbPeakLevelUpdate', <String, dynamic>{
      'intervalInSecs': intervalInSecs,
    });
    return result;
  }

  /// Enables or disables processing the Peak level in db's. Default is disabled
  Future<String> setDbLevelEnabled(bool enabled) async {
    String result =
        await _channel.invokeMethod('setDbLevelEnabled', <String, dynamic>{
      'enabled': enabled,
    });
    return result;
  }

  /// Sets the function to call when the user tries to skip forward or backward
  /// from the notification.
  void _setSkipTrackHandlers({
    Function skipForward,
    Function skipBackward,
  }) {
    _skipTrackForwardHandlerSet = skipForward != null;
    _skipTrackBackwardHandlerSet = skipBackward != null;

    /*_channel.setMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case 'skipForward':
          if (skipForward != null) skipForward();
          break;
        case 'skipBackward':
          if (skipBackward != null) skipBackward();
          break;
      }
    });*/

    _callHandlers.addAll({
      'skipForward': (call) {
        if (skipForward != null) skipForward();
      },
      'skipBackward': (call) {
        if (skipBackward != null) skipBackward();
      },
    });
  }

  /// Sets the function to execute when the playback state changes
  void _setPlaybackStateUpdateListeners() {
    _callHandlers.addAll({
      'updatePlaybackState': (call) {
        switch (call.arguments) {
          case 0:
            _playbackState = PlaybackState.PLAYING;
            break;
          case 1:
            _playbackState = PlaybackState.PAUSED;
            break;
          case 2:
            _playbackState = PlaybackState.STOPPED;
            break;
          default:
            throw Exception(
                'An invalid playback state was given to updatePlaybackState.');
        }

        // If the controller has been initialized notify the listeners that the
        // playback state has changed.
        if (_playbackStateChangedController != null) {
          _playbackStateChangedController.add(_playbackState);
        }
      },
    });
  }

  /// Initializes the media player and all the callbacks for the player and the
  /// recorder. This must be called before all other media player and recorder
  /// methods.
  ///
  /// [skipForwardHandler] and [skipBackwardForward] are functions that are
  /// called when the user tries to skip forward or backward using the
  /// notification controls. They can be null.
  ///
  /// Media player and recorder controls should be displayed only after this
  /// method has finished executing.
  Future<void> initialize({
    Function skipForwardHandler,
    Function skipBackwardForward,
  }) async {
    try {
      await _channel.invokeMethod('initializeMediaPlayer');
      _setPlaybackStateUpdateListeners();
      _setSkipTrackHandlers(
        skipForward: skipForwardHandler,
        skipBackward: skipBackwardForward,
      );
      _setPlayerCallback();
      _setRecorderCallback();

      if (_playerController == null) {
        _playerController = new StreamController.broadcast();
      }
      if (_playbackStateChangedController == null) {
        _playbackStateChangedController = StreamController.broadcast();
      }

      // Add the method call handler
      _channel.setMethodCallHandler((MethodCall call) async {
        if (!_callHandlers.containsKey(call.method)) {
          throw new ArgumentError('Unknown method ${call.method}');
        }

        _callHandlers.forEach((methodName, callback) {
          if (methodName == call.method) callback(call);
        });

        return null;
      });
    } catch (err) {
      print('err: $err');
      throw PlayerNotInitializedException(err);
    }
  }

  /// Resets the media player and cleans up the device resources. This must be
  /// called when the player is no longer needed.
  Future<void> releaseMediaPlayer() async {
    try {
      // Stop the player playback before releasing
      if (_playbackState != PlaybackState.STOPPED) await stopPlayer();
      await _channel.invokeMethod('releaseMediaPlayer');

      _removePlaybackStateCallback();
      _removePlayerCallback();
      _playbackState = null;
    } catch (err) {
      print('err: $err');
      throw PlayerNotInitializedException(err);
    }
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

class PlayerNotInitializedException implements Exception {
  final String message;
  PlayerNotInitializedException(this.message);
}

/// The possible states of the playback.
enum PlaybackState {
  /// The audio player is playing an audio file
  PLAYING,

  /// The audio player is currently paused
  PAUSED,

  /// The audio player has been stopped
  STOPPED,

  /// The audio player finished playing the current track
  COMPLETED,
}

/// The track to play in the audio player
class Track {
  /// The title of this track
  final String trackTitle;

  /// The buffer containing the audio file to play
  final Uint8List dataBuffer;

  /// The name of the author of this track
  final String trackAuthor;

  /// The path that points to the track audio file
  final String trackPath;

  /// The URL that points to the album art of the track
  final String albumArtUrl;

  /// The codec of the audio file to play
  final t_CODEC codec;

  Track({
    this.trackPath,
    this.dataBuffer,
    this.trackTitle,
    this.trackAuthor,
    this.albumArtUrl,
    this.codec,
  })  : assert(trackPath != null || dataBuffer != null,
            'You should provide a path or a buffer for the audio content to play.'),
        assert(
            (trackPath != null && dataBuffer == null) ||
                (trackPath == null && dataBuffer != null),
            'You cannot provide both a path and a buffer.');

  /// Convert this object to a [Map] containing the properties of this object
  /// as values.
  Map<String, dynamic> toMap() {
    final map = {
      "path": trackPath,
      "dataBuffer": dataBuffer,
      "title": trackTitle,
      "author": trackAuthor,
      "albumArt": albumArtUrl,
      "bufferCodecIndex": codec.index,
    };

    return map;
  }
}
