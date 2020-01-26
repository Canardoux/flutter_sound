import 'dart:async';
import 'dart:core';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data' show Uint8List;
import 'package:flutter/services.dart';
import 'package:flutter_sound/android_encoder.dart';
import 'package:flutter_sound/ios_quality.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';


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


final List<String> defaultPaths =
  [
                'sound.aac',	// DEFAULT
  		'sound.aac',	// CODEC_AAC
  		'sound.opus',	// CODEC_OPUS
  		'sound.caf',	// CODEC_CAF_OPUS
  		'sound.mp3',	// CODEC_MP3
  		'sound.ogg',	// CODEC_VORBIS
  		'sound.wav',	// CODEC_PCM
];

class FlutterSound {
  static const MethodChannel _channel = const MethodChannel('flutter_sound');
  static const MethodChannel _FFmpegChannel = const MethodChannel('flutter_ffmpeg');
  static StreamController<RecordStatus> _recorderController;
  static StreamController<double> _dbPeakController;
  static StreamController<PlayStatus> _playerController;
  static bool isOppOpus = false; // Set by startRecorder when the user wants to record an ogg/opus
  static String savedUri; // Used by startRecorder/stopRecorder to keep the caller wanted uri
  static String tmpUri; // Used by startRecorder/stopRecorder to keep the temporary uri to record CAF

  /// Value ranges from 0 to 120
  Stream<double> get onRecorderDbPeakChanged => _dbPeakController.stream;
  Stream<RecordStatus> get onRecorderStateChanged => _recorderController.stream;
  Stream<PlayStatus> get onPlayerStateChanged => _playerController.stream;
  @Deprecated('Prefer to use audio_state variable')
  bool get isPlaying => _isPlaying();
  bool get isRecording => _isRecording();
  t_AUDIO_STATE get audioState => _audioState;

  bool _isRecording() => _audioState == t_AUDIO_STATE.IS_RECORDING ;
  t_AUDIO_STATE _audioState = t_AUDIO_STATE.IS_STOPPED;
  bool _isPlaying() => _audioState == t_AUDIO_STATE.IS_PLAYING || _audioState == t_AUDIO_STATE.IS_PAUSED;

  Future<String> defaultPath(t_CODEC codec) async
  {
    Directory tempDir = await getTemporaryDirectory ();
    File fout = await File ('${tempDir.path}/${defaultPaths[codec.index]}');
    return fout.path;
  }


  /// Returns true if the flutter_ffmpeg plugin is really plugged
  Future<bool>isFFmpegSupported() async
  {
    try {
      final Map<dynamic, dynamic> vers = await _FFmpegChannel.invokeMethod('getFFmpegVersion');
      final Map<dynamic, dynamic> platform = await _FFmpegChannel.invokeMethod('getPlatform');
      final Map<dynamic, dynamic> packageName = await _FFmpegChannel.invokeMethod('getPackageName');
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
  Future<int> executeFFmpegWithArguments(List<String> arguments) async {
    try {
      final Map<dynamic, dynamic> result = await _FFmpegChannel
          .invokeMethod('executeFFmpegWithArguments', {'arguments': arguments});
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

      if ( (codec == t_CODEC.CODEC_OPUS) &&  (Platform.isIOS) ){
        if ( ! await isFFmpegSupported() )
          result = false;
        else
          result = await _channel.invokeMethod('isEncoderSupported', <String, dynamic> { 'codec': t_CODEC.CODEC_CAF_OPUS.index } );
      } else
        result = await _channel.invokeMethod('isEncoderSupported', <String, dynamic> { 'codec': codec.index } );
      return result;
  }


  /// Returns true if the specified decoder is supported by flutter_sound on this platform
  Future<bool>  isDecoderSupported(t_CODEC codec) async {
    bool result;
    // For decoding ogg/opus on ios, we need to support two steps :
    // - remux OGG file format to CAF file format (with ffmpeg)
    // - decode CAF/OPPUS (with native Apple AVFoundation)
    if ( (codec == t_CODEC.CODEC_OPUS) &&  (Platform.isIOS) ){
        if ( ! await isFFmpegSupported() )
          result = false;
        else
          result = await _channel.invokeMethod('isDecoderSupported', <String, dynamic> { 'codec': t_CODEC.CODEC_CAF_OPUS.index } );
    } else
        result = await _channel.invokeMethod('isDecoderSupported', <String, dynamic> { 'codec': codec.index } );
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
          _audioState = t_AUDIO_STATE.IS_STOPPED;
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
        String uri = null,
        int sampleRate = 16000, int numChannels = 1, int bitRate = 16000,
        t_CODEC codec = t_CODEC.CODEC_AAC,
        AndroidEncoder androidEncoder = AndroidEncoder.AAC,
        AndroidAudioSource androidAudioSource = AndroidAudioSource.MIC,
        AndroidOutputFormat androidOutputFormat = AndroidOutputFormat.DEFAULT,
        IosQuality iosQuality = IosQuality.LOW,
      }) async {

    // Request Microphone permission if needed
    Map<PermissionGroup, PermissionStatus> permission = await PermissionHandler().requestPermissions([PermissionGroup.microphone]);
    if (permission[PermissionGroup.microphone]!= PermissionStatus.granted)
      throw new Exception("Microphone permission not granted");

    if (_audioState != t_AUDIO_STATE.IS_STOPPED) {
      throw new RecorderRunningException('Recorder is not stopped.');
    }
    if (! await isEncoderSupported(codec))
      throw new RecorderRunningException('Codec not supported.');

    if (uri == null)
      uri = await defaultPath(codec);


    // If we want to record OGG/OPUS on iOS, we record with CAF/OPUS and we remux the CAF file format to a regular OGG/OPUS.
    // We use FFmpeg for that task.
    if ( (Platform.isIOS) &&
        ( (codec == t_CODEC.CODEC_OPUS) || (_fileExtension(uri) == '.opus') )  ) {
      savedUri = uri;
      isOppOpus = true;
      codec = t_CODEC.CODEC_CAF_OPUS;
      Directory tempDir = await getTemporaryDirectory ();
      File fout = await File ('${tempDir.path}/flutter_sound-tmp.caf');
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
      _setRecorderCallback();
      _audioState = t_AUDIO_STATE.IS_RECORDING;
      // if the caller wants OGG/OPUS we must remux the temporary file
      if ( (result != null) && isOppOpus) {
         return savedUri;
      }
      return result;
    } catch (err) {
      throw new Exception(err);
    }
  }

  Future<String> stopRecorder() async {
    if (_audioState != t_AUDIO_STATE.IS_RECORDING) {
      throw new RecorderStoppedException('Recorder is not recording.');
    }

    String result = await _channel.invokeMethod('stopRecorder');

    _audioState = t_AUDIO_STATE.IS_STOPPED;
    _removeRecorderCallback();
    _removeDbPeakCallback();

    if (isOppOpus) {
      // delete the target if it exists (ffmpeg gives an error if the output file already exists)
      File f = File(savedUri);
      if (f.existsSync())
        await f.delete();
      // The following ffmpeg instruction re-encode the Apple CAF to OPUS. Unfortunatly we cannot just remix the OPUS data,
      // because Apple does not set the "extradata" in its private OPUS format.
      var rc = await executeFFmpegWithArguments (['-i', tmpUri, '-c:a', 'libopus', savedUri,]); // remux CAF to OGG
      if (rc != 0)
        return null;
      return savedUri;
    }
    return result;
  }

  /// Return the file extension for the given path.
  /// path can be null. We return null in this case.
  String _fileExtension(String path) {
      if (path == null )
        return null;
      String r =  p.extension(path);
      return r;
  }

  Future<String> _startPlayer(String method, Map <String, dynamic> what) async {
    String result;
    if (_audioState == t_AUDIO_STATE.IS_PAUSED) {
      this.resumePlayer();
      _audioState = t_AUDIO_STATE.IS_PLAYING;
      return 'Player resumed';
      // throw PlayerRunningException('Player is already playing.');
    }
    if (_audioState != t_AUDIO_STATE.IS_STOPPED) {
            throw PlayerRunningException('Player is not stopped.');
    }

    try
    {
      t_CODEC codec = what['codec'];
      String path = what['path']; // can be null
      Uint8List dataBuffer = what['dataBuffer']; // can be null
      if (codec != null)
        what['codec'] = codec.index; // Flutter cannot transfer an enum to a native plugin. We use an integer instead

      // If we want to play OGG/OPUS on iOS, we remux the OGG file format to a specific Apple CAF envelope before starting the player.
      // We use FFmpeg for that task.
      if ( (Platform.isIOS) &&
            ( (codec == t_CODEC.CODEC_OPUS) || (_fileExtension(path) == '.opus') )  ) {
          Directory tempDir = await getTemporaryDirectory ();
          File fout = await File ('${tempDir.path}/flutter_sound-tmp.caf');
          if (fout.existsSync()) // delete the old temporary file if it exists
            await fout.delete();
          // The following ffmpeg instruction does not decode and re-encode the file. It just remux the OPUS data into an Apple CAF envelope.
          // It is probably very fast and the user will not notice any delay, even with a very large data.
          // This is the price to pay for the Apple stupidity.
          var rc = await executeFFmpegWithArguments (['-i', path, '-c:a', 'copy', fout.path,]); // remux OGG to CAF
          if (rc != 0)
            return null;
          // Now we can play Apple CAF/OPUS
          result = await _channel.invokeMethod ('startPlayer', {'path': fout.path});
      } else
        result = await _channel.invokeMethod(method, what);

      if (result != null)
      {
        print ('startPlayer result: $result');
        _setPlayerCallback ();
        _audioState = t_AUDIO_STATE.IS_PLAYING;
      }

      return result;
    } catch (err) {
      throw Exception(err);
    }
  }


  Future<String> startPlayer(String uri) async => _startPlayer('startPlayer', {'path': uri});

  Future<String> startPlayerFromBuffer(Uint8List dataBuffer, {t_CODEC codec = null,}) async {

    // If we want to play OGG/OPUS on iOS, we need to remux the OGG file format to a specific Apple CAF envelope before starting the player.
    // We write the data in a temporary file before calling ffmpeg.
    if ( (codec == t_CODEC.CODEC_OPUS) && (Platform.isIOS) ) {
      Directory tempDir = await getTemporaryDirectory();
      File inputFile = await File('${tempDir.path}/flutter_sound-tmp.opus');
      if (inputFile.existsSync())
        await inputFile.delete();
      inputFile.writeAsBytesSync(dataBuffer); // Write the user buffer into the temporary file
      // Now we can play the temporary file
      return await _startPlayer('startPlayer', {'path': inputFile.path, 'codec': codec,}); // And play something that Apple will be happy with.
    } else
      return await _startPlayer ('startPlayerFromBuffer', {'dataBuffer': dataBuffer, 'codec': codec});
  }


  Future<String> stopPlayer() async {

    if (_audioState != t_AUDIO_STATE.IS_PAUSED && _audioState != t_AUDIO_STATE.IS_PLAYING ) {
            throw PlayerRunningException('Player is not playing.');
    }

    _audioState = t_AUDIO_STATE.IS_STOPPED;

    String result = await _channel.invokeMethod('stopPlayer');
    _removePlayerCallback();
    return result;
  }

  Future<String> pausePlayer() async {
  if (_audioState != t_AUDIO_STATE.IS_PLAYING ) {
          throw PlayerRunningException('Player is not playing.');
  }

          try {
      String result = await _channel.invokeMethod('pausePlayer');
      if (result != null)
        _audioState = t_AUDIO_STATE.IS_PAUSED;
      return result;
    } catch (err) {
      print('err: $err');
      _audioState = t_AUDIO_STATE.IS_STOPPED; // In fact _audioState is in an unknown state
      throw Exception(err);;
    }
  }

  Future<String> resumePlayer() async {
    if (_audioState != t_AUDIO_STATE.IS_PAUSED ) {
          throw PlayerRunningException('Player is not paused.');
    }

    try {
      String result = await _channel.invokeMethod('resumePlayer');
      if (result != null)
        _audioState = t_AUDIO_STATE.IS_PLAYING;
      return result;
    } catch (err) {
      print('err: $err');
      throw Exception(err);;
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
      throw Exception(err);;
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

