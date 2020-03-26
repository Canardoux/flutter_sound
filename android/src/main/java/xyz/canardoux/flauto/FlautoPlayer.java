package xyz.canardoux.flauto;
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


import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;
import android.media.MediaPlayer;
import android.media.MediaRecorder;
import android.media.AudioManager;
import android.os.Build;
import android.os.Environment;
import android.os.Handler;
import android.os.SystemClock;
import android.support.v4.media.MediaMetadataCompat;
import android.support.v4.media.session.PlaybackStateCompat;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.arch.core.util.Function;
import androidx.core.app.ActivityCompat;

import android.media.AudioFocusRequest;

import java.io.*;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;
import java.io.FileOutputStream;
import java.util.HashMap;
import java.util.Timer;
import java.util.TimerTask;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import java.util.concurrent.Callable;

import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;

class FlautoPlayerPlugin
	implements MethodCallHandler
{
	public static MethodChannel      channel;
	static        Context            androidContext;
	static        FlautoPlayerPlugin flautoPlayerPlugin; // singleton
	FlautoPlayer theFlautoPlayer; // Temporary !!!!!!!!!!!

	static boolean _isAndroidDecoderSupported[] = {
		true, // DEFAULT
		true, // AAC
		true, // OGG/OPUS
		false, // CAF/OPUS
		true, // MP3
		true, // OGG/VORBIS
		true, // WAV/PCM
	};


	final static int CODEC_OPUS   = 2;
	final static int CODEC_VORBIS = 5;


	public static void attachFlautoPlayer (
		Context ctx,
		BinaryMessenger messenger
	                                      )
	{
		flautoPlayerPlugin = new FlautoPlayerPlugin ();
		channel            = new MethodChannel ( messenger, "xyz.canardoux.flauto_player" );
		channel.setMethodCallHandler ( flautoPlayerPlugin );
		androidContext = ctx;

	}


	@Override
	public void onMethodCall (
		final MethodCall call,
		final Result result
	                         )
	{
		final String path = call.argument ( "path" );
		switch ( call.method )
		{

			case "initializeFlautoPlayer":
			{
				theFlautoPlayer = new FlautoPlayer ();
				theFlautoPlayer.initializeFlautoPlayer ( call, result );

				result.success ( true );
			}
			break;

			case "releaseFlautoPlayer":
			{
				theFlautoPlayer.releaseFlautoPlayer ( call, result );
				result.success ( true );
			}
			break;

			case "isDecoderSupported":
			{
				int     _codec = call.argument ( "codec" );
				boolean b      = _isAndroidDecoderSupported[ _codec ];
				if ( Build.VERSION.SDK_INT < 23 )
				{
					if ( ( _codec == CODEC_OPUS ) || ( _codec == CODEC_VORBIS ) )
					{
						b = false;
					}
				}
				result.success ( b );
			}
			break;

			case "startPlayer":
			{
				theFlautoPlayer.startPlayer ( path, result );
			}
			break;

			case "startPlayerFromBuffer":
			{
				Integer _codec     = call.argument ( "codec" );
				t_CODEC codec      = t_CODEC.values ()[ ( _codec != null ) ? _codec : 0 ];
				byte[]  dataBuffer = call.argument ( "dataBuffer" );
				theFlautoPlayer.startPlayerFromBuffer ( dataBuffer, codec, result );
			}
			break;

			case "stopPlayer":
			{
				theFlautoPlayer.stopPlayer ( result );
			}
			break;

			case "pausePlayer":
			{
				theFlautoPlayer.pausePlayer ( result );
			}
			break;

			case "resumePlayer":
			{
				theFlautoPlayer.resumePlayer ( result );
			}
			break;

			case "seekToPlayer":
			{
				int sec = call.argument ( "sec" );
				theFlautoPlayer.seekToPlayer ( sec, result );
			}
			break;

			case "setVolume":
			{
				double volume = call.argument ( "volume" );
				theFlautoPlayer.setVolume ( volume, result );
			}
			break;

			case "setSubscriptionDuration":
			{
				if ( call.argument ( "sec" ) == null )
				{
					return;
				}
				double duration = call.argument ( "sec" );
				theFlautoPlayer.setSubscriptionDuration ( duration, result );
			}
			break;

			case "androidAudioFocusRequest":
			{
				Integer audioFocusGain = call.argument ( "focusGain" );
				theFlautoPlayer.androidAudioFocusRequest ( audioFocusGain, result );
			}
			break;

			case "setActive":
			{
				Boolean b = call.argument ( "enabled" );
				theFlautoPlayer.setActive ( b, result );
			}
			break;

			default:
			{
				result.notImplemented ();
			}
			break;
		}
	}

}


// SDK compatibility
// -----------------

class sdkCompat
{
	static final int AUDIO_ENCODER_VORBIS = 6; // MediaRecorder.AudioEncoder.VORBIS added in API level 21
	static final int AUDIO_ENCODER_OPUS   = 7; // MediaRecorder.AudioEncoder.OPUS added in API level 29
	static final int OUTPUT_FORMAT_OGG    = 11; // MediaRecorder.OutputFormat.OGG added in API level 29
	static final int VERSION_CODES_M      = 23; // added in API level 23
}

class PlayerAudioModel
{
	final public static String DEFAULT_FILE_LOCATION = Environment.getDataDirectory ().getPath () + "/default.aac"; // SDK
	public              int    subsDurationMillis    = 10;

	private MediaPlayer mediaPlayer;
	private long        playTime = 0;


	public MediaPlayer getMediaPlayer ()
	{
		return mediaPlayer;
	}

	public void setMediaPlayer ( MediaPlayer mediaPlayer )
	{
		this.mediaPlayer = mediaPlayer;
	}

	public long getPlayTime ()
	{
		return playTime;
	}

	public void setPlayTime ( long playTime )
	{
		this.playTime = playTime;
	}
}

//-------------------------------------------------------------------------------------------------------------


public class FlautoPlayer
{


	enum t_SET_CATEGORY_DONE
	{
		NOT_SET,
		FOR_PLAYING, // Flutter_sound did it during startPlayer()
		BY_USER // The caller did it himself : flutterSound must not change that)
	}

	;

	String extentionArray[] = {
		".aac" // DEFAULT
		, ".aac" // CODEC_AAC
		, ".opus" // CODEC_OPUS
		, ".caf" // CODEC_CAF_OPUS (this is apple specific)
		, ".mp3" // CODEC_MP3
		, ".ogg" // CODEC_VORBIS
		, ".wav" // CODEC_PCM
	};


	final static  String           TAG         = "FlutterSoundPlugin";
	final         PlayerAudioModel model       = new PlayerAudioModel ();
	private       Timer            mTimer      = new Timer ();
	final private Handler          mainHandler = new Handler ();
	t_SET_CATEGORY_DONE setActiveDone     = t_SET_CATEGORY_DONE.NOT_SET;
	AudioFocusRequest   audioFocusRequest = null;
	AudioManager        audioManager;


	static final String ERR_UNKNOWN           = "ERR_UNKNOWN";
	static final String ERR_PLAYER_IS_NULL    = "ERR_PLAYER_IS_NULL";
	static final String ERR_PLAYER_IS_PLAYING = "ERR_PLAYER_IS_PLAYING";


	void initializeFlautoPlayer (
		final MethodCall call,
		final Result result
	                            )
	{
		audioManager = ( AudioManager ) FlautoPlayerPlugin.androidContext.getSystemService ( Context.AUDIO_SERVICE );
	}

	void releaseFlautoPlayer (
		final MethodCall call,
		final Result result
	                         )
	{
	}

	MethodChannel getChannel ()
	{
		return FlautoPlayerPlugin.channel;
	}

	public void startPlayer (
		final String path,
		final Result result
	                        )
	{
		if ( this.model.getMediaPlayer () != null )
		{
			Boolean isPaused = !this.model.getMediaPlayer ().isPlaying () && this.model.getMediaPlayer ().getCurrentPosition () > 1;

			if ( isPaused )
			{
				this.model.getMediaPlayer ().start ();
				result.success ( "player resumed." );
				return;
			}

			Log.e ( TAG, "Player is already running. Stop it first." );
			result.success ( "player is already running." );
			return;
		} else
		{
			this.model.setMediaPlayer ( new MediaPlayer () );
		}
		mTimer = new Timer ();

		try
		{
			if ( path == null )
			{
				this.model.getMediaPlayer ().setDataSource ( PlayerAudioModel.DEFAULT_FILE_LOCATION );
			} else
			{
				this.model.getMediaPlayer ().setDataSource ( path );
			}
			if ( setActiveDone == t_SET_CATEGORY_DONE.NOT_SET )
			{

				setActiveDone = t_SET_CATEGORY_DONE.FOR_PLAYING;
				requestFocus ();
			}

			this.model.getMediaPlayer ().setOnPreparedListener ( mp ->
			                                                     {
				                                                     Log.d ( TAG, "mediaPlayer prepared and start" );
				                                                     mp.start ();

				                                                     /*
				                                                      * Set timer task to send event to RN.
				                                                      */
				                                                     TimerTask mTask = new TimerTask ()
				                                                     {
					                                                     @Override
					                                                     public void run ()
					                                                     {
						                                                     // long time = mp.getCurrentPosition();
						                                                     // DateFormat format = new SimpleDateFormat("mm:ss:SS", Locale.US);
						                                                     // final String displayTime = format.format(time);
						                                                     try
						                                                     {
							                                                     JSONObject json = new JSONObject ();
							                                                     json.put ( "duration", String.valueOf ( mp.getDuration () ) );
							                                                     json.put ( "current_position", String.valueOf ( mp.getCurrentPosition () ) );
							                                                     mainHandler.post ( new Runnable ()
							                                                     {
								                                                     @Override
								                                                     public void run ()
								                                                     {
									                                                     getChannel ().invokeMethod ( "updateProgress", json.toString () );
								                                                     }
							                                                     } );

						                                                     }
						                                                     catch ( Exception e )
						                                                     {
							                                                     Log.d ( TAG, "Exception: " + e.toString () );
						                                                     }
					                                                     }
				                                                     };

				                                                     mTimer.schedule ( mTask, 0, model.subsDurationMillis );
				                                                     String resolvedPath = ( path == null ) ? PlayerAudioModel.DEFAULT_FILE_LOCATION : path;
				                                                     result.success ( ( resolvedPath ) );
			                                                     } );
			/*
			 * Detect when finish playing.
			 */
			this.model.getMediaPlayer ().setOnCompletionListener ( mp ->
			                                                       {
				                                                       /*
				                                                        * Reset player.
				                                                        */
				                                                       Log.d ( TAG, "Plays completed." );
				                                                       try
				                                                       {
					                                                       JSONObject json = new JSONObject ();
					                                                       json.put ( "duration", String.valueOf ( mp.getDuration () ) );
					                                                       json.put ( "current_position", String.valueOf ( mp.getCurrentPosition () ) );
					                                                       getChannel ().invokeMethod ( "audioPlayerFinishedPlaying", json.toString () );
				                                                       }
				                                                       catch ( Exception e )
				                                                       {
					                                                       Log.d ( TAG, "Json Exception: " + e.toString () );
				                                                       }
				                                                       mTimer.cancel ();
				                                                       if ( mp.isPlaying () )
				                                                       {
					                                                       mp.stop ();
				                                                       }
				                                                       if ( ( setActiveDone != t_SET_CATEGORY_DONE.BY_USER ) && ( setActiveDone != t_SET_CATEGORY_DONE.NOT_SET ) )
				                                                       {

					                                                       setActiveDone = t_SET_CATEGORY_DONE.NOT_SET;
					                                                       abandonFocus ();
				                                                       }
				                                                       mp.reset ();
				                                                       mp.release ();
				                                                       model.setMediaPlayer ( null );
			                                                       } );
			this.model.getMediaPlayer ().prepare ();
		}
		catch ( Exception e )
		{
			Log.e ( TAG, "startPlayer() exception" );
			result.error ( ERR_UNKNOWN, ERR_UNKNOWN, e.getMessage () );
		}
	}

	public void startPlayerFromBuffer (
		final byte[] dataBuffer,
		t_CODEC codec,
		final Result result
	                                  )
	{
		try
		{
			File             f   = File.createTempFile ( "flutter_sound", extentionArray[ codec.ordinal () ] );
			FileOutputStream fos = new FileOutputStream ( f );
			fos.write ( dataBuffer );
			startPlayer ( f.getAbsolutePath (), result );
		}
		catch ( Exception e )
		{
			result.error ( ERR_UNKNOWN, ERR_UNKNOWN, e.getMessage () );
		}
	}

	public void stopPlayer ( final Result result )
	{
		mTimer.cancel ();

		if ( this.model.getMediaPlayer () == null )
		{
			result.error ( ERR_PLAYER_IS_NULL, ERR_PLAYER_IS_NULL, ERR_PLAYER_IS_NULL );
			return;
		}
		if ( ( setActiveDone != t_SET_CATEGORY_DONE.BY_USER ) && ( setActiveDone != t_SET_CATEGORY_DONE.NOT_SET ) )
		{

			setActiveDone = t_SET_CATEGORY_DONE.NOT_SET;
			abandonFocus ();
		}

		try
		{
			this.model.getMediaPlayer ().stop ();
			this.model.getMediaPlayer ().reset ();
			this.model.getMediaPlayer ().release ();
			this.model.setMediaPlayer ( null );
			result.success ( "stopped player." );
		}
		catch ( Exception e )
		{
			Log.e ( TAG, "stopPlay exception: " + e.getMessage () );
			result.error ( ERR_UNKNOWN, ERR_UNKNOWN, e.getMessage () );
		}
	}

	public void pausePlayer ( final Result result )
	{
		if ( this.model.getMediaPlayer () == null )
		{
			result.error ( ERR_PLAYER_IS_NULL, ERR_PLAYER_IS_NULL, ERR_PLAYER_IS_NULL );
			return;
		}
		if ( ( setActiveDone != t_SET_CATEGORY_DONE.BY_USER ) && ( setActiveDone != t_SET_CATEGORY_DONE.NOT_SET ) )
		{

			setActiveDone = t_SET_CATEGORY_DONE.NOT_SET;
			abandonFocus ();
		}

		try
		{
			this.model.getMediaPlayer ().pause ();
			result.success ( "paused player." );
		}
		catch ( Exception e )
		{
			Log.e ( TAG, "pausePlay exception: " + e.getMessage () );
			result.error ( ERR_UNKNOWN, ERR_UNKNOWN, e.getMessage () );
		}

	}

	public void resumePlayer ( final Result result )
	{
		if ( this.model.getMediaPlayer () == null )
		{
			result.error ( ERR_PLAYER_IS_NULL, ERR_PLAYER_IS_NULL, ERR_PLAYER_IS_NULL );
			return;
		}

		if ( this.model.getMediaPlayer ().isPlaying () )
		{
			result.error ( ERR_PLAYER_IS_PLAYING, ERR_PLAYER_IS_PLAYING, ERR_PLAYER_IS_PLAYING );
			return;
		}
		if ( setActiveDone == t_SET_CATEGORY_DONE.NOT_SET )
		{

			setActiveDone = t_SET_CATEGORY_DONE.FOR_PLAYING;
			requestFocus ();
		}

		try
		{
			this.model.getMediaPlayer ().seekTo ( this.model.getMediaPlayer ().getCurrentPosition () );
			this.model.getMediaPlayer ().start ();
			result.success ( "resumed player." );
		}
		catch ( Exception e )
		{
			Log.e ( TAG, "mediaPlayer resume: " + e.getMessage () );
			result.error ( ERR_UNKNOWN, ERR_UNKNOWN, e.getMessage () );
		}
	}

	public void seekToPlayer (
		int millis,
		final Result result
	                         )
	{
		if ( this.model.getMediaPlayer () == null )
		{
			result.error ( ERR_PLAYER_IS_NULL, ERR_PLAYER_IS_NULL, ERR_PLAYER_IS_NULL );
			return;
		}

		int currentMillis = this.model.getMediaPlayer ().getCurrentPosition ();
		Log.d ( TAG, "currentMillis: " + currentMillis );
		// millis += currentMillis; [This was the problem for me]

		Log.d ( TAG, "seekTo: " + millis );

		this.model.getMediaPlayer ().seekTo ( millis );
		result.success ( String.valueOf ( millis ) );
	}

	public void setVolume (
		double volume,
		final Result result
	                      )
	{
		if ( this.model.getMediaPlayer () == null )
		{
			result.error ( ERR_PLAYER_IS_NULL, ERR_PLAYER_IS_NULL, ERR_PLAYER_IS_NULL );
			return;
		}

		float mVolume = ( float ) volume;
		this.model.getMediaPlayer ().setVolume ( mVolume, mVolume );
		result.success ( "Set volume" );
	}


	public void setSubscriptionDuration (
		double sec,
		Result result
	                                    )
	{
		this.model.subsDurationMillis = ( int ) ( sec * 1000 );
		result.success ( "setSubscriptionDuration: " + this.model.subsDurationMillis );
	}

	void androidAudioFocusRequest (
		Integer focusGain,
		final Result result
	                              )
	{
		if ( Build.VERSION.SDK_INT >= Build.VERSION_CODES.O )
		{
			audioFocusRequest = new AudioFocusRequest.Builder ( focusGain )
				// .setAudioAttributes(mPlaybackAttributes)
				// .setAcceptsDelayedFocusGain(true)
				// .setWillPauseWhenDucked(true)
				// .setOnAudioFocusChangeListener(this, mMyHandler)
				.build ();
			Boolean b = true;
			setActiveDone = t_SET_CATEGORY_DONE.NOT_SET;

			result.success ( b );
		} else
		{
			Boolean b = false;
			result.success ( b );
		}
	}

	boolean requestFocus ()
	{
		if ( Build.VERSION.SDK_INT >= Build.VERSION_CODES.O )
		{
			if ( audioFocusRequest == null )
			{
				audioFocusRequest = new AudioFocusRequest.Builder ( AudioManager.AUDIOFOCUS_GAIN )
					//.setAudioAttributes(mPlaybackAttributes)
					//.setAcceptsDelayedFocusGain(true)
					//.setWillPauseWhenDucked(true)
					//.setOnAudioFocusChangeListener(this, mMyHandler)
					.build ();
			}
			return ( audioManager.requestAudioFocus ( audioFocusRequest ) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED );
		} else
		{
			return false;
		}
	}

	boolean abandonFocus ()
	{
		if ( Build.VERSION.SDK_INT >= Build.VERSION_CODES.O )
		{
			if ( audioFocusRequest == null )
			{
				audioFocusRequest = new AudioFocusRequest.Builder ( AudioManager.AUDIOFOCUS_GAIN )
					//.setAudioAttributes(mPlaybackAttributes)
					//.setAcceptsDelayedFocusGain(true)
					//.setWillPauseWhenDucked(true)
					//.setOnAudioFocusChangeListener(this, mMyHandler)
					.build ();
			}
			return ( audioManager.abandonAudioFocusRequest ( audioFocusRequest ) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED );
		} else
		{
			return false;
		}

	}

	void setActive (
		boolean enabled,
		final Result result
	               )
	{
		Boolean b = false;
		try
		{
			if ( enabled )
			{
				if ( setActiveDone != t_SET_CATEGORY_DONE.NOT_SET )
				{ // Already activated. Nothing todo;
					setActiveDone = t_SET_CATEGORY_DONE.BY_USER;
					result.success ( b );
					return;
				}
				setActiveDone = t_SET_CATEGORY_DONE.BY_USER;
				b             = requestFocus ();
			} else
			{
				if ( setActiveDone == t_SET_CATEGORY_DONE.NOT_SET )
				{ // Already desactivated
					result.success ( b );
					return;
				}

				setActiveDone = t_SET_CATEGORY_DONE.NOT_SET;
				b             = abandonFocus ();
			}
		}
		catch ( Exception e )
		{
			b = false;
		}
		result.success ( b );
	}


}

//-------------------------------------------------------------------------------------------------------------
