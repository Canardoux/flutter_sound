import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

bool get fsIsIOS => Platform.isIOS;

Future<String> fsTemporaryDirectoryPath() async =>
    (await getTemporaryDirectory()).path;

Future<String> fsApplicationDocumentsDirectoryPath() async =>
    (await getApplicationDocumentsDirectory()).path;

Uint8List fsReadFileBytesSync(String path) => File(path).readAsBytesSync();

int fsFileLengthSync(String path) => File(path).lengthSync();

Future<void> fsWriteFileBytes(String path, List<int> bytes) async {
  final sink = File(path).openWrite();
  sink.add(bytes);
  await sink.close();
}

Future<void> fsWriteFileWithHeader({
  required String path,
  required void Function(EventSink<List<int>> sink) writeHeader,
  required List<int> body,
}) async {
  final sink = File(path).openWrite();
  writeHeader(sink);
  sink.add(body);
  await sink.close();
}
