/*
 * Copyright 2018, 2019, 2020 Dooboolab.
 *
 * This file is part of Flutter-Sound.
 *
 * Flutter-Sound is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License version 3 (LGPL-V3), as published by
 * the Free Software Foundation.
 *
 * Flutter-Sound is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with Flutter-Sound.  If not, see <https://www.gnu.org/licenses/>.
 */



import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/src/session.dart';

enum RecorderState {
  isStopped,
  isPaused,
  isRecording,
}

enum AudioSource {
  defaultSource,
  microphone,
  voiceDownlink, // (if someone can explain me what it is, I will be grateful ;-) )
  camCorder,
  remote_submix,
  unprocessed,
  voice_call,
  voice_communication,
  voice_performance,
  voice_recognition,
  voiceUpLink,
  bluetoothHFP,
  headsetMic,
  lineIn,
}

FlautoRecorderPlugin flautoRecorderPlugin; // Singleton, lazy initialized

class FlautoRecorderPlugin  extends FlautoPlugin {

  /* ctor */  FlautoRecorderPlugin() {
    setCallback();
  }

  void setCallback() {
    channel = const MethodChannel('com.dooboolab.flutter_sound_recorder');
    channel.setMethodCallHandler((MethodCall call) {
      // This lambda function is necessary because channelMethodCallHandler is a virtual function
      return channelMethodCallHandler(call);
    });
  }


  Future<dynamic> channelMethodCallHandler(MethodCall call) {
    FlutterSoundRecorder aRecorder = getSession (call) as FlutterSoundRecorder;

    switch (call.method) {
      case "updateRecorderProgress":
        {
          aRecorder.updateRecorderProgress(call.arguments as Map<dynamic, dynamic>);
        }
        break;

      default:
        throw ArgumentError('Unknown method ${call.method}');
    }
    return null;
  }
}

class FlutterSoundRecorder extends Session {
  RecorderState recorderState = RecorderState.isStopped;
  StreamController<RecordingDisposition> _recorderController;


  ///
  Stream<RecordingDisposition> dispositionStream() {
    return (_recorderController != null) ? _recorderController.stream : null;
  }
  Stream<RecordingDisposition> get onProgress => (_recorderController != null) ? _recorderController.stream : null;



  bool isOggOpus =
      false; // Set by startRecorder when the user wants to record an ogg/opus
  String
      savedUri; // Used by startRecorder/stopRecorder to keep the caller wanted uri
  String
      tmpUri; // Used by startRecorder/stopRecorder to keep the temporary uri to record CAF

  bool get isRecording => (recorderState == RecorderState.isRecording);

  bool get isStopped => (recorderState == RecorderState.isStopped);

  bool get isPaused => (recorderState == RecorderState.isPaused);



  //FlutterSoundRecorder() {}

  FlautoPlugin getPlugin() => flautoRecorderPlugin;

  Future<FlutterSoundRecorder> openAudioSession( {
                                                   AudioFocus focus = AudioFocus.requestFocusTransient,
                                                   SessionCategory category = SessionCategory.playAndRecord,
                                                   SessionMode mode = SessionMode.modeDefault,
                                                   AudioDevice device = AudioDevice.speaker}) async {
    if (isInited == Initialized.fullyInitialized) {
      return this;
    }
    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }

    isInited = Initialized.initializationInProgress;

    if (flautoRecorderPlugin == null) {
      flautoRecorderPlugin = FlautoRecorderPlugin();
    } // The lazy singleton
    _setRecorderCallback();
    openSession();
    await invokeMethod('initializeFlautoRecorder', <String, dynamic>{'focus': focus.index, 'category': category.index, 'mode': mode.index, 'device': device.index,});

    isInited = Initialized.fullyInitialized;
    return this;
  }

  Future<void> closeAudioSession() async {
    if (isInited == Initialized.notInitialized) {
      return this;
    }
    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    await stopRecorder();
    isInited = Initialized.initializationInProgress;
    _removeRecorderCallback(); // _recorderController will be closed by this function
    await invokeMethod('releaseFlautoRecorder', <String, dynamic>{});
    closeSession();
    isInited = Initialized.notInitialized;
  }

  void updateRecorderProgress(Map call) {
    int duration = call['duration'] as int;
    double dbPeakLevel = call['dbPeakLevel'] as double;
    _recorderController.add(RecordingDisposition( Duration(milliseconds: duration), dbPeakLevel ,) );
  }


  /// Returns true if the specified encoder is supported by flutter_sound on this platform
  Future<bool> isEncoderSupported(Codec codec) async {
    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (isInited != Initialized.fullyInitialized) {
      throw (_notOpen());
    }

    bool result;
    // For encoding ogg/opus on ios, we need to support two steps :
    // - encode CAF/OPPUS (with native Apple AVFoundation)
    // - remux CAF file format to OPUS file format (with ffmpeg)

    if ((codec == Codec.opusOGG) && (Platform.isIOS)) {
      //if (!await isFFmpegSupported( ))
      //result = false;
      //else
      result = await invokeMethod('isEncoderSupported',
          <String, dynamic>{'codec': Codec.opusCAF.index}) as bool;
    } else {
      result = await invokeMethod(
              'isEncoderSupported', <String, dynamic>{'codec': codec.index})
          as bool;
    }
    return result;
  }

  Future<void> _setRecorderCallback()  {
    if (_recorderController == null) {
      _recorderController = StreamController.broadcast();
    }

  }

  void _removeRecorderCallback() {
    if (_recorderController != null) {
      _recorderController
        //..add(null) // We keep that strange line for backward compatibility
        ..close();
      _recorderController = null;
    }
  }




  /// Sets the frequency at which duration updates are sent to
  /// duration listeners.
  /// The default is every 10 milliseconds.
  Future<void> setSubscriptionDuration(Duration duration) async {
    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (isInited != Initialized.fullyInitialized) {
      throw (_notOpen());
    }
    await invokeMethod('setSubscriptionDuration', <String, dynamic>{
      'duration': duration.inMilliseconds,
    }) ;
  }


  /// Return the file extension for the given path.
  /// path can be null. We return null in this case.
  String fileExtension(String path) {
    if (path == null) return null;
    var r = p.extension(path);
    return r;
  }

  Future<String> defaultPath(Codec codec) async {
    var tempDir = await getTemporaryDirectory();
    var fout = File('${tempDir.path}/flutter_sound${ext[codec.index]}');
    return fout.path;
  }

  Future<void> startRecorder( {
    Codec codec = Codec.defaultCodec,
    String toFile = null,
    Stream toStream = null,
    int sampleRate = 16000,
    int numChannels = 1,
    int bitRate = 16000,
    AudioSource audioSource = AudioSource.defaultSource,
  }) async {
    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (isInited != Initialized.fullyInitialized) {
      throw (_notOpen());
    }
    // Request Microphone permission if needed
    /*
    if (requestPermission) {
      PermissionStatus status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw RecordingPermissionException("Microphone permission not granted");
      }
    }
    */
    if (recorderState != null && recorderState != RecorderState.isStopped) {
      throw RecorderRunningException('Recorder is not stopped.');
    }
    if (!await isEncoderSupported(codec)) {
      throw CodecNotSupportedException('Codec not supported.');
    }

    //if (toFile == null) toFile = await defaultPath(codec);

    // If we want to record OGG/OPUS on iOS, we record with CAF/OPUS and we remux the CAF file format to a regular OGG/OPUS.
    // We use FFmpeg for that task.
    if ((Platform.isIOS) &&
        ((codec == Codec.opusOGG) || (fileExtension(toFile) == '.opus'))) {
      savedUri = toFile;
      isOggOpus = true;
      codec = Codec.opusCAF;
      var tempDir = await getTemporaryDirectory();
      var fout = File('${tempDir.path}/$slotNo-flutter_sound-tmp.caf');
      toFile = fout.path;
      tmpUri = toFile;
    } else {
      isOggOpus = false;
    }

    try {
      var param = <String, dynamic>{
        'path': toFile,
        'sampleRate': sampleRate,
        'numChannels': numChannels,
        'bitRate': bitRate,
        'codec': codec.index,
        'toStream': toStream,
        'audioSource': audioSource.index,
      };

      await invokeMethod('startRecorder', param);

      recorderState = RecorderState.isRecording;
      // if the caller wants OGG/OPUS we must remux the temporary file
      if ( isOggOpus) {
        return savedUri;
      }
    } catch (err) {
      throw Exception(err);
    }
  }

  Future<void> stopRecorder() async {
    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (isInited != Initialized.fullyInitialized) {
      throw (_notOpen());
    }
    await invokeMethod('stopRecorder', <String, dynamic>{}) as String;

    recorderState = RecorderState.isStopped;

    if (isOggOpus) {
      // delete the target if it exists
      // (ffmpeg gives an error if the output file already exists)
      File f = File(savedUri);
      if (f.existsSync()) await f.delete();
      // The following ffmpeg instruction re-encode the Apple CAF to OPUS.
      // Unfortunately we cannot just remix the OPUS data,
      // because Apple does not set the "extradata" in its private OPUS format.
      // It will be good if we can improve this...
      int rc = await flutterSoundHelper.executeFFmpegWithArguments([
        '-loglevel',
        'error',
        '-y',
        '-i',
        tmpUri,
        '-c:a',
        'libopus',
        savedUri,
      ]); // remux CAF to OGG
      if (rc != 0) return null;
      return savedUri;
    }
  }


  Future<void> setAudioFocus( {
                                AudioFocus focus = AudioFocus.requestFocusTransient,
                                SessionCategory category = SessionCategory.playAndRecord,
                                SessionMode mode = SessionMode.modeDefault,
                                AudioDevice device = AudioDevice.speaker}) async {
    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (isInited != Initialized.fullyInitialized) {
      throw (_notOpen());
    }
    await invokeMethod('setAudioFocus', <String, dynamic>{'focus':focus.index, 'category': category.index, 'mode': mode.index, 'device':device.index});
  }


  Future<void> pauseRecorder() async {
    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (isInited != Initialized.fullyInitialized) {
      throw (_notOpen());
    }
    await invokeMethod('pauseRecorder', <String, dynamic>{}) as String;
    recorderState = RecorderState.isPaused;
  }

  Future<void> resumeRecorder() async {
    if (isInited == Initialized.initializationInProgress) {
      throw (_InitializationInProgress());
    }
    if (isInited != Initialized.fullyInitialized) {
      throw (_notOpen());
    }
    await invokeMethod('resumeRecorder', <String, dynamic>{}) as String;
    recorderState = RecorderState.isRecording;
  }
}

/// Holds point in time details of the recording disposition
/// including the current duration and decibels.
/// Use the [dispositionStream] method to subscribe to a stream
/// of [RecordingDisposition] will be emmited whilst recording.
class RecordingDisposition {
  /// The total duration of the recording at this point in time.
  final Duration duration;

  /// The volume of the audio being captured
  /// at this point in time.
  /// Value ranges from 0 to 120
  final double decibels;

  /// ctor
  RecordingDisposition(this.duration, this.decibels);

  /// use this ctor to as the initial value when building
  /// a [StreamBuilder]
  RecordingDisposition.zero()
              : duration = Duration(seconds: 0),
                decibels = 0;

  @override
  String toString() {
    return 'duration: $duration decibels: $decibels';
  }
}


class RecorderException implements Exception {
  final String _message;

  RecorderException(this._message);

  String get message => _message;
}

class RecorderRunningException extends RecorderException {
  RecorderRunningException(String message) : super(message);
}

class CodecNotSupportedException extends RecorderException {
  CodecNotSupportedException(String message) : super(message);
}

class RecordingPermissionException extends RecorderException {
  RecordingPermissionException(String message) : super(message);
}

class _InitializationInProgress implements Exception {
  _InitializationInProgress() {
    print('An initialization is currently already in progress.');
  }
}


class _notOpen implements Exception {
  _notOpen() {
    print('Audio session is not open');
  }
}
