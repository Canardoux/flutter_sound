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
import 'package:flutter_sound/flutter_sound.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;


/*
 *
 * A very simple example showing how to play Live Data with back pressure.
 * It feeds a live stream, waiting that the Futures are completed for each block.
 *
 * This example get the data from an asset file, which is completely stupid :
 * if an App wants to play an asset file he must use "StartPlayerFromBuffer().
 *
 * If you do not need any back pressure, you can see another simple example : "LivePlaybackWithoutbackPressure.dart".
 * This other example is a little bit simpler because the App does not need to await the playback for each block before playing another one.
 * But if you do not use any back pressure, you will be front of two problems :
 * - If your App is too fast feeding the audio channel, it can have problems with the Stream memory used.
 * - The App does not have any knowledge of when the provided block is really played. If he does a "stopPlayer()" it will loose all the buffered data.
 *
 */


const int SAMPLE_RATE = 48000;
const int BLOCK_SIZE = 4096;
typedef fn();


/// Example app.
class LivePlaybackWithBackPressure extends StatefulWidget {
  @override
  _LivePlaybackWithBackPressureState createState() => _LivePlaybackWithBackPressureState();
}

class _LivePlaybackWithBackPressureState extends State<LivePlaybackWithBackPressure> {

  FlutterSoundPlayer _mPlayer = FlutterSoundPlayer();
  bool _mPlayerIsInited = false;


  @override
  void initState() {
    super.initState();
    // Be careful : openAudioSession return a Future.
    // Do not access your FlutterSoundPlayer or FlutterSoundRecorder before the completion of the Future
    _mPlayer.openAudioSession().then((value){  setState( (){_mPlayerIsInited = true;} );} );
  }


  @override
  void dispose() {
    stopPlayer();
    _mPlayer.closeAudioSession();
    _mPlayer = null;

    super.dispose();
  }

  // -------  Here is the code to play Live data with back-pressure ------------


  Future<void> feedHim(Uint8List data ) async
  {
    int start = 0;
    int totalLength = data.length;
    while (totalLength > 0 && _mPlayer != null && !_mPlayer.isStopped)
    {
      int ln = totalLength > BLOCK_SIZE ? BLOCK_SIZE : totalLength;
      int r = await _mPlayer.feed(data.sublist(start,start + ln));
      totalLength -= r;
      start += r;
    }
  }



  void play() async
  {
    assert (_mPlayerIsInited && _mPlayer.isStopped);
    await _mPlayer.startPlayerFromStream(
      codec:  Codec.pcm16,
      numChannels: 1,
      sampleRate: SAMPLE_RATE,
      blockSize:  BLOCK_SIZE,
    );
    setState(() {});
    Uint8List data = await getAssetData('assets/samples/sample.pcm');
    await feedHim(data);
    if (_mPlayer != null) {
      await stopPlayer();
      setState(() {});
    }
  }


  // --------------------- (it was very simple, wasn't it ?) -------------------



  Future<Uint8List> getAssetData(String path) async
  {
    ByteData asset = await rootBundle.load(path);
    return asset.buffer.asUint8List();
  }

  Future<void> stopPlayer() async
  {
    if (_mPlayer != null)
      await _mPlayer.stopPlayer();
  }

  fn getPlaybackFn()
  {
    if (!_mPlayerIsInited)
      return null;
    return _mPlayer.isStopped ? play : (){stopPlayer().then((value) => setState((){}));};
  }

  // ----------------------------------------------------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {

    Widget makeBody()
    {
      return Column( children:[

        Container
          (
          margin: const EdgeInsets.all( 3 ),
          padding: const EdgeInsets.all( 3 ),
          height: 80,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration
            (
            color:  Color( 0xFFFAF0E6 ),
            border: Border.all( color: Colors.indigo, width: 3, ),
          ),
          child: Row(
              children: [
                RaisedButton(onPressed: getPlaybackFn(), color: Colors.white, disabledColor: Colors.grey, child: Text(_mPlayer.isPlaying ? 'Stop' : 'Play'), ),
                SizedBox(width: 20,),
                Text(_mPlayer.isPlaying ? 'Playback in progress' : 'Player is stopped'),
              ]
          ),
        ),

      ],
      );
    }


    return Scaffold(backgroundColor: Colors.blue,
      appBar: AppBar(
        title: const Text('Play from Live data ex.'),
      ),
      body: makeBody(),
    );
  }
}
