/*
 * Copyright 2018, 2019, 2020, 2021 Dooboolab.
 *
 * This file is part of Flutter-Sound.
 *
 * Flutter-Sound is free software: you can redistribute it and/or modify
 * it under the terms of the Mozilla Public License version 2 (MPL2.0),
 * as published by the Mozilla organization.
 *
 * Flutter-Sound is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * MPL General Public License for more details.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data' show Uint8List;

import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

/*

This is a demo of what it is possible to do with Flutter Sound. The code of this demo app is not so simple.

Flutter Sound beginners : you probably should look to [SimplePlayback](fs-ex_simple_playback.html)
and [SimpleRecorder](fs-ex_simple_recorder.html)

The biggest interest of this Demo is that it shows most of the features of Flutter Sound :

* Plays from various media with various codecs
* Records to various media with various codecs
* Pause and Resume control from recording or playback
* Shows how to use a stream for getting the playback \(or recoding\) events
* Shows how to specify a callback function when a playback is terminated,
* Shows how to record to a Stream or playback from a stream
* ...

 */
///
const int cstSAMPLERATE = 8000;
const int cstCHANNELNB = 2;
const int cstBITRATE = 16000;

///
const int cstBLOCKSIZE = 4096;

///
enum Media {
  ///
  file,

  ///
  buffer,

  ///
  asset,

  ///
  stream,

  ///
  remoteExampleFile,
}

///
enum AudioState {
  ///
  isPlaying,

  ///
  isPaused,

  ///
  isStopped,

  ///
  isRecording,

  ///
  isRecordingPaused,
}

/*
///
final exampleAudioFilePathAACAdts =
    //'https://filesamples.com/samples/audio/aac/sample1.aac';
    'https://www.canardoux.xyz/tau_sound/web_example/sample.aac';

///
final exampleAudioFilePathWave =
    'http://5.189.150.137:5000/download_audio/CantinaBand3.wav';

///
final exampleAudioFilePathMP3 =
    'https://file-examples-com.github.io/uploads/2017/11/file_example_MP3_700KB.mp3';

///
final exampleAudioFilePathOPUS =
    'https://whatsapp-inbox-server.clare.ai/api/file/showFile?fileName=data/audios/e3f16eb2-10c3-45c9-b0fa-900c94cbe805.opus&token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJqdGkiOiIxMWI5YjQ3Zi1jMzBjLTRlZDMtYTFhNy1iNmYxNzRkMWQ1NTYiLCJ1bmlxdWVfbmFtZSI6InZlcm5hbEBjbGFyZS5haSIsIm5hbWVpZCI6InZlcm5hbEBjbGFyZS5haSIsImVtYWlsIjoidmVybmFsQGNsYXJlLmFpIiwiaHR0cDovL3NjaGVtYXMubWljcm9zb2Z0LmNvbS93cy8yMDA4LzA2L2lkZW50aXR5L2NsYWltcy9yb2xlIjoiRVhURVJOQUxfQURNSU5JU1RSQVRPUiIsImV4cCI6MjUzNDAyMzAwODAwLCJpc3MiOiJDbGFyZV9BSSIsImF1ZCI6IkNsYXJlX0FJIn0.yXVZ3n_lYYvJ1rGyF2mVh-80HuS0EEp7sQepxn9rGcY';
///
final albumArtPath =
    'https://file-examples-com.github.io/uploads/2017/10/file_example_PNG_500kB.png';
*/
const albumArtPathRemote =
    'https://flutter-sound.canardoux.xyz/web_example/assets/extract/3iob.png';
const albumArtPath =
    'https://file-examples-com.github.io/uploads/2017/10/file_example_PNG_500kB.png';

///
class Demo extends StatefulWidget {
  const Demo({super.key});
  @override
  State<Demo> createState() => _MyAppState();
}

class _MyAppState extends State<Demo> {
  bool _isRecording = false;
  final List<String?> _path = [
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
  ];

  List<String> assetSample = [
    'assets/samples/sample.aac',
    'assets/samples/sample.aac',
    'assets/samples/sample.opus',
    'assets/samples/sample_opus.caf',
    'assets/samples/sample.mp3',
    'assets/samples/sample.ogg',
    'assets/samples/sample_s16_2ch.raw', // Raw PCM int16
    'assets/samples/sample_2ch.wav', // int16 wav stereo
    'assets/samples/sample.aiff',
    'assets/samples/sample_pcm.caf',
    'assets/samples/sample.flac',
    'assets/samples/sample.mp4',
    'assets/samples/sample.amr', // amrNB
    'assets/samples/sample_xxx.amr', // amrWB
    'assets/samples/sample_xxx.pcm', // pcm8
    'assets/samples/sample_f32_2ch.raw', // Raw pcmFloat32
    '', // 'assets/samples/sample_xxx.pcm', // pcmWebM
    'assets/samples/sample_opus.webm', // opusWebM
    'assets/samples/sample_vorbis.webm', // vorbisWebM
    'assets/samples/sample_f32_2ch.wav', // wav Float32 stereo
  ];

  List<String> remoteSample = [
    'https://fs-doc.vercel.app/extract/01.aac', // 'assets/samples/sample.aac',
    'https://fs-doc.vercel.app/extract/01.aac', // 'assets/samples/sample.aac',
    'https://fs-doc.vercel.app/extract/08.opus', // 'assets/samples/sample.opus',
    'https://fs-doc.vercel.app/extract/04-opus.caf', // 'assets/samples/sample_opus.caf',
    'https://fs-doc.vercel.app/extract/05.mp3', // 'assets/samples/sample.mp3',
    'https://fs-doc.vercel.app/extract/07.ogg', // 'assets/samples/sample.ogg',
    'https://fs-doc.vercel.app/extract/sample_s16_2ch.pcm', // Raw PCM int16
    'https://fs-doc.vercel.app/extract/sample_2ch.wav', // int16 wav stereo
    'https://fs-doc.vercel.app/extract/02.aiff', // 'assets/samples/sample.aiff',
    'https://fs-doc.vercel.app/extract/01-pcm.caf', // 'assets/samples/sample_pcm.caf',
    'https://fs-doc.vercel.app/extract/04.flac', // 'assets/samples/sample.flac',
    'https://fs-doc.vercel.app/extract/06.mp4', // 'assets/samples/sample.mp4',
    'https://fs-doc.vercel.app/extract/03.amr', // 'assets/samples/sample.amr', // amrNB
    'https://fs-doc.vercel.app/extract/03.amr', // 'assets/samples/sample_xxx.amr', // amrWB
    'https://fs-doc.vercel.app/extract/09-pcm8.raw', // 'assets/samples/sample_xxx.pcm', // pcm8
    'https://fs-doc.vercel.app/extract/sample_f32_2ch.raw', // Raw pcmFloat32
    '', // pcmWebM
    'https://fs-doc.vercel.app/extract/02-opus.webm', // 'assets/samples/sample_opus.webm', // opusWebM
    'https://fs-doc.vercel.app/extract/03-vorbis.webm', // 'assets/samples/sample_vorbis.webm', // vorbisWebM
    'https://fs-doc.vercel.app/extract/sample_f32_2ch.wav', // wav Float32 stereo
  ];

  StreamSubscription? _recorderSubscription;
  StreamSubscription? _playerSubscription;
  StreamSubscription? _recordingDataSubscription;

  FlutterSoundPlayer playerModule = FlutterSoundPlayer();
  FlutterSoundRecorder recorderModule = FlutterSoundRecorder();

  String _recorderTxt = '00:00:00';
  String _playerTxt = '00:00:00';
  double? _dbLevel;

  double sliderCurrentPosition = 0.0;
  double maxDuration = 1.0;
  Media? _media = Media.remoteExampleFile;
  Codec _codec = Codec.aacMP4;

  bool? _encoderSupported = true; // Optimist
  bool _decoderSupported = true; // Optimist

  StreamController<Uint8List>? recordingDataController;
  IOSink? sink;

  Future<void> _initializeExample() async {
    await playerModule.closePlayer();
    await playerModule.openPlayer();
    await playerModule
        .setSubscriptionDuration(const Duration(milliseconds: 10));
    await recorderModule
        .setSubscriptionDuration(const Duration(milliseconds: 100));
    await initializeDateFormatting();
    await setCodec(_codec);
  }

  Future<void> openTheRecorder() async {
    if (!kIsWeb) {
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw RecordingPermissionException('Microphone permission not granted');
      }
    }
    await recorderModule.openRecorder();

    if (!await recorderModule.isEncoderSupported(_codec) && kIsWeb) {
      _codec = Codec.opusWebM;
    }
  }

  Future<void> init() async {
    await openTheRecorder();
    await _initializeExample();

    if ((!kIsWeb) && Platform.isAndroid) {
      await copyAssets();
    }

    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions:
          AVAudioSessionCategoryOptions.allowBluetooth |
              AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      avAudioSessionRouteSharingPolicy:
          AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.voiceCommunication,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));
  }

  Future<void> copyAssets() async {
    var dataBuffer =
        (await rootBundle.load('assets/canardo.png')).buffer.asUint8List();
    var path = '${await playerModule.getResourcePath()}/assets';
    if (!await Directory(path).exists()) {
      await Directory(path).create(recursive: true);
    }
    await File('$path/canardo.png').writeAsBytes(dataBuffer);
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  void cancelRecorderSubscriptions() {
    if (_recorderSubscription != null) {
      _recorderSubscription!.cancel();
      _recorderSubscription = null;
    }
  }

  void cancelPlayerSubscriptions() {
    if (_playerSubscription != null) {
      _playerSubscription!.cancel();
      _playerSubscription = null;
    }
  }

  void cancelRecordingDataSubscription() {
    if (_recordingDataSubscription != null) {
      _recordingDataSubscription!.cancel();
      _recordingDataSubscription = null;
    }
    recordingDataController = null;
    if (sink != null) {
      sink!.close();
      sink = null;
    }
  }

  @override
  void dispose() {
    super.dispose();
    cancelPlayerSubscriptions();
    cancelRecorderSubscriptions();
    cancelRecordingDataSubscription();
    releaseFlauto();
  }

  Future<void> releaseFlauto() async {
    try {
      await playerModule.closePlayer();
      await recorderModule.closeRecorder();
    } on Exception {
      playerModule.logger.e('Released unsuccessful');
    }
  }

  void startRecorder() async {
    try {
      // Request Microphone permission if needed
      if (!kIsWeb) {
        var status = await Permission.microphone.request();
        if (status != PermissionStatus.granted) {
          throw RecordingPermissionException(
              'Microphone permission not granted');
        }
      }
      var path = '';
      if (!kIsWeb) {
        var tempDir = await getTemporaryDirectory();
        path = '${tempDir.path}/flutter_sound${ext[_codec.index]}';
      } else {
        path = '_flutter_sound${ext[_codec.index]}';
      }

      if (_media == Media.stream) {
        assert(_codec == Codec.pcm16);
        if (!kIsWeb) {
          var outputFile = File(path);
          if (outputFile.existsSync()) {
            await outputFile.delete();
          }
          sink = outputFile.openWrite();
        } else {
          sink = null; // TODO
        }
        recordingDataController = StreamController<Uint8List>();
        _recordingDataSubscription =
            recordingDataController!.stream.listen((buffer) {
          sink!.add(buffer);
        });
        await recorderModule.startRecorder(
          toStream: recordingDataController!.sink,
          bufferSize: 128,
          codec: _codec,
          numChannels: cstCHANNELNB,
          sampleRate: cstSAMPLERATE, // tSTREAMSAMPLERATE, //tSAMPLERATE,
        );
      } else {
        await recorderModule.startRecorder(
          toFile: path,
          codec: _codec,
          bitRate: cstBITRATE,
          numChannels: cstCHANNELNB,
          sampleRate:
              cstSAMPLERATE, // (_codec == Codec.pcm16) ? tSTREAMSAMPLERATE : tSAMPLERATE,
        );
      }
      recorderModule.logger.d('startRecorder');

      _recorderSubscription = recorderModule.onProgress!.listen((e) {
        var date = DateTime.fromMillisecondsSinceEpoch(
            e.duration.inMilliseconds,
            isUtc: true);
        var txt = DateFormat('mm:ss:SS', 'en_GB').format(date);

        setState(() {
          _recorderTxt = txt.substring(0, 8);
          _dbLevel = e.decibels;
        });
      });

      setState(() {
        _isRecording = true;
        _path[_codec.index] = path;
      });
    } on Exception catch (err) {
      recorderModule.logger.e('startRecorder error: $err');
      setState(() {
        stopRecorder();
        _isRecording = false;
        cancelRecordingDataSubscription();
        cancelRecorderSubscriptions();
      });
    }
  }

  void stopRecorder() async {
    try {
      await recorderModule.stopRecorder();
      recorderModule.logger.d('stopRecorder');
      cancelRecorderSubscriptions();
      cancelRecordingDataSubscription();
    } on Exception catch (err) {
      recorderModule.logger.d('stopRecorder error: $err');
    }
    setState(() {
      _isRecording = false;
    });
  }

  Future<bool> fileExists(String path) async {
    return await File(path).exists();
  }

  // In this simple example, we just load a file in memory.This is stupid but just for demonstration  of startPlayerFromBuffer()
  Future<Uint8List?> makeBuffer(String path) async {
    try {
      if (!await fileExists(path)) return null;
      var file = File(path);
      file.openRead();
      var contents = await file.readAsBytes();
      playerModule.logger.i('The file is ${contents.length} bytes long.');
      return contents;
    } on Exception catch (e) {
      playerModule.logger.e(e);
      return null;
    }
  }

  void _addListeners() {
    cancelPlayerSubscriptions();
    _playerSubscription = playerModule.onProgress!.listen((e) {
      maxDuration = e.duration.inMilliseconds.toDouble();
      if (maxDuration <= 0) maxDuration = 0.0;

      sliderCurrentPosition =
          min(e.position.inMilliseconds.toDouble(), maxDuration);
      if (sliderCurrentPosition < 0.0) {
        sliderCurrentPosition = 0.0;
      }

      var date = DateTime.fromMillisecondsSinceEpoch(e.position.inMilliseconds,
          isUtc: true);
      var txt = DateFormat('mm:ss:SS', 'en_GB').format(date);
      setState(() {
        _playerTxt = txt.substring(0, 8);
      });
    });
  }

  Future<Uint8List> _readFileByte(String filePath) async {
    var myUri = Uri.parse(filePath);
    var audioFile = File.fromUri(myUri);
    Uint8List bytes;
    var b = await audioFile.readAsBytes();
    bytes = Uint8List.fromList(b);
    playerModule.logger.d('reading of bytes is completed');
    return bytes;
  }

  Future<Uint8List> getAssetData(String path) async {
    var asset = await rootBundle.load(path);
    return asset.buffer.asUint8List();
  }

  /*
  Future<void> feedHim(String path) async {
    var data = await _readFileByte(path);
    return await playerModule.feedFromStream(data);
  }
*/

  final int blockSize = 4096;
  Future<void> feedHim(String path) async {
    var buffer = await _readFileByte(path);
    //var buffer = await getAssetData('assets/samples/sample.pcm');

    var lnData = 0;
    var totalLength = buffer.length;
    while (totalLength > 0 && !playerModule.isStopped) {
      var bsize = totalLength > blockSize ? blockSize : totalLength;
      await playerModule
          .feedUint8FromStream(buffer.sublist(lnData, lnData + bsize)); // await !!!!
      lnData += bsize;
      totalLength -= bsize;
    }
  }

  Future<void> startPlayer() async {
    try {
      Uint8List? dataBuffer;
      String? audioFilePath;
      var codec = _codec;
      if (_media == Media.asset) {
        dataBuffer = (await rootBundle.load(assetSample[codec.index]))
            .buffer
            .asUint8List();
      } else if (_media == Media.file || _media == Media.stream) {
        // Do we want to play from buffer or from file ?
        if (kIsWeb || await fileExists(_path[codec.index]!)) {
          audioFilePath = _path[codec.index];
        }
      } else if (_media == Media.buffer) {
        // Do we want to play from buffer or from file ?
        if (await fileExists(_path[codec.index]!)) {
          dataBuffer = await makeBuffer(_path[codec.index]!);
          if (dataBuffer == null) {
            throw Exception('Unable to create the buffer');
          }
        }
      } else if (_media == Media.remoteExampleFile) {
        // We have to play an example audio file loaded via a URL
        audioFilePath = remoteSample[_codec.index];
      }

      if (_media == Media.stream) {
        await playerModule.startPlayerFromStream(
          codec: Codec.pcm16, //_codec,
          numChannels: cstCHANNELNB,
          sampleRate: cstSAMPLERATE, // tSTREAMSAMPLERATE, //tSAMPLERATE,
        );
        _addListeners();
        setState(() {});
        await feedHim(audioFilePath!);
        //await finishPlayer();
        await stopPlayer();
        return;
      } else {
        if (audioFilePath != null) {
          await playerModule.startPlayer(
              fromURI: audioFilePath,
              codec: codec,
              numChannels: cstCHANNELNB,
              sampleRate: cstSAMPLERATE, // tSTREAMSAMPLERATE,
              whenFinished: () {
                playerModule.logger.d('Play finished');
                setState(() {});
              });
        } else if (dataBuffer != null) {
          if (codec == Codec.pcm16) {
            dataBuffer = await flutterSoundHelper.pcmToWaveBuffer(
              inputBuffer: dataBuffer,
              numChannels: cstCHANNELNB,
              sampleRate:
                  cstSAMPLERATE, //(_codec == Codec.pcm16 && _media == Media.asset) ? 48000 : cstSAMPLERATE,
            );
            codec = Codec.pcm16WAV;
          }
          await playerModule.startPlayer(
              fromDataBuffer: dataBuffer,
              sampleRate: cstSAMPLERATE,
              numChannels: cstCHANNELNB,
              codec: codec,
              whenFinished: () {
                playerModule.logger.d('Play finished');
                setState(() {});
              });
        }
      }
      _addListeners();
      setState(() {});
      playerModule.logger.d('<--- startPlayer');
    } on Exception catch (err) {
      playerModule.logger.e('error: $err');
      await stopPlayer();
    }
  }

  Future<void> stopPlayer() async {
    try {
      await playerModule.stopPlayer();
      playerModule.logger.d('stopPlayer');
      if (_playerSubscription != null) {
        await _playerSubscription!.cancel();
        _playerSubscription = null;
      }
      sliderCurrentPosition = 0.0;
    } on Exception catch (err) {
      playerModule.logger.d('error: $err');
    }
    setState(() {});
  }

  void pauseResumePlayer() async {
    try {
      if (playerModule.isPlaying) {
        await playerModule.pausePlayer();
      } else {
        await playerModule.resumePlayer();
      }
    } on Exception catch (err) {
      playerModule.logger.e('error: $err');
    }
    setState(() {});
  }

  void pauseResumeRecorder() async {
    try {
      if (recorderModule.isPaused) {
        await recorderModule.resumeRecorder();
      } else {
        await recorderModule.pauseRecorder();
        assert(recorderModule.isPaused);
      }
    } on Exception catch (err) {
      recorderModule.logger.e('error: $err');
    }
    setState(() {});
  }

  Future<void> seekToPlayer(int milliSecs) async {
    //playerModule.logger.d('-->seekToPlayer');
    try {
      if (playerModule.isPlaying) {
        await playerModule.seekToPlayer(Duration(milliseconds: milliSecs));
      }
    } on Exception catch (err) {
      playerModule.logger.e('error: $err');
    }
    setState(() {});
    //playerModule.logger.d('<--seekToPlayer');
  }

  Widget makeDropdowns(BuildContext context) {
    final mediaDropdown = Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(right: 16.0),
          child: Text('Media:'),
        ),
        DropdownButton<Media>(
          value: _media,
          onChanged: (newMedia) {
            _media = newMedia;
            setState(() {});
          },
          items: const <DropdownMenuItem<Media>>[
            DropdownMenuItem<Media>(
              value: Media.file,
              child: Text('File'),
            ),
            DropdownMenuItem<Media>(
              value: Media.buffer,
              child: Text('Buffer'),
            ),
            DropdownMenuItem<Media>(
              value: Media.asset,
              child: Text('Asset'),
            ),
            DropdownMenuItem<Media>(
              value: Media.remoteExampleFile,
              child: Text('Remote Example File'),
            ),
            DropdownMenuItem<Media>(
              value: Media.stream,
              child: Text('Dart Stream'),
            ),
          ],
        ),
      ],
    );

    final codecDropdown = Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(right: 16.0),
          child: Text('Codec:'),
        ),
        DropdownButton<Codec>(
          value: _codec,
          onChanged: (newCodec) {
            setCodec(newCodec!);
            _codec = newCodec;
            setState(() {});
          },
          items: const <DropdownMenuItem<Codec>>[
            DropdownMenuItem<Codec>(
              value: Codec.aacADTS,
              child: Text('AAC/ADTS'),
            ),
            DropdownMenuItem<Codec>(
              value: Codec.opusOGG,
              child: Text('Opus/OGG'),
            ),
            DropdownMenuItem<Codec>(
              value: Codec.opusCAF,
              child: Text('Opus/CAF'),
            ),
            DropdownMenuItem<Codec>(
              value: Codec.mp3,
              child: Text('MP3'),
            ),
            DropdownMenuItem<Codec>(
              value: Codec.vorbisOGG,
              child: Text('Vorbis/OGG'),
            ),
            DropdownMenuItem<Codec>(
              value: Codec.pcm16,
              child: Text('PCM16'),
            ),
            DropdownMenuItem<Codec>(
              value: Codec.pcm16WAV,
              child: Text('PCM16/WAV'),
            ),
            DropdownMenuItem<Codec>(
              value: Codec.pcm16AIFF,
              child: Text('PCM16/AIFF'),
            ),
            DropdownMenuItem<Codec>(
              value: Codec.pcm16CAF,
              child: Text('PCM16/CAF'),
            ),
            DropdownMenuItem<Codec>(
              value: Codec.flac,
              child: Text('FLAC'),
            ),
            DropdownMenuItem<Codec>(
              value: Codec.aacMP4,
              child: Text('AAC/MP4'),
            ),
            DropdownMenuItem<Codec>(
              value: Codec.amrNB,
              child: Text('AMR-NB'),
            ),
            DropdownMenuItem<Codec>(
              value: Codec.amrWB,
              child: Text('AMR-WB '),
            ),
            DropdownMenuItem<Codec>(
              value: Codec.pcm8,
              child: Text('PCM8 '),
            ),
            DropdownMenuItem<Codec>(
              value: Codec.pcmFloat32,
              child: Text('PCM Float32 '),
            ),
            DropdownMenuItem<Codec>(
              value: Codec.pcmWebM,
              child: Text('PCM/WebM '),
            ),
            DropdownMenuItem<Codec>(
              value: Codec.opusWebM,
              child: Text('Opus/WebM '),
            ),
            DropdownMenuItem<Codec>(
              value: Codec.vorbisWebM,
              child: Text('Vorbis/WebM '),
            ),
            DropdownMenuItem<Codec>(
              value: Codec.pcmFloat32WAV,
              child: Text('PCM Float32/WAV'),
            ),
          ],
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: mediaDropdown,
          ),
          codecDropdown,
        ],
      ),
    );
  }

  void Function()? onPauseResumePlayerPressed() {
    if (playerModule.isPaused || playerModule.isPlaying) {
      return pauseResumePlayer;
    }
    return null;
  }

  void Function()? onPauseResumeRecorderPressed() {
    if (recorderModule.isPaused || recorderModule.isRecording) {
      return pauseResumeRecorder;
    }
    return null;
  }

  void Function()? onStopPlayerPressed() {
    return (playerModule.isPlaying || playerModule.isPaused)
        ? stopPlayer
        : null;
  }

  void Function()? onStartPlayerPressed() {
    if (_media == Media.buffer && kIsWeb) {
      return null;
    }
    if (_media == Media.file ||
        _media == Media.stream ||
        _media == Media.buffer) // A file must be already recorded to play it
    {
      if (_path[_codec.index] == null) return null;
    }

    if (_media == Media.stream && _codec != Codec.pcm16) {
      return null;
    }

    // Disable the button if the selected codec is not supported
    if (!(_decoderSupported ||
        _codec == Codec.pcm16 ||
        _codec == Codec.pcmFloat32)) {
      return null;
    }

    return (playerModule.isStopped) ? startPlayer : null;
  }

  void startStopRecorder() {
    if (recorderModule.isRecording || recorderModule.isPaused) {
      stopRecorder();
    } else {
      startRecorder();
    }
  }

  void Function()? onStartRecorderPressed() {
    // Disable the button if the selected codec is not supported
    if (!_encoderSupported!) return null;
    if (_media == Media.stream && _codec != Codec.pcm16) return null;
    return startStopRecorder;
  }

  AssetImage recorderAssetImage() {
    if (onStartRecorderPressed() == null) {
      return const AssetImage('res/icons/ic_mic_disabled.png');
    }
    return (recorderModule.isStopped)
        ? const AssetImage('res/icons/ic_mic.png')
        : const AssetImage('res/icons/ic_stop.png');
  }

  Future<void> setCodec(Codec codec) async {
    _encoderSupported = await recorderModule.isEncoderSupported(codec);
    _decoderSupported = await playerModule.isDecoderSupported(codec);

    setState(() {
      _codec = codec;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dropdowns = makeDropdowns(context);

    Widget recorderSection = Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(top: 12.0, bottom: 16.0),
            child: Text(
              _recorderTxt,
              style: const TextStyle(
                fontSize: 35.0,
                color: Colors.black,
              ),
            ),
          ),
          _isRecording
              ? LinearProgressIndicator(
                  value: 100.0 / 160.0 * (_dbLevel ?? 1) / 100,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.indigo),
                  backgroundColor: Colors.limeAccent)
              : Container(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                width: 56.0,
                height: 50.0,
                child: ClipOval(
                  child: TextButton(
                    onPressed: onStartRecorderPressed(),
                    //padding: EdgeInsets.all(8.0),
                    child: Image(
                      image: recorderAssetImage(),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 56.0,
                height: 50.0,
                child: ClipOval(
                  child: TextButton(
                    onPressed: onPauseResumeRecorderPressed(),
                    //disabledColor: Colors.white,
                    //padding: EdgeInsets.all(8.0),
                    child: Image(
                      width: 36.0,
                      height: 36.0,
                      image: AssetImage(onPauseResumeRecorderPressed() != null
                          ? 'res/icons/ic_pause.png'
                          : 'res/icons/ic_pause_disabled.png'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ]);

    Widget playerSection = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
          margin: const EdgeInsets.only(top: 12.0, bottom: 16.0),
          child: Text(
            _playerTxt,
            style: const TextStyle(
              fontSize: 35.0,
              color: Colors.black,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 56.0,
              height: 50.0,
              child: ClipOval(
                child: TextButton(
                  onPressed: onStartPlayerPressed(),
                  //disabledColor: Colors.white,
                  //padding: EdgeInsets.all(8.0),
                  child: Image(
                    image: AssetImage(onStartPlayerPressed() != null
                        ? 'res/icons/ic_play.png'
                        : 'res/icons/ic_play_disabled.png'),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 56.0,
              height: 50.0,
              child: ClipOval(
                child: TextButton(
                  onPressed: onPauseResumePlayerPressed(),
                  //disabledColor: Colors.white,
                  //padding: EdgeInsets.all(8.0),
                  child: Image(
                    width: 36.0,
                    height: 36.0,
                    image: AssetImage(onPauseResumePlayerPressed() != null
                        ? 'res/icons/ic_pause.png'
                        : 'res/icons/ic_pause_disabled.png'),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 56.0,
              height: 50.0,
              child: ClipOval(
                child: TextButton(
                  onPressed: onStopPlayerPressed(),
                  //disabledColor: Colors.white,
                  //padding: EdgeInsets.all(8.0),
                  child: Image(
                    width: 28.0,
                    height: 28.0,
                    image: AssetImage(onStopPlayerPressed() != null
                        ? 'res/icons/ic_stop.png'
                        : 'res/icons/ic_stop_disabled.png'),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(
            height: 30.0,
            child: Slider(
                value: min(sliderCurrentPosition, maxDuration),
                min: 0.0,
                max: maxDuration,
                onChanged: (value) async {
                  await seekToPlayer(value.toInt());
                },
                divisions: maxDuration == 0.0 ? 1 : maxDuration.toInt())),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Sound Demo'),
      ),
      body: ListView(
        children: <Widget>[
          recorderSection,
          playerSection,
          dropdowns,
        ],
      ),
    );
  }
}
