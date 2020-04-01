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

public class MediaBrowserHelper
{
	MediaControllerCompat mediaControllerCompat;

	private MediaBrowserCompat mMediaBrowserCompat;
	private Activity           mActivity;
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
			// A new MediaBrowserCompat object is created and connected. Then, initialize a
			// MediaControllerCompat object and associate it with MediaSessionCompat. Once
			// completed,
			// start the audio playback.
			try
			{
				assert(mActivity != null);
				mediaControllerCompat = new MediaControllerCompat( mActivity, mMediaBrowserCompat.getSessionToken() );
				MediaControllerCompat.setMediaController( mActivity, mediaControllerCompat );

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
	 * @param activity                        The activity in which to initialize
	 *                                        the media browser helper.
	 * @param serviceSuccessConnectionCallback   The callback to call when the
	 *                                        connection is successful.
	 * @param serviceUnsuccConnectionCallback The callback to call when the
	 *                                        connection is unsuccessful.
	 */
	MediaBrowserHelper(
		Activity activity, Callable<Void> serviceSuccessConnectionCallback, Callable<Void> serviceUnsuccConnectionCallback
	                  )
	{
		assert(activity != null);
		mActivity                              = activity;
		BackgroundAudioService.activity        = mActivity;
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
		assert(mActivity != null);
		BackgroundAudioService.activity = mActivity;
		// Create and connect a MediaBrowserCompat
		mMediaBrowserCompat = new MediaBrowserCompat( mActivity, new ComponentName( mActivity, BackgroundAudioService.class ), mMediaBrowserCompatConnectionCallback, mActivity.getIntent().getExtras() );


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
		mediaControllerCompat.getTransportControls().play();
	}

	void pausePlayback()
	{
		mediaControllerCompat.getTransportControls().pause();
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
