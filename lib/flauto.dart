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
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:io' show Platform;
import 'dart:typed_data' show Uint8List;

import 'package:flauto/flutter_sound.dart';
import 'package:flauto/track_player.dart';
import 'package:flauto/flauto_recorder.dart';
import 'package:flauto/flauto_player.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';


// this enum MUST be synchronized with fluttersound/AudioInterface.java  and ios/Classes/FlutterSoundPlugin.h
enum t_CODEC
{
        DEFAULT,
        CODEC_AAC,
        CODEC_OPUS,
        CODEC_CAF_OPUS, // Apple encapsulates its bits in its own special envelope : .caf instead of a regular ogg/opus (.opus). This is completely stupid, this is Apple.
        CODEC_MP3,
        CODEC_VORBIS,
        CODEC_PCM,
}

FlutterFFmpeg flutterFFmpeg ;
FlutterFFmpegConfig _flutterFFmpegConfig ;

//!!!const MethodChannel _FFmpegChannel = const MethodChannel( 'flutter_ffmpeg' );

/*!!!
/// Returns true if the flutter_ffmpeg plugin is really plugged in
Future<bool> isFFmpegSupported( )
async {
        try
        {
                await _FFmpegChannel.invokeMethod( 'getFFmpegVersion' );
                await _FFmpegChannel.invokeMethod( 'getPlatform' );
                await _FFmpegChannel.invokeMethod( 'getPackageName' );
                return true;
        }
        catch (e)
        {
                return false;
        }
}
*/

/// We use here our own ffmpeg "execute" procedure instead of the one provided by the flutter_ffmpeg plugin,
/// so that the developers not interested by ffmpeg can use flutter_plugin without the flutter_ffmpeg plugin
/// and without any complain from the link-editor.
///
/// Executes FFmpeg with [commandArguments] provided.
Future<int> executeFFmpegWithArguments( List<String> arguments )
{
        if(flutterFFmpeg == null)
                flutterFFmpeg = new FlutterFFmpeg();
        return flutterFFmpeg.executeWithArguments(arguments);
        /* !!!
        try
        {
                if (!await isFFmpegSupported( ))
                        return -1;
                final Map<dynamic, dynamic> result = await _FFmpegChannel.invokeMethod( 'executeFFmpegWithArguments', {'arguments': arguments} );
                return result['rc'];
        }
        on PlatformException catch (e)
        {
                print( "Plugin error: ${e.message}" );
                return -1;
        }

         */
}


/// We use here our own ffmpeg "getLastReturnCode" procedure instead of the one provided by the flutter_ffmpeg plugin,
/// so that the developers not interested by ffmpeg can use flutter_plugin without the flutter_ffmpeg plugin
/// and without any complain from the link-editor.
///
/// Returns return code of last executed command.
Future<int> getLastFFmpegReturnCode( )
{
        //if(_flutterFFmpeg == null)
                //_flutterFFmpeg = new FlutterFFmpeg();
        if ( _flutterFFmpegConfig == null)
                _flutterFFmpegConfig = new FlutterFFmpegConfig();
        return _flutterFFmpegConfig.getLastReturnCode();
        /*
        try
        {
                final Map<dynamic, dynamic> result =
                await _FFmpegChannel.invokeMethod( 'getLastReturnCode' );
                return result['lastRc'];
        }
        on PlatformException catch (e)
        {
                print( "Plugin error: ${e.message}" );
                return -1;
        }
         */
}

/// We use here our own ffmpeg "getLastCommandOutput" procedure instead of the one provided by the flutter_ffmpeg plugin,
/// so that the developers not interested by ffmpeg can use flutter_plugin without the flutter_ffmpeg plugin
/// and without any complain from the link-editor.
///
/// Returns log output of last executed command. Please note that disabling redirection using
/// This method does not support executing multiple concurrent commands. If you execute multiple commands at the same time, this method will return output from all executions.
/// [disableRedirection()] method also disables this functionality.
Future<String> getLastFFmpegCommandOutput( )
async {
        if ( _flutterFFmpegConfig == null)
                _flutterFFmpegConfig = new FlutterFFmpegConfig();
        return _flutterFFmpegConfig.getLastCommandOutput();
       /*
        try
        {
                final Map<dynamic, dynamic> result =
                await _FFmpegChannel.invokeMethod( 'getLastCommandOutput' );
                return result['lastCommandOutput'];
        }
        on PlatformException catch (e)
        {
                print( "Plugin error: ${e.message}" );
                return null;
        }

         */
}


/// This class is deprecated. It is just to keep backward compatibility.
/// New users must use the class TrackPlayer
@deprecated
class Flauto extends FlutterSound
{
        Flauto()
        {
                initializeMediaPlayer( );
        }

        void initializeMediaPlayer( )
        async
        {
                if (soundPlayer == null)
                        soundPlayer = TrackPlayer( );
                if (soundRecorder == null)
                        soundRecorder = FlautoRecorder( );
                await soundPlayer.initialize( );
                await soundRecorder.initialize( );
        }

        Future<String> startPlayerFromTrack(
                    Track track, {
                            t_CODEC codec,
                            t_whenFinished whenFinished,
                            t_whenPaused whenPaused,
                            t_onSkip onSkipForward = null,
                            t_onSkip onSkipBackward = null,
                    } ) async
        {
                TrackPlayer player = soundPlayer;
                await player.startPlayerFromTrack( track,
                                                     whenFinished: whenFinished,
                                                     onSkipBackward: onSkipBackward,
                                                     onSkipForward: onSkipForward,
                                             );
        }


}
