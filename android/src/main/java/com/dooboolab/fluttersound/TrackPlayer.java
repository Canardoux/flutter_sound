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

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel.Result;


//-----------------------------------------------------------------------------------------------------------------------------


public class TrackPlayer extends FlutterSoundPlayer
{
	private       	MediaBrowserHelper 	mMediaBrowserHelper;
	private       	Timer              	mTimer      = new Timer();
	private		long			mDuration   = 0;
	final private 	Handler            	mainHandler = new Handler(Looper.getMainLooper ());
	//public		boolean			initDone = false;
	private		int 			playerState = 0;

	int getPlayerState()
	{
		if (mMediaBrowserHelper == null)
			return 0;
		return playerState;
	}



	@Override
	void initializeFlautoPlayer( final MethodCall call, final Result result )
	{
		//super.initializeFlautoPlayer( call, result );
		audioManager = ( AudioManager ) FlautoPlayerManager.androidContext.getSystemService ( Context.AUDIO_SERVICE );
		assert(Flauto.androidActivity != null);

		// Initialize the media browser if it hasn't already been initialized
		if ( mMediaBrowserHelper == null )
		{
			//initDone = false;
			// If the initialization will be successful, result.success will
			// be called, otherwise result.error will be called.
			mMediaBrowserHelper = new MediaBrowserHelper
			(
				new MediaPlayerConnectionListener(  true ),
				new MediaPlayerConnectionListener(  false )
			);
			// Pass the playback state updater to the media browser
			mMediaBrowserHelper.setPlaybackStateUpdater( new PlaybackStateUpdater() );
		}
		//result.success( true );
		//while (!initDone)
			//Thread.yield();
		//super.initializeFlautoPlayer( call, result);
		boolean r = prepareFocus(call);
		//invokeMethodWithBoolean( "openAudioSessionCompleted", r );

		if (r)
		{

			result.success(getPlayerState());
		}
		else
			result.error ( ERR_UNKNOWN, ERR_UNKNOWN, "Failure to open session");

	}

	@Override
	void releaseFlautoPlayer( final MethodCall call, final Result result )
	{
		// Throw an error if the media player is not initialized
		if ( mMediaBrowserHelper == null )
		{
			result.error( TAG, "The player cannot be released because it is not initialized.", null );
			return;
		}

		// Release the media browser
		mMediaBrowserHelper.releaseMediaBrowser();
		mMediaBrowserHelper = null;
		if (hasFocus)
			abandonFocus();
		releaseSession();
		result.success( getPlayerState() );
	}

	void invokeMethodWithInteger ( String methodName, double arg )
	{
		Map<String, Object> dic = new HashMap<String, Object> ();
		dic.put ( "slotNo", slotNo );
		dic.put ( "arg", arg );
		getPlugin ().invokeMethod ( methodName, dic );
	}

	void invokeMethodWithBoolean ( String methodName, Boolean arg )
	{
		Map<String, Object> dic = new HashMap<String, Object> ();
		dic.put ( "slotNo", slotNo );
		dic.put ( "arg", arg );
		getPlugin ().invokeMethod ( methodName, dic );
	}


	public void startPlayerFromTrack( final MethodCall call, final Result result )
	{
		final HashMap<String, Object> trackMap = call.argument( "track" );
		final Track track = new Track( trackMap );

		boolean canSkipForward = call.argument( "canSkipForward" );
		boolean canSkipBackward = call.argument( "canSkipBackward" );
		boolean canPause = call.argument( "canPause" );

		// Exit the method if a media browser helper was not initialized
		if ( !wasMediaPlayerInitialized( result ) )
		{
			result.error( ERR_UNKNOWN, ERR_UNKNOWN, "Track player not initialized" );
			return;
		}

		// Check whether the audio file is stored by a string or a buffer
		String path;
		if ( track.isUsingPath() )
		{
			// The audio file is stored by a String, then get the path to the file audio to
			// play
			path = track.getPath();
		} else
		{
			// The audio file is stored by a buffer, then save it as a file and get the path
			// to that file.
			try
			{
				File             f   = File.createTempFile( "flutter_sound", extentionArray[ track.getBufferCodecIndex() ] );
				FileOutputStream fos = new FileOutputStream( f );
				fos.write( track.getDataBuffer() );
				path = f.getAbsolutePath();
			}
			catch ( Exception e )
			{
				result.error( ERR_UNKNOWN, ERR_UNKNOWN, e.getMessage() );
				return;
			}
		}

		_stopPlayer(); // To start a clean new playback

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
					//mediaPlayer.setPreferredDevice(info);

				}
			}
		}


		// A path was given, then send it to the media player
		mMediaBrowserHelper.mediaControllerCompat.getTransportControls().playFromMediaId( path, null );
		playerState = 1;
		result.success ( getPlayerState());
		// The media player is started in the on prepared callback
	}


	private boolean _stopPlayer()
	{
		// This remove all pending runnables
		mTimer.cancel();
		mDuration = 0;
		pauseMode = false;
		if ( mMediaBrowserHelper == null )
			return false;
		try
		{
			// Stop the playback
			mMediaBrowserHelper.stop();
			playerState = 0;
		}
		catch ( Exception e )
		{
			return false;
		}
		return true;
	}

	@Override
	public void stopPlayer(final MethodCall call, final Result result )
	{
		_stopPlayer();
		result.success( getPlayerState() );
	}

	@Override
	public void pausePlayer(final MethodCall call, final Result result )
	{
		// Exit the method if a media browser helper was not initialized
		if ( !wasMediaPlayerInitialized( result ) )
		{
			return;
		}
		pauseMode = true;
		playerState = 2;

		try
		{
			// Pause the media player
			mMediaBrowserHelper.pausePlayback();
			result.success(getPlayerState() );
		}
		catch ( Exception e )
		{
			Log.e( TAG, "pausePlay exception: " + e.getMessage() );
			result.error( ERR_UNKNOWN, ERR_UNKNOWN, e.getMessage() );
		}
	}

	@Override
	public void resumePlayer( final MethodCall call,final Result result )
	{
		// Exit the method if a media browser helper was not initialized
		if ( !wasMediaPlayerInitialized( result ) )
		{
			return;
		}

		// Throw an error if we can't resume the media player because it is already
		// playing
		PlaybackStateCompat playbackState = mMediaBrowserHelper.mediaControllerCompat.getPlaybackState();
		if ( playbackState != null && playbackState.getState() == PlaybackStateCompat.STATE_PLAYING )
		{
			result.error( ERR_PLAYER_IS_PLAYING, ERR_PLAYER_IS_PLAYING, ERR_PLAYER_IS_PLAYING );
			return;
		}
		pauseMode = false;

		try
		{
			// Resume the player
			mMediaBrowserHelper.resumePlayback();

			playerState = 1;
			// Seek the player to the last position and resume it
			result.success(getPlayerState());
		}
		catch ( Exception e )
		{
			Log.e( TAG, "mediaPlayer resume: " + e.getMessage() );
			result.error( ERR_UNKNOWN, ERR_UNKNOWN, e.getMessage() );
		}
	}

	@Override
	public void seekToPlayer(final MethodCall call,Result result )
	{
		int millis = call.argument ( "duration" ) ;

		// Exit the method if a media browser helper was not initialized
		if ( !wasMediaPlayerInitialized( result ) )
		{
			Log.d(TAG, "seekToPlayer ended with no initialization");
			result.error( TAG,"seekToPlayer ended with no initialization", null);
			return;
		}

		mMediaBrowserHelper.seekTo(millis);
		// Should declaratively change state: https://stackoverflow.com/questions/39719320/seekto-does-not-trigger-onplaybackstatechanged-in-mediacontrollercompat
		mMediaBrowserHelper.playPlayback();

		result.success(getPlayerState());
	}

	@Override
	public void setVolume(final MethodCall call,final Result result )
	{
		// Exit the method if a media browser helper was not initialized
		if ( !wasMediaPlayerInitialized( result ) )
		{
			return;
		}
		double volume = call.argument("volume");
		float mVolume = (float) volume;

		// Get the maximum value for the volume
		int maxVolume = mMediaBrowserHelper.mediaControllerCompat.getPlaybackInfo().getMaxVolume();
		// Get the value of the new volume level
		int newVolume = ( int ) Math.floor( mVolume * maxVolume );

		// Adjust the media player volume to the given level
		mMediaBrowserHelper.mediaControllerCompat.setVolumeTo( newVolume, 0 );
		result.success( getPlayerState() );
	}


	public void setSubscriptionDuration( final MethodCall call, Result result )
	{
		if (call.argument("milliSec") == null)
			return;
		int duration = call.argument("milliSec");

		subsDurationMillis = duration;
		result.success( getPlayerState());
	}

	private boolean wasMediaPlayerInitialized(  final Result result )
	{
		if ( mMediaBrowserHelper == null )
		{
			Log.e( TAG, "initializePlayer() must be called before this method." );
			result.error( TAG, "initializePlayer() must be called before this method.", null );
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
		private Result  mResult;
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
			if ( mIsSuccessfulCallback )
			{
				//mResult.success( "The media player has been successfully initialized" );
				//mDuration = mMediaBrowserHelper.mediaControllerCompat.getMetadata().getLong( MediaMetadataCompat.METADATA_KEY_DURATION );
				//initDone = true;
			} else
			{
				//mResult.error( TAG, "An error occurred while initializing the media player", null );
				//initDone = true;
			}

			//long trackDuration = mMediaBrowserHelper.mediaControllerCompat.getMetadata().getLong( MediaMetadataCompat.METADATA_KEY_DURATION );



			invokeMethodWithBoolean( "openAudioSessionCompleted", mIsSuccessfulCallback );
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
				invokeMethodWithInteger( "skipForward", getPlayerState() );
			} else
			{
				invokeMethodWithInteger( "skipBackward", getPlayerState() );
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
			invokeMethodWithInteger( "pause", getPlayerState() );

			return null;
		}
	}



	/**
	 * A function that triggers a function in the Dart code to update the playback
	 * state.
	 */
	private class PlaybackStateUpdater
		implements Function<Integer, Void>
	{
		@Override
		public Void apply( Integer newState )
		{
			playerState = newState.intValue();
			invokeMethodWithInteger( "updatePlaybackState", newState );
			return null;
		}
	}

	void updateProgress()
	{
		// long time = mp.getCurrentPosition();
		// DateFormat format = new SimpleDateFormat("mm:ss:SS", Locale.US);
		// final String displayTime = format.format(time);
		mainHandler.post( new Runnable()
		{
			@Override
			public void run()
			{


				if ((mMediaBrowserHelper == null) || (mMediaBrowserHelper.mediaControllerCompat == null))
				{
					Log.e( TAG, "MediaPlayerOnPreparedListener timer: mMediaBrowserHelper.mediaControllerCompat is NULL. This is BAD !!!"  );
					_stopPlayer( );
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
				int state = playbackState.getState();
				if (position > duration || position > 5000 || duration == 0) // for debugging)
				{
					assert(position <= duration);
				}
				Map<String, Object> dic = new HashMap<String, Object> ();
				dic.put ( "position", position );
				dic.put ( "duration", duration );
				dic.put ( "playerStatus", getPlayerState() );


				invokeMethodWithMap( "updateProgress",dic);
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

		private MediaPlayerOnPreparedListener(
			String path
		                                     )
		{
			//mResult = result;
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
			invokeMethodWithInteger( "startPlayerCompleted", (int)trackDuration);

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

	void getProgress ( final MethodCall call, final Result result )
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
			assert(position <= duration);
		}

		if (duration > 30000 || position > 5000) // for debugging
		{
			long toto = duration;
			System.out.println(toto);
		}

		Map<String, Object> dic = new HashMap<String, Object> ();
		dic.put ( "position", position );
		dic.put ( "duration", duration );
		dic.put ( "playerStatus", getPlayerState() );
		dic.put ( "slotNo", slotNo);
		result.success(dic);
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
			playerState = 0;
			pauseMode = false;
			invokeMethodWithInteger( "audioPlayerFinishedPlaying", getPlayerState() );

			return null;
		}
	}

}
//---------------------------------------------------------------------------------------------------------------------------------
