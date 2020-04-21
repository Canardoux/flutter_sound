import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'audio.dart';
import 'codec.dart';

typedef TrackAction = void Function(Track current);

/// Should we abstract a track from how it gets played.
/// I've never liked the hard link between a track
/// and the OS playback mechanism.
///
/// So what I want is for:
/// SoundPlayer - just plays audio no UI.
///  - able to send events so you can implement your own audio.
///
/// Track - allows you to define additional info such as artist
///   but you can also provide a UI manager
///   - the problem is that the plugin architecture is awkard for this
///     as it encapsulates play back and the UI.
///
/// AudioSession - we pass this around to create a coherent
/// session.
/// A SoundPlayer gets a session when it is initialised unless
/// one is passed to it.
/// An album creates a session and passes it to a Track/SoundPlayer
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
  Audio audio;

  ///
  Track.fromPath(String uri, {Codec codec}) {
    audio = Audio.fromPath(uri, codec);
  }

  ///
  Track.fromBuffer(Uint8List dataBuffer, {@required Codec codec}) {
    audio = Audio.fromBuffer(dataBuffer, codec);
  }

  ///
  Codec get codec => audio.codec;

  /// released any system resources.
  /// Under normal circumstances you don't need to call this
  /// method all of flutter_sound classes manage it for you.
  void release() => audio.release();

  /// Used to prepare a audio stream for playing.
  /// You should NOT call this method as it is managed
  /// internally.
  void prepareStream() {
    audio.prepareStream();
  }
}
