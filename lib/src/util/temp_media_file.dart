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

import 'dart:io';
import 'dart:typed_data';

import '../playback_disposition.dart';
import 'file_util.dart' as fm;
import 'log.dart';

/// Used to track temporary media files
/// that need to be deleted once they
/// are no longer used.
/// Call the [delete] method to cleanup the temp file.
class TempMediaFile {
  /// path to the temporary media file.
  String path;

  bool _deleted = false;

  /// Track a temporary media file
  /// [path] to the temporary file.
  TempMediaFile(this.path);

  /// Deletes the temporary media file.
  void delete() {
    if (_deleted) {
      throw TempMediaFileAlreadyDeletedException(
          "The file $path has already been deleted");
    }
    if (fm.FileUtil().exists(path)) fm.FileUtil().delete(path);
    _deleted = true;
  }

  /// creates a temporary media file which can be written to.
  TempMediaFile.empty() {
    path = fm.FileUtil().tempFile();

    if (fm.FileUtil().exists(path)) {
      fm.FileUtil().delete(path);
    }
  }

  /// Writes [dataBuffer] to a temporary file
  /// and returns the path to that file.
  TempMediaFile.fromBuffer(
      Uint8List dataBuffer, LoadingProgress loadingProgress) {
    path = fm.FileUtil().tempFile();

    if (fm.FileUtil().exists(path)) {
      fm.FileUtil().delete(path);
    }

    var bytesWritten = 0;

    /// write out the buffer in 4K chucks so we can report
    /// the progress as we go.
    const packetSize = 4096;
    var file = File(path);
    var length = dataBuffer.length;
    var parts = length ~/ packetSize;
    var increment = 1.0 / parts;
    for (var i = 0; i < parts; i++) {
      var start = i * packetSize;
      var end = start + packetSize;
      file.writeAsBytesSync(dataBuffer.sublist(start, end),
          mode: FileMode.append); // Write
      bytesWritten += packetSize;
      var progress = i * increment;
      Log.e("Progress: $progress");
      loadingProgress(PlaybackDisposition.loading(progress: progress));
    }
    // write final packet if there is a partial packet left
    if (bytesWritten != length) {
      file.writeAsBytesSync(dataBuffer.sublist(parts * packetSize, length),
          mode: FileMode.append);
      bytesWritten += length - (parts * packetSize);
    }
    assert(bytesWritten == length);
    loadingProgress(PlaybackDisposition.loaded());
  }
}

/// You tried to delete a temporary media file that has already
/// been deleted.
class TempMediaFileAlreadyDeletedException implements Exception {
  final String _message;

  ///
  TempMediaFileAlreadyDeletedException(this._message);

  String toString() => _message;
}
