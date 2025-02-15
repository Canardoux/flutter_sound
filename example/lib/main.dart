/*
 * Copyright 2018, 2019, 2020, 2021 Dooboolab.
 *
 * This file is part of Flutter-Sound.
 *
 * Flutter-Sound is free software: you can redistribute it and/or modify
 * it under the terms of the Mozilla Public License version 2 (MPL2.0),
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

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'demo/demo.dart';
import 'livePlaybackWithBackPressure/live_playback_with_back_pressure.dart';
import 'livePlaybackWithoutBackPressure/live_playback_without_back_pressure.dart';
import 'multi_playback/multi_playback.dart';
import 'recordToStream/record_to_stream_example.dart';
//import 'dummy_mobile.dart'
//if (dart.library.js_interop) 'mediaRecorder/media_recorder.dart'; // package:web implementation
import 'streams/streams.dart';
import 'simple_playback/simple_playback.dart';
import 'simple_recorder/simple_recorder.dart';
import 'soundEffect/sound_effect.dart';
import 'loglevel/loglevel.dart';
import 'volume_control/volume_control.dart';
import 'volumepan_control/volumepan_control.dart';
import 'speed_control/speed_control.dart';
import 'player_onProgress/player_on_progress.dart';
import 'recorder_onProgress/recorder_on_progress.dart';
import 'seek/seek.dart';

/*
    This APP is just a driver to call the various Flutter Sound examples.
    Please refer to the examples/README.md and all the examples located under the examples/lib directory.
*/

void main() {
  runApp(const ExamplesApp());
}

///
const int tNotWeb = 1;

///
class Example {
  ///
  final String? title;

  ///
  final String? subTitle;

  ///
  final String? description;

  ///
  final WidgetBuilder? route;

  ///
  final int? flags;

  ///
  /* ctor */ Example(
      {this.title, this.subTitle, this.description, this.flags, this.route});

  ///
  void go(BuildContext context) =>
      Navigator.push(context, MaterialPageRoute<void>(builder: route!));
}

///
final List<Example> exampleTable = [
  // If you update the following test, please update also the Examples/README.md file and the comment inside the dart file.

  Example(
      title: 'Demo',
      subTitle: 'Flutter Sound capabilities',
      flags: 0,
      route: (_) => const Demo(),
      description:
          '''
A demonstration of the Flutter Sound features.
This is a Demo of what it is possible to do with Flutter Sound. The code of this Demo app is not so simple.

Flutter Sound beginners : you probably should look to [SimplePlayback](fs-ex_simple_playback.html) and [SimpleRecorder](fs-ex_simple_recorder.html)

The biggest interest of this Demo is that it shows most of the features of Flutter Sound :

* Plays from various media with various codecs
* Records to various media with various codecs
* Pause and Resume control from recording or playback
* Shows how to use a Stream for getting the playback \(or recoding\) events
* Shows how to specify a callback function when a playback is terminated,
* Shows how to record to a Stream or playback from a stream
* Can show controls on the iOS or Android lock-screen
* ...
'''),

  Example(
    title: 'simplePlayback',
    subTitle: 'A very simple example',
    flags: 0,
    route: (_) => const SimplePlayback(),
    description: '''
This is a very simple example for Flutter Sound beginners,
that shows how to play a remote file.

This example is really basic.
''',
  ),

  Example(
    title: 'simpleRecorder',
    subTitle: 'A very simple example',
    flags: 0,
    route: (_) => const SimpleRecorder(),
    description: '''
This is a very simple example for Flutter Sound beginners,
that shows how to record, and then playback a file.

This example is really basic.
''',
  ),

  Example(
    title: 'multiPlayback',
    subTitle: 'Playing several sound at the same time',
    flags: 0,
    route: (_) => const MultiPlayback(),
    description: '''
This is a simple example doing several playbacks at the same time.
It launch two players which play each an asset. The User can adjust the volume of them independently.

This example shows also :
- The Pause/Resume feature.
- The Display of the elapsed time
''',
  ),

  Example(
    title: 'Volume Control',
    subTitle: 'Volume Control',
    flags: 0,
    route: (_) => const VolumeControl(),
    description: '''
This is a very simple basic example which allows the user to adjust the sound volume.
It launch two players which play each an asset. The User can adjust the volume of them independently.
''',
  ),

  Example(
    title: 'Volume Pan Control',
    subTitle: 'Volume Pan Control',
    flags: 0,
    route: (_) => const VolumePanControl(),
    description: '''
This is a very simple example showing how to set the Volume and Pan during a playback.

This example is really basic.
''',
  ),

  Example(
    title: 'Speed Control',
    subTitle: 'Speed Control',
    flags: 0,
    route: (_) => const SpeedControl(),
    description: '''
This is a very simple example showing how tune the speed of a playback.

This example is really basic.
''',
  ),

  Example(
    title: 'Seek Player',
    subTitle: 'Seek Player',
    flags: 0,
    route: (_) => const Seek(),
    description: '''
This is a very simple example showing how tune the speed of a playback.

This example is really basic.
''',
  ),

  Example(
    title: 'Player onProgress',
    subTitle: 'Player onProgress',
    flags: 0,
    route: (_) => const PlayerOnProgress(),
    description: '''
This is a very simple example showing how to  call `setSubscriptionDuration() and use onProgress() on a player.
There is a slider to show are the playback frequency can be adjust.

This example is really basic.
''',
  ),

  Example(
    title: 'Recorder onProgress',
    subTitle: 'Recorder onProgress',
    flags: 0,
    route: (_) => const RecorderOnProgress(),
    description: '''
This is a very simple example showing how to  call `setSubscriptionDuration() and use onProgress() on a recorder.
There is a slider to show are the playback frequency can be adjust.

This example is really basic.
''',
  ),

  Example(
    title: 'recordToStream',
    subTitle: 'Example of recording to Stream',
    flags: tNotWeb,
    route: (_) => const RecordToStreamExample(),
    description: '''
This is an example showing how to record to a Dart Stream.
It writes all the recorded data from a Stream to a File, which is completely stupid:
if an App wants to record something to a File, it must not use Streams.

The real interest of recording to a Stream is for example to feed a Speech-to-Text engine, or for processing the Live data in Dart in real time.
Note : actually this example does not work on Flutter Web.
For Web, you can look to the example `media_recorder` which is another example doing `RecordToStream()`.
''',
  ),

//This example works only on Flutter Web. For Android or iOS, you can look to the example `recordToStream`.
  Example(
    title: 'Streams',
    subTitle: 'Records and playback to/from a Float32 stream',
    flags: 0,
    route: (_) => const StreamsExample(),
    description: '''
This is an example showing how to record to a Dart Float32List Stream and play from a Float32List Stream.
The streams are Float32List for pcmFloat32 codec.

You can also refer to the following examples that uses UInt8List:

- recordToStream
- livePlaybackWithoutBackPressure
''',
  ),

  Example(
    title: 'Live Playback from stream',
    subTitle: 'Live Playback from stream',
    flags: tNotWeb,
    route: (_) => const LivePlaybackWithoutBackPressure(),
    description:
        '''A very simple example showing how to play Live Data without back pressure.
A very simple example showing how to play Live Data without back pressure.

[You can also refer to the following examples that uses Float32List: Streams Example]

It feeds a live stream, without waiting that the Futures are completed for each block.
This is simple because the App does not need to await the playback for each block before playing another one.


This example get the data from an asset file, which is completely stupid :
if an App wants to play an asset file he must use "StartPlayerFromBuffer().

Feeding Flutter Sound without back pressure is very simple but you can have two problems :
- If your App is too fast feeding the audio channel, it can have problems with the Stream memory used.
- The App does not have any knowledge of when the provided block is really played.
If he does a "stopPlayer()" it will loose all the buffered data.

This example uses the ```foodEvent``` object to resynchronize the output stream before doing a ```stop()```
''',
  ),

  Example(
    title: 'livePlaybackWithBackPressure',
    subTitle: 'Live Playback with BackPressure',
    flags: tNotWeb,
    route: (_) => const LivePlaybackWithBackPressure(),
    description: '''
A very simple example showing how to play Live Data with back pressure.
It feeds a live stream, waiting that the Futures are completed for each block.

This example get the data from an asset file, which is completely stupid :
if an App wants to play an asset file he must use "StartPlayerFromBuffer().

If you do not need any back pressure, you can see another simple example : "LivePlaybackWithoutBackPressure.dart".
This other example is a little bit simpler because the App does not need to await the playback for each block before
playing another one.
''',
  ),

  Example(
    title: 'soundEffect',
    subTitle: 'Sound Effect',
    flags: tNotWeb,
    route: (_) => const SoundEffect(),
    description: '''
```startPlayerFromStream()``` can be very efficient to play sound effects. For example in a game App.
The App open the Audio Session and call ```startPlayerFromStream()``` during initialization.
When it want to play a noise, it has just to call the verb ```feed```
''',
  ),

  Example(
    title: 'setLogLevel()',
    subTitle: 'Dynamically change the log level',
    flags: 0,
    route: (_) => const LogLevel(),
    description: '''
```
Shows how to change the loglevel during an audio session.
''',
  ),
];

///
class ExamplesApp extends StatelessWidget {
  const ExamplesApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Sound Examples',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const ExamplesAppHomePage(title: 'Flutter Sound Examples'),
    );
  }
}

///
class ExamplesAppHomePage extends StatefulWidget {
  ///
  const ExamplesAppHomePage({super.key, this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  ///
  final String? title;

  @override
  State<ExamplesAppHomePage> createState() => _ExamplesHomePageState();
}

class _ExamplesHomePageState extends State<ExamplesAppHomePage> {
  Example? selectedExample;

  @override
  void initState() {
    selectedExample = exampleTable[0];
    super.initState();
    //_scrollController = ScrollController( );
  }

  @override
  Widget build(BuildContext context) {
    Widget cardBuilder(BuildContext context, int index) {
      var isSelected = (exampleTable[index] == selectedExample);
      return GestureDetector(
        onTap: () => setState(() {
          selectedExample = exampleTable[index];
        }),
        child: Card(
          shape: const RoundedRectangleBorder(),
          borderOnForeground: false,
          elevation: 3.0,
          child: Container(
            height: 55,
            margin: const EdgeInsets.all(3),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isSelected ? Colors.indigo : const Color(0xFFFAF0E6),
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
            ),

            //color: isSelected ? Colors.indigo : Colors.cyanAccent,
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(exampleTable[index].title!,
                  style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black)),
              Text(exampleTable[index].subTitle!,
                  style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black)),
            ]),
          ),
        ),
      );
    }

    Widget makeBody() {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(3),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF0E6),
                border: Border.all(
                  color: Colors.indigo,
                  width: 3,
                ),
              ),
              child: ListView.builder(
                  itemCount: exampleTable.length, itemBuilder: cardBuilder),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(3),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF0E6),
                border: Border.all(
                  color: Colors.indigo,
                  width: 3,
                ),
              ),
              child: SingleChildScrollView(
                child: Text(selectedExample!.description!),
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        title: Text(widget.title!),
      ),
      body: makeBody(),
      bottomNavigationBar: BottomAppBar(
        color: Colors.blue,
        child: Container(
            margin: const EdgeInsets.all(3),
            padding: const EdgeInsets.all(3),
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFAF0E6),
              border: Border.all(
                color: Colors.indigo,
                width: 3,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text((kIsWeb && (selectedExample!.flags! & tNotWeb != 0))
                    ? 'Not supported on Flutter Web '
                    : ''),
                ElevatedButton(
                  onPressed:
                      (kIsWeb && (selectedExample!.flags! & tNotWeb != 0))
                          ? null
                          : () => selectedExample!.go(context),
                  //color: Colors.indigo,
                  child: const Text(
                    'GO',
                    style: TextStyle(color: Colors.black),
                  ),
                )
              ],
            )),
      ),
    );
  }
}
