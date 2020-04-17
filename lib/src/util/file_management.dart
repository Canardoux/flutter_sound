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
  return '${join(Directory.systemTemp.path, uuid.v4())}$suffix';
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
