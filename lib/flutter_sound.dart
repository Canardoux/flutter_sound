/*
 * This is a flutter_sound module.
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

import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';
import 'dart:io' show Platform;
import 'dart:typed_data' show Uint8List;

import 'package:flutter/services.dart';
import 'package:flutter_sound/android_encoder.dart';
import 'package:flutter_sound/ios_quality.dart';
import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

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

enum t_AUDIO_STATE
{
        IS_STOPPED,
        IS_PLAYING,
        IS_PAUSED,
        IS_RECORDING,
}

enum t_IOS_SESSION_CATEGORY
{
        AMBIENT,
        MULTI_ROUTE,
        PLAY_AND_RECORD,
        PLAYBACK,
        RECORD,
        SOLO_AMBIENT,
}

final List<String> iosSessionCategory =
[
        'AVAudioSessionCategoryAmbient',
        'AVAudioSessionCategoryMultiRoute',
        'AVAudioSessionCategoryPlayAndRecord',
        'AVAudioSessionCategoryPlayback',
        'AVAudioSessionCategoryRecord',
        'AVAudioSessionCategorySoloAmbient',
];

enum t_IOS_SESSION_MODE
{
        DEFAULT,
        GAME_CHAT,
        MEASUREMENT,
        MOVIE_PLAYBACK,
        SPOKEN_AUDIO,
        VIDEO_CHAT,
        VIDEO_RECORDING,
        VOICE_CHAT,
        VOICE_PROMPT,
}

final List<String> iosSessionMode =
[
        'AVAudioSessionModeDefault',
        'AVAudioSessionModeGameChat',
        'AVAudioSessionModeMeasurement',
        'AVAudioSessionModeMoviePlayback',
        'AVAudioSessionModeSpokenAudio',
        'AVAudioSessionModeVideoChat',
        'AVAudioSessionModeVideoRecording',
        'AVAudioSessionModeVoiceChat',
        'AVAudioSessionModeVoicePrompt',
];

// Values for AUDIO_FOCUS_GAIN on Android
const int ANDROID_AUDIOFOCUS_GAIN = 1;
const int ANDROID_AUDIOFOCUS_GAIN_TRANSIENT = 2;
const int ANDROID_AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK = 3;
const int ANDROID_AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE = 4;

// Options for setSessionCategory on iOS
const int IOS_MIX_WITH_OTHERS = 0x1;
const int IOS_DUCK_OTHERS = 0x2;
const int IOS_INTERRUPT_SPOKEN_AUDIO_AND_MIX_WITH_OTHERS = 0x11;
const int IOS_ALLOW_BLUETOOTH = 0x4;
const int IOS_ALLOW_BLUETOOTH_A2DP = 0x20;
const int IOS_ALLOW_AIR_PLAY = 0x40;
const int IOS_DEFAULT_TO_SPEAKER = 0x8;


final List<String> defaultPaths = [
        'sound.aac', // DEFAULT
        'sound.aac', // CODEC_AAC
        'sound.opus', // CODEC_OPUS
        'sound.caf', // CODEC_CAF_OPUS
        'sound.mp3', // CODEC_MP3
        'sound.ogg', // CODEC_VORBIS
        'sound.wav', // CODEC_PCM
];


/// Return the file extension for the given path.
/// path can be null. We return null in this case.
String fileExtension( String path )
{
        if (path == null) return null;
        String r = p.extension( path );
        return r;
}

typedef void t_whenFinished( );
typedef void t_whenPaused ( bool paused );
typedef void t_onSkip ( );
typedef void t_updateProgress( int current, int max );


//FlutterSound flutterSound = FlutterSound( ); // Singleton

class FlutterSound
{
        static const MethodChannel _channel = const MethodChannel( 'flutter_sound' );
        static const MethodChannel _FFmpegChannel = const MethodChannel( 'flutter_ffmpeg' );
        static StreamController<RecordStatus> _recorderController;
        static StreamController<double> _dbPeakController;
        StreamController<PlayStatus> playerController;
        static bool isOppOpus = false; // Set by startRecorder when the user wants to record an ogg/opus
        static String savedUri; // Used by startRecorder/stopRecorder to keep the caller wanted uri
        static String tmpUri; // Used by startRecorder/stopRecorder to keep the temporary uri to record CAF


        /// The current state of the playback
        //Future<t_AUDIO_STATE> getPlayerState() async
        //{
        //t_AUDIO_STATE result = await getChannel().invokeMethod( 'getPlayerState', );
        //return result;
        //}

        /// The current state of the playback
        //t_AUDIO_STATE playbackState;

        /// The current state of the recorder
        //t_AUDIO_STATE _recordingState;
        //t_AUDIO_STATE get recorderState => _recordingState;


        /// Value ranges from 0 to 120
        Stream<double> get onRecorderDbPeakChanged
        => _dbPeakController.stream;

        Stream<RecordStatus> get onRecorderStateChanged
        => _recorderController.stream;

        Stream<PlayStatus> get onPlayerStateChanged
        => playerController.stream;

        t_whenFinished audioPlayerFinishedPlaying; // User callback "whenFinished:"
        t_whenPaused whenPause; // User callback "whenPaused:"
        t_onSkip onSkipForward; // User callback "whenPaused:"
        t_onSkip onSkipBackward; // User callback "whenPaused:"
        t_updateProgress onUpdateProgress;


        //bool get isPlaying => (  getPlayerState( ) == (t_AUDIO_STATE.IS_PLAYING) );

        bool get isRecording
        => audioState == t_AUDIO_STATE.IS_RECORDING;

        //bool isPlaying( ) => playbackState == t_AUDIO_STATE.IS_PLAYING || playbackState == t_AUDIO_STATE.IS_PAUSED;

        t_AUDIO_STATE audioState = t_AUDIO_STATE.IS_STOPPED;

        MethodChannel getChannel( )
        => _channel;

        Future<String> defaultPath( t_CODEC codec )
        async {
                Directory tempDir = await getTemporaryDirectory( );
                File fout = File( '${tempDir.path}/${defaultPaths[codec.index]}' );
                return fout.path;
        }

        Future<void> initializeMediaPlayer( )
        async {
                await getChannel( ).invokeMethod( 'initializeMediaPlayer' );
        }


        /// Resets the media player and cleans up the device resources. This must be
        /// called when the player is no longer needed.
        Future<void> releaseMediaPlayer( )
        async {
                // Stop the player playback before releasing
                await stopPlayer( );
                await getChannel( ).invokeMethod( 'releaseMediaPlayer' );
        }

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

        /// We use here our own ffmpeg "execute" procedure instead of the one provided by the flutter_ffmpeg plugin,
        /// so that the developers not interested by ffmpeg can use flutter_plugin without the flutter_ffmpeg plugin
        /// and without any complain from the link-editor.
        ///
        /// Executes FFmpeg with [commandArguments] provided.
        static Future<int> executeFFmpegWithArguments( List<String> arguments )
        async {
                try
                {
                        final Map<dynamic, dynamic> result = await _FFmpegChannel.invokeMethod(
                                    'executeFFmpegWithArguments', {'arguments': arguments} );
                        return result['rc'];
                }
                on PlatformException catch (e)
                {
                        print( "Plugin error: ${e.message}" );
                        return -1;
                }
        }

        /// Returns true if the specified encoder is supported by flutter_sound on this platform
        Future<bool> isEncoderSupported( t_CODEC codec )
        async {
                bool result;
                // For encoding ogg/opus on ios, we need to support two steps :
                // - encode CAF/OPPUS (with native Apple AVFoundation)
                // - remux CAF file format to OPUS file format (with ffmpeg)

                if ((codec == t_CODEC.CODEC_OPUS) && (Platform.isIOS))
                {
                        if (!await isFFmpegSupported( ))
                                result = false;
                        else
                                result = await getChannel( ).invokeMethod( 'isEncoderSupported',
                                                                                       <String, dynamic>{'codec': t_CODEC.CODEC_CAF_OPUS.index} );
                } else
                        result = await getChannel( ).invokeMethod(
                                    'isEncoderSupported', <String, dynamic>{'codec': codec.index} );
                return result;
        }


        /// Returns true if the specified decoder is supported by flutter_sound on this platform
        Future<bool> isDecoderSupported( t_CODEC codec )
        async {
                bool result;
                // For decoding ogg/opus on ios, we need to support two steps :
                // - remux OGG file format to CAF file format (with ffmpeg)
                // - decode CAF/OPPUS (with native Apple AVFoundation)
                if ((codec == t_CODEC.CODEC_OPUS) && (Platform.isIOS))
                {
                        if (!await isFFmpegSupported( ))
                                result = false;
                        else
                                result = await getChannel( ).invokeMethod( 'isDecoderSupported',
                                                                                       <String, dynamic>{'codec': t_CODEC.CODEC_CAF_OPUS.index} );
                } else
                        result = await getChannel( ).invokeMethod(
                                    'isDecoderSupported', <String, dynamic>{'codec': codec.index} );
                return result;
        }

        /// For iOS only.
        /// If this function is not called, everthing is managed by default by flutter_sound.
        /// If this function is called, it is probably called just once when the app starts.
        /// After calling this function, the caller is responsible for using correctly setActive
        ///    probably before startRecorder or startPlayer, and stopPlayer and stopRecorder
        Future<bool> iosSetCategory( t_IOS_SESSION_CATEGORY category, t_IOS_SESSION_MODE mode, int options )
        async {
                if (!Platform.isIOS)
                        return false;
                bool r = await getChannel( ).invokeMethod( 'iosSetCategory', <String, dynamic>{ 'category': iosSessionCategory[category.index], 'mode': iosSessionMode[mode.index], 'options': options} );
                return r;
        }


        /// For Android only.
        /// If this function is not called, everthing is managed by default by flutter_sound.
        /// If this function is called, it is probably called just once when the app starts.
        /// After calling this function, the caller is responsible for using correctly setActive
        ///    probably before startRecorder or startPlayer, and stopPlayer and stopRecorder
        Future<bool> androidAudioFocusRequest( int focusGain )
        async {
                if (!Platform.isAndroid)
                        return false;
                bool r = await getChannel( ).invokeMethod( 'androidAudioFocusRequest', <String, dynamic>{ 'focusGain': focusGain} );
                return r;
        }


        ///  After iosSetCategory() or androidAudioFocusRequest the caller must manage his audio session with this function
        Future<bool> setActive( bool enabled )
        async {
                bool r = await getChannel( ).invokeMethod( 'setActive', <String, dynamic>{ 'enabled': enabled} );
                return r;
        }

        Future<String> setSubscriptionDuration( double sec )
        {
                return getChannel( ).invokeMethod( 'setSubscriptionDuration', <String, dynamic>{
                        'sec': sec,
                } );
        }

        Future<dynamic> channelRecorderMethodCallHandler( MethodCall call ) // This procedure is superCharged in "flauto"
        {
                switch (call.method)
                {
                        default:
                                throw new ArgumentError( 'Unknown method ${call.method} ' );
                }
        }

        Future<void> _setRecorderCallback( )
        async {
                if (_recorderController == null)
                {
                        _recorderController = new StreamController.broadcast( );
                }
                if (_dbPeakController == null)
                {
                        _dbPeakController = new StreamController.broadcast( );
                }


                getChannel( ).setMethodCallHandler( ( MethodCall call )
                                                    {
                                                            // This lambda function is necessary because channelMethodCallHandler is a virtual function (polymorphism)
                                                            return channelMethodCallHandler( call );
                                                    } );
        }

        Future<dynamic> channelMethodCallHandler( MethodCall call ) // This procedure is superCharged in "flauto"
        {
                switch (call.method)
                {
                        case "updateProgress":
                                Map<String, dynamic> result = jsonDecode( call.arguments );
                                if (playerController != null)
                                        playerController.add( new PlayStatus.fromJSON( result ) );
                                if (onUpdateProgress != null)
                                {
                                        int cur = int.parse( result['current_position'] );
                                        int max = int.parse( result['duration'] );
                                        onUpdateProgress( cur, max );
                                }
                                break;

                        case "audioPlayerFinishedPlaying":
                                Map<String, dynamic> result = jsonDecode( call.arguments );
                                PlayStatus status = new PlayStatus.fromJSON( result );
                                if (status.currentPosition != status.duration)
                                {
                                        status.currentPosition = status.duration;
                                }
                                if (playerController != null)
                                        playerController.add( status );

                                audioState = t_AUDIO_STATE.IS_STOPPED;
                                _removePlayerCallback( );
                                if (audioPlayerFinishedPlaying != null)
                                        audioPlayerFinishedPlaying( );
                                break;

                        case 'pause':
                                {
                                        if (whenPause != null) whenPause( true );
                                }
                                break;

                        case 'resume':
                                {
                                        if (whenPause != null) whenPause( false );
                                }
                                break;


                        case "updateRecorderProgress":
                                Map<String, dynamic> result = json.decode( call.arguments );
                                if (_recorderController != null)
                                        _recorderController.add( new RecordStatus.fromJSON( result ) );
                                break;

                        case "updateDbPeakProgress":
                                if (_dbPeakController != null)
                                        _dbPeakController.add( call.arguments );
                                break;

                        case 'skipForward':
                                {
                                        if (onSkipForward != null) onSkipForward( );
                                }
                                break;

                        case 'skipBackward':
                                {
                                        if (onSkipBackward != null) onSkipBackward( );
                                }
                                break;


                        default:
                                throw new ArgumentError( 'Unknown method ${call.method}' );
                }
                return null;
        }

        Future<void> setPlayerCallback( )
        async {
                if (playerController == null)
                {
                        playerController = new StreamController.broadcast( );
                }

                getChannel( ).setMethodCallHandler( ( MethodCall call )
                                                    {
                                                            // This lambda function is necessary because channelMethodCallHandler is a virtual function (polymorphism)
                                                            return channelMethodCallHandler( call );
                                                    } );
        }


        void _removeRecorderCallback( )
        {
                if (_recorderController != null)
                {
                        _recorderController
                                ..add( null ) // ????? We keep that strange line for backwardcompatibility
                                ..close( );
                        _recorderController = null;
                }
        }


        void _removeDbPeakCallback( )
        {
                if (_dbPeakController != null)
                {
                        _dbPeakController
                                ..add( null )
                                ..close( );
                        _dbPeakController = null;
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


        Future<String> startRecorder( {
                                              String uri,
                                              int sampleRate = 16000, int numChannels = 1, int bitRate = 16000,
                                              t_CODEC codec = t_CODEC.CODEC_AAC,
                                              AndroidEncoder androidEncoder = AndroidEncoder.AAC,
                                              AndroidAudioSource androidAudioSource = AndroidAudioSource.MIC,
                                              AndroidOutputFormat androidOutputFormat = AndroidOutputFormat.DEFAULT,
                                              IosQuality iosQuality = IosQuality.LOW,
                                      } )
        async {
                // Request Microphone permission if needed
                Map<PermissionGroup, PermissionStatus> permission = await PermissionHandler( ).requestPermissions( [PermissionGroup.microphone] );
                if (permission[PermissionGroup.microphone] != PermissionStatus.granted)
                        throw new Exception( "Microphone permission not granted" );

                //if (_recordingState != t_AUDIO_STATE.IS_STOPPED) {
                // throw new RecorderRunningException('Recorder is not stopped.');
                //}
                if (audioState != null && audioState != t_AUDIO_STATE.IS_STOPPED)
                {
                        throw new RecorderRunningException( 'Recorder is not stopped.' );
                }
                if (!await isEncoderSupported( codec ))
                        throw new RecorderRunningException( 'Codec not supported.' );

                if (uri == null)
                        uri = await defaultPath( codec );


                // If we want to record OGG/OPUS on iOS, we record with CAF/OPUS and we remux the CAF file format to a regular OGG/OPUS.
                // We use FFmpeg for that task.
                if ((Platform.isIOS) &&
                    ( (codec == t_CODEC.CODEC_OPUS) || (fileExtension( uri ) == '.opus') ))
                {
                        savedUri = uri;
                        isOppOpus = true;
                        codec = t_CODEC.CODEC_CAF_OPUS;
                        Directory tempDir = await getTemporaryDirectory( );
                        File fout = File( '${tempDir.path}/flutter_sound-tmp.caf' );
                        if (fout.existsSync( )) // delete the old temporary file if it exists
                                await fout.delete( );
                        uri = fout.path;
                        tmpUri = uri;
                } else
                        isOppOpus = false;

                try
                {
                        var param = <String, dynamic>{
                                'path': uri,
                                'sampleRate': sampleRate,
                                'numChannels': numChannels,
                                'bitRate': bitRate,
                                'codec': codec.index,
                                'androidEncoder': androidEncoder?.value,
                                'androidAudioSource': androidAudioSource?.value,
                                'androidOutputFormat': androidOutputFormat?.value,
                                'iosQuality': iosQuality?.value
                        };

                        String result = await getChannel( ).invokeMethod( 'startRecorder', param );


                        _setRecorderCallback( );
                        audioState = t_AUDIO_STATE.IS_RECORDING;
                        // if the caller wants OGG/OPUS we must remux the temporary file
                        if ((result != null) && isOppOpus)
                        {
                                return savedUri;
                        }
                        return result;
                }
                catch (err)
                {
                        throw new Exception( err );
                }
        }

        Future<String> stopRecorder( )
        async {
                String result = await getChannel( ).invokeMethod( 'stopRecorder' );

                audioState = t_AUDIO_STATE.IS_STOPPED;

                _removeRecorderCallback( );
                _removeDbPeakCallback( );

                if (isOppOpus)
                {
                        // delete the target if it exists (ffmpeg gives an error if the output file already exists)
                        File f = File( savedUri );
                        if (f.existsSync( )) await f.delete( );
                        // The following ffmpeg instruction re-encode the Apple CAF to OPUS. Unfortunatly we cannot just remix the OPUS data,
                        // because Apple does not set the "extradata" in its private OPUS format.
                        var rc = await executeFFmpegWithArguments( [
                                                                           '-loglevel', 'error',
                                                                           '-y',
                                                                           '-i',
                                                                           tmpUri,
                                                                           '-c:a',
                                                                           'libopus',
                                                                           savedUri,
                                                                   ] ); // remux CAF to OGG
                        if (rc != 0) return null;
                        return savedUri;
                }
                return result;
        }

        /// Return the file extension for the given path.
        /// path can be null. We return null in this case.
        String fileExtension( String path )
        {
                if (path == null)
                        return null;
                String r = p.extension( path );
                return r;
        }

        Future<String> _startPlayer( String method, Map <String, dynamic> what )
        async {
                String result;
                await stopPlayer( ); // Just in case
                try
                {
                        t_CODEC codec = what['codec'];
                        String path = what['path']; // can be null
                        if (codec != null)
                                what['codec'] = codec.index; // Flutter cannot transfer an enum to a native plugin. We use an integer instead

                        // If we want to play OGG/OPUS on iOS, we remux the OGG file format to a specific Apple CAF envelope before starting the player.
                        // We use FFmpeg for that task.
                        if ((Platform.isIOS) &&
                            ( (codec == t_CODEC.CODEC_OPUS) || (fileExtension( path ) == '.opus') ))
                        {
                                Directory tempDir = await getTemporaryDirectory( );
                                File fout = File( '${tempDir.path}/flutter_sound-tmp.caf' );
                                if (fout.existsSync( )) // delete the old temporary file if it exists
                                        await fout.delete( );
                                // The following ffmpeg instruction does not decode and re-encode the file. It just remux the OPUS data into an Apple CAF envelope.
                                // It is probably very fast and the user will not notice any delay, even with a very large data.
                                // This is the price to pay for the Apple stupidity.
                                var rc = await executeFFmpegWithArguments( ['-loglevel', 'error', '-y', '-i', path, '-c:a', 'copy', fout.path,] ); // remux OGG to CAF
                                if (rc != 0)
                                        return null;
                                // Now we can play Apple CAF/OPUS
                                audioPlayerFinishedPlaying = what['whenFinished'];
                                what['whenFinished'] = null; // We must remove this parameter because _channel.invokeMethod() does not like it
                                result = await getChannel( ).invokeMethod( 'startPlayer', {'path': fout.path} );
                        } else
                        {
                                audioPlayerFinishedPlaying = what['whenFinished'];
                                what['whenFinished'] = null; // We must remove this parameter because _channel.invokeMethod() does not like it
                                result = await getChannel( ).invokeMethod( method, what );
                        }

                        if (result != null)
                        {
                                print( 'startPlayer result: $result' );
                                setPlayerCallback( );

                                audioState = t_AUDIO_STATE.IS_PLAYING;
                        }

                        return result;
                }
                catch (err)
                {
                        audioPlayerFinishedPlaying = null;
                        throw Exception( err );
                }
        }


        Future<String> startPlayer( String uri, {t_CODEC codec, whenFinished( ),} )
        async => _startPlayer( 'startPlayer', {'path': uri, 'codec': codec, 'whenFinished': whenFinished,} );

        Future<String> startPlayerFromBuffer( Uint8List dataBuffer, {t_CODEC codec, whenFinished( ),} )
        async {
                // If we want to play OGG/OPUS on iOS, we need to remux the OGG file format to a specific Apple CAF envelope before starting the player.
                // We write the data in a temporary file before calling ffmpeg.
                if ((codec == t_CODEC.CODEC_OPUS) && (Platform.isIOS))
                {
                        //if (playbackState == PlaybackState.PAUSED) {
                        //this.resumePlayer();
                        //playbackState = PlaybackState.PLAYING;
                        //return 'Player resumed';
                        //}
                        await stopPlayer( );
                        Directory tempDir = await getTemporaryDirectory( );
                        File inputFile = File( '${tempDir.path}/flutter_sound-tmp.opus' );
                        if (inputFile.existsSync( ))
                                await inputFile.delete( );
                        inputFile.writeAsBytesSync( dataBuffer ); // Write the user buffer into the temporary file
                        // Now we can play the temporary file
                        return await _startPlayer( 'startPlayer', {'path': inputFile.path, 'codec': codec, 'whenFinished': whenFinished,} ); // And play something that Apple will be happy with.
                } else
                        return await _startPlayer( 'startPlayerFromBuffer', {'dataBuffer': dataBuffer, 'codec': codec, 'whenFinished': whenFinished,} );
        }


        Future<String> stopPlayer( )
        async {
                audioState = t_AUDIO_STATE.IS_STOPPED;
                audioPlayerFinishedPlaying = null;

                try
                {
                        String result = await getChannel( ).invokeMethod( 'stopPlayer' );
                        return result;
                }
                catch (e)
                {}
                return null;
        }


        Future<String> _stopPlayerwithCallback( )
        async {
                if (audioPlayerFinishedPlaying != null)
                {
                        audioPlayerFinishedPlaying( );
                        audioPlayerFinishedPlaying = null;
                }

                return stopPlayer( );
        }


        Future<String> pausePlayer( )
        {
                if (audioState != t_AUDIO_STATE.IS_PLAYING)
                {
                        _stopPlayerwithCallback( ); // To recover a clean state
                        throw PlayerRunningException( 'Player is not playing.' ); // I am not sure that it is good to throw an exception here
                }
                audioState = t_AUDIO_STATE.IS_PAUSED;

                return getChannel( ).invokeMethod( 'pausePlayer' );
        }

        Future<String> resumePlayer( )
        {
                if (audioState != t_AUDIO_STATE.IS_PAUSED)
                {
                        _stopPlayerwithCallback( ); // To recover a clean state
                        throw PlayerRunningException( 'Player is not paused.' ); // I am not sure that it is good to throw an exception here
                }
                audioState = t_AUDIO_STATE.IS_PLAYING;
                return getChannel( ).invokeMethod( 'resumePlayer' );
        }

        Future<String> seekToPlayer( int milliSecs )
        {
                return getChannel( ).invokeMethod( 'seekToPlayer', <String, dynamic>{
                        'sec': milliSecs,
                } );
        }

        Future<String> setVolume( double volume )
        {
                double indexedVolume = Platform.isIOS ? volume * 100 : volume;
                if (volume < 0.0 || volume > 1.0)
                {
                        throw RangeError( 'Value of volume should be between 0.0 and 1.0.' );
                }

                return getChannel( ).invokeMethod( 'setVolume', <String, dynamic>{
                        'volume': indexedVolume,
                } );
        }

        /// Defines the interval at which the peak level should be updated.
        /// Default is 0.8 seconds
        Future<String> setDbPeakLevelUpdate( double intervalInSecs )
        {
                return getChannel( ).invokeMethod( 'setDbPeakLevelUpdate', <String, dynamic>{
                        'intervalInSecs': intervalInSecs,
                } );
        }

        /// Enables or disables processing the Peak level in db's. Default is disabled
        Future<String> setDbLevelEnabled( bool enabled )
        {
                return getChannel( ).invokeMethod( 'setDbLevelEnabled', <String, dynamic>{
                        'enabled': enabled,
                } );
        }

}

class RecordStatus
{
        final double currentPosition;

        RecordStatus.fromJSON( Map<String, dynamic> json )
                    : currentPosition = double.parse( json['current_position'] );

        @override
        String toString( )
        {
                return 'currentPosition: $currentPosition';
        }
}

class PlayStatus
{
        final double duration;
        double currentPosition;

        PlayStatus.fromJSON( Map<String, dynamic> json )
                    : duration = double.parse( json['duration'] ),
                            currentPosition = double.parse( json['current_position'] );

        @override
        String toString( )
        {
                return 'duration: $duration, '
                            'currentPosition: $currentPosition';
        }
}

class PlayerRunningException
            implements Exception
{
        final String message;

        PlayerRunningException( this.message );
}

class PlayerStoppedException
            implements Exception
{
        final String message;

        PlayerStoppedException( this.message );
}

class RecorderRunningException
            implements Exception
{
        final String message;

        RecorderRunningException( this.message );
}

class RecorderStoppedException
            implements Exception
{
        final String message;

        RecorderStoppedException( this.message );
}

