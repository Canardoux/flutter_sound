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

import 'package:flutter/material.dart';
import 'demo/demo.dart';
import 'widgetUI/widgetUIDemo.dart';
import 'recordToStream/recordToStreamExample.dart';
import 'playFromStream/playFromStreamExample.dart';
import 'playFromLive/playFromLiveExample.dart';

/*
    This APP is just a driver to call the various Flutter Sound examples.
    Please refer to the examples/README.md and all the examples located under the examples/lib directory.
*/

void main() {
  runApp(ExamplesApp());
}

class Example
{
    final String title;
    final String subTitle;
    final String description;
    final WidgetBuilder route;

    /* ctor */ Example({ this.title, this.subTitle, this.description, this.route}){}

    void go(BuildContext context) => Navigator.push(context, MaterialPageRoute<void>( builder: route));
}

final List<Example> exampleTable =
    [
      Example(title: 'Demo', subTitle: 'Flutter Sound capabilities', route: (BuildContext) => Demo(), description:
'''This is a Demo of what it is possible to do with Flutter Sound.
The code of this Demo app is not so simple and unfortunately not very clean :-( .

The biggest interest of this Demo is that it shows most of the features of Flutter Sound :

- Plays from various media with various codecs
- Records to various media with various codecs
- Pause and Resume control from recording or playback
- Shows how to use a Stream for getting the playback (or recoding) events
- Shows how to specify a callback function when a playback is terminated,
- Shows how to record to a Stream or playback from a stream
- Can show controls on the iOS or Android lock-screen
- ...

It would be really great if someone rewrite this demo soon'''
      ),

      Example(title: 'WidgetUIDemo', subTitle: 'Demonstration of the UI Widget', route: (BuildContext) => WidgetUIDemo(), description:
'''the description
''',
      ),

      Example(title: 'RecordToStreamExample', subTitle: 'Example of recording to Stream', route: (BuildContext) => RecordToStreamExample(), description:
'''zozo sldgkdslk; a dsflk; df;alkd ;ladfsk sdf;ldfsk sdf;lkdfs  sdf;lksd dfsa dflkdfsf;dfs dfl;kdfs dfsk dfs;ldsfk dsfk sdf'kdsf l;sdaf
La plume
erwer
gsfgsdfgsdfg
sfgsgfgfg
lklklklklkkk
zozo sldgkdslk; a dsflk; df;alkd ;ladfsk sdf;ldfsk sdf;lkdfs  sdf;lksd dfsa dflkdfsf;dfs dfl;kdfs dfsk dfs;ldsfk dsfk sdf'kdsf l;sdaf
La plume
erwer
gsfgsdfgsdfg
sfgsgfgfg
lklklklklkkk
zozo sldgkdslk; a dsflk; df;alkd ;ladfsk sdf;ldfsk sdf;lkdfs  sdf;lksd dfsa dflkdfsf;dfs dfl;kdfs dfsk dfs;ldsfk dsfk sdf'kdsf l;sdaf
La plume
erwer
gsfgsdfgsdfg
sfgsgfgfg
lklklklklkkk
zozo sldgkdslk; a dsflk; df;alkd ;ladfsk sdf;ldfsk sdf;lkdfs  sdf;lksd dfsa dflkdfsf;dfs dfl;kdfs dfsk dfs;ldsfk dsfk sdf'kdsf l;sdaf
La plume
erwer
gsfgsdfgsdfg
sfgsgfgfg
lklklklklkkk



''',
      ),

      Example(title: 'PlayFromStreamExample', subTitle: 'Example of playing from Stream', route: (BuildContext) => PlayFromStreamExample(), description:
'''the description
''',
      ),

      Example(title: 'PlayFromLiveExample', subTitle: 'Example of playing from <live> feed()', route: (BuildContext) => PlayFromLiveExample(), description:
'''the description
''',
      ),
    ];


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

class ExamplesAppHomePage extends StatefulWidget {
  ExamplesAppHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _ExamplesHomePageState createState() => _ExamplesHomePageState();
}

class _ExamplesHomePageState extends State<ExamplesAppHomePage> {
  Example selectedExample;

  @override
  void initState( ) {
    selectedExample = exampleTable[0];
    super.initState();
    //_scrollController = ScrollController( );
  }



  @override
  Widget build(BuildContext context) {
    Widget cardBuilder(BuildContext context, int index)
    {
        bool isSelected = (exampleTable[index] == selectedExample);
        return     GestureDetector
        (
            onTap: ( ) => setState( (){selectedExample = exampleTable[index];}),
            child: Card(shape: RoundedRectangleBorder(),
              child: Container
              (
                margin: const EdgeInsets.all( 3 ),
                padding: const EdgeInsets.all( 3 ),
                decoration: BoxDecoration
                  (
                  color:  isSelected ? Colors.indigo : Color( 0xFFFAF0E6), 
                  border: Border.all( color: Colors.white, width: 3, ),
                ),

                height: 50,

                //color: isSelected ? Colors.indigo : Colors.cyanAccent,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:[
                      Text(exampleTable[index].title, style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
                      Text(exampleTable[index].subTitle, style: TextStyle(color: isSelected ? Colors.white : Colors.black)),
                    ]
                ) ,
              ),
              borderOnForeground: false, elevation: 3.0,
            ),
        );
    }

    Widget makeBody()
    {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>
        [
          Expanded(
              child: Container(
              margin: const EdgeInsets.all( 3 ),
              padding: const EdgeInsets.all( 3 ),
              decoration: BoxDecoration
                (
                color:  Color( 0xFFFAF0E6 ),
                border: Border.all( color: Colors.indigo, width: 3, ),
              ),
              child:
              ListView.builder(
                itemCount: exampleTable.length,
                itemBuilder:  cardBuilder
              ),
            ),
          ),

          Expanded(
            child: Container(
              margin: const EdgeInsets.all( 3 ),
              padding: const EdgeInsets.all( 3 ),

              decoration: BoxDecoration
                (
                color: Color( 0xFFFAF0E6 ),
                border: Border.all( color: Colors.indigo, width: 3, ),
              ),
              child: SingleChildScrollView(
                child:Text( selectedExample.description
                    ), ),
            ),
          ),

        ],
      );

    }

    return Scaffold(backgroundColor: Colors.blue,
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: makeBody(),
            bottomNavigationBar: BottomAppBar
        (
        color: Colors.blue,
    child: Container(
    margin: const EdgeInsets.all( 3 ),
    padding: const EdgeInsets.all( 3 ),
    height: 40,
    decoration: BoxDecoration
    (
    color:  Color( 0xFFFAF0E6 ),
    border: Border.all( color: Colors.indigo, width: 3, ),
    ),
        child: Row ( mainAxisAlignment: MainAxisAlignment.end, children: [ RaisedButton(onPressed: () =>selectedExample.go(context), color: Colors.indigo, child: Text('GO', style: TextStyle(color: Colors.white),),)],)
      ),
      ),

    );
  }
}
