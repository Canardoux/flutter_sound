import 'dart:io';

import 'package:path/path.dart';
import 'package:uuid/uuid.dart';

/// Creates an path to a temporary file.
String tempFile({String suffix}) {
  suffix ??= 'tmp';

  if (!suffix.startsWith('.')) {
    suffix = '.$suffix';
  }
  var uuid = Uuid();
  return '${join(Directory.systemTemp.path, uuid.v4())}$suffix';
}
