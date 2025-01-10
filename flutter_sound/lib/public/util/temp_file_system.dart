/*
 * Copyright 2018, 2019, 2020 Dooboolab.
 * Copyright 2021, 2022, 2023, 2024 Canardoux.
 *
 * This file is part of Flutter-Sound.
 *
 * Flutter-Sound is free software: you can redistribute it and/or modify
 * it under the terms of the Mozilla Public License version 2 (MPL-2.0),
 * as published by the Mozilla organization.
 *
 * Flutter-Sound is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * MPL General Public License for more details.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

/// -------
///
/// A very basic module to access temporary files.
///
/// ----------
///
/// {@category Utilities}
library temp_file_system;

import 'dart:async';
import 'dart:io';

import 'package:uuid/uuid.dart';

///
enum TempFileLocations {
  ///
  recordings
}

///
class TempFiles {
  static TempFiles? _self;
  static const _rootDir = 'square_phone';

  ///
  factory TempFiles() {
    _self ??= TempFiles._internal();
    return _self!;
  }

  TempFiles._internal() {
    // _mfs = MemoryFileSystem(style: FileSystemStyle.posix);
  }

  ///
  /// Creates a temporary file in the systems temp directory.
  /// @param subdirectory - the directory (under the temp file system)
  /// to place the file in.
  /// @param prefix - an optional prefix to prepend to the randomly
  ///  generated filename.
  ///
  /// Example:
  ///    File tmpRecording = await TempFiles()
  ///        .create(TempFileLocations.RECORDINGS);
  ///
  Future<File> create(TempFileLocations location, [String prefix = '']) async {
    var derivedPath = '${Directory.systemTemp.path}'
        '/'
        '$_rootDir'
        '/'
        '${location.toString().split('.').last}';

    var directory = await Directory(derivedPath).create(recursive: true);

    // make certain we have a random filename that doesn't already exist.
    String path;
    do {
      var fileName = prefix + generateRandomFileName();
      path = '${directory.path}/$fileName}';
    } while (File(path).existsSync());

    var tmpFile = File(path);
    await tmpFile.create();

    return tmpFile;
  }

  ///
  String generateRandomFileName() {
    return Uuid().toString();
  }
}
