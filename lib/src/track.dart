import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'codec.dart';
import 'util/audio.dart';
import 'util/file_management.dart' as fm;
import 'util/file_management.dart';

typedef TrackAction = void Function(Track current);

///
/// The [Track] class lets you define an audio track
/// either from a path (uri) or a databuffer.
///
//
class Track {
  /// The title of this track
  String title;

  /// The name of the author of this track
  String author;

  /// The URL that points to the album art of the track
  String albumArtUrl;

  /// The asset that points to the album art of the track
  String albumArtAsset;

  /// The file that points to the album art of the track
  String albumArtFile;

  ///
  Audio _audio;

  /// Creates a Track from a local file or asset.
  /// Other classes that use fromPath should also be reviewed.
  Track.fromPath(String path, {Codec codec}) {
    if (!exists(path)) {
      throw TrackPathException('The given path $path does not exist.');
    }

    if (!isFile(path)) {
      throw TrackPathException('The given path $path is not a file.');
    }
    _audio = Audio.fromPath(path, codec);
  }

  /// TODO: consider change this to fromURI.
  /// Other classes that use fromPath should also be reviewed.
  Track.fromURL(String url, {Codec codec}) {
    _audio = Audio.fromURL(url, codec);
  }

  ///
  Track.fromBuffer(Uint8List dataBuffer, {@required Codec codec}) {
    _audio = Audio.fromBuffer(dataBuffer, codec);
  }

  ///
  Codec get codec => _audio.codec;

  /// true if the track is a url to the audio data.
  bool get isURL => _audio.isURL;

  /// True if the track is a local file path
  bool get isPath => _audio.isPath;

  /// If the [Track] was created via [Track.fromURL]
  /// then this will be the passed url.
  String get url => _audio.url;

  /// If the [Track] was created via [Track.fromPath]
  /// then this will be the passed url.
  String get path => _audio.path;

  /// returns a unique id for the [Track].
  /// If the [Track] is a path then the path is returned.
  /// If the [Track] is a url then the url.
  /// If the [Track] is a databuffer then its dart hashCode.
  String get identity {
    if (isPath) return path;
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
  void _prepareStream() async {
    await _audio.prepareStream();
  }

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
void prepareStream(Track track) => track._prepareStream();

/// Returns the uri this track was constructed
/// with assuming the [fromPath] ctor or
/// the databuffer had to be converted to a file.
String trackStoragePath(Track track) => track._audio.storagePath;

/// Retursn the databuffer.
Uint8List trackBuffer(Track track) => track._audio.buffer;

/// The SoundPlayerPlugin doesn't support passing a databuffer
/// so we need to force the file to disk.
void trackForceToDisk(Track track) => track._audio.forceToDisk();

/// Exception throw in a file path passed to a Track isn't valid.
class TrackPathException implements Exception {
  ///
  String message;

  ///
  TrackPathException(this.message);

  String toString() => message;
}
