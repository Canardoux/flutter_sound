import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'codec.dart';
import 'playback_disposition.dart';
import 'util/audio.dart';
import 'util/file_management.dart' as fm;

typedef TrackAction = void Function(Track current);

///
/// The [Track] class lets you define an audio track
/// either from a path (uri) or a databuffer.
///
//
class Track {
  _TrackStorageType _storageType;

  /// The title of this track
  String title;

  /// The name of the artist of this track
  String artist;

  /// The album the track belongs.
  String album;

  /// The URL that points to the album art of the track
  String albumArtUrl;

  /// The asset that points to the album art of the track
  String albumArtAsset;

  /// The file that points to the album art of the track
  String albumArtFile;

  ///
  Audio _audio;

  /// Returns the length of the audio in bytes.
  int get length => _audio.length;

  @override
  String toString() {
    return '${title ?? ""} ${artist ?? ""} audio: $_audio';
  }

  /// Creates a Track from a local file or asset.
  /// Other classes that use fromFile should also be reviewed.
  Track.fromFile(String path, {Codec codec}) {
    if (path == null) {
      throw TrackPathException('The path MUST not be null.');
    }

    if (!fm.exists(path)) {
      throw TrackPathException('The given path $path does not exist.');
    }

    if (!fm.isFile(path)) {
      throw TrackPathException('The given path $path is not a file.');
    }
    _storageType = _TrackStorageType.path;

    _audio = Audio.fromFile(path, codec);
  }

  /// Creates a track from a remote URL.
  /// HTTP and HTTPS are supported
  Track.fromURL(String url, {Codec codec}) {
    if (url == null) {
      throw TrackPathException('The url MUST not be null.');
    }

    _storageType = _TrackStorageType.url;

    _audio = Audio.fromURL(url, codec);
  }

  /// Creates a track from a buffer.
  /// You may pass null for the [dataBuffer] in which case an
  /// empty databuffer will be created.
  /// This is useful if you need to record into a track
  /// backed by a buffer.
  ///
  Track.fromBuffer(Uint8List dataBuffer, {@required Codec codec}) {
    if (dataBuffer == null) {
      dataBuffer = Uint8List(0);
    }

    _storageType = _TrackStorageType.buffer;
    _audio = Audio.fromBuffer(dataBuffer, codec);
  }

  ///
  Codec get codec => _audio.codec;

  /// true if the track is a url to the audio data.
  bool get isURL => _storageType == _TrackStorageType.url;

  /// True if the track is a local file path
  bool get isFile => _storageType == _TrackStorageType.path;

  /// True if the [Track] media is stored in buffer.
  bool get isBuffer => _storageType == _TrackStorageType.buffer;

  /// If the [Track] was created via [Track.fromURL]
  /// then this will be the passed url.
  String get url => _audio.url;

  /// If the [Track] was created via [Track.fromFile]
  /// then this will be the passed path.
  String get path => _audio.path;

  /// returns a unique id for the [Track].
  /// If the [Track] is a path then the path is returned.
  /// If the [Track] is a url then the url.
  /// If the [Track] is a databuffer then its dart hashCode.
  String get identity {
    if (isFile) return path;
    if (isURL) return url;

    return '${_audio.buffer.hashCode}';
  }

  /// released any system resources.
  /// Under normal circumstances you don't need to call this
  /// method all of flutter_sound classes manage it for you.
  void _release() => _audio.release();

  /// Used to prepare a audio stream for playing.
  /// You should NOT call this method as it is managed
  /// internally.
  Future _prepareStream(LoadingProgress progress) async =>
      _audio.prepareStream(progress);

  /// Returns the duration of the track.
  ///
  /// This can be an expensive operation as we need to
  /// process the media to determine its duration.
  ///
  /// If this track is being recorded into, the recorder
  /// will update the duration as the recording proceeds.
  ///
  /// The duration should always be considered as an estimate.
  Future<Duration> get duration async => _audio.duration;

  /// This is a convenience method that
  /// creates an empty temporary file in the system temp directory.
  ///
  /// You are responsible for deleting the file once done.
  ///
  /// The temp file name will be <uuid>.<codec>.
  ///
  /// ```dart
  /// var file = tempfile(Codec.mp3)
  ///
  /// print(file);
  /// > 1230811273109.mp3
  ///
  static String tempFile(Codec codec) {
    return fm.tempFile(suffix: CodecHelper.codecToExtensionMap[codec]);
  }
}

///
/// globl functions to allow us to hide methods from the public api.
///

void trackRelease(Track track) => track._release();

/// Used by the SoundRecorder to update the duration of the
/// track as the track is recorded into.
void setTrackDuration(Track track, Duration duration) =>
    track._audio.setDuration(duration);

///
Future prepareStream(Track track, LoadingProgress progress) =>
    track._prepareStream(progress);

/// Returns the uri where this track is currently stored.
///
String trackStoragePath(Track track) {
  if (track._audio.onDisk) {
    return track._audio.storagePath;
  } else {
    // this should no longer fire as we are now downloading the track
    assert(track.isURL);
    return track.url;
  }
}

/// Returns the databuffer which holds the audio.
/// If this Track was created via [fromBuffer].
///
/// This may not be the same buffer you passed in if we had
/// to re-encode the buffer or if you recorded into the track.
Uint8List trackBuffer(Track track) => track._audio.buffer;

/// Exception throw in a file path passed to a Track isn't valid.
class TrackPathException implements Exception {
  ///
  String message;

  ///
  TrackPathException(this.message);

  String toString() => message;
}

enum _TrackStorageType { buffer, path, url }
