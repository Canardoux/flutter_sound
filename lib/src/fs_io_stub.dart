import 'dart:async';
import 'dart:typed_data';

bool get fsIsIOS => false;

Never _unsupported() =>
    throw UnsupportedError('This file helper is not available on web.');

Future<String> fsTemporaryDirectoryPath() async => _unsupported();

Future<String> fsApplicationDocumentsDirectoryPath() async => _unsupported();

Uint8List fsReadFileBytesSync(String path) => _unsupported();

int fsFileLengthSync(String path) => _unsupported();

Future<void> fsWriteFileBytes(String path, List<int> bytes) async =>
    _unsupported();

Future<void> fsWriteFileWithHeader({
  required String path,
  required void Function(EventSink<List<int>> sink) writeHeader,
  required List<int> body,
}) async => _unsupported();
