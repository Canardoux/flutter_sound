/*
 * This file is part of Flutter-Sound (Flauto).
 *
 *   Flutter-Sound (Flauto) is free software: you can redistribute it and/or modify
 *   it under the terms of the Lesser GNU General Public License
 *   version 3 (LGPL3) as published by the Free Software Foundation.
 *
 *   Flutter-Sound (Flauto) is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the Lesser GNU General Public License
 *   along with Flutter-Sound (Flauto).  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:flutter/material.dart';

import 'main_body.dart';

/// Boolean to specify if we want to test the Rentrance/Concurency feature.
/// If true, we start two instances of FlautoPlayer when
/// the user hit the "Play" button.
/// If true, we start two instances of FlautoRecorder and one instance of
/// FlautoPlayer when the user hit the Record button
const renetranceConcurrency = false;

/// path to remote auido file.
const String exampleAudioFilePath =
    "https://file-examples.com/wp-content/uploads/2017/11/file_example_MP3_700KB.mp3";

/// path to remote auido file artwork.
final String albumArtPath =
    "https://file-examples.com/wp-content/uploads/2017/10/file_example_PNG_500kB.png";

void main() {
  runApp(MyApp());
}

/// Example app.
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Sound'),
        ),
        body: MainBody(),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
