/*
 * flauto is a flutter_sound module.
 * flutter_sound is distributed with a MIT License
 *
 * Copyright (c) 2018 dooboolab
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 */

/*
 * flauto is a flutter_sound module.
 * Its purpose is to offer higher level functionnalities, using MediaService/MediaBrowser.
 * This module may use flutter_sound module, but flutter_sound module may not depends on this module.
 */

import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:io' show Platform;
import 'dart:typed_data' show Uint8List;

import 'package:flutter/services.dart';
import 'package:flutter_sound/android_encoder.dart';
import 'package:flutter_sound/ios_quality.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';


class PlayerNotInitializedException
            implements Exception
{
        final String message;

        PlayerNotInitializedException( this.message );
}

/// The track to play in the audio player
class Track
{
        /// The title of this track
        final String trackTitle;

        /// The buffer containing the audio file to play
        final Uint8List dataBuffer;

        /// The name of the author of this track
        final String trackAuthor;

        /// The path that points to the track audio file
        String trackPath;

        /// The URL that points to the album art of the track
        final String albumArtUrl;

        /// The codec of the audio file to play. If this parameter's value is null
        /// it will be set to [t_CODEC.DEFAULT].
        t_CODEC codec;

        Track( {
                       this.trackPath,
                       this.dataBuffer,
                       this.trackTitle,
                       this.trackAuthor,
                       this.albumArtUrl,
                       this.codec = t_CODEC.DEFAULT,
               } )
        {
                codec = codec == null ? t_CODEC.DEFAULT : codec;
                assert(trackPath != null || dataBuffer != null,
                'You should provide a path or a buffer for the audio content to play.');
                assert(
                (trackPath != null && dataBuffer == null) ||
                (trackPath == null && dataBuffer != null),
                'You cannot provide both a path and a buffer.');
        }

        /// Convert this object to a [Map] containing the properties of this object
        /// as values.
        Future<Map<String, dynamic>> toMap( )
        async {
                // Re-mux OGG format to play in iOS
                // await _adaptOggToIos(); // TODO: test it

                final map = {
                        "path": trackPath,
                        "dataBuffer": dataBuffer,
                        "title": trackTitle,
                        "author": trackAuthor,
                        "albumArt": albumArtUrl,
                        "bufferCodecIndex": codec?.index,
                };

                return map;
        }

        Future<void> _adaptOggToIos( )
        async {
                // If we want to play OGG/OPUS on iOS, we re-mux the OGG file format to a specific Apple CAF envelope before starting the player.
                // We use FFmpeg for that task.
                if ((Platform.isIOS) &&
                    ((codec == t_CODEC.CODEC_OPUS) ||
                     (fileExtension( trackPath ) == '.opus')))
                {
                        Directory tempDir = await getTemporaryDirectory( );
                        File fout = await File( '${tempDir.path}/flutter_sound-tmp.caf' );
                        if (fout.existsSync( )) // delete the old temporary file if it exists
                                await fout.delete( );
                        int rc;
                        String inputFileName = trackPath;
                        // The following ffmpeg instruction does not decode and re-encode the file. It just remux the OPUS data into an Apple CAF envelope.
                        // It is probably very fast and the user will not notice any delay, even with a very large data.
                        // This is the price to pay for the Apple stupidity.
                        if (dataBuffer != null)
                        {
                                // Write the user buffer into the temporary file
                                inputFileName = '${tempDir.path}/flutter_sound-tmp.opus';
                                File fin = await File( inputFileName );
                                fin.writeAsBytesSync( dataBuffer );
                        }
                        rc = await FlutterSound.executeFFmpegWithArguments( [
                                                                                    '-y',
                                                                                    '-loglevel',
                                                                                    'error',
                                                                                    '-i',
                                                                                    inputFileName,
                                                                                    '-c:a',
                                                                                    'copy',
                                                                                    fout.path,
                                                                            ] ); // remux OGG to CAF
                        if (rc != 0)
                        {
                                throw 'FFmpeg exited with code ${rc}';
                        }
                        // Now we can play Apple CAF/OPUS
                        trackPath = fout.path;
                }
        }

}

Flauto flauto = Flauto( ); // Singleton

class Flauto extends FlutterSound
{
        static const MethodChannel _channel = const MethodChannel( 'flauto' );
        StreamController<PlaybackState> _playbackStateChangedController;

        //StreamController<PlayStatus> _playerController;
        //Function _skipForward;
        //Function _skipBackward;

        // Whether the handler for when the user tries to skip forward was set
        //bool _skipTrackForwardHandlerSet = false;

        // Whether the handler for when the user tries to skip backward was set
        //bool _skipTrackBackwardHandlerSet = false;


        @override
        MethodChannel getChannel( )
        => _channel;

        /// Initializes the media player and all the callbacks for the player and the
        /// recorder. This must be called before all other media player and recorder
        /// methods.
        ///
        /// If [includeAudioPlayerFeatures] is true, the audio player specific
        /// features will be included (eg. playback handling via hardware buttons,
        /// lock screen controls). If you initialized the media player with the
        /// audio player features, but you don't want them anymore, you must
        /// re-initialize it. Do the same if you initialized the media player without
        /// the audio player features, but you need them now.
        ///
        /// [skipForwardHandler] and [skipBackwardForward] are functions that are
        /// called when the user tries to skip forward or backward using the
        /// notification controls. They can be null.
        ///
        /// Media player and recorder controls should be displayed only after this
        /// method has finished executing.
        Future<void> initializeMediaPlayer( )
        async {
                try
                {
                        await getChannel( ).invokeMethod( 'initializeMediaPlayer', <String, dynamic>{
                                'includeAudioPlayerFeatures': true,
                        } );
                        onSkipBackward = null;
                        onSkipForward = null;

                        //if (playerController == null)
                        //{
                                //playerController = new StreamController.broadcast( );
                        //}
                        if (_playbackStateChangedController == null)
                        {
                                _playbackStateChangedController = StreamController.broadcast( );
                        }

                        // Add the method call handler
                        getChannel( ).setMethodCallHandler( channelMethodCallHandler );
                }
                catch (err)
                {
                        throw err;
                }
        }

        /// Resets the media player and cleans up the device resources. This must be
        /// called when the player is no longer needed.
        Future<void> releaseMediaPlayer( )
        async {
                try
                {
                        // Stop the player playback before releasing
                        if (playbackState != PlaybackState.STOPPED) await stopPlayer( );
                        await getChannel( ).invokeMethod( 'releaseMediaPlayer' );

                        _removePlaybackStateCallback( );
                        _removePlayerCallback( );
                        playbackState = null;
                        onSkipBackward = null;
                        onSkipForward = null;
                }
                catch (err)
                {
                        print( 'err: $err' );
                        throw err;
                }
        }

        /// Plays the given [track]. [canSkipForward] and [canSkipBackward] must be
        /// passed to provide information on whether the user can skip to the next
        /// or to the previous song in the lock screen controls.
        ///
        /// This method should only be used if the   player has been initialize
        /// with the audio player specific features.
        Future<String> startPlayerFromTrack(
                    Track track,
                    {
                            t_CODEC codec,
                            t_whenFinished whenFinished,
                            t_whenPaused whenPaused,
                            t_onSkip onSkipForward = null,
                            t_onSkip onSkipBackward = null,
                            t_updateProgress onUpdateProgress = null,
                    } )
        async {
                // Check whether we can start the player
                if (playbackState != null &&
                    playbackState != PlaybackState.STOPPED)
                {
                        throw PlayerRunningException(
                                    'Cannot start player in playback state "$playbackState". The player '
                                                'must be just initialized or in "${PlaybackState.STOPPED}" '
                                                'state' );
                }

                // Check the current codec is not supported on this platform
                if (!await flutterSound.isDecoderSupported( track.codec ))
                {
                        throw PlayerRunningException( 'The selected codec is not supported on '
                                                                  'this platform.' );
                }


                await track._adaptOggToIos( );

                final trackMap = await track.toMap( );


                audioPlayerFinishedPlaying = whenFinished;
                this.whenPause = whenPaused;
                this.onSkipForward = onSkipForward;
                this.onSkipBackward = onSkipBackward;
                this.onUpdateProgress = onUpdateProgress;
                setPlayerCallback( );
                return getChannel( ).invokeMethod( 'startPlayerFromTrack', <String, dynamic>
                {
                        'track': trackMap,
                        'canSkipForward': onSkipForward != null,
                        'canSkipBackward': onSkipBackward != null,
                } );
        }


        Future<dynamic> channelMethodCallHandler( MethodCall call )
        {
                switch (call.method)
                {
                        case 'audioPlayerFinishedPlaying':
                                {
                                        Map<String, dynamic> result = jsonDecode( call.arguments );
                                        PlayStatus status = new PlayStatus.fromJSON( result );
                                        if (status.currentPosition != status.duration)
                                        {
                                                status.currentPosition = status.duration;
                                        }
                                        if (playerController != null) playerController.add( status );
                                        if (_playbackStateChangedController != null)
                                        {
                                                //playbackState = PlaybackState.STOPPED;
                                                _playbackStateChangedController.add( PlaybackState.STOPPED );
                                        }
                                        playbackState = PlaybackState.STOPPED;
                                        if (audioPlayerFinishedPlaying != null)
                                        {
                                                audioPlayerFinishedPlaying( );
                                                audioPlayerFinishedPlaying = null;
                                        }
                                }
                                break;

                        case 'updatePlaybackState':
                                {
                                        switch (call.arguments)
                                        {
                                                case 0:
                                                        playbackState = PlaybackState.PLAYING;
                                                        break;
                                                case 1:
                                                        playbackState = PlaybackState.PAUSED;
                                                        break;
                                                case 2:
                                                        playbackState = PlaybackState.STOPPED;
                                                        break;
                                                default:
                                                        throw Exception(
                                                                    'An invalid playback state was given to updatePlaybackState.' );
                                        }

                                        // If the controller has been initialized notify the listeners that the
                                        // playback state has changed.
                                        if (_playbackStateChangedController != null)
                                        {
                                                _playbackStateChangedController.add( playbackState );
                                        }
                                }
                                break;


                        default:
                                super.channelMethodCallHandler( call );
                }
        }

        void _removePlaybackStateCallback( )
        {
                if (_playbackStateChangedController != null)
                {
                        _playbackStateChangedController.close( );
                        _playbackStateChangedController = null;
                }
        }

        void _removePlayerCallback( )
        {
                if (playerController != null)
                {
                        playerController
                                ..add( null )
                                ..close( );
                        playerController = null;
                }
        }
}
