import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import '../codec.dart';
import '../ffmpeg/ffmpeg_util.dart';
import '../util/codec_conversions.dart';
import '../util/temp_media_file.dart';
import 'file_management.dart';

/// Provide a set of tools to manage audio data.
/// Used for Tracks and Recording.
/// This class is NOT part of the public api.
class Audio {
  final List<TempMediaFile> _tempMediaFiles = [];

  ///
  Codec codec;

  /// An Audio instance can be created as on of :
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
  /// through multiple processes
  /// to a temporary file for processing.
  /// If that occurs this path points that temporary file.
  String _storagePath;

  /// Indicates if the audio media is stored on disk.
  bool _onDisk = false;

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
  /// duruation.
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
      /// will write to disk if its a databuffer.
      _writeBufferToDisk();
      if (fileLength(_storagePath) > 0) {
        _duration = await FFMpegUtil().duration(_storagePath);
      } else {
        _duration = Duration.zero;
      }
    }
    return _duration;
  }

  /// This method should ONLY be used by the SoundRecorder
  /// to update a tracks duration as we record into the track.
  /// The duration is normally calculated when the [duration] getter is called.
  //ignore: use_setters_to_change_properties
  void setDuration(Duration duration) {
    _duration = duration;
  }

  ///
  Audio.fromPath(this.path, Codec codec) {
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
  bool get isPath => path != null;

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
  void prepareStream() async {
    /// we can do no preparation for the url.
    if (isURL) return;

    // android doesn't support data buffers so we must convert
    // to a file.
    // iOS doesn't support opus so we must convert to a file so we
    /// remux it.
    if (isBuffer &&
        (Platform.isAndroid || Platform.isIOS && codec == Codec.opusOGG)) {
      _writeBufferToDisk();
    }

    // If we want to play OGG/OPUS on iOS, we remux the OGG file format to a specific Apple CAF envelope before starting the player.
    // We use FFmpeg for that task.
    if (Platform.isIOS && codec == Codec.opusOGG) {
      var tempMediaFile = TempMediaFile(
          await CodecConversions.opusToCafOpus(fromPath: _storagePath));
      _tempMediaFiles.add(tempMediaFile);

      // update the codec so we won't reencode again.
      codec = Codec.cafOpus;

      /// update the path to the new file.
      _storagePath = tempMediaFile.path;
      _onDisk = true;
    }
  }

  /// Only writes the audio to disk if we have a databuffer and we haven't
  /// already written it to disk.
  ///
  /// Returns the path where the current version of the audio is stored.
  void _writeBufferToDisk() {
    if (!_onDisk && isBuffer) {
      var tempMediaFile = TempMediaFile.fromBuffer(_dataBuffer);
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

  /// The SoundPlayerPlugin doesn't support passing a databuffer
  /// so we need to force the file to disk.
  void forceToDisk() {
    _writeBufferToDisk();
  }
}
