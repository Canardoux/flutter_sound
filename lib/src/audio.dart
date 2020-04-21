import 'dart:io';
import 'dart:typed_data';

import 'codec.dart';
import 'util/codec_conversions.dart';
import 'util/temp_media_file.dart';

/// Manages the audio data for a Track.
class Audio {
  final List<TempMediaFile> _tempMediaFiles = [];

  ///
  Codec codec;

  ///
  String uri;

  ///
  Uint8List _dataBuffer;

  ///
  Audio.fromPath(this.uri, Codec codec) {
    this.codec = determineCodec(uri, codec);
  }

  ///
  Audio.fromBuffer(this._dataBuffer, this.codec) {
    if (codec == null) {
      throw CodecNotSupportedException('You must pass in a codec.');
    }
  }

  /// returns true if the Audio's media is located in via
  /// a URI (as opposed to a databuffer)
  bool get isURI => _dataBuffer == null;

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
      throw CodecNotSupportedException(
          "The uri's extension does not match any of the supported extensions. "
          'You must pass in a codec.');
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
    var path = uri;

    // android doesn't support data buffers so we must convert
    // to a file.
    // iOS doesn't support opus so we must convert to a file so we
    /// remux it.
    if (_dataBuffer != null &&
        (Platform.isAndroid || Platform.isIOS && codec == Codec.opus)) {
      _writeToDisk();
    }

    // If we want to play OGG/OPUS on iOS, we remux the OGG file format to a specific Apple CAF envelope before starting the player.
    // We use FFmpeg for that task.
    if (Platform.isIOS && codec == Codec.opus) {
      var tempMediaFile =
          TempMediaFile(await CodecConversions.opusToCafOpus(path));
      _tempMediaFiles.add(tempMediaFile);

      // update the codec so we won't reencode again.
      codec = Codec.cafOpus;

      /// update the path to the new file.
      path = tempMediaFile.path;
    }
  }

  void _writeToDisk() {
    if (_dataBuffer != null) {
      var tempMediaFile = TempMediaFile.fromBuffer(_dataBuffer);
      _tempMediaFiles.add(tempMediaFile);

      /// clear the buffer so we won't do this again.
      _dataBuffer = null;

      /// update the path to the new file.
      uri = tempMediaFile.path;
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
    _deleteTempFiles();
  }

  /// The SoundPlayerPlugin doesn't support passing a databuffer
  /// so we need to force the file to disk.
  void forceToDisk() {
    _writeToDisk();
  }
}
