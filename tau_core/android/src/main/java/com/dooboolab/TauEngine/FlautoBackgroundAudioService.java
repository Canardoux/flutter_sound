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



import android.app.Activity;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.content.res.AssetManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.media.AudioAttributes;
import android.media.AudioFocusRequest;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.os.AsyncTask;
import android.os.Build;
import android.os.Bundle;
import android.os.PowerManager;
import android.support.v4.media.MediaBrowserCompat;
import android.support.v4.media.MediaDescriptionCompat;
import android.support.v4.media.MediaMetadataCompat;
import android.support.v4.media.session.MediaControllerCompat;
import android.support.v4.media.session.MediaSessionCompat;
import android.support.v4.media.session.PlaybackStateCompat;
import android.text.TextUtils;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.arch.core.util.Function;
import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;
import androidx.media.MediaBrowserServiceCompat;
import androidx.media.app.NotificationCompat.MediaStyle;
import androidx.media.session.MediaButtonReceiver;
//import com.dooboolab.TauEngine.R;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.List;
import java.util.concurrent.Callable;

public class FlautoBackgroundAudioService
	extends MediaBrowserServiceCompat
	implements MediaPlayer.OnCompletionListener,
	           AudioManager.OnAudioFocusChangeListener
{

	final static String TAG                   = "BackgroundAudioService";
	static final String notificationChannelId = "tau_channel_01";

	public        static Callable mediaPlayerOnPreparedListener;
	public        static Callable mediaPlayerOnCompletionListener;
	public        static Callable skipTrackForwardHandler;
	public        static Callable skipTrackBackwardHandler;
	public        static Callable pauseHandler;
	public        static Function playbackStateUpdater;
	// public static boolean includeAudioPlayerFeatures;
	//public static Activity activity;

	//public final static int PLAYING_STATE = 1;
	//public final static int PAUSED_STATE  = 2;
	//public final static int STOPPED_STATE = 0;

	/**
	 * The track that we're currently playing
	 */
	public static FlautoTrack currentTrack;
	public static boolean pauseResumeCalledByApp = false;

	private boolean            mIsNoisyReceiverRegistered;
	private MediaPlayer        mMediaPlayer;
	private MediaSessionCompat mMediaSessionCompat;
	private AudioFocusRequest  mAudioFocusRequest;
	private BroadcastReceiver  mNoisyReceiver = new BroadcastReceiver()
	{
		@Override
		public void onReceive( Context context, Intent intent )
		{
			// The headphone has been unplugged, so the audio is becoming noisy. Then, pause
			// the player.
			if ( mMediaPlayer != null && mMediaPlayer.isPlaying() )
			{
				mMediaPlayer.pause();
			}
		}

	};


	private MediaSessionCompat.Callback mMediaSessionCallback = new MediaSessionCompat.Callback()
	{

		/**
		 * Starts the playback
		 */
		@Override
		@SuppressWarnings ( "unchecked" )
		public void onPlay()
		{
			super.onPlay();
			// Someone asked to start the playback, then start it

			// Request the audio focus and check if it was granted
			/*
			 * if (!successfullyRetrievedAudioFocus()) { // The audio focus was not granted,
			 * then don't start the playback // TODO: handle failed audio focus request more
			 * gracefully Log.e(TAG,
			 * "The audio focus has not been granted, then it's impossible to play audio.");
			 * return; }
			 *
			 */
			if ( (pauseHandler != null ) && (! pauseResumeCalledByApp) )
			{
				try
				{
					pauseHandler.call();
					return;
				}
				catch ( Exception e )
				{
					e.printStackTrace();
				}
			} else
			{
				pauseResumeCalledByApp = false;
			}

			startPlayerPlayback();
		}

		/**
		 * Pauses the playback
		 */
		@Override
		@SuppressWarnings ( "unchecked" )
		public void onPause()
		{
			// Someone requested to pause the playback, then pause it
			super.onPause();


			// Call the handler to pause, when given
			if ( (pauseHandler != null ) && (! pauseResumeCalledByApp) )
			{
				try
				{
					pauseHandler.call();
					return;
				}
				catch ( Exception e )
				{
					e.printStackTrace();
				}
			} else
			{
				pauseResumeCalledByApp = false;
			}

			// Check whether the media player is playing
			if ( mMediaPlayer.isPlaying() )
			{
				// The media player is playing, then pause it
				mMediaPlayer.pause();

				// Change the state of the MediaSessionCompat to paused state
				setMediaPlaybackState( PlaybackStateCompat.STATE_PAUSED );

				// Show a notification to handle the media playback
				showPausedNotification();

				// Stop the service (allow the user to dismiss the notification)
				stopBackgroundAudioService( false );

				// Update the playback state
				playbackStateUpdater.apply(Flauto.t_PLAYER_STATE.PLAYER_IS_PAUSED );
			}
		}

		/**
		 * Change the audio content of the media player
		 */
		@Override
		public void onPlayFromMediaId( String mediaId, Bundle extras )
		{
			super.onPlayFromMediaId( mediaId, extras );
			// Change audio track

			try
			{
				mMediaPlayer.reset(); // Just to avoid crashes when media player not in good state
				// Pass the given path to the media player
				mMediaPlayer.setDataSource( mediaId );

				// Prepare the player for playback
				mMediaPlayer.prepareAsync();

			}
			catch ( Exception e )
			{
				Log.e( TAG, "The following error occurred while trying to set the track to play in the audio player.", e );
			}
		}

		/**
		 * Seek the playback to a new position
		 */
		@Override
		public void onSeekTo( long pos )
		{
			super.onSeekTo( pos );
			// Seek the playback to the given position
			mMediaPlayer.seekTo( ( int ) pos );
		}

		/**
		 * Stop the media playback
		 */
		@Override
		@SuppressWarnings ( "unchecked" )
		public void onStop()
		{
			super.onStop();

			// Stop the media player
			mMediaPlayer.stop();

			// Set the paused playback state
			setMediaPlaybackState( PlaybackStateCompat.STATE_STOPPED );

			// Reset the media player
			mMediaPlayer.reset();

			// Stop the service
			stopBackgroundAudioService( true );

			// Update the playback state
			playbackStateUpdater.apply(Flauto.t_PLAYER_STATE.PLAYER_IS_STOPPED );
		}

		@Override
		public void onSkipToNext()
		{
			// Call the handler to skip forward, when given
			if ( skipTrackForwardHandler != null )
			{
				try
				{
					skipTrackForwardHandler.call();
				}
				catch ( Exception e )
				{
					e.printStackTrace();
				}
			}

			super.onSkipToNext();
		}

		@Override
		public void onSkipToPrevious()
		{
			// Call the handler to skip backward, when given
			if ( skipTrackBackwardHandler != null )
			{
				try
				{
					skipTrackBackwardHandler.call();
				}
				catch ( Exception e )
				{
					e.printStackTrace();
				}
			}

			super.onSkipToPrevious();
		}
	};

	/**
	 * Starts the playback of the player (without requesting audio focus).
	 */
	@SuppressWarnings ( "unchecked" )
	private boolean startPlayerPlayback()
	{
		//if (Flauto.androidActivity == null)
		{
			//Log.e( TAG, "BackgroundAudioService.startPlayerPlayback() : Flauto.androidActivity == null. THIS IS BAD !!!");
			//return false;
		}
		// Activate the MediaSessionCompat and give it the playing state
		mMediaSessionCompat.setActive( true );
		setMediaPlaybackState( PlaybackStateCompat.STATE_PLAYING );

		// Show a notification to handle the media playback
		showPlayingNotification();

		// Start the audio player
		mMediaPlayer.start();

		// Start the service
		// The two following instructions probably do no work
		if (Flauto.androidActivity == null)
			throw new RuntimeException();
		//startService( new Intent( Flauto.androidActivity, BackgroundAudioService.class ) );

		// Update the playback state
		playbackStateUpdater.apply(Flauto.t_PLAYER_STATE.PLAYER_IS_PLAYING );
		return true;
	}

	private void stopBackgroundAudioService( boolean removeNotification )
	{
		// Remove the notification
		stopForeground( removeNotification );
		// Stop the service
		stopSelf();

	}

	// Not important for general audio service, required for class
	@Override
	public BrowserRoot onGetRoot(
			String clientPackageName, int clientUid,
			Bundle rootHints
	                            )
	{
		if ( TextUtils.equals( clientPackageName, getPackageName() ) )
		{
			String appName = "";
			try
			{
				Context        context = getApplicationContext();
				PackageManager pm      = context.getPackageManager();
				PackageInfo    info    = pm.getPackageInfo( context.getPackageName(), 0 );
				appName = info.applicationInfo.loadLabel( pm ).toString();
			}
			catch ( PackageManager.NameNotFoundException e )
			{
				e.printStackTrace();
			}
			return new BrowserRoot( appName, null );
		}

		return null;
	}

	// Not important for general audio service, required for class
	@Override
	public void onLoadChildren(
			String parentId,
			Result<List<MediaBrowserCompat.MediaItem>> result
	                          )
	{
		result.sendResult( null );
	}

	@Override
	public int onStartCommand( Intent intent, int flags, int startId )
	{
		// Someone requested to start the service, then send the given intent
		// to MediaButtonReceiver class.
		// MediaButtonReceiver will extract the key event from intent, and pass it to
		// the
		// media session, that in turn will trigger the appropriate callback
		MediaButtonReceiver.handleIntent( mMediaSessionCompat, intent );
		return super.onStartCommand( intent, flags, startId );
	}

	@Override
	public void onAudioFocusChange( int focusChange )
	{
		// The audio focus has changed, then take an action based on the new audio focus
		switch ( focusChange )
		{
			case AudioManager.AUDIOFOCUS_LOSS:
			{
				// Another app has requested audio focus, then stop audio playback
			}
			case AudioManager.AUDIOFOCUS_LOSS_TRANSIENT:
			{
				// Another app wants to play audio for a short time, then pause audio playback
				mMediaSessionCallback.onPause();
				break;
			}
			case AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK:
			{
				// Another app requested focus, but we can continue the media playback
				// bringing the volume down a bit.
				if ( mMediaPlayer != null )
				{
					mMediaPlayer.setVolume( 0.3f, 0.3f );
				}
				break;
			}
			case AudioManager.AUDIOFOCUS_GAIN:
			{
				// The audio focus was granted: either a request was accepted, or a
				// AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK event has completed.
				if ( mMediaPlayer != null )
				{
					// Restart the player if it was not playing
					if ( !mMediaPlayer.isPlaying() )
					{
						startPlayerPlayback();
					}
					// Set the volume to its previous levels
					mMediaPlayer.setVolume( 1.0f, 1.0f );
				}
				break;
			}
		}
	}

	@Override
	@SuppressWarnings ( "unchecked" )
	public void onCompletion( MediaPlayer mediaPlayer )
	{
		// The actions to perform when the audio file has finished
		// The media source reached the end

		// Call the callback
		if ( mediaPlayerOnCompletionListener != null )
		{
			try
			{
				mediaPlayerOnCompletionListener.call();
			}
			catch ( Exception e )
			{
				Log.e( TAG, "The following error occurred while executing the onCompletion callback.", e );
			}
		}

		// Reset the media player
		if ( mMediaPlayer != null )
		{
			mMediaPlayer.reset();
		}
	}

	@Override
	public void onDestroy()
	{
		super.onDestroy();
		// This service is no longer used and is being removed, then clean up any
		// resources it holds
		// and abandon the audio focus.
		/*
		 * AudioManager audioManager = (AudioManager)
		 * getSystemService(Context.AUDIO_SERVICE);
		 *
		 * if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) { if(mAudioFocusRequest
		 * != null) audioManager.abandonAudioFocusRequest(mAudioFocusRequest); } else {
		 * audioManager.abandonAudioFocus(this); }
		 *
		 */

		// Unregister the noisy receiver only if it was previously set
		if ( mIsNoisyReceiverRegistered )
		{
			unregisterReceiver( mNoisyReceiver );
			mIsNoisyReceiverRegistered = false;
		}

		// Stop the service
		stopBackgroundAudioService( true );

		resetMediaPlayer();
	}

	@Override
	public void onCreate()
	{
		super.onCreate();
		// This service has been created, then initialize the media player and all the
		// stuff
		// related to it.

		initMediaPlayer();
		initMediaSession();

		// Do not initialize the noisy receiver if we should not include audio player
		// features
		// if(includeAudioPlayerFeatures) {
		initNoisyReceiver();
		// }
	}

	private void initMediaPlayer()
	{
		// Initialize the media player
		mMediaPlayer = new MediaPlayer();
		// Request the partial wake lock permission
		mMediaPlayer.setWakeMode( getApplicationContext(), PowerManager.PARTIAL_WAKE_LOCK );
		// Set the media player stream type and volume
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P)
			mMediaPlayer.setAudioAttributes(new AudioAttributes.Builder().setContentType(AudioAttributes.CONTENT_TYPE_MUSIC).build());
		mMediaPlayer.setVolume( 1.0f, 1.0f );
		// Set the onCompletion listener
		mMediaPlayer.setOnCompletionListener( this );
		// Set the onPreparedListener
		mMediaPlayer.setOnPreparedListener( mp ->
		                                    {
			                                    // Start retrieving the album art if the audio player features should be
			                                    // included
			                                    // if(includeAudioPlayerFeatures) {
			                                    Bitmap albumArt = null;
			                                    if ( currentTrack.getAlbumArtUrl() != null )
			                                    {
				                                    new AlbumArtDownloader().execute( currentTrack.getAlbumArtUrl() );
				                                    // }

				                                    // Pass the audio file metadata to the media session

			                                    } else if ( currentTrack.getAlbumArtAsset() != null )
                                                            {
                                                                try
                                                                {
                                                                    AssetManager assetManager = getApplicationContext().getAssets();
                                                                    InputStream  istr         = assetManager.open( currentTrack.getAlbumArtAsset() );
                                                                    albumArt = BitmapFactory.decodeStream( istr );

                                                                }
                                                                catch ( IOException e )
                                                                {
                                                                }
                                                            } else  if ( currentTrack.getAlbumArtFile() != null )
			                                    {
				                                    try
				                                    {
					                                    File            file            = new File( currentTrack.getAlbumArtFile());
					                                    FileInputStream istr = new FileInputStream( file);
					                                    albumArt = BitmapFactory.decodeStream( istr );

				                                    }
				                                    catch ( IOException e )
				                                    {
				                                    }
			                                    } else
			                                    {
				                                    try
				                                    {
					                                    AssetManager assetManager = getApplicationContext().getAssets();
					                                    InputStream  istr         = assetManager.open( "AppIcon.png");
					                                    albumArt = BitmapFactory.decodeStream( istr );

				                                    }
				                                    catch ( IOException e )
				                                    {
				                                    }

			                                    }
			                                    initMediaSessionMetadata( albumArt );

			                                    // Call the callback
			                                    if ( mediaPlayerOnPreparedListener != null )
			                                    {
				                                    try
				                                    {
					                                    mediaPlayerOnPreparedListener.call();
				                                    }
				                                    catch ( Exception e )
				                                    {
					                                    Log.e( TAG, "The following error occurred while executing the onPrepared callback.", e );
				                                    }
			                                    }
		                                    } );
	}

	private void initMediaSession()
	{
		// Get an identifier to the system that receives hardware media playback actions
		// and
		// translates them into the appropriate callbacks.
		ComponentName mediaButtonReceiver = new ComponentName( getApplicationContext(), MediaButtonReceiver.class );
		// Initialize the media session compat object
		String mediaSessionDebugTag = "tau_media_session";
		mMediaSessionCompat = new MediaSessionCompat( getApplicationContext(), mediaSessionDebugTag, mediaButtonReceiver, null );
		// Pass to the media session the callback that responds to media button events
		mMediaSessionCompat.setCallback( mMediaSessionCallback );

		// Do not support hardware media playback actions if we are not including audio
		// features
		// Inform the session that it is capable of handling media button events and
		// transport control commands.
		mMediaSessionCompat.setFlags( MediaSessionCompat.FLAG_HANDLES_MEDIA_BUTTONS | MediaSessionCompat.FLAG_HANDLES_TRANSPORT_CONTROLS );

		// Create a new Intent for handling media button inputs on pre-Lollipop devices
		Intent mediaButtonIntent = new Intent( Intent.ACTION_MEDIA_BUTTON );
		mediaButtonIntent.setClass( this, MediaButtonReceiver.class );
		PendingIntent pendingIntent = PendingIntent.getBroadcast( this, 0, mediaButtonIntent, 0 );
		mMediaSessionCompat.setMediaButtonReceiver( pendingIntent );

		// Set the session activity
		// The five following instructions do not work when Flauto.androidActivity is NULL
		// This can happen when this module is directly instanciated by the OS, without initializing TrackPlayer first.
		//assert(Flauto.androidActivity != null);
		//Context       context       = getApplicationContext();
		//Intent        intent        = new Intent( context, Flauto.androidActivity.getClass() );
		//PendingIntent pendingIntent2 = PendingIntent.getActivity( context, 1, intent, PendingIntent.FLAG_UPDATE_CURRENT );
		//mMediaSessionCompat.setSessionActivity( pendingIntent2 );
		// Pass the media session token to this service
		setSessionToken( mMediaSessionCompat.getSessionToken() );
	}

	private void initMediaSessionMetadata( Bitmap albumArt )
	{
		// Build the metadata of the currently playing audio file
		MediaMetadataCompat.Builder metadataBuilder = new MediaMetadataCompat.Builder();

		// Add the track duration
		metadataBuilder.putLong( MediaMetadataCompat.METADATA_KEY_DURATION, mMediaPlayer.getDuration() );
		// Include the other metadata if the audio player features should be included
		//if ( true )
		{
			// Add the display icon and the album art
			metadataBuilder.putBitmap( MediaMetadataCompat.METADATA_KEY_DISPLAY_ICON, albumArt );
			metadataBuilder.putBitmap( MediaMetadataCompat.METADATA_KEY_ALBUM_ART, albumArt );

			// lock screen icon for pre lollipop
			metadataBuilder.putBitmap( MediaMetadataCompat.METADATA_KEY_ART, albumArt );
			metadataBuilder.putString( MediaMetadataCompat.METADATA_KEY_DISPLAY_TITLE, currentTrack.getTitle() );
			metadataBuilder.putString( MediaMetadataCompat.METADATA_KEY_DISPLAY_SUBTITLE, currentTrack.getAuthor() );
			// metadataBuilder.putLong(MediaMetadataCompat.METADATA_KEY_TRACK_NUMBER, 1);
			// metadataBuilder.putLong(MediaMetadataCompat.METADATA_KEY_NUM_TRACKS, 1);
		}
		// Pass the metadata of the currently playing audio file to the media session
		mMediaSessionCompat.setMetadata( metadataBuilder.build() );
	}

	private void initNoisyReceiver()
	{
		// Register the callback to trigger when the headphones are unplugged
		IntentFilter filter = new IntentFilter( AudioManager.ACTION_AUDIO_BECOMING_NOISY );
		registerReceiver( mNoisyReceiver, filter );
		mIsNoisyReceiverRegistered = true;
	}

	private void resetMediaPlayer()
	{
		// Exit the method if the media player has already been reset
            if ( mMediaPlayer == null )
            {
                return;
            }

		// Reset the media player
		mMediaPlayer.reset();
		mMediaPlayer.release();
		mMediaPlayer = null;
	}

	/**
	 * Returns whether the audio focus was successfully retrieved.
	 *
	 * @return Whether the audio focus was successfully retrieved.
	 */
	/*
	 * private boolean successfullyRetrievedAudioFocus() { // Get a reference to the
	 * system AudioManager AudioManager audioManager = (AudioManager)
	 * getSystemService(Context.AUDIO_SERVICE);
	 *
	 * // Request audio focus to stream music int result; if
	 * (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
	 * AudioAttributes playbackAttributes = new AudioAttributes.Builder()
	 * .setUsage(AudioAttributes.USAGE_MEDIA)
	 * .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC) .build();
	 *
	 * mAudioFocusRequest = new
	 * AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
	 * .setAudioAttributes(playbackAttributes) .setOnAudioFocusChangeListener(this)
	 * .build();
	 *
	 * result = audioManager.requestAudioFocus(mAudioFocusRequest); } else { result
	 * = audioManager.requestAudioFocus(this, AudioManager.STREAM_MUSIC,
	 * AudioManager.AUDIOFOCUS_GAIN); }
	 *
	 *
	 * // Check whether the audio focus was gained return result ==
	 * AudioManager.AUDIOFOCUS_GAIN; }
	 *
	 */
	private void setMediaPlaybackState( int state )
	{
		// Build a playback state from the given state
		PlaybackStateCompat.Builder playbackStateBuilder = new PlaybackStateCompat.Builder();

		// Set the appropriate playback action based on the given state
		int  playbackSpeed;
		long playPauseAction;
		if ( state == PlaybackStateCompat.STATE_PLAYING )
		{
			// The media player is playing, then the action will pause the playback
			playPauseAction = PlaybackStateCompat.ACTION_PLAY_PAUSE | PlaybackStateCompat.ACTION_PAUSE;
			playbackSpeed   = 1;
		} else
		{
			// The media player is playing, then the action will resume the playback
			playPauseAction = PlaybackStateCompat.ACTION_PLAY_PAUSE | PlaybackStateCompat.ACTION_PLAY;
			playbackSpeed   = 0;
		}

		// Add the actions to skip forward and backward and the play/pause action
		playbackStateBuilder.setActions( playPauseAction | PlaybackStateCompat.ACTION_SKIP_TO_NEXT | PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS );

		// playbackStateBuilder.setState(state,
		// PlaybackStateCompat.PLAYBACK_POSITION_UNKNOWN, playbackSpeed);
		if (mMediaPlayer != null) {
			playbackStateBuilder.setState( state, mMediaPlayer.getCurrentPosition(), playbackSpeed );
		}

		// Pass the playback state to the media session
		if (mMediaSessionCompat != null) {
			mMediaSessionCompat.setPlaybackState( playbackStateBuilder.build() );
		}
	}

	/**
	 * Shows a notification with the media controls for the playing state.
	 */
	private void showPlayingNotification()
	{
		// The player is playing, then build an action to pause the playback
		NotificationCompat.Action actionPause = new NotificationCompat.Action( R.drawable.ic_pause, "Pause", MediaButtonReceiver.buildMediaButtonPendingIntent( this, PlaybackStateCompat.ACTION_PLAY_PAUSE ) );

		// Show the notification
		displayNotification( getApplicationContext(), actionPause );

	}

	/**
	 * Shows a notification with the media controls for the paused state.
	 */
	private void showPausedNotification()
	{
		// The player is paused, then build an action to play the playback
		NotificationCompat.Action actionPlay = new NotificationCompat.Action( R.drawable.ic_play_arrow, "Play", MediaButtonReceiver.buildMediaButtonPendingIntent( this, PlaybackStateCompat.ACTION_PLAY_PAUSE ) );

		// Show the notification
		displayNotification( getApplicationContext(), actionPlay );
	}

	/**
	 * Shows a notification with the media controls to handle the media player
	 * playback. If audio player features should not be included the notification
	 * won't be displayed.
	 *
	 * @param context The context in which to display the notification
	 * @param action  The main action to display in the notification (play or pause
	 *                button).
	 */
	private void displayNotification( Context context, NotificationCompat.Action action )
	{

		NotificationManager notificationManager = null;
		if ( Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP )
		{
			// Get the audio metadata
			MediaControllerCompat  controller    = mMediaSessionCompat.getController();
			MediaMetadataCompat    mediaMetadata = controller.getMetadata();
			MediaDescriptionCompat description   = mediaMetadata.getDescription();

			// Get the app icon
			int icon = context.getResources().getIdentifier( "ic_launcher", "mipmap", context.getPackageName() );

			// Create the notification with media style, and associate it to the current
			// media session
			MediaStyle style = new MediaStyle().setShowActionsInCompactView( 1 ).setMediaSession( mMediaSessionCompat.getSessionToken() );

			// Create the actions to skip forward and backward
			boolean skipBackwardEnabled = skipTrackBackwardHandler != null;
			NotificationCompat.Action skipBackward = new NotificationCompat.Action( skipBackwardEnabled ? R.drawable.ic_skip_prev_on : R.drawable.ic_skip_prev_off, "Skip Backward",
			                                                                        skipBackwardEnabled ? MediaButtonReceiver.buildMediaButtonPendingIntent( this, PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS ) : null
			);
			boolean skipForwardEnabled = true; // skipTrackForwardHandler != null;
			NotificationCompat.Action skipForward = new NotificationCompat.Action( skipForwardEnabled ? R.drawable.ic_skip_next_on : R.drawable.ic_skip_next_off, "Skip Forward",
			                                                                       skipForwardEnabled ? MediaButtonReceiver.buildMediaButtonPendingIntent( this, PlaybackStateCompat.ACTION_SKIP_TO_NEXT ) : null
			);

			// Build the notification
			NotificationCompat.Builder builder = new NotificationCompat.Builder( context, notificationChannelId );
			builder.setVisibility( NotificationCompat.VISIBILITY_PUBLIC ).setOnlyAlertOnce( true ).setContentTitle( description.getTitle() ).setContentText( description.getSubtitle() ).setLargeIcon(
				description.getIconBitmap() ).setSmallIcon( icon ).setContentIntent( controller.getSessionActivity() ).setDeleteIntent(
				MediaButtonReceiver.buildMediaButtonPendingIntent( context, PlaybackStateCompat.ACTION_STOP ) ).addAction( skipBackward ).addAction( action ).addAction( skipForward ).setStyle( style );

			// Create the notification channel, if needed
			String notificationChannelId = "tau_channel_01";
			if ( Build.VERSION.SDK_INT >= Build.VERSION_CODES.O )
			{
				// Initialize the channel with name, description, importance and ID
				CharSequence        name               = "tau";
				String              channelDescription = "Media playback controls";
				int                 importance         = NotificationManager.IMPORTANCE_LOW;
				NotificationChannel channel            = new NotificationChannel( notificationChannelId, name, importance );
				channel.setDescription( channelDescription );
				channel.setShowBadge( false );
				channel.setLockscreenVisibility( Notification.VISIBILITY_PUBLIC );

				// Add the just created channel ID to the notification builder
				builder.setChannelId( notificationChannelId );

				// Get the notification manager and create the notification channel
				notificationManager = context.getSystemService( NotificationManager.class );
				notificationManager.createNotificationChannel( channel );
			}

			// Build the notification
			Notification notification = builder.build();

			// Display the notification and place the service in the foreground
			startForeground( 1, notification );

		}
	}

	/**
	 * A tool to download the album art to display in the notification in a
	 * background thread.
	 */
	private class AlbumArtDownloader
		extends AsyncTask<String, Void, Bitmap>
	{
		@Override
		protected Bitmap doInBackground( String... params )
		{
			// Download the image, convert it to Bitmap and return it
			try
			{
				URL               url        = new URL( params[ 0 ] );
				HttpURLConnection connection = ( HttpURLConnection ) url.openConnection();
				connection.setDoInput( true );
				connection.connect();
				InputStream in = connection.getInputStream();
				return BitmapFactory.decodeStream( in );
			}
			catch ( MalformedURLException e )
			{
				e.printStackTrace();
			}
			catch ( IOException e )
			{
				e.printStackTrace();
			}
			return null;
		}

		@Override
		protected void onPostExecute( Bitmap bitmap )
		{
			super.onPostExecute( bitmap );
			// Reinitialize the metadata when the image has been downloaded
			initMediaSessionMetadata( bitmap );
			//NotificationCompat.Action actionPlay = new NotificationCompat.Action( R.drawable.ic_play_arrow, "Play", MediaButtonReceiver.buildMediaButtonPendingIntent( getApplicationContext(), PlaybackStateCompat.ACTION_PLAY_PAUSE ) );
			//displayNotification( getApplicationContext(), actionPlay );

			if (! mMediaPlayer.isPlaying() )
			{
				// Show a notification to handle the media playback
				showPausedNotification();
			} else
			{
				showPlayingNotification();
			}
		}
	}
}
