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
import android.media.AudioDeviceInfo;
import android.media.AudioManager;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.support.v4.media.MediaMetadataCompat;
import android.support.v4.media.session.PlaybackStateCompat;
import android.util.Log;
import androidx.arch.core.util.Function;

import java.io.File;
import java.io.FileOutputStream;
import java.util.HashMap;
import java.util.Map;
import java.util.Timer;
import java.util.TimerTask;
import java.util.concurrent.Callable;
import java.lang.System;
import com.dooboolab.TauEngine.Flauto.*;


//-----------------------------------------------------------------------------------------------------------------------------


public class FlautoTrackPlayer extends FlautoPlayer
{
	private       	FlautoMediaBrowserHelper 	mMediaBrowserHelper;
	private       	Timer              	mTimer      = new Timer();
	private		long			mDuration   = 0;
	final private 	Handler            	mainHandler = new Handler(Looper.getMainLooper ());

	/* ctor */ public FlautoTrackPlayer(FlautoPlayerCallback callBack)
	{
		super(callBack);
	}


	public t_PLAYER_STATE getPlayerState()
	{
		if (mMediaBrowserHelper == null)
			return t_PLAYER_STATE.PLAYER_IS_STOPPED;
		return playerState;
	}



	@Override
	public boolean openPlayer(t_AUDIO_FOCUS focus, t_SESSION_CATEGORY category, t_SESSION_MODE sessionMode, int audioFlags, t_AUDIO_DEVICE audioDevice)
	{
		audioManager = ( AudioManager ) Flauto.androidContext.getSystemService ( Context.AUDIO_SERVICE );
		if (Flauto.androidActivity == null)
			throw new RuntimeException();

		// Initialize the media browser if it hasn't already been initialized
		if ( mMediaBrowserHelper == null )
		{
			mMediaBrowserHelper = new FlautoMediaBrowserHelper
			(
				new MediaPlayerConnectionListener(  true ),
				new MediaPlayerConnectionListener(  false )
			);
			// Pass the playback state updater to the media browser
			mMediaBrowserHelper.setPlaybackStateUpdater( new PlaybackStateUpdater() );
		}
		boolean r = setAudioFocus(focus, category, sessionMode, audioFlags, audioDevice);
		return r;
	}

	@Override
	public void closePlayer()
	{
		// Throw an error if the media player is not initialized
		if ( mMediaBrowserHelper == null )
		{
			Log.e( TAG, "The player cannot be released because it is not initialized."  );
			return;
		}

		// Release the media browser
		mMediaBrowserHelper.releaseMediaBrowser();
		mMediaBrowserHelper = null;
		if (hasFocus)
			abandonFocus();
		releaseSession();
		playerState = t_PLAYER_STATE.PLAYER_IS_STOPPED;
		m_callBack.closePlayerCompleted(true);

	}

	public boolean startPlayer (t_CODEC codec, String fromURI, byte[] dataBuffer, int numChannels, int sampleRate, int blockSize ) {
		//Log.e (TAG,  "Must use startPlayerFromTrack()" );
		//return false;
		final HashMap<String, Object> dic = new HashMap<String, Object>();
		dic.put("trackPath", fromURI);
		dic.put("codec", codec);
		dic.put("dataBuffer", dataBuffer);
		dic.put("trackTitle", "This is a record");
		dic.put("trackAuthor", "from flutter_sound");
		//albumArtUrl: albumArtUrl,
		//albumArtAsset: albumArtAsset,
		//albumArtFile: albumArtFile,

		return startPlayerFromTrack(new FlautoTrack(dic), false, false, false, -1, 0, true, true);
	}

		public boolean startPlayerFromTrack
	(
		FlautoTrack track,
		boolean canPause,
		boolean canSkipForward,
		boolean canSkipBackward,
		int progress, // NOT YET USED ! CAN BE -1 IF NULL
		int duration,
		boolean removeUIWhenStopped,
		boolean defaultPauseResume
	)
	{

		// Exit the method if a media browser helper was not initialized
		if ( !wasMediaPlayerInitialized( ) )
		{
			Log.e (TAG,  "Track player not initialized" );
			return false;
		}

		// Check whether the audio file is stored by a string or a buffer
		String path;
		if ( track.isUsingPath() )
		{
			// The audio file is stored by a String, then get the path to the file audio to
			// play
			path = track.getPath();
			path = Flauto.getPath(path);

		} else
		{
			// The audio file is stored by a buffer, then save it as a file and get the path
			// to that file.
			try
			{
				File             f   = File.createTempFile( "Tau", extentionArray[ track.getBufferCodecIndex() ] );
				FileOutputStream fos = new FileOutputStream( f );
				fos.write( track.getDataBuffer() );
				path = f.getAbsolutePath();
			}
			catch ( Exception e )
			{
				Log.e(TAG, e.getMessage() );
				return false;
			}
		}

		stopPlayer(); // To start a clean new playback

		mTimer = new Timer();

		// Add or remove the handlers for when the user tries to skip the current track
		if ( canSkipForward )
		{
			mMediaBrowserHelper.setSkipTrackForwardHandler( new SkipTrackHandler( true ) );
		} else
		{
			mMediaBrowserHelper.removeSkipTrackForwardHandler();
		}
		if ( canSkipBackward )
		{
			mMediaBrowserHelper.setSkipTrackBackwardHandler( new SkipTrackHandler( false ) );
		} else
		{
			mMediaBrowserHelper.removeSkipTrackBackwardHandler();
		}

		if ( canPause )
		{
			mMediaBrowserHelper.setPauseHandler( new PauseHandler(  ) );
		} else
		{
			mMediaBrowserHelper.removePauseHandler();
		}
		requestFocus();
		// Pass to the media browser the metadata to use in the notification
		mMediaBrowserHelper.setNotificationMetadata( track );

		// Add the listeners for the onPrepared and onCompletion events
		mMediaBrowserHelper.setMediaPlayerOnPreparedListener( new MediaPlayerOnPreparedListener(  path ) );
		mMediaBrowserHelper.setMediaPlayerOnCompletionListener( new MediaPlayerOnCompletionListener() );

		// Check whether the device has a speaker.
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M)
		{
			AudioDeviceInfo[] devices = audioManager.getDevices( AudioManager.GET_DEVICES_OUTPUTS );
			for (AudioDeviceInfo device : devices)
			{
				if (device.getType() == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER)
				{
					AudioDeviceInfo info = device;
				}
			}
		}


		// A path was given, then send it to the media player
		mMediaBrowserHelper.mediaControllerCompat.getTransportControls().playFromMediaId( path, null );
		return true;
		// The media player is started in the on prepared callback
	}

	@Override
	public void stopPlayer()
	{
		// This remove all pending runnables
		mTimer.cancel();
		mDuration = 0;
		pauseMode = false;
		if ( mMediaBrowserHelper == null )
			return;
		try
		{
			// Stop the playback
			mMediaBrowserHelper.stop();
		}
		catch ( Exception e )
		{
			Log.e(TAG, "stopPlayer() error" + e.getMessage());
		}
		playerState = t_PLAYER_STATE.PLAYER_IS_STOPPED;

		m_callBack.stopPlayerCompleted(true);
	}

	@Override
	public boolean pausePlayer()
	{
		// Exit the method if a media browser helper was not initialized
		if ( !wasMediaPlayerInitialized(  ) )
		{
			return false;
		}
		pauseMode = true;
		playerState = t_PLAYER_STATE.PLAYER_IS_PAUSED;

		try
		{
			// Pause the media player
			mMediaBrowserHelper.pausePlayback();
			playerState = t_PLAYER_STATE.PLAYER_IS_PAUSED;

			m_callBack.pausePlayerCompleted(true);
			return true;
		}
		catch ( Exception e )
		{
			Log.e( TAG, "pausePlayer exception: " + e.getMessage() );
			return false;
		}
	}

	@Override
	public boolean resumePlayer( )
	{
		// Exit the method if a media browser helper was not initialized
		if ( !wasMediaPlayerInitialized(  ) )
		{
			return false;
		}

		// Throw an error if we can't resume the media player because it is already
		// playing
		PlaybackStateCompat playbackState = mMediaBrowserHelper.mediaControllerCompat.getPlaybackState();
		if ( playbackState != null && playbackState.getState() == PlaybackStateCompat.STATE_PLAYING )
		{
			Log.e( TAG, "resumePlayer exception: "  );
			return false;
		}
		pauseMode = false;

		try
		{
			// Resume the player
			mMediaBrowserHelper.resumePlayback();
			playerState = t_PLAYER_STATE.PLAYER_IS_PLAYING;

			m_callBack.resumePlayerCompleted(true);

			// Seek the player to the last position and resume it
			return true;
		}
		catch ( Exception e )
		{
			Log.e( TAG, "mediaPlayer resume: " + e.getMessage() );
			return false;
		}
	}

	@Override
	public boolean seekToPlayer (long millis)
	{

		// Exit the method if a media browser helper was not initialized
		if ( !wasMediaPlayerInitialized( ) )
		{
			Log.d(TAG, "seekToPlayer ended with no initialization");
			return false;
		}

		mMediaBrowserHelper.seekTo(millis);
		// Should declaratively change state: https://stackoverflow.com/questions/39719320/seekto-does-not-trigger-onplaybackstatechanged-in-mediacontrollercompat
		mMediaBrowserHelper.playPlayback();

		return true;
	}

	@Override
	public boolean setVolume ( double volume )
	{
		// Exit the method if a media browser helper was not initialized
		if ( !wasMediaPlayerInitialized( ) )
		{
			return false;
		}
		float mVolume = (float) volume;

		// Get the maximum value for the volume
		int maxVolume = mMediaBrowserHelper.mediaControllerCompat.getPlaybackInfo().getMaxVolume();
		// Get the value of the new volume level
		int newVolume = ( int ) Math.floor( mVolume * maxVolume );

		// Adjust the media player volume to the given level
		mMediaBrowserHelper.mediaControllerCompat.setVolumeTo( newVolume, 0 );
		return true;
	}


	private boolean wasMediaPlayerInitialized()
	{
		if ( mMediaBrowserHelper == null )
		{
			Log.e( TAG, "initializePlayer() must be called before this method." );
			return false;
		}
		return true;
	}


//-------------------------------------------------------------------------------------------------------------------------------

	/**
	 * The callable instance to call when the media player has been connected.
	 */
	private class MediaPlayerConnectionListener
		implements Callable<Void>
	{
		//private Result  mResult;
		// Whether this callback is called when the connection is successful
		private boolean mIsSuccessfulCallback;

		MediaPlayerConnectionListener(  boolean isSuccessfulCallback )
		{
			mIsSuccessfulCallback = isSuccessfulCallback;
		}

		@Override
		public Void call()
			throws
			Exception
		{
			m_callBack.openPlayerCompleted(mIsSuccessfulCallback);
			return null;
		}
	}

	/**
	 * A listener that is triggered when the skip buttons in the notification are
	 * clicked.
	 */
	private class SkipTrackHandler
		implements Callable<Void>
	{
		private boolean mIsSkippingForward;

		SkipTrackHandler( boolean isSkippingForward )
		{
			mIsSkippingForward = isSkippingForward;
		}

		@Override
		public Void call()
			throws
			Exception
		{
			if ( mIsSkippingForward )
			{
				m_callBack.skipForward();
			} else
			{
				m_callBack.skipBackward();
			}

			return null;
		}
	}

	/**
	 * A listener that is triggered when the pause buttons in the notification are
	 * clicked.
	 */
	private class PauseHandler
		implements Callable<Void>
	{
		private boolean mIsSkippingForward;

		PauseHandler(  )
		{
		}

		@Override
		public Void call()
			throws
			Exception
		{
			PlaybackStateCompat playbackState = mMediaBrowserHelper.mediaControllerCompat.getPlaybackState();
			if (playbackState.getState() == PlaybackStateCompat.STATE_PAUSED)
			{
				m_callBack.resume();
			} else
			if (playbackState.getState() == PlaybackStateCompat.STATE_PLAYING)
			{
				m_callBack.pause();
			} else
			{

			}
			return null;
		}
	}



	/**
	 * A function that triggers a function in the Dart code to update the playback
	 * state.
	 */
	private class PlaybackStateUpdater
		implements Function<t_PLAYER_STATE, Void>
	{
		@Override
		public Void apply( t_PLAYER_STATE newState )
		{
			playerState = newState;
			m_callBack.updatePlaybackState(playerState);
			return null;
		}
	}

	void updateProgress()
	{
		mainHandler.post( new Runnable()
		{
			@Override
			public void run()
			{


				if ((mMediaBrowserHelper == null) || (mMediaBrowserHelper.mediaControllerCompat == null))
				{
					Log.e( TAG, "MediaPlayerOnPreparedListener timer: mMediaBrowserHelper.mediaControllerCompat is NULL. This is BAD !!!"  );
					stopPlayer( );
					if (mMediaBrowserHelper != null)
						mMediaBrowserHelper.releaseMediaBrowser();
					mMediaBrowserHelper = null;
					return;
				}
				PlaybackStateCompat playbackState = mMediaBrowserHelper.mediaControllerCompat.getPlaybackState();

				if ( playbackState == null || playbackState.getState() != PlaybackStateCompat.STATE_PLAYING)
				{
					return;
				}

				long position = playbackState.getPosition();
				long duration = mMediaBrowserHelper.mediaControllerCompat.getMetadata().getLong( MediaMetadataCompat.METADATA_KEY_DURATION );
				if (position > duration)
				{
					position = duration;
				}
				m_callBack.updateProgress(position, duration);
			}
		} );

	}


	/**
	 * The callable instance to call when the media player is prepared.
	 */
	private class MediaPlayerOnPreparedListener
		implements Callable<Void>
	{
		//private Result mResult;
		private String mPath;

		private MediaPlayerOnPreparedListener(String path)
		{
			mPath   = path;
		}

		@Override
		public Void call()
			throws
			Exception
		{
			// The content is ready to be played, then play it
			mMediaBrowserHelper.playPlayback();
			long trackDuration = mMediaBrowserHelper.mediaControllerCompat.getMetadata().getLong( MediaMetadataCompat.METADATA_KEY_DURATION );
			playerState = t_PLAYER_STATE.PLAYER_IS_PLAYING;

			m_callBack.startPlayerCompleted(true, trackDuration);

			updateProgress();
			// Set timer task to send event to RN

			TimerTask mTask = new TimerTask()
			{
				@Override
				public void run()
				{
					updateProgress();
				}
			};

			if (subsDurationMillis > 0)
				mTimer.schedule( mTask, 0, subsDurationMillis );
			return null;
		}
	}

	public Map<String, Object> getProgress (  )
	{
		long position = 0;
		long duration = 0;
		PlaybackStateCompat playbackState = mMediaBrowserHelper.mediaControllerCompat.getPlaybackState();
		if (playbackState != null)
		{
			position = playbackState.getPosition();
			duration = mDuration;
		}

		if (position > duration)
		{
			if (position > duration)
				throw new RuntimeException();
		}

		Map<String, Object> dic = new HashMap<String, Object> ();
		dic.put ( "position", position );
		dic.put ( "duration", duration );
		dic.put ( "playerStatus", getPlayerState() );
		return dic;
	}



	/**
	 * The callable instance to call when the media player calls the onCompletion
	 * event.
	 */
	private class MediaPlayerOnCompletionListener
		implements Callable<Void>
	{
		MediaPlayerOnCompletionListener()
		{
		}

		@Override
		public Void call()
			throws
			Exception
		{
			// Reset the timer
			mTimer.cancel();

			Log.d( TAG, "Play completed." );
			playerState = t_PLAYER_STATE.PLAYER_IS_STOPPED;
			pauseMode = false;
			m_callBack.audioPlayerDidFinishPlaying(true); // What is "true" for ?
			return null;
		}
	}

}
//---------------------------------------------------------------------------------------------------------------------------------
