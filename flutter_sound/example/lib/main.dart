/*
 * Copyright 2018, 2019, 2020 Dooboolab.
 *
 * This file is part of Flutter-Sound.
 *
 * Flutter-Sound is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License version 3 (LGPL-V3), as published by
 * the Free Software Foundation.
 *
 * Flutter-Sound is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with Flutter-Sound.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'demo/demo.dart';
import 'livePlaybackWithBackPressure/live_playback_with_back_pressure.dart';
import 'livePlaybackWithoutBackPressure/live_playback_without_back_pressure.dart';
import 'multi_playback/multi_playback.dart';
import 'play_from_mic/play_from_mic.dart';
import 'recordToStream/record_to_stream_example.dart';
import 'simple_playback/simple_playback.dart';
import 'simple_recorder/simple_recorder.dart';
import 'soundEffect/sound_effect.dart';
import 'streamLoop/stream_loop.dart';
import 'widgetUI/widget_ui_demo.dart';

/*
    This APP is just a driver to call the various Flutter Sound examples.
    Please refer to the examples/README.md and all the examples located under the examples/lib directory.
*/

void main() {
  runApp(ExamplesApp());
}

///
const int tNotWeb = 1;

///
class Example {
  ///
  final String title;

  ///
  final String subTitle;

  ///
  final String description;

  ///
  final WidgetBuilder route;

  ///
  final int flags;

  ///
  /* ctor */ Example(
      {this.title, this.subTitle, this.description, this.flags, this.route});

  ///
  void go(BuildContext context) =>
      Navigator.push(context, MaterialPageRoute<void>(builder: route));
}

///
final List<Example> exampleTable = [
  // If you update the following test, please update also the Examples/README.md file and the comment inside the dart file.

  Example(
      title: 'Demo',
      subTitle: 'Flutter Sound capabilities',
      flags: 0,
      route: (_) => Demo(),
      description:
          '''This is a Demo of what it is possible to do with Flutter Sound.
The code of this Demo app is not so simple and unfortunately not very clean :-( .

Flutter Sound beginners : you probably should look to `[SimplePlayback]`  and `[SimpleRecorder]` 

The biggest interest of this Demo is that it shows most of the features of Flutter Sound :

- Plays from various media with various codecs
- Records to various media with various codecs
- Pause and Resume control from recording or playback
- Shows how to use a Stream for getting the playback (or recoding) events
- Shows how to specify a callback function when a playback is terminated,
- Shows how to record to a Stream or playback from a stream
- Can show controls on the iOS or Android lock-screen
- ...

This Demo does not make use of the Flutter Sound UI Widgets.

It would be really great if someone rewrite this demo soon'''),

  Example(
    title: 'WidgetUIDemo',
    subTitle: 'Demonstration of the UI Widget',
    flags: 0,
    route: (_) => WidgetUIDemo(),
    description:
// If you update the following test, please update also the Examples/README.md file and the comment inside the dart file.
        '''
This is a Demo of an App which uses the Flutter Sound UI Widgets.

My own feeling is that this Demo is really too much complicated for doing something very simple.
There is too many dependencies and too many sources.

I really hope that someone will write soon another simpler Demo App.
''',
  ),

  Example(
    title: 'simplePlayback',
    subTitle: 'A very simple example',
    flags: 0,
    route: (_) => SimplePlayback(),
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
    route: (_) => SimpleRecorder(),
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
    route: (_) => MultiPlayback(),
    description: '''
This is a simple example that plays several sound at the same time.
''',
  ),

  Example(
    title: 'Play from Mic',
    subTitle: 'Play from microphone',
    flags: tNotWeb,
    route: (_) => PlayFromMic(),
    description: '''
Play on the bluetooth headset what is recorded by the microphone.
This example is very simple.

>>> Please ensure that your headset is correctly connected via bluetooth
''',
  ),

  Example(
    title: 'recordToStream',
    subTitle: 'Example of recording to Stream',
    flags: tNotWeb,
    route: (_) => RecordToStreamExample(),
    description: '''
This is an example showing how to record to a Dart Stream.
It writes all the recorded data from a Stream to a File, which is completely stupid:
if an App wants to record something to a File, it must not use Streams.

The real interest of recording to a Stream is for example to feed a Speech-to-Text engine, or for processing the Live data in Dart in real time.
''',
  ),

  Example(
    title: 'livePlaybackWithoutBackPressure',
    subTitle: 'Live Playback without BackPressure',
    flags: tNotWeb,
    route: (_) => LivePlaybackWithoutBackPressure(),
    description:
        '''A very simple example showing how to play Live Data without back pressure.
A very simple example showing how to play Live Data without back pressure.
It feeds a live stream, without waiting that the Futures are completed for each block.
This is simpler because the App does not need to await the playback for each block before playing another one.


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
    route: (_) => LivePlaybackWithBackPressure(),
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
    route: (_) => SoundEffect(),
    description: '''
```startPlayerFromStream()``` can be very efficient to play sound effects. For example in a game App.
The App open the Audio Session and call ```startPlayerFromStream()``` during initialization.
When it want to play a noise, it has just to call the verb ```feed```
''',
  ),

  Example(
    title: 'streamLoop',
    subTitle: 'Loop from recorder to player',
    flags: tNotWeb,
    route: (_) => StreamLoop(),
    description: '''
```streamLoop()``` is a very simple example which connect the FlutterSoundRecorder sink 
to the FlutterSoundPlayer Stream.

Of course, we do not play to the loudspeaker to avoid a very unpleasant Larsen effect.

This example does not use a new StreamController, but use directly `foodStreamController`
from flutter_sound_player.dart.
''',
  ),
];

///
class ExamplesApp extends StatelessWidget {
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
      home: ExamplesAppHomePage(title: 'Flutter Sound Examples'),
    );
  }
}

///
class ExamplesAppHomePage extends StatefulWidget {
  ///
  ExamplesAppHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  ///
  final String title;

  @override
  _ExamplesHomePageState createState() => _ExamplesHomePageState();
}

class _ExamplesHomePageState extends State<ExamplesAppHomePage> {
  Example selectedExample;

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
          shape: RoundedRectangleBorder(),
          child: Container(
            margin: const EdgeInsets.all(3),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isSelected ? Colors.indigo : Color(0xFFFAF0E6),
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
            ),

            height: 50,

            //color: isSelected ? Colors.indigo : Colors.cyanAccent,
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(exampleTable[index].title,
                  style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black)),
              Text(exampleTable[index].subTitle,
                  style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black)),
            ]),
          ),
          borderOnForeground: false,
          elevation: 3.0,
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
                color: Color(0xFFFAF0E6),
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
                color: Color(0xFFFAF0E6),
                border: Border.all(
                  color: Colors.indigo,
                  width: 3,
                ),
              ),
              child: SingleChildScrollView(
                child: Text(selectedExample.description),
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: makeBody(),
      bottomNavigationBar: BottomAppBar(
        color: Colors.blue,
        child: Container(
            margin: const EdgeInsets.all(3),
            padding: const EdgeInsets.all(3),
            height: 40,
            decoration: BoxDecoration(
              color: Color(0xFFFAF0E6),
              border: Border.all(
                color: Colors.indigo,
                width: 3,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text((kIsWeb && (selectedExample.flags & tNotWeb != 0))
                    ? 'Not supported on Flutter Web '
                    : ''),
                ElevatedButton(
                  onPressed: (kIsWeb && (selectedExample.flags & tNotWeb != 0))
                      ? null
                      : () => selectedExample.go(context),
                  //color: Colors.indigo,
                  child: Text(
                    'GO',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              ],
            )),
      ),
    );
  }
}
