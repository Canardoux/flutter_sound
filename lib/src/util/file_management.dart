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

import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

/// creates an empty temporary file in the system temp directory.
/// You are responsible for deleting the file once done.
/// The temp file name will be <uuid>.tmp
/// unless you provide a [suffix] in which
/// case the file name will be <uuid>.<suffix>
String tempFile({String suffix}) {
  suffix ??= 'tmp';

  if (!suffix.startsWith('.')) {
    suffix = '.$suffix';
  }
  var uuid = Uuid();
  var path = '${join(Directory.systemTemp.path, uuid.v4())}$suffix';
  touch(path);
  return path;
}

/// Return the file extension for the given path.
/// path can be null. We return null in this case.
String fileExtension(String path) {
  return path ?? extension(path);
}

/// Checks if the given path exists.
bool exists(String path) {
  var fout = File(path);
  return fout.existsSync();
}

/// Checks if the given path exists.
bool directoryExists(String path) {
  return Directory(path).existsSync();
}

/// Delete the given path.
void delete(String path) {
  var fout = File(path);
  fout.deleteSync();
}

/// Truncates the file to zero bytes in length.
void truncate(String path) {
  RandomAccessFile raf;

  try {
    var file = File(path);
    raf = file.openSync(mode: FileMode.write);
    raf.truncateSync(0);
  } finally {
    if (raf != null) raf.closeSync();
  }
}

/// If the file doesn't exist then create it.
/// If a file is created it will be zero length.
void touch(String path) {
  final file = File(path);
  file.createSync();
}

/// Returns true if the given [path] is a file (as apposed to a directory or
/// a symlink).
bool isFile(String path) {
  var fromType = FileSystemEntity.typeSync(path);
  return (fromType == FileSystemEntityType.file);
}

/// Returns the length of the file located at [path].
int fileLength(String path) {
  return File(path).lengthSync();
}
