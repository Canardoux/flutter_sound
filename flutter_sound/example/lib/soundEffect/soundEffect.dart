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
import 'package:flauto/flutter_sound.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;


/*
 *
 * ```startPlayerFromStream()``` can be very efficient to play sound effects. For example in a game App.
 * The App open the Audio Session and call ```startPlayerFromStream()``` during initialization.
 * When it want to play a noise, we just call the verb ```feed```
 *
 */


const int SAMPLE_RATE = 44100;
const int NUM_CHANNELS = 1;
const BIM = 'assets/noises/bim.wav';
const BAM = 'assets/noises/bam.wav';
const BOUM = 'assets/noises/boum.wav';

typedef Fn();


/// Example app.
class SoundEffect extends StatefulWidget {
  @override
  _SoundEffectState createState() => _SoundEffectState();
}

class _SoundEffectState extends State<SoundEffect>
{

        FlutterSoundPlayer _mPlayer = FlutterSoundPlayer();
        bool _mPlayerIsInited = false;
        Uint8List bimData;
        Uint8List bamData;
        Uint8List boumData;
        bool busy = false;


        Future<Uint8List> getAssetData(String path) async
        {
                ByteData asset = await rootBundle.load(path);
                return asset.buffer.asUint8List();
        }


        Future<void> init() async
        {
                await _mPlayer.openAudioSession();
                bimData = await FlutterSoundHelper().waveToPCMBuffer(inputBuffer: await getAssetData(BIM), );
                bamData = await FlutterSoundHelper().waveToPCMBuffer(inputBuffer: await getAssetData(BAM), );
                boumData = await FlutterSoundHelper().waveToPCMBuffer(inputBuffer: await getAssetData(BOUM), );
                await _mPlayer.startPlayerFromStream(
                  codec:  Codec.pcm16,
                  numChannels: NUM_CHANNELS,
                  sampleRate: SAMPLE_RATE,
                );

        }

        @override
        void initState()
        {
                super.initState();
                init().then((value) => setState( (){_mPlayerIsInited = true;}));
        }


        @override
        void dispose()
        {
              _mPlayer.stopPlayer();
              _mPlayer.stop();
              _mPlayer.closeAudioSession();
              _mPlayer = null;

              super.dispose();
        }


        void play(Uint8List data) async
        {
                if (!busy && _mPlayerIsInited)
                {
                          busy = true;
                          _mPlayer.feedFromStream(data).then((value) => busy = false);
                }
        }


        // ----------------------------------------------------------------------------------------------------------------------

        @override
        Widget build(BuildContext context) {

          Widget makeBody()
          {
                  return Column( children:
                  [

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
                                  child: Row
                                  (
                                          children:
                                          [
                                                  RaisedButton(onPressed: (){play(bimData);}, color: Colors.white, child: Text('Bim!'), ),
                                                  SizedBox(width:10),
                                                  RaisedButton(onPressed: (){play(bamData);}, color: Colors.white, child: Text('Bam!'), ),
                                                  SizedBox(width:10),
                                                  RaisedButton(onPressed: (){play(boumData);}, color: Colors.white, child: Text('Boum!'), ),
                                          ]
                                  ),
                          ),

                  ],
                  );
                }


          return Scaffold
          (
                  backgroundColor: Colors.blue,
                  appBar: AppBar
                  (
                          title: const Text('Noise Effect'),
                  ),
                  body: makeBody(),
          );
        }
}
