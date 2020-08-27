package com.dooboolab.fluttersound;
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




import android.content.Context;
import android.media.MediaPlayer;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import android.media.AudioFocusRequest;

import java.io.File;
import java.io.FileOutputStream;
import java.util.HashMap;
import java.util.Map;
import java.util.Timer;
import java.util.TimerTask;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

// SDK compatibility
// -----------------

class sdkCompat
{
	static final int AUDIO_ENCODER_VORBIS = 6; // MediaRecorder.AudioEncoder.VORBIS added in API level 21
	static final int AUDIO_ENCODER_OPUS   = 7; // MediaRecorder.AudioEncoder.OPUS added in API level 29
	static final int OUTPUT_FORMAT_OGG    = 11; // MediaRecorder.OutputFormat.OGG added in API level 29
	static final int VERSION_CODES_M      = 23; // added in API level 23
	static final int ENCODING_PCM_16BIT   = 2;
	static final int ENCODING_OPUS        = 20; // Android R
}

//-------------------------------------------------------------------------------------------------------------


public class FlutterSoundPlayer extends Session implements MediaPlayer.OnErrorListener
{

	static boolean _isAndroidDecoderSupported[] = {
		true, // DEFAULT
		true, // aacADTS				// OK
		true,//Build.VERSION.SDK_INT >= 23, // opusOGG	// NOK
		false, // opusCAF				// NOK
		true, // MP3					// OK
		true,//Build.VERSION.SDK_INT >= 23, // vorbisOGG// OK
		true, // pcm16 // Really ???
		true, // pcm16WAV				// OK
		false, // pcm16AIFF				// OK
		false, // pcm16CAF				// NOK
		true, // flac					// OK
		true, // aacMP4					// OK
		true, // amrNB					// OK
		true, // amrWB					// OK
	};


	String extentionArray[] = {
		".aac" // DEFAULT
		, ".aac" // CODEC_AAC
		, ".opus" // CODEC_OPUS
		, "_opus.caf" // CODEC_CAF_OPUS (this is apple specific)
		, ".mp3" // CODEC_MP3
		, ".ogg" // CODEC_VORBIS
		, ".pcm" // CODEC_PCM
		, ".wav"
		, ".aiff"
		, "._pcm.caf"
		, ".flac"
		, ".mp4"
		, ".amr" // amrNB
		, ".amr" // amrWB
	};


	enum PlayerState {
		/// Player is stopped
		isStopped,
		/// Player is playing
		isPlaying,
		/// Player is paused
		isPaused,
	}



	final static  String           TAG         = "FlutterSoundPlugin";
	//final         PlayerAudioModel model       = new PlayerAudioModel ();
	int subsDurationMillis = 0;
	MediaPlayer mediaPlayer                    = null;
	private       Timer            mTimer      = new Timer ();
	final private Handler          mainHandler = new Handler (Looper.getMainLooper ());
	boolean pauseMode;


	static final String ERR_UNKNOWN           = "ERR_UNKNOWN";
	static final String ERR_PLAYER_IS_NULL    = "ERR_PLAYER_IS_NULL";
	static final String ERR_PLAYER_IS_PLAYING = "ERR_PLAYER_IS_PLAYING";


	FlautoManager getPlugin ()
	{
		return FlautoPlayerManager.flautoPlayerPlugin;
	}


	void initializeFlautoPlayer ( final MethodCall call, final Result result )
	{
		boolean r = prepareFocus(call);
		invokeMethodWithBoolean( "openAudioSessionCompleted", r );

		if (r)
		{

			result.success(getPlayerState());
		}
		else
			result.error ( ERR_UNKNOWN, ERR_UNKNOWN, "Failure to open session");

	}

	void releaseFlautoPlayer ( final MethodCall call, final Result result )
	{
		if (hasFocus)
			abandonFocus();
		releaseSession();
		result.success ( getPlayerState() );
	}

	Boolean isPaused() { return mediaPlayer != null && (!mediaPlayer.isPlaying ()) && pauseMode;}

	int getPlayerState()
	{
		if (mediaPlayer == null)
			return PlayerState.isStopped.ordinal();
		if (mediaPlayer.isPlaying())
		{
			assert(!pauseMode);
			return PlayerState.isPlaying.ordinal();
		}
		return pauseMode ? PlayerState.isPaused.ordinal() : PlayerState.isStopped.ordinal();
	}


	public void startPlayer ( final MethodCall call, final Result result )
	{

		Integer           _codec     = call.argument ( "codec" );
		FlutterSoundCodec codec      = FlutterSoundCodec.values()[ ( _codec != null ) ? _codec : 0 ];
		byte[]            dataBuffer = call.argument ( "fromDataBuffer" );
		String path = call.argument("fromURI");
		//if ( ! hasFocus ) // We always require focus because it could have been abandoned by another Session
		{
			requestFocus ();
		}
		if (dataBuffer != null)
		{
			try
			{
				File             f   = File.createTempFile ( "flutter_sound_buffer-" + Integer.toString(slotNo), extentionArray[ codec.ordinal () ] );
				FileOutputStream fos = new FileOutputStream ( f );
				fos.write ( dataBuffer );
				path = f.getPath();
			}
			catch ( Exception e )
			{
				result.error ( ERR_UNKNOWN, ERR_UNKNOWN, e.getMessage () );
				return;
			}

		}
		stop(); // To start a new clean playback
		if ( mediaPlayer != null )
		{


			if ( isPaused() )
			{
				mediaPlayer.start ();
				result.success ( getPlayerState());
				return;
			}

			Log.e ( TAG, "Player is already running. Stop it first." );
			result.success ( getPlayerState() );
			return;
		} else
		{
			mediaPlayer = new MediaPlayer () ;
		}

		mTimer = new Timer ();

		try
		{
			if ( path == null )
			{
				//this.model.getMediaPlayer ().setDataSource ( PlayerAudioModel.DEFAULT_FILE_LOCATION );
				result.error( ERR_UNKNOWN, ERR_UNKNOWN, "path is NULL");
				return;
			}
			//else
			{
				mediaPlayer.setDataSource (  path );
			}
			final String pathFile = path;
			mediaPlayer.setOnPreparedListener ( mp -> onPrepared(mp, pathFile)	);
			/*
			 * Detect when finish playing.
			 */
			mediaPlayer.setOnCompletionListener ( mp -> onCompletion(mp) );
			mediaPlayer.setOnErrorListener(this);

			mediaPlayer.prepare ();
		}
		catch ( Exception e )
		{
			Log.e ( TAG, "startPlayer() exception" );
			result.error ( ERR_UNKNOWN, ERR_UNKNOWN, e.getMessage () );
			return;
		}
		result.success ( getPlayerState());
	}

	public void startPlayerFromTrack ( final MethodCall call, final Result result )
	{
		result.error ( ERR_UNKNOWN, ERR_UNKNOWN, "Must be initialized With UI" );
	}

	public boolean onError(MediaPlayer mp, int what, int extra)
	{
	// ... react appropriately ...
	// The MediaPlayer has moved to the Error state, must be reset!
	return false;
	}


	// listener called when media player has completed playing.
	private void onCompletion(MediaPlayer mp)
	{
			/*
			 * Reset player.
			 */
			Log.d(TAG, "Playback completed.");
			assert(mp == mediaPlayer);
			mTimer.cancel();
			if (mp.isPlaying()) {
				mp.stop();
			}
			mp.reset();
			mp.release();
			mediaPlayer = null;
			pauseMode = false;
			assert(getPlayerState() == 0);
			invokeMethodWithInteger("audioPlayerFinishedPlaying", getPlayerState() );
	}

	// Listener called when media player has completed preparation.
	private void onPrepared(MediaPlayer mp, String path)
	{
		Log.d(TAG, "mediaPlayer prepared and started");
		mp.start();

		mainHandler.post(new Runnable()
		{
			@Override
			public void run() {
				long duration = 0;
				try
				{
					 duration = mp.getDuration();
				} catch(Exception e)
				{
					System.out.println(e.toString());
				}
				invokeMethodWithInteger("startPlayerCompleted", (int) duration);
			}
		});
		/*
		 * Set timer task to send event to RN.
		 */
		TimerTask mTask = new TimerTask() {
			@Override
			public void run() {
					mainHandler.post(new Runnable()
					{
						@Override
						public void run()
						{
							try {

								long position = mp.getCurrentPosition();
								long duration = mp.getDuration();
								if (position > duration)
								{
									assert(position <= duration);
								}

								Map<String, Object> dic = new HashMap<String, Object> ();
								dic.put ( "position", position );
								dic.put ( "duration", duration );
								dic.put ( "playerStatus", getPlayerState() );

								invokeMethodWithMap("updateProgress", dic);
							} catch (Exception e)
							{
								Log.d(TAG, "Exception: " + e.toString());
								stop();
							}
						}
					});


			}
		};

		if (subsDurationMillis > 0)
			mTimer.schedule(mTask, 0, subsDurationMillis);
	}

	void stop()
	{
		pauseMode = false;
		mTimer.cancel ();

		if ( mediaPlayer == null )
		{
			return;
		}

		try
		{
			mediaPlayer.stop ();
			mediaPlayer.reset ();
			mediaPlayer.release ();
			mediaPlayer =  null ;
		}
		catch ( Exception e )
		{
			Log.e ( TAG, "stopPlay exception: " + e.getMessage () );
		}

	}


	public void stopPlayer ( final MethodCall call, final Result result )
	{
		stop();
		result.success ( getPlayerState());
	}

	public void isDecoderSupported ( final MethodCall call, final Result result )
	{
		int     _codec = call.argument ( "codec" );
		boolean b      = _isAndroidDecoderSupported[ _codec ];
		//if ( Build.VERSION.SDK_INT < 23 )
		{
			//if ( ( _codec == CODEC_OPUS ) || ( _codec == CODEC_VORBIS ) )
			{
				//b = false;
			}
		}
		result.success (b );

	}

	public void pausePlayer ( final MethodCall call, final Result result )
	{
		if ( mediaPlayer == null )
		{
			result.error ( ERR_PLAYER_IS_NULL, "pausePlayer()", ERR_PLAYER_IS_NULL );
			return;
		}
		try
		{
			mediaPlayer.pause ();
			pauseMode = true;
			result.success ( getPlayerState());
		}
		catch ( Exception e )
		{
			Log.e ( TAG, "pausePlay exception: " + e.getMessage () );
			result.error ( ERR_UNKNOWN, ERR_UNKNOWN, e.getMessage () );
		}

	}

	public void resumePlayer ( final MethodCall call, final Result result )
	{
		if ( mediaPlayer == null )
		{
			result.error ( ERR_PLAYER_IS_NULL, "resumePlayer", ERR_PLAYER_IS_NULL );
			return;
		}

		if ( mediaPlayer.isPlaying () )
		{
			result.error ( ERR_PLAYER_IS_PLAYING, ERR_PLAYER_IS_PLAYING, ERR_PLAYER_IS_PLAYING );
			return;
		}
		pauseMode = false;
		try
		{
			// Is it really good ? // mediaPlayer.seekTo ( mediaPlayer.getCurrentPosition () );
			mediaPlayer.start ();
			result.success ( getPlayerState());
		}
		catch ( Exception e )
		{
			Log.e ( TAG, "mediaPlayer resume: " + e.getMessage () );
			result.error ( ERR_UNKNOWN, ERR_UNKNOWN, e.getMessage () );
		}
	}

	public void seekToPlayer ( final MethodCall call, final Result result )
	{
		int millis = call.argument ( "duration" ) ;

		if ( mediaPlayer == null )
		{
			result.error ( ERR_PLAYER_IS_NULL, "seekToPlayer()", ERR_PLAYER_IS_NULL );
			return;
		}

		int currentMillis = mediaPlayer.getCurrentPosition ();
		Log.d ( TAG, "currentMillis: " + currentMillis );
		// millis += currentMillis; [This was the problem for me]

		Log.d ( TAG, "seekTo: " + millis );

		mediaPlayer.seekTo ( millis );
		result.success (getPlayerState() );
	}

	public void setVolume ( final MethodCall call, final Result result )
	{
		double volume = call.argument ( "volume" );

		if ( mediaPlayer == null )
		{
			result.error ( ERR_PLAYER_IS_NULL, "setVolume()", ERR_PLAYER_IS_NULL );
			return;
		}

		float mVolume = ( float ) volume;
		mediaPlayer.setVolume ( mVolume, mVolume );
		result.success ( getPlayerState());
	}


	public void setSubscriptionDuration ( final MethodCall call, Result result )
	{
		if ( call.argument ( "milliSec" ) == null )
		{
			return;
		}
		int duration = call.argument ( "milliSec" );

		subsDurationMillis = duration;
		result.success ( getPlayerState());
	}

	void androidAudioFocusRequest ( final MethodCall call, final Result result )
	{
		Integer focusGain = call.argument ( "focusGain" );

		if ( Build.VERSION.SDK_INT >= Build.VERSION_CODES.O )
		{
			audioFocusRequest = new AudioFocusRequest.Builder ( focusGain )
				// .setAudioAttributes(mPlaybackAttributes)
				// .setAcceptsDelayedFocusGain(true)
				// .setWillPauseWhenDucked(true)
				// .setOnAudioFocusChangeListener(this, mMyHandler)
				.build ();
			Boolean b = true;

			result.success (getPlayerState() );
		} else
		{
			Boolean b = false;
			result.success (getPlayerState() );
		}
	}
	void setActive ( final MethodCall call, final Result result )
	{
		Boolean enabled = call.argument ( "enabled" );

		Boolean b = false;
		try
		{
			if ( enabled )
			{
				b  = requestFocus ();
			} else
			{

				b             = abandonFocus ();
			}
		}
		catch ( Exception e )
		{
			b = false;
		}
		result.success (getPlayerState() );
	}

	void getProgress ( final MethodCall call, final Result result )
	{
		long position = 0;
		long duration = 0;
		if ( mediaPlayer != null ) {
			 position = mediaPlayer.getCurrentPosition();
			 duration = mediaPlayer.getDuration();
		}
		if (position > duration)
		{
			assert(position <= duration);
		}

		Map<String, Object> dic = new HashMap<String, Object> ();
		dic.put ( "position", position );
		dic.put ( "duration", duration );
		dic.put ( "playerStatus", getPlayerState() );
		dic.put ( "slotNo", slotNo);
		result.success(dic);
	}

	void nowPlaying ( final MethodCall call, final Result result )
	{
		// TODO
		result.success (getPlayerState() );
	}


	void setUIProgressBar ( final MethodCall call, final Result result )
	{
		// TODO
		result.success (getPlayerState() );

	}

	void getResourcePath ( final MethodCall call, final Result result )
	{
		// TODO
		result.success ("");

	}

	void getPlayerState ( final MethodCall call, final Result result )
	{
		result.success (getPlayerState());
	}
}

//-------------------------------------------------------------------------------------------------------------
