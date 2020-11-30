package com.dooboolab.TauEngine;
/*
 * Copyright 2018, 2019, 2020 Dooboolab.
 *
 * This file is part of the Tau project.
 *
 * Tau is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License version 3 (LGPL-V3), as published by
 * the Free Software Foundation.
 *
 * Tau is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with the Tau project.  If not, see <https://www.gnu.org/licenses/>.
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
import java.lang.Thread;

//import static androidx.core.content.ContextCompat.getSystemService;
import com.dooboolab.TauEngine.Flauto.*;


public class FlautoPlayer extends FlautoSession implements MediaPlayer.OnErrorListener
{

	static boolean _isAndroidDecoderSupported[] = {
		true, // DEFAULT
		true, // aacADTS				// OK
		Build.VERSION.SDK_INT >= 23, // opusOGG	// (API 29 ???)
		Build.VERSION.SDK_INT >= 23, // opusCAF				/
		true, // MP3					// OK
		true, //Build.VERSION.SDK_INT >= 23, // vorbisOGG// OK
		true, // pcm16
		true, // pcm16WAV				// OK
		true, // pcm16AIFF				// OK
		true, // pcm16CAF				// NOK
		true, // flac					// OK
		true, // aacMP4					// OK
		true, // amrNB					// OK
		true, // amrWB					// OK
		false, // pcm8
		false, // pcmFloat32
		false, // pcmWebM
		true, // opusWebM
		true, // vorbisWebM
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
		, ".pcm" // pcm8
		, ".pcm" // pcmFloat323
		, ".webm" // pcmWebM
		, ".opus" // opusWebM
		, ".vorbis" // vorbisWebM
	};


	final static  String           TAG         = "FlautoPlayer";
	//final         PlayerAudioModel model       = new PlayerAudioModel ();
	long subsDurationMillis = 0;
	//MediaPlayer mediaPlayer                    = null;
	FlautoPlayerEngineInterface player;
	private       Timer            mTimer      = new Timer ();
	final private Handler          mainHandler = new Handler (Looper.getMainLooper ());
	boolean pauseMode;
	FlautoPlayerCallback m_callBack;


	static final String ERR_UNKNOWN           = "ERR_UNKNOWN";
	static final String ERR_PLAYER_IS_NULL    = "ERR_PLAYER_IS_NULL";
	static final String ERR_PLAYER_IS_PLAYING = "ERR_PLAYER_IS_PLAYING";

	/* ctor */ public FlautoPlayer(FlautoPlayerCallback callBack)
	{
		m_callBack = callBack;
	}


	public boolean initializeFlautoPlayer (t_AUDIO_FOCUS focus, t_SESSION_CATEGORY category, t_SESSION_MODE sessionMode, int audioFlags, t_AUDIO_DEVICE audioDevice)
	{
		boolean r = setAudioFocus(focus, category, sessionMode, audioFlags, audioDevice);
		m_callBack.openAudioSessionCompleted(r);
		return r;
	}

	public void releaseFlautoPlayer ( )
	{
		if (hasFocus)
			abandonFocus();
		releaseSession();
	}


	public t_PLAYER_STATE getPlayerState()
	{
		if (player == null)
			return t_PLAYER_STATE.PLAYER_IS_STOPPED;
		if (player._isPlaying())
		{
			if (pauseMode)
				throw new RuntimeException();
			return t_PLAYER_STATE.PLAYER_IS_PLAYING;
		}
		return pauseMode ? t_PLAYER_STATE.PLAYER_IS_PAUSED : t_PLAYER_STATE.PLAYER_IS_STOPPED;
	}


	public boolean startPlayer (t_CODEC codec, String fromURI, byte[] dataBuffer, int numChannels, int sampleRate, int blockSize )
	{

		//if ( ! hasFocus ) // We always require focus because it could have been abandoned by another Session
		{
			requestFocus ();
		}

		if (dataBuffer != null)
		{
			try
			{
				File             f   = File.createTempFile ( "flauto_buffer-" + Integer.toString(slotNo), extentionArray[ codec.ordinal () ] );
				FileOutputStream fos = new FileOutputStream ( f );
				fos.write ( dataBuffer );
				fromURI = f.getPath();
			}
			catch ( Exception e )
			{
				return false;
			}
		}

		stopPlayer(); // To start a new clean playback

		try
		{
			if (fromURI == null && codec == t_CODEC.pcm16)
			{
				player = new FlautoPlayerEngine();
			} else
			{
				player = new FlautoPlayerMedia();
			}

			mTimer = new Timer();
			player._startPlayer(fromURI,  sampleRate, numChannels, blockSize, this);
		}
		catch ( Exception e )
		{
			Log.e ( TAG, "startPlayer() exception" );
			return false;
		}
		return true;
	}

	public int feed( byte[] data)
	{
		if (player == null)
		{
			return -1;
		}

		try
		{
			int ln = player.feed(data);
			return ln;
		} catch (Exception e)
		{
			Log.e ( TAG, "feed() exception" );
			return -1;
		}
	}

	public void needSomeFood(int ln)
	{
		if (ln < 0)
			throw new RuntimeException();
		mainHandler.post(new Runnable()
		{
			@Override
			public void run()
			{
				m_callBack.needSomeFood(ln);
			}
		});
	}

	public boolean startPlayerFromTrack
	(
		FlautoTrack track,
		boolean canPause,
		boolean canSkipForward,
		boolean canSkipBackward,
		int progress,
		int duration,
		boolean removeUIWhenStopped,
		boolean defaultPauseResume
	)
	{
		Log.e (TAG,  "Must be initialized With UI" );
		return false;
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
			stopPlayer();
			if (getPlayerState() != t_PLAYER_STATE.PLAYER_IS_STOPPED)
				throw new RuntimeException();
			m_callBack.audioPlayerDidFinishPlaying(true);
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
				//invokeMethodWithInteger("startPlayerCompleted", (int) duration);
				//Map<String, Object> dico = new HashMap<String, Object> ();
				//dico.put( "duration", (int) duration);
				//dico.put( "state",  (int)getPlayerState());
				m_callBack.startPlayerCompleted(duration);
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
							try
							{
								if (player != null)
								{

									long position = player._getCurrentPosition();
									long duration = player._getDuration();
									if (position > duration)
									{
										position = duration;
									}
/*
									Map<String, Object> dic = new HashMap<String, Object>();
									dic.put("position", position);
									dic.put("duration", duration);
									dic.put("playerStatus", getPlayerState());
*/
									m_callBack.updateProgress(position, duration);
								}
							} catch (Exception e)
							{
								Log.d(TAG, "Exception: " + e.toString());
								stopPlayer();
							}
						}
					});


			}
		};

		if (subsDurationMillis > 0)
			mTimer.schedule(mTask, 0, subsDurationMillis);
	}


	public void stopPlayer ( )
	{
		pauseMode = false;
		mTimer.cancel ();
		if (player != null)
			player._stop();
		player = null;
	}



	public boolean isDecoderSupported (t_CODEC codec )
	{
		return _isAndroidDecoderSupported[ codec.ordinal() ];
	}

	public boolean pausePlayer (  )
	{
		try
		{
			player._pausePlayer();
			pauseMode = true;
			return true;
		}
		catch ( Exception e )
		{
			Log.e ( TAG, "pausePlay exception: " + e.getMessage () );
			return false;
		}

	}

	public boolean resumePlayer (  )
	{
		try
		{
			player._resumePlayer();
			pauseMode = false;
			return true;
		}
		catch ( Exception e )
		{
			Log.e ( TAG, "mediaPlayer resume: " + e.getMessage () );
			return false;
		}
	}

	public boolean seekToPlayer (long millis)
	{

		if ( player == null )
		{
			Log.e ( TAG, "seekToPlayer() error: "  );
			return false;
		}


		Log.d ( TAG, "seekTo: " + millis );

		player._seekTo ( millis );
		return true;
	}

	public boolean setVolume ( double volume )
	{
		try
		{

			if (player == null) {
				Log.e ( TAG,  "setVolume(): player is null" );
				return false;
			}

			float mVolume = (float) volume;
			player._setVolume(mVolume);
			return true;
		} catch(Exception e)
		{
			Log.e ( TAG, "setVolume: " + e.getMessage () );
			return false;
		}
	}


	public void setSubscriptionDuration (long duration)
	{
		subsDurationMillis = duration;
	}

	public boolean androidAudioFocusRequest ( int focusGain )
	{

		if ( Build.VERSION.SDK_INT >= 26 )
		{
			audioFocusRequest = new AudioFocusRequest.Builder ( focusGain )
				// .setAudioAttributes(mPlaybackAttributes)
				// .setAcceptsDelayedFocusGain(true)
				// .setWillPauseWhenDucked(true)
				// .setOnAudioFocusChangeListener(this, mMyHandler)
				.build ();
			return true;
		} else
		{
			return false;
		}
	}


	public boolean setActive (Boolean enabled )
	{

		Boolean b = false;
		try
		{
			if ( enabled )
			{
				b = requestFocus ();
			} else
			{

				b = abandonFocus ();
			}
		}
		catch ( Exception e )
		{
			b = false;
		}
		return b;
	}

	public Map<String, Object> getProgress (  )
	{
		long position = 0;
		long duration = 0;
		if ( player != null ) {
			 position = player._getCurrentPosition();
			 duration = player._getDuration();
		}
		if (position > duration)
		{
			position = duration;
		}

		Map<String, Object> dic = new HashMap<String, Object> ();
		dic.put ( "position", position );
		dic.put ( "duration", duration );
		dic.put ( "playerStatus", getPlayerState() );
		return dic;
	}

	public void nowPlaying
	(
		FlautoTrack track,
		boolean canPause,
		boolean canSkipForward,
		boolean canSkipbackward,
		boolean defaultPauseResume,
		int progress,
		int duration
	)
	{
		throw new RuntimeException(); // TODO
	}


	public void setUIProgressBar (int progress, int duration)
	{
		throw new RuntimeException(); // TODO
	}

}

