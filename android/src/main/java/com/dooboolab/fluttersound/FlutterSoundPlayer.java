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
import android.media.AudioAttributes;
import android.media.AudioFormat;
import android.media.AudioManager;
import android.media.AudioTrack;
import android.media.MediaPlayer;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.os.SystemClock;
import android.util.Log;

import android.media.AudioFocusRequest;

import java.io.File;
import java.io.FileOutputStream;
import java.util.HashMap;
import java.util.Map;
import java.util.Timer;
import java.util.TimerTask;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel.Result;

import static androidx.core.content.ContextCompat.getSystemService;

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

abstract class PlayerInterface
{
	abstract void _startPlayer(String path, FlutterSoundPlayer flutterPlayer, int sampleRate, FlutterSoundPlayer theSession) throws Exception;
	abstract void _stop();
	abstract void _pausePlayer() throws Exception;
	abstract void _resumePlayer() throws Exception;
	abstract void _setVolume(float volume);
	abstract void _seekTo(int millisec);
	abstract boolean _isPlaying();
	abstract long _getDuration();
	abstract long _getCurrentPosition();
	abstract int feed(byte[] data) throws Exception;
	abstract void _finish() ;


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
	//MediaPlayer mediaPlayer                    = null;
	PlayerInterface player;
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


	int getPlayerState()
	{
		if (player == null)
			return PlayerState.isStopped.ordinal();
		if (player._isPlaying())
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

		if (path == null && codec == FlutterSoundCodec.pcm16)
		{
			player = new AudioTrackEngine();
		} else
		{
			player = new MediaPlayerEngine();
		}

		try
		{
			Integer		  _sampleRate  = 16000;
			if (call.argument ( "sampleRate" ) != null)
			{
				_sampleRate = call.argument ( "sampleRate" );
			}
			mTimer = new Timer();
			player._startPlayer(path, this, _sampleRate, this);
		}
		catch ( Exception e )
		{
			Log.e ( TAG, "startPlayer() exception" );
			result.error ( ERR_UNKNOWN, ERR_UNKNOWN, e.getMessage () );
			return;
		}
		result.success ( getPlayerState());
	}

	public void feed ( final MethodCall call, final Result result )
	{
		try
		{
			byte[] data = call.argument ( "data" );

			 int r = player.feed(data);
			 result.success (r);
		} catch (Exception e)
		{
			Log.e ( TAG, "feed() exception" );
			result.error ( ERR_UNKNOWN, ERR_UNKNOWN, e.getMessage () );
		}
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
	public void onCompletion()
	{
			/*
			 * Reset player.
			 */
			Log.d(TAG, "Playback completed.");
			stop();
			assert(getPlayerState() == 0);
			invokeMethodWithInteger("audioPlayerFinishedPlaying", getPlayerState() );
	}

	// Listener called when media player has completed preparation.
	public void onPrepared( )
	{
		Log.d(TAG, "mediaPlayer prepared and started");

		mainHandler.post(new Runnable()
		{
			@Override
			public void run() {
				long duration = 0;
				try
				{
					 duration = player._getDuration();
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

								long position = player._getCurrentPosition();
								long duration = player._getDuration();
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
		if (player != null)
			player._stop();
		player = null;
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
		try
		{
			player._pausePlayer();
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
		try
		{
			player._resumePlayer();
			pauseMode = false;
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

		if ( player == null )
		{
			result.error ( ERR_PLAYER_IS_NULL, "seekToPlayer()", ERR_PLAYER_IS_NULL );
			return;
		}


		Log.d ( TAG, "seekTo: " + millis );

		player._seekTo ( millis );
		result.success (getPlayerState() );
	}

	public void setVolume ( final MethodCall call, final Result result )
	{
		double volume = call.argument ( "volume" );

		if ( player == null )
		{
			result.error ( ERR_PLAYER_IS_NULL, "setVolume()", ERR_PLAYER_IS_NULL );
			return;
		}

		float mVolume = ( float ) volume;
		player._setVolume(mVolume);
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
		if ( player != null ) {
			 position = player._getCurrentPosition();
			 duration = player._getDuration();
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


class MediaPlayerEngine extends PlayerInterface
{
	MediaPlayer mediaPlayer = null;
	FlutterSoundPlayer flutterPlayer;

	void _startPlayer(String path, FlutterSoundPlayer aFlutterPlayer, int sampleRate, FlutterSoundPlayer theSession) throws Exception
 	{
 		mediaPlayer = new MediaPlayer();

		if (path == null)
		{
			throw new Exception("path is NULL");
		}
		this.flutterPlayer = aFlutterPlayer;
		mediaPlayer.setDataSource(path);
		final String pathFile = path;
		mediaPlayer.setOnPreparedListener(mp -> {mp.start(); flutterPlayer.onPrepared();});
		mediaPlayer.setOnCompletionListener(mp -> flutterPlayer.onCompletion());
		mediaPlayer.setOnErrorListener(flutterPlayer);
		mediaPlayer.prepare();
	}

	int feed(byte[] data) throws Exception
	{
		throw new Exception("Cannot feed a Media Player");
	}

	void _setVolume(float volume)
	{
		mediaPlayer.setVolume ( volume, volume );
	}

	void _stop() {
		if (mediaPlayer == null)
		{
			return;
		}

		try
		{
			mediaPlayer.stop();
		} catch (Exception e)
		{
		}

		try
		{
			mediaPlayer.reset();
		} catch (Exception e)
		{
		}

		try
		{
			mediaPlayer.release();
		} catch (Exception e)
		{
		}
		mediaPlayer = null;

	}

	void _finish() { // NO-OP
	}



	void _pausePlayer() throws Exception {
		if (mediaPlayer == null) {
			throw new Exception("pausePlayer()");
		}
		mediaPlayer.pause();
	}

	void _resumePlayer() throws Exception {
		if (mediaPlayer == null) {
			throw new Exception("resumePlayer");
		}

		if (mediaPlayer.isPlaying()) {
			throw new Exception("resumePlayer");
		}
		// Is it really good ? // mediaPlayer.seekTo ( mediaPlayer.getCurrentPosition () );
		mediaPlayer.start();
	}

	void _seekTo(int millisec)
	{
		mediaPlayer.seekTo ( millisec );
	}

	boolean _isPlaying()
	{
		return mediaPlayer.isPlaying ();
	}

	long _getDuration()
	{
		return mediaPlayer.getDuration();
	}

	long _getCurrentPosition()
	{
		return mediaPlayer.getCurrentPosition();
	}
}

//---------------------------------------------------------------------------------------------------------------------------------------------

class AudioTrackEngine extends PlayerInterface
{
	AudioTrack audioTrack = null;
	int sessionId = 0;
	long mPauseTime = 0;
	long mStartPauseTime = -1;
	long systemTime = 0;



	/* ctor */ AudioTrackEngine()
	{
		AudioManager audioManager = ( AudioManager ) FlautoPlayerManager.androidContext.getSystemService ( Context.AUDIO_SERVICE );
		sessionId = audioManager.generateAudioSessionId ();
	}


	void _startPlayer
		(
			String path,
			FlutterSoundPlayer flutterPlayer,
			int sampleRate,
			FlutterSoundPlayer theSession
		) throws Exception
	{
		AudioAttributes attributes = new AudioAttributes.Builder()
			.setLegacyStreamType(AudioManager.STREAM_MUSIC)
			.setUsage(AudioAttributes.USAGE_MEDIA)
			.setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
			.build();

		AudioFormat format = new AudioFormat.Builder()
			.setEncoding(AudioFormat.ENCODING_PCM_16BIT)
			.setSampleRate(sampleRate)
			.setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
			.build();
		audioTrack = new AudioTrack(attributes, format, 2048, AudioTrack.MODE_STREAM, sessionId);
		mPauseTime = 0;
		mStartPauseTime = -1;
		systemTime = SystemClock.elapsedRealtime();

		audioTrack.play();
		theSession.onPrepared( );
	}


	void _stop()
	{
		audioTrack.stop();
		audioTrack.release();
		audioTrack = null;

	}

	void _finish()
	{
	}



	void _pausePlayer() throws Exception
	{
		mStartPauseTime = SystemClock.elapsedRealtime ();
		audioTrack.pause();
	}


	void _resumePlayer() throws Exception
	{
		if (mStartPauseTime >= 0)
			mPauseTime += SystemClock.elapsedRealtime () - mStartPauseTime;
		mStartPauseTime = -1;

		audioTrack.play();

	}


	void _setVolume(float volume)
	{
		audioTrack.setVolume(volume);
	}


	void _seekTo(int millisec)
	{

	}


	boolean _isPlaying()
	{
		return audioTrack.getPlayState () == AudioTrack.PLAYSTATE_PLAYING;
	}


	long _getDuration()
	{
		return _getCurrentPosition(); // It would be better if we add what is in the input buffers and not still played
	}


	long _getCurrentPosition()
	{
		long time ;
		if (mStartPauseTime >= 0)
			time =   mStartPauseTime - systemTime - mPauseTime ;
		else
			time = SystemClock.elapsedRealtime() - systemTime - mPauseTime;
		return time;
	}


	int feed(byte[] data) throws Exception
	{
		if ( Build.VERSION.SDK_INT >= 23 )
		{
			return audioTrack.write(data, 0, data.length, AudioTrack.WRITE_NON_BLOCKING);
		} else
		{
			return audioTrack.write(data, 0, data.length);

		}
	}


}