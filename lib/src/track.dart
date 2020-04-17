import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'codec.dart';
import 'util/temp_media_file.dart';

/// The track to play in the audio player
class Track {
  /// The path that points to the track audio file
  String _trackPath;

  /// The title of this track
  final String trackTitle;

  /// The name of the author of this track
  final String trackAuthor;

  /// The URL that points to the album art of the track
  final String albumArtUrl;

  /// The asset that points to the album art of the track
  final String albumArtAsset;

  /// The image that points to the album art of the track
  //final String albumArtImage;

  /// The codec of the audio file to play. If this parameter's value is null
  /// it will be set to [Codec.DEFAULT].
  Codec codec;

  Uint8List _dataBuffer;

  /// Returns [true] if the Track originated from a
  /// in memory buffer.
  bool get isBuffer => _dataBuffer != null || _decantedBuffer != null;

  /// If we are passed a buffer we write
  /// the buffer to a temporary file.
  /// We only decant the file when someone tries to access
  /// the [trackedPath].
  TempMediaFile _decantedBuffer;

  ///
  Track({
    @required String trackPath,
    this.trackTitle,
    this.trackAuthor,
    this.albumArtUrl,
    this.albumArtAsset,
    this.codec = Codec.defaultCodec,
  }) : _trackPath = trackPath {
    codec = codec == null ? Codec.defaultCodec : codec;
    assert(trackPath != null,
        'You should provide a path for the audio content to play.');
  }

  ///
  Track.fromBuffer({
    @required Uint8List dataBuffer,
    this.trackTitle,
    this.trackAuthor,
    this.albumArtUrl,
    this.albumArtAsset,
    this.codec = Codec.defaultCodec,
  }) : _dataBuffer = dataBuffer {
    codec = codec == null ? Codec.defaultCodec : codec;
    assert(dataBuffer != null,
        'You should provide a dataBuffer for the audio content to play.');
  }

  /// The path that points to the tracked audio file
  String get trackPath {
    if (_dataBuffer != null) {
      _decantedBuffer = TempMediaFile.fromBuffer(_dataBuffer);
      _trackPath = _decantedBuffer.path;
      _dataBuffer = null;
    }
    return _trackPath;
  }

  /// Call this method to allow the Track to
  /// clean up any resources that it used.
  /// This is normally dealt with if you pass the track to
  /// on of the SoundPlayer.startXX methods.
  ///
  void release() {
    _decantedBuffer?.delete();
  }

  /// Convert this object to a [Map] containing the properties of this object
  /// as values.
  Future<Map<String, dynamic>> toMap() async {
    final map = {
      "path": _trackPath,
      "title": trackTitle,
      "author": trackAuthor,
      "albumArtUrl": albumArtUrl,
      "albumArtAsset": albumArtAsset,
      "bufferCodecIndex": codec?.index,
    };

    return map;
  }
}
