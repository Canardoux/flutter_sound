import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'codec.dart';
import 'util/audio.dart';

typedef TrackAction = void Function(Track current);

/// Should we abstract a track from how it gets played.
/// I've never liked the hard link between a track
/// and the OS playback mechanism.
///
/// So what I want is for:
/// QuickPlay - just plays audio no UI.
///  - able to send events so you can implement your own audio.
///
/// Track - allows you to define additional info such as artist
///   but you can also provide a UI manager
///   - the problem is that the plugin architecture is awkard for this
///     as it encapsulates play back and the UI.
///
/// SoundPlayer - we pass this around to create a coherent
/// player.
/// A QuickPlay gets a player when it is initialised unless
/// one is passed to it.
/// An album creates a player and passes it to a Track/QuickPlay
///

///
/// The [Track] class lets you define an audio track.
///
/// An implementation has been used to hide a number of api
/// calls that need to be visible to other classes but which
/// are not part of our public api.
///
class Track {
  /// The title of this track
  String title;

  /// The name of the author of this track
  String author;

  /// The URL that points to the album art of the track
  String albumArtUrl;

  /// The asset that points to the album art of the track
  String albumArtAsset;

  ///
  Audio _audio;

  ///
  Track.fromPath(String uri, {Codec codec}) {
    _audio = Audio.fromPath(uri, codec);
  }

  ///
  Track.fromBuffer(Uint8List dataBuffer, {@required Codec codec}) {
    _audio = Audio.fromBuffer(dataBuffer, codec);
  }

  ///
  Codec get codec => _audio.codec;

  /// true if the track is a path/url to the audio data.
  bool get isURI => _audio.isURI;

  /// released any system resources.
  /// Under normal circumstances you don't need to call this
  /// method all of flutter_sound classes manage it for you.
  void _release() => _audio.release();

  /// Used to prepare a audio stream for playing.
  /// You should NOT call this method as it is managed
  /// internally.
  void _prepareStream() {
    _audio.prepareStream();
  }
}

/// globl functions to allow us to hide methods from the public api.

void trackRelease(Track track) => track._release();

///
void prepareStream(Track track) => track._prepareStream();

/// Returns the uri this track was constructed
/// with assuming the [fromPath] ctor or
/// the databuffer had to be converted to a file.
String trackUri(Track track) => track._audio.uri;

/// Retursn the databuffer.
Uint8List trackBuffer(Track track) => track._audio.buffer;

/// The SoundPlayerPlugin doesn't support passing a databuffer
/// so we need to force the file to disk.
void trackForceToDisk(Track track) => track._audio.forceToDisk();
