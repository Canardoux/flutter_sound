/*
 * This file is part of Flutter-Sound.
 *
 *   Flutter-Sound is free software: you can redistribute it and/or modify
 *   it under the terms of the Lesser GNU General Public License
 *   version 3 (LGPL3) as published by the Free Software Foundation.
 *
 *   Flutter-Sound is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the Lesser GNU General Public License
 *   along with Flutter-Sound.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:async';

import '../ffmpeg/ffmpeg_util.dart';

import '../playback_disposition.dart';
import 'file_util.dart';

/// Provides some codec conversions.
class CodecConversions {
  ///
  /// Takes the file located at [file] which contains
  /// opus encoded audio file and remux's it
  /// into a Apple CAF envelope so we can play
  /// an Opus file on IOS.
  static Future<String> opusToCafOpus(
      {String fromPath, LoadingProgress progress}) async {
    var toPath = FileUtil().tempFile(suffix: '.caf');
    if (FileUtil().exists(toPath)) {
      // delete the old temporary file if it exists
      FileUtil().delete(toPath);
    }
    // The following ffmpeg instruction
    // does not decode and re-encode the file.
    // It just remux the OPUS data into an Apple CAF envelope.
    // It is probably very fast
    // and the user will not notice any delay,
    // even with a very large data.

    // This is the price to pay for the Apple stupidity.
    var rc = await FFMpegUtil().executeFFmpegWithArguments([
      '-loglevel',
      'error',
      '-y',
      '-i',
      fromPath,
      '-c:a',
      'copy',
      toPath,
    ]); // remux OGG to CAF

    if (rc != 0) {
      throw RemuxFailedException(
          'Conversion.opusToCafOpus of $toPath failed. Returned $rc');
    }
    return toPath;
  }

  /// Converts a Caf Opus encoded file to Opus (ogg).
  static Future cafOpusToOpus(String fromPath, String toPath) async {
    /// we have to remux the file to get it into the required codec.
    // delete the target if it exists
    // (ffmpeg gives an error if the output file already exists)
    if (FileUtil().exists(toPath)) FileUtil().delete(toPath);
    // The following ffmpeg instruction re-encode the Apple CAF to OPUS.
    // Unfortunately we cannot just remix the OPUS data,
    // because Apple does not set the "extradata" in its private OPUS format.
    // It will be good if we can improve this...
    var rc = await FFMpegUtil().executeFFmpegWithArguments([
      '-loglevel',
      'error',
      '-y',
      '-i',
      fromPath,
      '-c:a',
      'libopus',
      toPath,
    ]); // remux CAF to OGG

    if (rc != 0) {
      throw RemuxFailedException(
          'Conversion.cafOpusToOpus of $fromPath failed. Returned $rc');
    }
  }
}

/// Throw if remux a file fails.
class RemuxFailedException implements Exception {
  final String _message;

  ///
  RemuxFailedException(this._message);

  String toString() => _message;
}
