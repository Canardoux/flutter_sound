/*
 * This file is part of Flauto.
 *
 *   Flauto is free software: you can redistribute it and/or modify
 *   it under the terms of the Lesser GNU General Public License
 *   version 3 (LGPL3) as published by the Free Software Foundation.
 *
 *   Flauto is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the Lesser GNU General Public License
 *   along with Flauto.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:async';
import 'dart:io';
import 'dart:typed_data' show Uint8List;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:flauto/flauto.dart';
import 'package:flauto/flauto_player.dart';
import 'package:flauto/flutter_sound.dart';
import 'package:flauto/track_player.dart';

enum t_MEDIA
{
        FILE,
        BUFFER,
        ASSET,
        STREAM,
        REMOTE_EXAMPLE_FILE,
}

void main( )
{
        runApp( new MyApp( ) );
}

class MyApp extends StatefulWidget
{
        @override
        _MyAppState createState( )
        => new _MyAppState( );
}

class _MyAppState extends State<MyApp>
{
        bool _isRecording = false;
        List<String> _path = [null, null, null, null, null, null, null];
        StreamSubscription _recorderSubscription;
        StreamSubscription _dbPeakSubscription;
        StreamSubscription _playerSubscription;
        StreamSubscription _playbackStateSubscription;
        static FlutterSound flutterSoundModule;

        String _recorderTxt = '00:00:00';
        String _playerTxt = '00:00:00';
        double _dbLevel;

        double sliderCurrentPosition = 0.0;
        double maxDuration = 1.0;
        t_MEDIA _media = t_MEDIA.FILE;
        t_CODEC _codec = t_CODEC.CODEC_AAC;

        bool _encoderSupported = true; // Optimist
        bool _decoderSupported = true; // Optimist

        // Whether the media player has been initialized and the UI controls can
        // be displayed.
        bool _canDisplayPlayerControls = false;

        // Whether the user wants to use the audio player features
        bool _isAudioPlayer = false;
        bool _duckOthers = false;

        void _initializeExample( FlutterSound module )
        async {
                flutterSoundModule = module;
                flutterSoundModule.initializeMediaPlayer( );
                flutterSoundModule.setSubscriptionDuration( 0.01 );
                flutterSoundModule.setDbPeakLevelUpdate( 0.8 );
                flutterSoundModule.setDbLevelEnabled( true );
                initializeDateFormatting( );
                setCodec( _codec );
                setDuck( );
        }

        @override
        void initState( )
        {
                super.initState( );
                _initializeExample( FlutterSound( ) );
        }

        void cancelRecorderSubscriptions( )
        {
                if (_recorderSubscription != null)
                {
                        _recorderSubscription.cancel( );
                        _recorderSubscription = null;
                }
                if (_dbPeakSubscription != null)
                {
                        _dbPeakSubscription.cancel( );
                        _dbPeakSubscription = null;
                }
        }

        void cancelPlayerSubscriptions( )
        {
                if (_playerSubscription != null)
                {
                        _playerSubscription.cancel( );
                        _playerSubscription = null;
                }

                if (_playbackStateSubscription != null)
                {
                        _playbackStateSubscription.cancel( );
                        _playbackStateSubscription = null;
                }
        }

        @override
        void dispose( )
        {
                super.dispose( );
                cancelPlayerSubscriptions( );
                cancelRecorderSubscriptions( );
                releasePlayer( );
        }

        Future<void> setDuck( )
        async {
                if (_duckOthers)
                {
                        if (Platform.isIOS)
                                await flutterSoundModule.iosSetCategory( t_IOS_SESSION_CATEGORY.PLAY_AND_RECORD, t_IOS_SESSION_MODE.DEFAULT, IOS_DUCK_OTHERS | IOS_DEFAULT_TO_SPEAKER );
                        else if (Platform.isAndroid) await flutterSoundModule.androidAudioFocusRequest( ANDROID_AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK );
                } else
                {
                        if (Platform.isIOS)
                                await flutterSoundModule.iosSetCategory( t_IOS_SESSION_CATEGORY.PLAY_AND_RECORD, t_IOS_SESSION_MODE.DEFAULT, IOS_DEFAULT_TO_SPEAKER );
                        else if (Platform.isAndroid) await flutterSoundModule.androidAudioFocusRequest( ANDROID_AUDIOFOCUS_GAIN );
                }
        }

        Future<void> releasePlayer( )
        async {
                try
                {
                        await flutterSoundModule.releaseMediaPlayer( );
                        print( 'media player released successfully' );
                        setState( ( )
                                  {
                                          _canDisplayPlayerControls = false;
                                  } );
                }
                catch (e)
                {
                        print( 'media player released unsuccessful' );
                        print( e );
                }
        }

        static const List<String> paths = [
                'sound.aac', // DEFAULT
                'sound.aac', // CODEC_AAC
                'sound.opus', // CODEC_OPUS
                'sound.caf', // CODEC_CAF_OPUS
                'sound.mp3', // CODEC_MP3
                'sound.ogg', // CODEC_VORBIS
                'sound.wav', // CODEC_PCM
        ];

        void startRecorder( )
        async {
                try
                {
                        // String path = await flutterSoundModule.startRecorder
                        // (
                        //   paths[_codec.index],
                        //   codec: _codec,
                        //   sampleRate: 16000,
                        //   bitRate: 16000,
                        //   numChannels: 1,
                        //   androidAudioSource: AndroidAudioSource.MIC,
                        // );
                        Directory tempDir = await getTemporaryDirectory( );

                        String path = await flutterSoundModule.startRecorder(
                                uri: '${tempDir.path}/${paths[_codec.index]}',
                                codec: _codec,
                                );
                        print( 'startRecorder: $path' );

                        _recorderSubscription = flutterSoundModule.onRecorderStateChanged.listen( ( e )
                                                                                                  {
                                                                                                          if (e.currentPosition != null)
                                                                                                          {
                                                                                                                  DateTime date = new DateTime.fromMillisecondsSinceEpoch( e.currentPosition.toInt( ), isUtc: true );
                                                                                                                  String txt = DateFormat( 'mm:ss:SS', 'en_GB' ).format( date );

                                                                                                                  this.setState( ( )
                                                                                                                                 {
                                                                                                                                         this._recorderTxt = txt.substring( 0, 8 );
                                                                                                                                 } );
                                                                                                          }
                                                                                                  } );
                        _dbPeakSubscription = flutterSoundModule.onRecorderDbPeakChanged.listen( ( value )
                                                                                                 {
                                                                                                         print( "got update -> $value" );
                                                                                                         setState( ( )
                                                                                                                   {
                                                                                                                           this._dbLevel = value;
                                                                                                                   } );
                                                                                                 } );

                        this.setState( ( )
                                       {
                                               this._isRecording = true;
                                               this._path[_codec.index] = path;
                                       } );
                }
                catch (err)
                {
                        print( 'startRecorder error: $err' );
                        setState( ( )
                                  {
                                          stopRecorder( );
                                          this._isRecording = false;
                                          if (_recorderSubscription != null)
                                          {
                                                  _recorderSubscription.cancel( );
                                                  _recorderSubscription = null;
                                          }
                                          if (_dbPeakSubscription != null)
                                          {
                                                  _dbPeakSubscription.cancel( );
                                                  _dbPeakSubscription = null;
                                          }
                                  } );
                }
        }

        void stopRecorder( )
        async {
                try
                {
                        String result = await flutterSoundModule.stopRecorder( );
                        print( 'stopRecorder: $result' );
                        cancelRecorderSubscriptions( );
                }
                catch (err)
                {
                        print( 'stopRecorder error: $err' );
                }
                this.setState( ( )
                               {
                                       this._isRecording = false;
                               } );
        }

        Future<bool> fileExists( String path )
        async {
                return await File( path ).exists( );
        }

        // In this simple example, we just load a file in memory.This is stupid but just for demonstration  of startPlayerFromBuffer()
        Future<Uint8List> makeBuffer( String path )
        async {
                try
                {
                        if (!await fileExists( path )) return null;
                        File file = File( path );
                        file.openRead( );
                        var contents = await file.readAsBytes( );
                        print( 'The file is ${contents.length} bytes long.' );
                        return contents;
                }
                catch (e)
                {
                        print( e );
                        return null;
                }
        }

        List<String> assetSample = [
                'assets/samples/sample.aac',
                'assets/samples/sample.aac',
                'assets/samples/sample.opus',
                'assets/samples/sample.caf',
                'assets/samples/sample.mp3',
                'assets/samples/sample.ogg',
                'assets/samples/sample.wav',
        ];

        void _addListeners( )
        {
                cancelPlayerSubscriptions( );
                _playerSubscription = flutterSoundModule.onPlayerStateChanged.listen( ( e )
                                                                                      {
                                                                                              if (e != null)
                                                                                              {
                                                                                                      sliderCurrentPosition = e.currentPosition;
                                                                                                      maxDuration = e.duration;

                                                                                                      DateTime date = new DateTime.fromMillisecondsSinceEpoch( e.currentPosition.toInt( ), isUtc: true );
                                                                                                      String txt = DateFormat( 'mm:ss:SS', 'en_GB' ).format( date );
                                                                                                      this.setState( ( )
                                                                                                                     {
                                                                                                                             //this._isPlaying = true;
                                                                                                                             this._playerTxt = txt.substring( 0, 8 );
                                                                                                                     } );
                                                                                              }
                                                                                      } );
        }

        Future<void> startPlayer( )
        async {
                try
                {
                        final exampleAudioFilePath = "https://file-examples.com/wp-content/uploads/2017/11/file_example_MP3_700KB.mp3";
                        final albumArtPath = "https://file-examples.com/wp-content/uploads/2017/10/file_example_PNG_500kB.png";
                        //final albumArtPath =
                        //"https://file-examples.com/wp-content/uploads/2017/10/file_example_PNG_500kB.png";

                        String path;
                        Uint8List dataBuffer;
                        String audioFilePath;
                        if (_media == t_MEDIA.ASSET)
                        {
                                dataBuffer = (await rootBundle.load( assetSample[_codec.index] )).buffer.asUint8List( );
                        } else if (_media == t_MEDIA.FILE)
                        {
                                // Do we want to play from buffer or from file ?
                                if (await fileExists( _path[_codec.index] )) audioFilePath = this._path[_codec.index];
                        } else if (_media == t_MEDIA.BUFFER)
                        {
                                // Do we want to play from buffer or from file ?
                                if (await fileExists( _path[_codec.index] ))
                                {
                                        dataBuffer = await makeBuffer( this._path[_codec.index] );
                                        if (dataBuffer == null)
                                        {
                                                throw Exception( 'Unable to create the buffer' );
                                        }
                                }
                        } else if (_media == t_MEDIA.REMOTE_EXAMPLE_FILE)
                        {
                                // We have to play an example audio file loaded via a URL
                                audioFilePath = exampleAudioFilePath;
                        }

                        // Check whether the user wants to use the audio player features
                        if (_isAudioPlayer)
                        {
                                String albumArtUrl;
                                String albumArtAsset;
                                if (_media == t_MEDIA.REMOTE_EXAMPLE_FILE)
                                        albumArtUrl = albumArtPath;
                                else
                                {
                                        if (Platform.isIOS)
                                        {
                                                albumArtAsset = 'AppIcon';
                                        } else if (Platform.isAndroid)
                                        {
                                                albumArtAsset = 'AppIcon.png';
                                        }
                                }

                                final track = Track(
                                        trackPath: audioFilePath,
                                        dataBuffer: dataBuffer,
                                        codec: _codec,
                                        trackTitle: "This is a record",
                                        trackAuthor: "from flutter_sound",
                                        albumArtUrl: albumArtUrl,
                                        albumArtAsset: albumArtAsset,
                                        );


                                TrackPlayer flauto = TrackPlayer();
                                path = await flauto.startPlayerFromTrack(
                                        track,
                                        /*canSkipForward:true, canSkipBackward:true,*/
                                        whenFinished: ( )
                                        {
                                                print( 'I hope you enjoyed listening to this song' );
                                        },
                                        onSkipBackward: ( )
                                        {
                                                print( 'Skip backward' );
                                                stopPlayer( );
                                                startPlayer( );
                                        },
                                        onSkipForward: ( )
                                        {
                                                print( 'Skip forward' );
                                                stopPlayer( );
                                                startPlayer( );
                                        },
                                        );
                        } else
                        {
                                if (audioFilePath != null)
                                {
                                        path = await flutterSoundModule.startPlayer( audioFilePath, codec: _codec, whenFinished: ( )
                                        {
                                                print( 'Play finished' );
                                                setState( ( )
                                                          {} );
                                        } );
                                } else if (dataBuffer != null)
                                {
                                        path = await flutterSoundModule.startPlayerFromBuffer( dataBuffer, codec: _codec, whenFinished: ( )
                                        {
                                                print( 'Play finished' );
                                                setState( ( )
                                                          {} );
                                        } );
                                }

                                if (path == null)
                                {
                                        print( 'Error starting player' );
                                        return;
                                }
                        }
                        _addListeners( );

                        print( 'startPlayer: $path' );
                        // await flutterSoundModule.setVolume(1.0);
                }
                catch (err)
                {
                        print( 'error: $err' );
                }
                setState( ( )
                          {} );
        }

        Future<void> stopPlayer( )
        async {
                try
                {
                        String result = await flutterSoundModule.stopPlayer( );
                        print( 'stopPlayer: $result' );
                        if (_playerSubscription != null)
                        {
                                _playerSubscription.cancel( );
                                _playerSubscription = null;
                        }
                        sliderCurrentPosition = 0.0;
                }
                catch (err)
                {
                        print( 'error: $err' );
                }
                this.setState( ( )
                               {
                                       //this._isPlaying = false;
                               } );
        }

        pauseResumePlayer( )
        {
                if (flutterSoundModule.isPlaying)
                {
                        flutterSoundModule.pausePlayer( );
                } else
                {
                        flutterSoundModule.resumePlayer( );
                }
        }

        void seekToPlayer( int milliSecs )
        async {
                String result = await flutterSoundModule.seekToPlayer( milliSecs );
                print( 'seekToPlayer: $result' );
        }

        Widget makeDropdowns( BuildContext context )
        {
                final mediaDropdown = Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                                Padding(
                                        padding: const EdgeInsets.only( right: 16.0 ),
                                        child: Text( 'Media:' ),
                                        ),
                                DropdownButton<t_MEDIA>(
                                        value: _media,
                                        onChanged: ( newMedia )
                                        {
                                                setState( ( )
                                                          {
                                                                  if (newMedia == t_MEDIA.REMOTE_EXAMPLE_FILE) _codec = t_CODEC.CODEC_MP3; // Actually this is the only example we use in this example
                                                                  _media = newMedia;
                                                          } );
                                        },
                                        items: <DropdownMenuItem<t_MEDIA>>[
                                                DropdownMenuItem<t_MEDIA>(
                                                        value: t_MEDIA.FILE,
                                                        child: Text( 'File' ),
                                                        ),
                                                DropdownMenuItem<t_MEDIA>(
                                                        value: t_MEDIA.BUFFER,
                                                        child: Text( 'Buffer' ),
                                                        ),
                                                DropdownMenuItem<t_MEDIA>(
                                                        value: t_MEDIA.ASSET,
                                                        child: Text( 'Asset' ),
                                                        ),
                                                DropdownMenuItem<t_MEDIA>(
                                                        value: t_MEDIA.REMOTE_EXAMPLE_FILE,
                                                        child: Text( 'Remote Example File' ),
                                                        ),
                                        ],
                                        ),
                        ],
                        );

                final codecDropdown = Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                                Padding(
                                        padding: const EdgeInsets.only( right: 16.0 ),
                                        child: Text( 'Codec:' ),
                                        ),
                                DropdownButton<t_CODEC>(
                                        value: _codec,
                                        onChanged: ( newCodec )
                                        {
                                                setCodec( newCodec );
                                                setState( ( )
                                                          {
                                                                  _codec = newCodec;
                                                          } );
                                        },
                                        items: <DropdownMenuItem<t_CODEC>>[
                                                DropdownMenuItem<t_CODEC>(
                                                        value: t_CODEC.CODEC_AAC,
                                                        child: Text( 'AAC' ),
                                                        ),
                                                DropdownMenuItem<t_CODEC>(
                                                        value: t_CODEC.CODEC_OPUS,
                                                        child: Text( 'OGG/Opus' ),
                                                        ),
                                                DropdownMenuItem<t_CODEC>(
                                                        value: t_CODEC.CODEC_CAF_OPUS,
                                                        child: Text( 'CAF/Opus' ),
                                                        ),
                                                DropdownMenuItem<t_CODEC>(
                                                        value: t_CODEC.CODEC_MP3,
                                                        child: Text( 'MP3' ),
                                                        ),
                                                DropdownMenuItem<t_CODEC>(
                                                        value: t_CODEC.CODEC_VORBIS,
                                                        child: Text( 'OGG/Vorbis' ),
                                                        ),
                                                DropdownMenuItem<t_CODEC>(
                                                        value: t_CODEC.CODEC_PCM,
                                                        child: Text( 'PCM' ),
                                                        ),
                                        ],
                                        ),
                        ],
                        );

                return Padding(
                        padding: const EdgeInsets.all( 8.0 ),
                        child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                        Padding(
                                                padding: const EdgeInsets.only( bottom: 16.0 ),
                                                child: mediaDropdown,
                                                ),
                                        codecDropdown,
                                ],
                                ),
                        );
        }

        onPauseResumePlayerPressed( )
        {
                switch (flutterSoundModule.audioState)
                {
                        case t_AUDIO_STATE.IS_PAUSED:
                                return pauseResumePlayer;
                                break;
                        case t_AUDIO_STATE.IS_PLAYING:
                                return pauseResumePlayer;
                                break;
                        case t_AUDIO_STATE.IS_STOPPED:
                                return null;
                                break;
                        case t_AUDIO_STATE.IS_RECORDING:
                                return null;
                                break;
                }
        }

        onStopPlayerPressed( )
        {
                return flutterSoundModule.audioState == t_AUDIO_STATE.IS_PLAYING || flutterSoundModule.audioState == t_AUDIO_STATE.IS_PAUSED ? stopPlayer : null;
        }

        onStartPlayerPressed( )
        {
                if (_media == t_MEDIA.FILE || _media == t_MEDIA.BUFFER) // A file must be already recorded to play it
                {
                        if (_path[_codec.index] == null) return null;
                }
                if (_media == t_MEDIA.REMOTE_EXAMPLE_FILE && _codec != t_CODEC.CODEC_MP3) // in this example we use just a remote mp3 file
                        return null;

                // Disable the button if the selected codec is not supported
                if (!_decoderSupported) return null;
                return flutterSoundModule.audioState == t_AUDIO_STATE.IS_STOPPED ? startPlayer : null;
        }

        void startStopRecorder( )
        {
                if (flutterSoundModule.audioState == t_AUDIO_STATE.IS_RECORDING)
                        stopRecorder( );
                else
                        startRecorder( );
        }

        onStartRecorderPressed( )
        {
                if (_media == t_MEDIA.ASSET || _media == t_MEDIA.BUFFER || _media == t_MEDIA.REMOTE_EXAMPLE_FILE) return null;
                // Disable the button if the selected codec is not supported
                if (!_encoderSupported) return null;
                if (flutterSoundModule.audioState == t_AUDIO_STATE.IS_PAUSED || flutterSoundModule.audioState == t_AUDIO_STATE.IS_PLAYING) return null;
                return startStopRecorder;
        }

        AssetImage recorderAssetImage( )
        {
                if (onStartRecorderPressed( ) == null) return AssetImage( 'res/icons/ic_mic_disabled.png' );
                return flutterSoundModule.audioState == t_AUDIO_STATE.IS_STOPPED ? AssetImage( 'res/icons/ic_mic.png' ) : AssetImage( 'res/icons/ic_stop.png' );
        }

        setCodec( t_CODEC codec )
        async {
                _encoderSupported = await flutterSoundModule.isEncoderSupported( codec );
                _decoderSupported = await flutterSoundModule.isDecoderSupported( codec );

                setState( ( )
                          {
                                  _codec = codec;
                          } );
        }

        audioPlayerSwitchChanged( )
        {
                if (flutterSoundModule.audioState != t_AUDIO_STATE.IS_STOPPED) return null;
                return (( newVal )
                async {
                        try
                        {
                                if (flutterSoundModule != null) flutterSoundModule.releaseMediaPlayer( );

                                _isAudioPlayer = newVal;
                                if (!newVal)
                                {
                                        _initializeExample( FlutterSound( ) );
                                } else
                                {
                                        _initializeExample( FlutterSound( ) );
                                }
                                setState( ( )
                                          {} );
                        }
                        catch (err)
                        {
                                print( err );
                        }
                });
        }

        duckOthersSwitchChanged( )
        {
                return (( newVal )
                async {
                        _duckOthers = newVal;

                        try
                        {
                                setDuck( );
                                setState( ( )
                                          {} );
                        }
                        catch (err)
                        {
                                print( err );
                        }
                });
        }

        @override
        Widget build( BuildContext context )
        {
                final recorderProgressIndicator = _isRecording
                                                  ? LinearProgressIndicator(
                        value: 100.0 / 160.0 * (this._dbLevel ?? 1) / 100,
                        valueColor: AlwaysStoppedAnimation<Color>( Colors.green ),
                        backgroundColor: Colors.red,
                        )
                                                  : Container( );
                final playerControls = ((!_canDisplayPlayerControls) && _isAudioPlayer)
                                       ? Container( child: Container( child: CircularProgressIndicator( ) ) )
                                       : Row(
                        children: <Widget>[
                                Container(
                                        width: 56.0,
                                        height: 56.0,
                                        child: ClipOval(
                                                child: FlatButton(
                                                        onPressed: onStartPlayerPressed( ),
                                                        padding: EdgeInsets.all( 8.0 ),
                                                        child: Image(
                                                                image: AssetImage( onStartPlayerPressed( ) != null ? 'res/icons/ic_play.png' : 'res/icons/ic_play_disabled.png' ),
                                                                ),
                                                        ),
                                                ),
                                        ),
                                Container(
                                        width: 56.0,
                                        height: 56.0,
                                        child: ClipOval(
                                                child: FlatButton(
                                                        onPressed: onPauseResumePlayerPressed( ),
                                                        padding: EdgeInsets.all( 8.0 ),
                                                        child: Image(
                                                                width: 36.0,
                                                                height: 36.0,
                                                                image: AssetImage( onPauseResumePlayerPressed( ) != null ? 'res/icons/ic_pause.png' : 'res/icons/ic_pause_disabled.png' ),
                                                                ),
                                                        ),
                                                ),
                                        ),
                                Container(
                                        width: 56.0,
                                        height: 56.0,
                                        child: ClipOval(
                                                child: FlatButton(
                                                        onPressed: onStopPlayerPressed( ),
                                                        padding: EdgeInsets.all( 8.0 ),
                                                        child: Image(
                                                                width: 28.0,
                                                                height: 28.0,
                                                                image: AssetImage( onStopPlayerPressed( ) != null ? 'res/icons/ic_stop.png' : 'res/icons/ic_stop_disabled.png' ),
                                                                ),
                                                        ),
                                                ),
                                        ),
                        ],
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        );
                final playerSlider = Container(
                            height: 56.0,
                            child: Slider(
                                        value: sliderCurrentPosition,
                                        min: 0.0,
                                        max: maxDuration,
                                        onChanged: ( double value )
                                        async {
                                                await flutterSoundModule.seekToPlayer( value.toInt( ) );
                                        },
                                        divisions: maxDuration == 0.0 ? 1 : maxDuration.toInt( ) ) );

                final dropdowns = makeDropdowns( context );
                final trackSwitch = Padding(
                        padding: const EdgeInsets.all( 8.0 ),
                        child: Row(
                                children: <Widget>[
                                        Padding(
                                                padding: const EdgeInsets.only( right: 4 ),
                                                child: Text( '"Flauto":' ),
                                                ),
                                        Switch(
                                                value: _isAudioPlayer,
                                                onChanged: audioPlayerSwitchChanged( ),
                                                ),
                                        Padding(
                                                padding: const EdgeInsets.only( right: 4.0 ),
                                                child: Text( 'Duck Others:' ),
                                                ),
                                        Switch(
                                                value: _duckOthers,
                                                onChanged: duckOthersSwitchChanged( ),
                                                ),
                                ],
                                ),
                        );

                Widget recorderSection = Column( crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                        Container(
                                margin: EdgeInsets.only( top: 12.0, bottom: 16.0 ),
                                child: Text(
                                        this._recorderTxt,
                                        style: TextStyle(
                                                fontSize: 35.0,
                                                color: Colors.black,
                                                ),
                                        ),
                                ),
                        _isRecording ? LinearProgressIndicator( value: 100.0 / 160.0 * (this._dbLevel ?? 1) / 100, valueColor: AlwaysStoppedAnimation<Color>( Colors.green ), backgroundColor: Colors.red ) : Container( ),
                        Row(
                                children: <Widget>[
                                        Container(
                                                width: 56.0,
                                                height: 50.0,
                                                child: ClipOval(
                                                        child: FlatButton(
                                                                onPressed: onStartRecorderPressed( ),
                                                                padding: EdgeInsets.all( 8.0 ),
                                                                child: Image(
                                                                        image: recorderAssetImage( ),
                                                                        ),
                                                                ),
                                                        ),
                                                ),
                                ],
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                ),
                ] );

                Widget playerSection = Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                                Container(
                                        margin: EdgeInsets.only( top: 12.0, bottom: 16.0 ),
                                        child: Text(
                                                this._playerTxt,
                                                style: TextStyle(
                                                        fontSize: 35.0,
                                                        color: Colors.black,
                                                        ),
                                                ),
                                        ),
                                Row(
                                        children: <Widget>[
                                                Container(
                                                        width: 56.0,
                                                        height: 50.0,
                                                        child: ClipOval(
                                                                child: FlatButton(
                                                                        onPressed: onStartPlayerPressed( ),
                                                                        disabledColor: Colors.white,
                                                                        padding: EdgeInsets.all( 8.0 ),
                                                                        child: Image(
                                                                                image: AssetImage( onStartPlayerPressed( ) != null ? 'res/icons/ic_play.png' : 'res/icons/ic_play_disabled.png' ),
                                                                                ),
                                                                        ),
                                                                ),
                                                        ),
                                                Container(
                                                        width: 56.0,
                                                        height: 50.0,
                                                        child: ClipOval(
                                                                child: FlatButton(
                                                                        onPressed: onPauseResumePlayerPressed( ),
                                                                        disabledColor: Colors.white,
                                                                        padding: EdgeInsets.all( 8.0 ),
                                                                        child: Image(
                                                                                width: 36.0,
                                                                                height: 36.0,
                                                                                image: AssetImage( onPauseResumePlayerPressed( ) != null ? 'res/icons/ic_pause.png' : 'res/icons/ic_pause_disabled.png' ),
                                                                                ),
                                                                        ),
                                                                ),
                                                        ),
                                                Container(
                                                        width: 56.0,
                                                        height: 50.0,
                                                        child: ClipOval(
                                                                child: FlatButton(
                                                                        onPressed: onStopPlayerPressed( ),
                                                                        disabledColor: Colors.white,
                                                                        padding: EdgeInsets.all( 8.0 ),
                                                                        child: Image(
                                                                                width: 28.0,
                                                                                height: 28.0,
                                                                                image: AssetImage( onStopPlayerPressed( ) != null ? 'res/icons/ic_stop.png' : 'res/icons/ic_stop_disabled.png' ),
                                                                                ),
                                                                        ),
                                                                ),
                                                        ),
                                        ],
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        ),
                                Container(
                                            height: 30.0,
                                            child: Slider(
                                                        value: sliderCurrentPosition,
                                                        min: 0.0,
                                                        max: maxDuration,
                                                        onChanged: ( double value )
                                                        async {
                                                                await flutterSoundModule.seekToPlayer( value.toInt( ) );
                                                        },
                                                        divisions: maxDuration == 0.0 ? 1 : maxDuration.toInt( ) ) ),
                        ],
                        );

                return MaterialApp(
                        home: Scaffold(
                                appBar: AppBar(
                                        title: const Text( 'Flutter Sound' ),
                                        ),
                                body: ListView(
                                        children: <Widget>[
                                                recorderSection,
                                                playerSection,
                                                dropdowns,
                                                trackSwitch,
                                        ],
                                        ),
                                ),
                        );
        }
}
