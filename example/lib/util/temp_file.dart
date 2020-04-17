import 'dart:io';

import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';

/// Creates an path to a temporary file.
Future<String> tempFile({String suffix}) async {
  suffix ??= 'tmp';

  if (!suffix.startsWith('.')) {
    suffix = '.$suffix';
  }
  var uuid = Uuid();
  var tmpDir = await getTemporaryDirectory();
  var path = '${join(tmpDir.path, uuid.v4())}$suffix';
  var parent = dirname(path);
  Directory(parent).createSync(recursive: true);

  return path;
}
