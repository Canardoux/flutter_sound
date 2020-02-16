import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:io' show Platform;
import 'dart:typed_data' show Uint8List;

import 'package:flutter/services.dart';
import 'package:flutter_sound/android_encoder.dart';
import 'package:flutter_sound/ios_quality.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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

final List<String> defaultPaths = [
  'sound.aac', // DEFAULT
  'sound.aac', // CODEC_AAC
  'sound.opus', // CODEC_OPUS
  'sound.caf', // CODEC_CAF_OPUS
  'sound.mp3', // CODEC_MP3
  'sound.ogg', // CODEC_VORBIS
  'sound.wav', // CODEC_PCM
];

/// Return the file extension for the given path.
/// path can be null. We return null in this case.
String _fileExtension(String path) {
  if (path == null) return null;
  String r = p.extension(path);
  return r;
}

class FlutterSound {
  static const MethodChannel _channel = const MethodChannel('flutter_sound');
  static const MethodChannel _FFmpegChannel =
      const MethodChannel('flutter_ffmpeg');
  static StreamController<RecordStatus> _recorderController;
  static StreamController<double> _dbPeakController;
  static StreamController<PlayStatus> _playerController;
  static StreamController<PlaybackState> _playbackStateChangedController;
  static StreamController<RecordingState> _recordingStateChangedController;

  /// Value ranges from 0 to 120
  Stream<double> get onRecorderDbPeakChanged => _dbPeakController.stream;
  Stream<RecordStatus> get onRecorderStateChanged => _recorderController.stream;
  Stream<PlayStatus> get onPlayerStateChanged => _playerController.stream;

  /// Notifies the listeners whenever the playback state of the audio player
  /// changes.
  ///
  /// This stream stops working when releaseMediaPlayer() is called.
  Stream<PlaybackState> get onPlaybackStateChanged =>
      _playbackStateChangedController.stream;

  /// Notifies the listeners whenever the recorder is recording or stopped.
  Stream<RecordingState> get onRecordingStateChanged =>
      _recordingStateChangedController.stream;

  /// The current state of the playback
  PlaybackState _playbackState;
  PlaybackState get playbackState => _playbackState;

  /// The current state of the recorder
  RecordingState _recordingState;
  RecordingState get recorderState => _recordingState;

  // Whether the handler for when the user tries to skip forward was set
  bool _skipTrackForwardHandlerSet = false;
  // Whether the handler for when the user tries to skip backward was set
  bool _skipTrackBackwardHandlerSet = false;

  static bool isOppOpus =
      false; // Set by startRecorder when the user wants to record an ogg/opus
  static String
      savedUri; // Used by startRecorder/stopRecorder to keep the caller wanted uri
  static String
      tmpUri; // Used by startRecorder/stopRecorder to keep the temporary uri to record CAF

  // The handlers for when a Dart method is invoked from the native code
  Map<String, Function(MethodCall)> _callHandlers =
      <String, Function(MethodCall)>{};

  Future<String> defaultPath(t_CODEC codec) async {
    Directory tempDir = await getTemporaryDirectory();
    File fout = File('${tempDir.path}/${defaultPaths[codec.index]}');
    return fout.path;
  }

  /// Returns true if the flutter_ffmpeg plugin is really plugged
  Future<bool> isFFmpegSupported() async {
    try {
      final Map<dynamic, dynamic> vers =
          await _FFmpegChannel.invokeMethod('getFFmpegVersion');
      final Map<dynamic, dynamic> platform =
          await _FFmpegChannel.invokeMethod('getPlatform');
      final Map<dynamic, dynamic> packageName =
          await _FFmpegChannel.invokeMethod('getPackageName');
      return true;
    } catch (e) {
      return false;
    }
  }

  /// We use here our own ffmpeg "execute" procedure instead of the one provided by the flutter_ffmpeg plugin,
  /// so that the developers not interested by ffmpeg can use flutter_plugin without the flutter_ffmpeg plugin
  /// and without any complain from the link-editor.
  ///
  /// Executes FFmpeg with [commandArguments] provided.
  static Future<int> executeFFmpegWithArguments(List<String> arguments) async {
    try {
      final Map<dynamic, dynamic> result = await _FFmpegChannel.invokeMethod(
          'executeFFmpegWithArguments', {'arguments': arguments});
      return result['rc'];
    } on PlatformException catch (e) {
      print("Plugin error: ${e.message}");
      return -1;
    }
  }

  /// Returns true if the specified encoder is supported by flutter_sound on this platform
  Future<bool> isEncoderSupported(t_CODEC codec) async {
    bool result;
    // For encoding ogg/opus on ios, we need to support two steps :
    // - encode CAF/OPPUS (with native Apple AVFoundation)
    // - remux CAF file format to OPUS file format (with ffmpeg)

    if ((codec == t_CODEC.CODEC_OPUS) && (Platform.isIOS)) {
      if (!await isFFmpegSupported())
        result = false;
      else
        result = await _channel.invokeMethod('isEncoderSupported',
            <String, dynamic>{'codec': t_CODEC.CODEC_CAF_OPUS.index});
    } else
      result = await _channel.invokeMethod(
          'isEncoderSupported', <String, dynamic>{'codec': codec.index});
    return result;
  }

  /// Returns true if the specified decoder is supported by flutter_sound on this platform
  Future<bool> isDecoderSupported(t_CODEC codec) async {
    bool result;
    // For decoding ogg/opus on ios, we need to support two steps :
    // - remux OGG file format to CAF file format (with ffmpeg)
    // - decode CAF/OPPUS (with native Apple AVFoundation)
    if ((codec == t_CODEC.CODEC_OPUS) && (Platform.isIOS)) {
      if (!await isFFmpegSupported())
        result = false;
      else
        result = await _channel.invokeMethod('isDecoderSupported',
            <String, dynamic>{'codec': t_CODEC.CODEC_CAF_OPUS.index});
    } else
      result = await _channel.invokeMethod(
          'isDecoderSupported', <String, dynamic>{'codec': codec.index});
    return result;
  }

  Future<String> setSubscriptionDuration(double sec) {
    return _channel.invokeMethod('setSubscriptionDuration', <String, dynamic>{
      'sec': sec,
    });
  }

  void _setRecorderCallback() {
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

  void _setPlayerCallback() {
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
        if (_playbackStateChangedController != null) {
          _playbackState = PlaybackState.COMPLETED;
          _playbackStateChangedController.add(PlaybackState.COMPLETED);
        }
      }
    });
  }

  void _removeRecorderCallback() {
    if (_recorderController != null) {
      _recorderController
        ..add(null)
        ..close();
      _recorderController = null;
    }
  }

  void _removeRecordingStateCallback() {
    if (_recordingStateChangedController != null) {
      _recordingStateChangedController.close();
      _recordingStateChangedController = null;
    }
  }

  void _removeDbPeakCallback() {
    if (_dbPeakController != null) {
      _dbPeakController
        ..add(null)
        ..close();
      _dbPeakController = null;
    }
  }

  void _removePlayerCallback() {
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

  void _initializeRecorderStreams() {
    if (_recorderController == null) {
      _recorderController = new StreamController.broadcast();
    }
    if (_recordingStateChangedController == null) {
      _recordingStateChangedController = new StreamController.broadcast();
    }
    if (_dbPeakController == null) {
      _dbPeakController = new StreamController.broadcast();
    }
  }

  void _initializePlayerStreams() {
    if (_playerController == null) {
      _playerController = new StreamController.broadcast();
    }
    if (_playbackStateChangedController == null) {
      _playbackStateChangedController = StreamController.broadcast();
    }
  }

  void _updateRecordingState(RecordingState newState) {
    _recordingState = newState;
    _recordingStateChangedController.add(_recordingState);
  }

  Future<String> startRecorder({
    String uri,
    int sampleRate = 16000,
    int numChannels = 1,
    int bitRate = 16000,
    t_CODEC codec = t_CODEC.CODEC_AAC,
    AndroidEncoder androidEncoder = AndroidEncoder.AAC,
    AndroidAudioSource androidAudioSource = AndroidAudioSource.MIC,
    AndroidOutputFormat androidOutputFormat = AndroidOutputFormat.DEFAULT,
    IosQuality iosQuality = IosQuality.LOW,
  }) async {
    if (_recordingState != null && _recordingState != RecordingState.STOPPED) {
      throw new RecorderRunningException('Recorder is not stopped.');
    }
    if (!await isEncoderSupported(codec))
      throw new RecorderRunningException('Codec not supported.');

    if (uri == null) uri = await defaultPath(codec);

    // If we want to record OGG/OPUS on iOS, we record with CAF/OPUS and we remux the CAF file format to a regular OGG/OPUS.
    // We use FFmpeg for that task.
    if ((Platform.isIOS) &&
        ((codec == t_CODEC.CODEC_OPUS) || (_fileExtension(uri) == '.opus'))) {
      savedUri = uri;
      isOppOpus = true;
      codec = t_CODEC.CODEC_CAF_OPUS;
      Directory tempDir = await getTemporaryDirectory();
      File fout = File('${tempDir.path}/flutter_sound-tmp.caf');
      if (fout.existsSync()) // delete the old temporary file if it exists
        await fout.delete();
      uri = fout.path;
      tmpUri = uri;
    } else
      isOppOpus = false;

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

      _updateRecordingState(RecordingState.RECORDING);

      // if the caller wants OGG/OPUS we must remux the temporary file
      if ((result != null) && isOppOpus) {
        return savedUri;
      }
      return result;
    } catch (err) {
      throw new Exception(err);
    }
  }

  Future<String> stopRecorder() async {
    if (_recordingState != RecordingState.RECORDING) {
      throw new RecorderStoppedException('Recorder is not recording.');
    }

    String result = await _channel.invokeMethod('stopRecorder');

    _updateRecordingState(RecordingState.STOPPED);

    _removeRecorderCallback();
    _removeRecordingStateCallback();
    _removeDbPeakCallback();

    if (isOppOpus) {
      // delete the target if it exists (ffmpeg gives an error if the output file already exists)
      File f = File(savedUri);
      if (f.existsSync()) await f.delete();
      // The following ffmpeg instruction re-encode the Apple CAF to OPUS. Unfortunatly we cannot just remix the OPUS data,
      // because Apple does not set the "extradata" in its private OPUS format.
      var rc = await executeFFmpegWithArguments([
        '-i',
        tmpUri,
        '-c:a',
        'libopus',
        savedUri,
      ]); // remux CAF to OGG
      if (rc != 0) return null;
      return savedUri;
    }
    return result;
  }

  /// Plays the given [track]. [canSkipForward] and [canSkipBackward] must be
  /// passed to provide information on whether the user can skip to the next
  /// or to the previous song in the lock screen controls.
  ///
  /// This method should only be used if the audio player has been initialize
  /// with the audio player specific features.
  Future<String> startPlayerFromTrack(
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

    final trackMap = await track.toMap();
    return _channel.invokeMethod('startPlayer', <String, dynamic>{
      'track': trackMap,
      'canSkipForward': _skipTrackForwardHandlerSet && canSkipForward,
      'canSkipBackward': _skipTrackBackwardHandlerSet && canSkipBackward,
    });
  }

  /// Plays the file that [fileUri] points to.
  ///
  /// This method should only be used if the audio player has been initialized
  /// without including the audio player specific features.
  Future<String> startPlayer(String fileUri) {
    final track = Track(trackPath: fileUri);
    return startPlayerFromTrack(track, false, false);
  }

  /// Plays the audio file in [buffer] decoded according to [codec].
  ///
  /// This method should only be used if the audio player has been initialized
  /// without including the audio player specific features.
  Future<String> startPlayerFromBuffer(Uint8List buffer, t_CODEC codec) {
    final track = Track(dataBuffer: buffer, codec: codec);
    return startPlayerFromTrack(track, false, false);
  }

  /// Stops the media player.
  ///
  /// If you would like to continue using the audio player you have to release
  /// and initialize it again.
  Future<String> stopPlayer() {
    if (_playbackState == null || _playbackState == PlaybackState.STOPPED) {
      throw PlayerRunningException('Player is not playing.');
    }

    return _channel.invokeMethod('stopPlayer');
  }

  Future<String> pausePlayer() {
    if (_playbackState != PlaybackState.PLAYING) {
      throw PlayerRunningException('Player is not playing.');
    }

    return _channel.invokeMethod('pausePlayer');
  }

  Future<String> resumePlayer() {
    if (_playbackState != PlaybackState.PAUSED) {
      throw PlayerRunningException('Player is not paused.');
    }

    return _channel.invokeMethod('resumePlayer');
  }

  Future<String> seekToPlayer(int milliSecs) {
    return _channel.invokeMethod('seekToPlayer', <String, dynamic>{
      'sec': milliSecs,
    });
  }

  Future<String> setVolume(double volume) {
    double indexedVolume = Platform.isIOS ? volume * 100 : volume;
    if (volume < 0.0 || volume > 1.0) {
      throw RangeError('Value of volume should be between 0.0 and 1.0.');
    }

    return _channel.invokeMethod('setVolume', <String, dynamic>{
      'volume': indexedVolume,
    });
  }

  /// Defines the interval at which the peak level should be updated.
  /// Default is 0.8 seconds
  Future<String> setDbPeakLevelUpdate(double intervalInSecs) {
    return _channel.invokeMethod('setDbPeakLevelUpdate', <String, dynamic>{
      'intervalInSecs': intervalInSecs,
    });
  }

  /// Enables or disables processing the Peak level in db's. Default is disabled
  Future<String> setDbLevelEnabled(bool enabled) {
    return _channel.invokeMethod('setDbLevelEnabled', <String, dynamic>{
      'enabled': enabled,
    });
  }

  /// Sets the function to call when the user tries to skip forward or backward
  /// from the notification.
  void _setSkipTrackHandlers({
    Function skipForward,
    Function skipBackward,
  }) {
    _skipTrackForwardHandlerSet = skipForward != null;
    _skipTrackBackwardHandlerSet = skipBackward != null;

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
  /// If [includeAudioPlayerFeatures] is true, the audio player specific
  /// features will be included (eg. playback handling via hardware buttons,
  /// lock screen controls). If you initialized the media player with the
  /// audio player features, but you don't want them anymore, you must
  /// re-initialize it. Do the same if you initialized the media player without
  /// the audio player features, but you need them now.
  ///
  /// [skipForwardHandler] and [skipBackwardForward] are functions that are
  /// called when the user tries to skip forward or backward using the
  /// notification controls. They can be null.
  ///
  /// Media player and recorder controls should be displayed only after this
  /// method has finished executing.
  Future<void> initialize(
    bool includeAudioPlayerFeatures, {
    Function skipForwardHandler,
    Function skipBackwardForward,
  }) async {
    try {
      await _channel.invokeMethod('initializeMediaPlayer', <String, dynamic>{
        'includeAudioPlayerFeatures': includeAudioPlayerFeatures,
      });
      _setPlaybackStateUpdateListeners();
      _setSkipTrackHandlers(
        skipForward: skipForwardHandler,
        skipBackward: skipBackwardForward,
      );
      _setPlayerCallback();
      _setRecorderCallback();

      _initializePlayerStreams();
      _initializeRecorderStreams();

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
      throw PlayerNotInitializedException(err);
    }
  }

  /// Resets the media player and cleans up the device resources. This must be
  /// called when the player is no longer needed.
  Future<void> releaseMediaPlayer() async {
    try {
      // Stop the player playback before releasing
      if (_playbackState != null && _playbackState != PlaybackState.STOPPED)
        await stopPlayer();
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

/// The possible states of the recorder
enum RecordingState {
  /// The recorder is currently recording audio
  RECORDING,

  /// The recorder has been stopped because it has finished recording audio
  STOPPED,
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
  String trackPath;

  /// The URL that points to the album art of the track
  final String albumArtUrl;

  /// The codec of the audio file to play. If this parameter's value is null
  /// it will be set to [t_CODEC.DEFAULT].
  t_CODEC codec;

  Track({
    this.trackPath,
    this.dataBuffer,
    this.trackTitle,
    this.trackAuthor,
    this.albumArtUrl,
    this.codec = t_CODEC.DEFAULT,
  }) {
    codec = codec == null ? t_CODEC.DEFAULT : codec;
    assert(trackPath != null || dataBuffer != null,
        'You should provide a path or a buffer for the audio content to play.');
    assert(
        (trackPath != null && dataBuffer == null) ||
            (trackPath == null && dataBuffer != null),
        'You cannot provide both a path and a buffer.');
  }

  /// Convert this object to a [Map] containing the properties of this object
  /// as values.
  Future<Map<String, dynamic>> toMap() async {
    // Re-mux OGG format to play in iOS
    // await _adaptOggToIos(); // TODO: test it

    final map = {
      "path": trackPath,
      "dataBuffer": dataBuffer,
      "title": trackTitle,
      "author": trackAuthor,
      "albumArt": albumArtUrl,
      "bufferCodecIndex": codec?.index,
    };

    return map;
  }

  Future<void> _adaptOggToIos() async {
    // If we want to play OGG/OPUS on iOS, we re-mux the OGG file format to a specific Apple CAF envelope before starting the player.
    // We use FFmpeg for that task.
    if ((Platform.isIOS) &&
        ((codec == t_CODEC.CODEC_OPUS) ||
            (_fileExtension(trackPath) == '.opus'))) {
      Directory tempDir = await getTemporaryDirectory();
      File fout = await File('${tempDir.path}/flutter_sound-tmp.caf');
      if (fout.existsSync()) // delete the old temporary file if it exists
        await fout.delete();
      // The following ffmpeg instruction does not decode and re-encode the file. It just remux the OPUS data into an Apple CAF envelope.
      // It is probably very fast and the user will not notice any delay, even with a very large data.
      // This is the price to pay for the Apple stupidity.
      if (dataBuffer != null) {
        // Write the user buffer into the temporary file
        fout.writeAsBytesSync(dataBuffer);
      } else if (trackPath != null) {
        var rc = await FlutterSound.executeFFmpegWithArguments([
          '-i',
          trackPath,
          '-c:a',
          'copy',
          fout.path,
        ]); // remux OGG to CAF
        if (rc != 0) {
          throw 'FFmpeg exited with code ${rc}';
        }
      }
      // Now we can play Apple CAF/OPUS
      trackPath = fout.path;
    }
  }
}
