import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../codec.dart';
import '../playback_disposition.dart';
import '../util/codec_conversions.dart';
import '../util/temp_media_file.dart';
import 'downloader.dart';
import 'file_util.dart';

/// Provide a set of tools to manage audio data.
/// Used for Tracks and Recording.
/// This class is NOT part of the public api.
class Audio {
  final List<TempMediaFile> _tempMediaFiles = [];

  ///
  Codec codec;

  /// An Audio instance can be created as one of :
  ///  * url
  ///  * path
  ///  * data buffer.
  ///
  String url;

  ///
  String path;

  ///
  Uint8List _dataBuffer;

  /// During process of an audio file it may need to pass
  /// through multiple temporary files for processing.
  /// If that occurs this path points the final temporary file.
  /// [_storagePath] will have a value of [_onDisk] is true.
  String _storagePath;

  /// Indicates if the audio media is stored on disk
  bool _onDisk = false;

  /// Indicates that [prepareStream] has been called and the stream
  /// is ready to play. Used to stop unnecessary calls to [prepareStream].
  bool _prepared = false;

  /// [true] if the audio is stored in the file system.
  /// This can be because it was passed as a path
  /// or because we had to force it to disk for code conversion
  /// or similar operations.
  /// Currently buffered data is always forced to disk.
  bool get onDisk => _onDisk;

  /// returns the length of the audio in bytes
  int get length {
    if (_onDisk) return File(_storagePath).lengthSync();
    if (isBuffer) return _dataBuffer.length;
    if (isFile) return File(path).lengthSync();

    // if its a URL and its not [_onDisk] then we don't know its length.
    return 0;
  }

  /// Converts the underlying storage into a buffer.
  /// This may take a significant amount of time if the
  /// storage is a remote url.
  /// Once called the audio will be cached so subsequent calls
  /// will return immediately.
  Future<Uint8List> get asBuffer async {
    if (isBuffer || _dataBuffer != null) {
      return _dataBuffer;
    }

    if (isFile) {
      _dataBuffer = await FileUtil().readIntoBuffer(_storagePath);
    }

    if (isURL) {
      TempMediaFile tempMediaFile;
      try {
        var tempMediaFile = TempMediaFile.empty();

        await Downloader().download(url, tempMediaFile.path, (disposition) {});

        _dataBuffer = await FileUtil().readIntoBuffer(tempMediaFile.path);
      } finally {
        tempMediaFile?.delete();
      }
    }
    return _dataBuffer;
  }

  /// Returns the location of the audio media on disk.
  String get storagePath {
    assert(_onDisk);
    return _storagePath;
  }

  /// Caches the duration so that we don't have to calculate
  /// it each time [duration] is called.
  Duration _duration;

  /// Returns the duration of the audio managed by this instances
  ///
  /// The first time this is called it can be quite an expensive
  /// operation as we have to process the audio to determine its
  /// duration.
  ///
  /// If the audio was passed via a call to [fromBuffer] then we
  /// have to first write the buffer to a file before we can
  /// process it. This may be optimised in future versions.
  ///
  /// After the first call we cache the duration so responses are
  /// instant.
  //ignore: avoid_setters_without_getters
  Future<Duration> get duration async {
    if (_duration == null) {
      _duration = Duration.zero;

      /// will write to disk if its a databuffer.
      _writeBufferToDisk((disposition) {});

      if (_onDisk && FileUtil().fileLength(_storagePath) > 0) {
        _duration = await CodecHelper.duration(codec, _storagePath);
      }
    }
    return _duration;
  }

  //ignore: use_setters_to_change_properties
  /// This method should ONLY be used by the SoundRecorder
  /// to update a tracks duration as we record into the track.
  /// The duration is normally calculated when the [duration] getter is called.
  void setDuration(Duration duration) {
    _duration = duration;
  }

  ///
  Audio.fromFile(this.path, Codec codec) {
    _storagePath = path;
    _onDisk = true;
    this.codec = determineCodec(path, codec);
  }

  ///
  Audio.fromURL(this.url, Codec codec) {
    this.codec = determineCodec(url, codec);
  }

  ///
  Audio.fromBuffer(this._dataBuffer, this.codec) {
    if (codec == null) {
      throw CodecNotSupportedException('You must pass in a codec.');
    }
  }

  /// returns true if the Audio's media is located in via
  /// a file Path.
  bool get isFile => path != null;

  /// returns true if the Audio's media is located in via
  /// a URL
  bool get isURL => url != null;

  /// returns true if the Audio's media is located in a
  /// databuffer  (as opposed to a URI)
  bool get isBuffer => _dataBuffer != null;

  /// returns the databuffer if there is one.
  /// see [isBuffer] to check if the audio is in a data buffer.
  Uint8List get buffer => _dataBuffer;

  ///
  static Codec determineCodec(String uri, Codec codec) {
    if (codec == null || codec == Codec.fromExtension) {
      codec = CodecHelper.determineCodec(uri);
      if (codec == null) {
        throw CodecNotSupportedException(
            "The uri's extension does not match any"
            " of the supported extensions. "
            'You must pass in a codec.');
      }
    }
    return codec;
  }

  /// Does any preparatory work required on a stream before it can be played.
  /// This includes converting databuffers to paths and
  /// any re-encoding required.
  ///
  /// This method can be called multiple times and will only
  /// do the conversions once.
  Future prepareStream(LoadingProgress loadingProgress) async {
    if (_prepared) {
      return;
    }
    // each stage reports a progress value between 0.0 and 1.0.
    // If we are running multiple stages we need to divide that value
    // by the no. of stages so progress is spread across all of the
    // stages.
    var stages = 1;
    var stage = 1;

    if (Platform.isIOS && codec == Codec.opusOGG) stages++;

    /// we can do no preparation for the url.
    if (isURL) {
      await _downloadURL((disposition) {
        _forwardStagedProgress(loadingProgress, disposition, stage, stages);
      });
      stage++;
    }

    // android doesn't support data buffers so we must convert
    // to a file.
    // iOS doesn't support opus so we must convert to a file so we
    /// remux it.
    if (isBuffer &&
        (Platform.isAndroid || Platform.isIOS && codec == Codec.opusOGG)) {
      await _writeBufferToDisk((disposition) {
        _forwardStagedProgress(loadingProgress, disposition, stage, stages);
      });
      stage++;
    }

    // If we want to play OGG/OPUS on iOS, we remux the OGG file format to a specific Apple CAF envelope before starting the player.
    // We use FFmpeg for that task.
    if (Platform.isIOS && codec == Codec.opusOGG) {
      var tempMediaFile = TempMediaFile(await CodecConversions.opusToCafOpus(
          fromPath: _storagePath,
          progress: (disposition) {
            _forwardStagedProgress(loadingProgress, disposition, stage, stages);
          }));
      stage++;
      _tempMediaFiles.add(tempMediaFile);

      // update the codec so we won't reencode again.
      codec = Codec.cafOpus;

      /// update the path to the new file.
      _storagePath = tempMediaFile.path;
      _onDisk = true;
    }
    _prepared = true;
  }

  Future<void> _downloadURL(LoadingProgress progress) async {
    var saveToFile = TempMediaFile.empty();
    _tempMediaFiles.add(saveToFile);
    await Downloader().download(url, saveToFile.path, progress);
    _storagePath = saveToFile.path;
    _onDisk = true;
  }

  /// Only writes the audio to disk if we have a databuffer and we haven't
  /// already written it to disk.
  ///
  /// Returns the path where the current version of the audio is stored.
  void _writeBufferToDisk(LoadingProgress progress) {
    assert(progress != null);
    if (!_onDisk && isBuffer) {
      var tempMediaFile = TempMediaFile.fromBuffer(_dataBuffer, progress);
      _tempMediaFiles.add(tempMediaFile);

      /// update the path to the new file.
      _storagePath = tempMediaFile.path;
      _onDisk = true;
    }
  }

  /// delete any tempoary media files we created whilst recording.
  void _deleteTempFiles() {
    for (var tmp in _tempMediaFiles) {
      tmp.delete();
    }
    _tempMediaFiles.clear();
  }

  /// You MUST call release once you have finished with an [Audio]
  /// otherwise you will leak temp files.
  void release() {
    if (_tempMediaFiles.isNotEmpty) {
      _onDisk = false;
      _deleteTempFiles();
    }
  }

  /// Adjust the loading progress as we have multiple stages we go
  /// through when preparing a stream.
  void _forwardStagedProgress(LoadingProgress loadingProgress,
      PlaybackDisposition disposition, int stage, int stages) {
    var rewritten = false;

    if (disposition.state == PlaybackDispositionState.loading) {
      // if we have 3 stages then a progress of 1.0 becomes progress
      /// 0.3.
      var progress = disposition.progress / stages;
      // offset the progress based on which stage we are in.
      progress += 1.0 / stages * (stage - 1);
      loadingProgress(PlaybackDisposition.loading(progress: progress));
      rewritten = true;
    }

    if (disposition.state == PlaybackDispositionState.loaded) {
      if (stage != stages) {
        /// if we are not the last stage change 'loaded' into loading.
        loadingProgress(
            PlaybackDisposition.loading(progress: stage * (1.0 / stages)));
        rewritten = true;
      }
    }
    if (!rewritten) {
      loadingProgress(disposition);
    }
  }

  @override
  String toString() {
    var desc = 'Codec: $codec';
    if (_onDisk) {
      desc += 'storage: $_storagePath';
    }

    if (url != null) desc += ' url: $url';
    if (path != null) desc += ' path: $path';
    if (_dataBuffer != null) desc += ' buffer len: ${_dataBuffer.length}';

    return desc;
  }
}
