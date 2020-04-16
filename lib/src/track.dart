import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'codec.dart';
import 'flutter_sound_helper.dart';
import 'flutter_sound_player.dart';

/// The track to play in the audio player
class Track {
  /// The title of this track
  final String trackTitle;

  /// The buffer containing the audio file to play
  final Uint8List dataBuffer;

  /// The name of the author of this track
  final String trackAuthor;

  /// The path that points to the track audio file
  String trackPath;

  /// The URL that points to the album art of the track
  final String albumArtUrl;

  /// The asset that points to the album art of the track
  final String albumArtAsset;

  /// The image that points to the album art of the track
  //final String albumArtImage;

  /// The codec of the audio file to play. If this parameter's value is null
  /// it will be set to [Codec.DEFAULT].
  Codec codec;

  ///
  Track({
    this.trackPath,
    this.dataBuffer,
    this.trackTitle,
    this.trackAuthor,
    this.albumArtUrl,
    this.albumArtAsset,
    this.codec = Codec.defaultCodec,
  }) {
    codec = codec == null ? Codec.defaultCodec : codec;
    assert(trackPath != null || dataBuffer != null,
        'You should provide a path or a buffer for the audio content to play.');
    assert(
        (trackPath != null && dataBuffer == null) ||
            (trackPath == null && dataBuffer != null),
        'You cannot provide both a path and a buffer.');
  }

  /// Convert this object to a [Map] containing the properties of this object
  /// as values.
  Future<Map<String, dynamic>> toMap() async {
    final map = {
      "path": trackPath,
      "dataBuffer": dataBuffer,
      "title": trackTitle,
      "author": trackAuthor,
      "albumArtUrl": albumArtUrl,
      "albumArtAsset": albumArtAsset,
      "bufferCodecIndex": codec?.index,
    };

    return map;
  }

  /// If we want to play OGG/OPUS on iOS, we re-mux the OGG file format to a
  /// specific Apple CAF envelope before starting the player.
  /// We use FFmpeg for that task.
  Future<void> adaptOggToIos() async {
    if ((Platform.isIOS) &&
        ((codec == Codec.codecOpus) || (fileExtension(trackPath) == '.opus'))) {
      var tempDir = await getTemporaryDirectory();
      var fout = await File('${tempDir.path}/flutter_sound-tmp.caf');
      if (fout.existsSync()) {
        await fout.delete();
      }

      int rc;
      var inputFileName = trackPath;
      // The following ffmpeg instruction does not decode and re-encode
      // the file.
      // It just remux the OPUS data into an Apple CAF envelope.
      // It is probably very fast and the user will not notice any delay,
      // even with a very large data.
      // This is the price to pay for the Apple stupidity.
      if (dataBuffer != null) {
        // Write the user buffer into the temporary file
        inputFileName = '${tempDir.path}/flutter_sound-tmp.opus';
        var fin = await File(inputFileName);
        fin.writeAsBytesSync(dataBuffer);
      }
      rc = await FlutterSoundHelper().executeFFmpegWithArguments([
        '-y',
        '-loglevel',
        'error',
        '-i',
        inputFileName,
        '-c:a',
        'copy',
        fout.path,
      ]); // remux OGG to CAF
      if (rc != 0) {
        throw 'FFmpeg exited with code $rc';
      }
      // Now we can play Apple CAF/OPUS
      trackPath = fout.path;
    }
  }
}
