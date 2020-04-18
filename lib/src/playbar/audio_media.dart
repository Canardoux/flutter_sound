import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'temp_file_system.dart';

///
enum RecordingStorage {
  ///
  url,

  ///
  file
}

/// Takes a URL or a byte buffer and stores it into a
/// temporary file so that it can be played back.
/// YOU MUST call dispose on this object to ensure the
///  temporary file is removed.
class AudioMedia {
  ///
  RecordingStorage storageType;
  // depending on the storageType one of the following two will contain a value.
  File _tmpRecording;

  ///
  String url;

  final Duration _duration;

  bool _cleanupRequired = false;

  ///
  Completer<bool> stored = Completer<bool>();

  /// Creates an empty AudioMedia object that you can record into.
  AudioMedia.empty() : _duration = Duration.zero {
    storageType = RecordingStorage.file;
    var creating = _createTempFile();
    creating.then((file) {
      _tmpRecording = file;
      stored.complete(true);
    });
  }

  ///
  AudioMedia.fromURL(this.url, {Duration duration = Duration.zero})
      : _duration = duration {
    storageType = RecordingStorage.url;
  }

  ///
  AudioMedia.fromBuffer(ByteBuffer buffer, {Duration duration = Duration.zero})
      : _duration = duration {
    _storeBuffer(buffer);
    storageType = RecordingStorage.file;
  }

  ///
  Future<String> get path async {
    await stored.future;
    return Future.value(_tmpRecording.path);
  }

  void _storeBuffer(ByteBuffer buffer) {
    var tmp = _createTempFile();

    tmp.then((tmpFile) {
      _tmpRecording = tmpFile;

      if (buffer != null) {
        var writing = _tmpRecording
            .writeAsBytes(buffer.asUint8List(0, buffer.lengthInBytes));
        // wait for the write to complete.
        writing.then((_) => stored.complete(true));
      }
    });
  }

  Future<File> _createTempFile() async {
    var tmpRecording = TempFiles().create(TempFileLocations.recordings);

    _cleanupRequired = true;

    return tmpRecording;
  }

  /// This MUST be called to remove the temporary recording.
  void dispose() {
    if (_cleanupRequired) {
      _cleanupRequired = false;
      if (_tmpRecording != null) {
        _tmpRecording.delete();
      }
    }
  }

  ///
  bool isEmpty() {
    return _duration == Duration.zero;
  }
}
