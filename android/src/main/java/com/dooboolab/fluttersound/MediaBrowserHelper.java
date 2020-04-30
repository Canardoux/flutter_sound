package com.dooboolab.fluttersound;
/*
 * This file is part of Flutter-Sound (Flauto).
 *
 *   Flutter-Sound (Flauto) is free software: you can redistribute it and/or modify
 *   it under the terms of the Lesser GNU General Public License
 *   version 3 (LGPL3) as published by the Free Software Foundation.
 *
 *   Flutter-Sound (Flauto) is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the Lesser GNU General Public License
 *   along with Flutter-Sound (Flauto).  If not, see <https://www.gnu.org/licenses/>.
 */


import android.app.Activity;
import android.app.Activity;
import android.content.ComponentName;
import android.os.RemoteException;
import android.support.v4.media.MediaBrowserCompat;
import android.support.v4.media.session.MediaControllerCompat;
import android.support.v4.media.session.PlaybackStateCompat;
import android.util.Log;

import androidx.arch.core.util.Function;

import java.util.concurrent.Callable;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;

public class MediaBrowserHelper
{
	MediaControllerCompat mediaControllerCompat;
	private MediaBrowserCompat mMediaBrowserCompat;
	// The function to call when the media browser successfully connects
	// to the service.
	private Callable<Void>     mServiceConnectionSuccessCallback;
	// The function to call when the media browser is unable to connect
	// to the service.
	private Callable<Void>     mServiceConnectionUnsuccessfulCallback;

	//private BackgroundAudioService backgroundAudioService ;


	private MediaBrowserCompat.ConnectionCallback mMediaBrowserCompatConnectionCallback = new MediaBrowserCompat.ConnectionCallback()
	{
		@Override
		public void onConnected()
		{
			super.onConnected();
			Log.d("MediaBrowserHelper", "onConnected");
			// A new MediaBrowserCompat object is created and connected. Then, initialize a
			// MediaControllerCompat object and associate it with MediaSessionCompat. Once
			// completed,
			// start the audio playback.
			try
			{
				assert(Flauto.androidActivity != null);
				mediaControllerCompat = new MediaControllerCompat( Flauto.androidActivity, mMediaBrowserCompat.getSessionToken() );
				MediaControllerCompat.setMediaController( Flauto.androidActivity, mediaControllerCompat );

				Log.w("MediaBrowserHelper", "onConnect = Success");

				// Start the audio playback
				// MediaControllerCompat.getMediaController(mActivity).getTransportControls().playFromMediaId("http://path-to-audio-file.com",
				// null);

			}
			catch ( RemoteException e )
			{
				Log.e( "MediaBrowserHelper", "The following error occurred while" + " initializing the media controller.", e );
			}

			// Call the successful connection callback if it was provided
			if ( mServiceConnectionSuccessCallback != null )
			{
				try
				{
					mServiceConnectionSuccessCallback.call();
					// Remove the callback
					mServiceConnectionSuccessCallback = null;
				}
				catch ( Exception e )
				{
					e.printStackTrace();
				}
			}
		}

		@Override
		public void onConnectionFailed()
		{
			super.onConnectionFailed();
			Log.d("MediaBrowserHelper", "onConnected");

			// Call the unsuccessful connection callback if it was provided
			if ( mServiceConnectionUnsuccessfulCallback != null )
			{
				try
				{
					mServiceConnectionUnsuccessfulCallback.call();
					// Remove the callback
					mServiceConnectionUnsuccessfulCallback = null;
				}
				catch ( Exception e )
				{
					e.printStackTrace();
				}
			}
		}
	};

	/**
	 * Initialize the media browser helper.
	 *
	 * @param serviceSuccessConnectionCallback   The callback to call when the
	 *                                        connection is successful.
	 * @param serviceUnsuccConnectionCallback The callback to call when the
	 *                                        connection is unsuccessful.
	 */
	MediaBrowserHelper(
		 Callable<Void> serviceSuccessConnectionCallback, Callable<Void> serviceUnsuccConnectionCallback
	                  )
	{
		mServiceConnectionSuccessCallback      = serviceSuccessConnectionCallback;
		mServiceConnectionUnsuccessfulCallback = serviceUnsuccConnectionCallback;
		//////backgroundAudioService = new BackgroundAudioService ();
		initMediaBrowser();
	}

	/**
	 * Initialize the media browser in this class
	 */
	private void initMediaBrowser()
	{
		assert(Flauto.androidActivity != null);
		// Create and connect a MediaBrowserCompat
		mMediaBrowserCompat = new MediaBrowserCompat
		(
			Flauto.androidActivity,
			new ComponentName( Flauto.androidActivity, BackgroundAudioService.class ),
			mMediaBrowserCompatConnectionCallback,
			Flauto.androidActivity.getIntent().getExtras()
		);


		mMediaBrowserCompat.connect();
	}

	/**
	 * Clean up the resources taken by the media browser.
	 * <p>
	 * Call this in onDestroy().
	 */
	void releaseMediaBrowser()
	{
		mMediaBrowserCompat.disconnect();
	}

	void playPlayback()
	{
		BackgroundAudioService.pauseResumeCalledByApp = true;
		mediaControllerCompat.getTransportControls().play();
	}

	void pausePlayback()
	{
		BackgroundAudioService.pauseResumeCalledByApp = true;
		mediaControllerCompat.getTransportControls().pause();
	}

	void resumePlayback()
	{
		BackgroundAudioService.pauseResumeCalledByApp = true;
		mediaControllerCompat.getTransportControls().play();
	}

	void seekTo( long newPosition )
	{
		mediaControllerCompat.getTransportControls().seekTo( newPosition );
	}

	void stop()
	{
		mediaControllerCompat.getTransportControls().stop();
	}

	void setMediaPlayerOnPreparedListener( Callable<Void> callback )
	{
		BackgroundAudioService.mediaPlayerOnPreparedListener = callback;
	}

	void setMediaPlayerOnCompletionListener( Callable<Void> callback )
	{
		BackgroundAudioService.mediaPlayerOnCompletionListener = callback;
	}

	/**
	 * Add a handler for when the user taps the button to skip the track forward.
	 */
	void setSkipTrackForwardHandler( Callable<Void> handler )
	{
		BackgroundAudioService.skipTrackForwardHandler = handler;
	}

	/**
	 * Remove the handler for when the user taps the button to skip the track
	 * forward.
	 */
	void removeSkipTrackForwardHandler()
	{
		BackgroundAudioService.skipTrackForwardHandler = null;
	}

	/**
	 * Add a handler for when the user taps the button to skip the track backward.
	 */
	void setSkipTrackBackwardHandler( Callable<Void> handler )
	{
		BackgroundAudioService.skipTrackBackwardHandler = handler;
	}

	/**
	 * Add a handler for when the user taps the button to pause/resume.
	 */
	void setPauseHandler( Callable<Void> handler )
	{
		BackgroundAudioService.pauseHandler = handler;
	}

	void removePauseHandler(  )
	{
		BackgroundAudioService.pauseHandler = null;
	}

	/**
	 * Remove the handler for when the user taps the button to skip the track
	 * backward.
	 */
	void removeSkipTrackBackwardHandler()
	{
		BackgroundAudioService.skipTrackBackwardHandler = null;
	}


	/**
	 * Passes the currently playing track to the media browser, in order to show the
	 * notification properly.
	 *
	 * @param track The currently playing track.
	 */
	void setNotificationMetadata( Track track )
	{
		BackgroundAudioService.currentTrack = track;
	}

	/**
	 * Passes to the media browser the function to execute to update the playback
	 * state in the Flutter code.
	 *
	 * @param playbackStateUpdater The function to execute to update the playback
	 *                             state in the Flutter code.
	 */
	void setPlaybackStateUpdater( Function playbackStateUpdater )
	{
		BackgroundAudioService.playbackStateUpdater = playbackStateUpdater;
	}
}
