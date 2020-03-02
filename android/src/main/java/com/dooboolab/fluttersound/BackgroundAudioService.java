package com.dooboolab.fluttersound;
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

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.res.AssetFileDescriptor;
import android.content.res.AssetManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.media.AudioAttributes;
import android.media.AudioFocusRequest;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.os.Build;
import android.os.Bundle;
import android.os.PowerManager;
import android.os.ResultReceiver;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;
import android.support.v4.media.MediaBrowserCompat;
import androidx.media.MediaBrowserServiceCompat;

import android.support.v4.media.MediaDescriptionCompat;
import android.support.v4.media.MediaMetadataCompat;
import androidx.media.session.MediaButtonReceiver;

import android.support.v4.media.session.MediaControllerCompat;
import android.support.v4.media.session.MediaSessionCompat;
import android.support.v4.media.session.PlaybackStateCompat;
//import androidx.appcompat.app.NotificationCompat;
import android.text.TextUtils;
import java.util.concurrent.Callable;



import androidx.arch.core.util.Function;
import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;
import androidx.media.MediaBrowserServiceCompat;
import androidx.media.app.NotificationCompat.MediaStyle;
import androidx.media.session.MediaButtonReceiver;


import com.dooboolab.fluttersound.R;

import java.io.IOException;
import java.io.InputStream;
import java.util.List;

public class BackgroundAudioService extends MediaBrowserServiceCompat implements MediaPlayer.OnCompletionListener, AudioManager.OnAudioFocusChangeListener  {

    public static final String COMMAND_EXAMPLE = "command_example";
    static final String notificationChannelId = "flutter_sound_channel_01";

    //private static final String MY_MEDIA_ROOT_ID = "media_root_id";//!!!
    //private static final String MY_EMPTY_MEDIA_ROOT_ID = "empty_root_id";//!!!
    //private PlaybackStateCompat.Builder stateBuilder;//!!!

    private MediaPlayer mMediaPlayer;
    private MediaSessionCompat mMediaSessionCompat;
    public static Callable skipTrackForwardHandler;
    public static Callable skipTrackBackwardHandler;
    //public static Function playbackStateUpdater;


    public final static int PLAYING_STATE = 0;
    public final static int PAUSED_STATE = 1;
    public final static int STOPPED_STATE = 2;


    private BroadcastReceiver mNoisyReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            if( mMediaPlayer != null && mMediaPlayer.isPlaying() ) {
                mMediaPlayer.pause();
            }
        }
    };

    private MediaSessionCompat.Callback mMediaSessionCallback = new MediaSessionCompat.Callback() {

        @Override
        public void onPlay() {
            super.onPlay();
            if( !successfullyRetrievedAudioFocus() ) {
                return;
            }

            mMediaSessionCompat.setActive(true);
            setMediaPlaybackState(PlaybackStateCompat.STATE_PLAYING);

            //showPlayingNotification();
            startPlayerPlayback();
            //mMediaPlayer.start();

            // Update the playback state
        }

        @Override
        public void onPause() {
            super.onPause();
            // Add or remove the handlers for when the user tries to skip the current track
                BackgroundAudioService.skipTrackForwardHandler =  new Flauto.SkipTrackHandler ( true );
                BackgroundAudioService.skipTrackBackwardHandler =  new Flauto.SkipTrackHandler ( false );

            if( mMediaPlayer.isPlaying() ) {
                mMediaPlayer.pause();
                if( !successfullyRetrievedAudioFocus() ) {
                    return;
                }

                AudioManager audioManager = (AudioManager) getSystemService(Context.AUDIO_SERVICE);
                AudioAttributes mPlaybackAttributes = new AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                        .build();
                AudioFocusRequest mFocusRequest = new AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                        .setAudioAttributes(mPlaybackAttributes)
                        //.setAcceptsDelayedFocusGain(true)
                        //.setWillPauseWhenDucked(true)
                        //.setOnAudioFocusChangeListener(this, mMyHandler)
                        .build();

                mMediaPlayer.setAudioAttributes(mPlaybackAttributes);
                final Object mFocusLock = new Object();

                boolean mPlaybackDelayed = false;

                // requesting audio focus
                int res = audioManager.requestAudioFocus(mFocusRequest);
                synchronized (mFocusLock) {
                    if (res == AudioManager.AUDIOFOCUS_REQUEST_FAILED) {
                        mPlaybackDelayed = false;
                    } else if (res == AudioManager.AUDIOFOCUS_REQUEST_GRANTED) {
                        mPlaybackDelayed = false;
                        startPlayerPlayback();
                    } else if (res == AudioManager.AUDIOFOCUS_REQUEST_DELAYED) {
                        mPlaybackDelayed = true;
                    }
                }


                successfullyRetrievedAudioFocus();
                mMediaSessionCompat.setActive(true);
                setMediaPlaybackState(PlaybackStateCompat.STATE_PLAYING);
                startPlayerPlayback();// [LARPOUX]!!!
                //showPausedNotification();

                // Update the playback state
                //playbackStateUpdater.apply(PAUSED_STATE);

            }
        }


        /**
         * Stop the media playback
         */
        @Override
        @SuppressWarnings("unchecked")
        public void onStop() {
            super.onStop();

            // Stop the media player
            mMediaPlayer.stop();

            // Set the paused playback state
            setMediaPlaybackState(PlaybackStateCompat.STATE_STOPPED);

            // Reset the media player
            mMediaPlayer.reset();

            // Remove the notification
            NotificationManagerCompat.from(BackgroundAudioService.this).cancel(1);

            // Update the playback state
            //playbackStateUpdater.apply(STOPPED_STATE);
        }



        @Override
        public void onPlayFromMediaId(String mediaId, Bundle extras) {
            super.onPlayFromMediaId(mediaId, extras);

            try {
                AssetFileDescriptor afd = getResources().openRawResourceFd(Integer.valueOf(mediaId));
                if( afd == null ) {
                    return;
                }

                try {
                    mMediaPlayer.setDataSource(afd.getFileDescriptor(), afd.getStartOffset(), afd.getLength());

                } catch( IllegalStateException e ) {
                    mMediaPlayer.release();
                    initMediaPlayer();
                    mMediaPlayer.setDataSource(afd.getFileDescriptor(), afd.getStartOffset(), afd.getLength());
                }

                afd.close();
                initMediaSessionMetadata();

            } catch (IOException e) {
                return;
            }

            try {
                mMediaPlayer.prepare();
            } catch (IOException e) {}

            //Work with extras here if you want
        }

        @Override
        public void onCommand(String command, Bundle extras, ResultReceiver cb) {
            super.onCommand(command, extras, cb);
            if( COMMAND_EXAMPLE.equalsIgnoreCase(command) ) {
                //Custom command here
            }
        }

        @Override
        public void onSeekTo(long pos) {
            super.onSeekTo(pos);
        }

        @Override
        public void onSkipToNext() {
            // Call the handler to skip forward, when given
            if (skipTrackForwardHandler != null) {
                try {
                    skipTrackForwardHandler.call();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }

            super.onSkipToNext();
        }

        @Override
        public void onSkipToPrevious() {
            // Call the handler to skip backward, when given
            if (skipTrackBackwardHandler != null) {
                try {
                    skipTrackBackwardHandler.call();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }

            super.onSkipToPrevious();
        }

    };

    @Override
    public void onCreate() {
        super.onCreate();

        initMediaPlayer();
        initMediaSession();
        initNoisyReceiver();
        AudioManager audioManager = (AudioManager) getSystemService(Context.AUDIO_SERVICE);
        AudioAttributes mPlaybackAttributes = new AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_MEDIA)
                .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                .build();
        AudioFocusRequest mFocusRequest = new AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                .setAudioAttributes(mPlaybackAttributes)
                //.setAcceptsDelayedFocusGain(true)
                //.setWillPauseWhenDucked(true)
                //.setOnAudioFocusChangeListener(this, mMyHandler)
                .build();

        mMediaPlayer.setAudioAttributes(mPlaybackAttributes);
        final Object mFocusLock = new Object();

        boolean mPlaybackDelayed = false;

        // requesting audio focus
        int res = audioManager.requestAudioFocus(mFocusRequest);
        synchronized (mFocusLock) {
            if (res == AudioManager.AUDIOFOCUS_REQUEST_FAILED) {
                mPlaybackDelayed = false;
            } else if (res == AudioManager.AUDIOFOCUS_REQUEST_GRANTED) {
                mPlaybackDelayed = false;
                startPlayerPlayback();
            } else if (res == AudioManager.AUDIOFOCUS_REQUEST_DELAYED) {
                mPlaybackDelayed = true;
            }
        }


    }

    private void initNoisyReceiver() {
        //Handles headphones coming unplugged. cannot be done through a manifest receiver
        IntentFilter filter = new IntentFilter(AudioManager.ACTION_AUDIO_BECOMING_NOISY);
        registerReceiver(mNoisyReceiver, filter);
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        AudioManager audioManager = (AudioManager) getSystemService(Context.AUDIO_SERVICE);
        audioManager.abandonAudioFocus(this);
        unregisterReceiver(mNoisyReceiver);
        mMediaSessionCompat.release();
        NotificationManagerCompat.from(this).cancel(1);
    }

    private void initMediaPlayer() {
        mMediaPlayer = new MediaPlayer();
        mMediaPlayer.setWakeMode(getApplicationContext(), PowerManager.PARTIAL_WAKE_LOCK);
        mMediaPlayer.setAudioStreamType(AudioManager.STREAM_MUSIC);
        mMediaPlayer.setVolume(1.0f, 1.0f);
    }

    private void showPlayingNotification() {






        NotificationCompat.Builder builder = MediaStyleHelper.from(BackgroundAudioService.this, mMediaSessionCompat);
        if( builder == null ) {
            return;
        }


        builder.addAction(new NotificationCompat.Action(android.R.drawable.ic_media_pause, "Pause", MediaButtonReceiver.buildMediaButtonPendingIntent(this, PlaybackStateCompat.ACTION_PLAY_PAUSE)));

        //builder.setStyle(new NotificationCompat.BigPictureStyle());
        //builder.setStyle(new NotificationCompat.MediaStyle().setShowActionsInCompactView(0).setMediaSession(mMediaSessionCompat.getSessionToken()));
        //try{ AssetManager assetManager = getAssets(); InputStream istr = assetManager.open("res/mipmap");Bitmap bitmap = BitmapFactory.decodeStream(istr);
            //builder.setStyle(new NotificationCompat.BigPictureStyle().bigPicture (bitmap ));} catch (Exception e) {}

        builder.setSmallIcon(R.mipmap.ic_launcher);
        Notification build =  builder.build();
        NotificationManagerCompat.from(BackgroundAudioService.this).notify(1, build);
        //startForeground(1, build);

        // The player is playing, then build an action to pause the playback
        NotificationCompat.Action actionPause = new NotificationCompat.Action(
                R.drawable.ic_pause,
                "Pause",
                MediaButtonReceiver.buildMediaButtonPendingIntent(this, PlaybackStateCompat.ACTION_PLAY_PAUSE)
        );



        // Show the notification
        displayNotification(getApplicationContext(), actionPause);

    }

    private void showPausedNotification() {
        NotificationCompat.Builder builder = MediaStyleHelper.from(this, mMediaSessionCompat);
        if( builder == null ) {
            return;
        }

        builder.addAction(new NotificationCompat.Action(android.R.drawable.ic_media_play, "Play", MediaButtonReceiver.buildMediaButtonPendingIntent(this, PlaybackStateCompat.ACTION_PLAY_PAUSE)));
        //builder.setStyle(new NotificationCompat.MediaStyle().setShowActionsInCompactView(0).setMediaSession(mMediaSessionCompat.getSessionToken()));

        //try{ AssetManager assetManager = getAssets(); InputStream istr = assetManager.open("res/mipmap");Bitmap bitmap = BitmapFactory.decodeStream(istr);
            //builder.setStyle(new NotificationCompat.BigPictureStyle().bigPicture (bitmap ));} catch (Exception e) {}

        builder.setSmallIcon( R.mipmap.ic_launcher);
        Notification build =  builder.build();
        NotificationManagerCompat.from(this).notify(1, build);


        // The player is playing, then build an action to pause the playback
        NotificationCompat.Action actionPause = new NotificationCompat.Action(
                R.drawable.ic_pause,
                "Pause",
                MediaButtonReceiver.buildMediaButtonPendingIntent(this, PlaybackStateCompat.ACTION_PLAY_PAUSE)
        );



        // Show the notification
        displayNotification(getApplicationContext(), actionPause);


        //startForeground(1, build);
    }



    /**
     * Shows a notification with the media controls to handle the media player playback.
     * If audio player features should not be included the notification won't be displayed.
     *
     * @param context The context in which to display the notification
     * @param action  The main action to display in the notification (play or pause button).
     */
    private void displayNotification(Context context, NotificationCompat.Action action) {
        // Don't display the notification if the audio player features should not be included

        NotificationManager notificationManager = null;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            // Get the audio metadata
            MediaControllerCompat controller = mMediaSessionCompat.getController();
            MediaMetadataCompat mediaMetadata = controller.getMetadata();
            MediaDescriptionCompat description = mediaMetadata.getDescription();

            // Get the app icon
            int icon = context.getResources().getIdentifier("ic_launcher", "mipmap", context.getPackageName());

            // Create the notification with media style, and associate it to the current media session
            MediaStyle style = new MediaStyle()
                    .setShowActionsInCompactView(1)
                    .setMediaSession(mMediaSessionCompat.getSessionToken());

            // Create the actions to skip forward and backward
            boolean skipBackwardEnabled = skipTrackBackwardHandler != null;
            NotificationCompat.Action skipBackward = new NotificationCompat.Action(
                    skipBackwardEnabled ? R.drawable.ic_skip_prev_on : R.drawable.ic_skip_prev_off,
                    "Skip Backward",
                    skipBackwardEnabled ? MediaButtonReceiver.buildMediaButtonPendingIntent(
                            this,
                            PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS) : null
            );
            boolean skipForwardEnabled = skipTrackForwardHandler != null;
            NotificationCompat.Action skipForward = new NotificationCompat.Action(
                    skipForwardEnabled ? R.drawable.ic_skip_next_on : R.drawable.ic_skip_next_off,
                    "Skip Forward",
                    skipForwardEnabled ? MediaButtonReceiver.buildMediaButtonPendingIntent(
                            this,
                            PlaybackStateCompat.ACTION_SKIP_TO_NEXT) : null
            );

            // Build the notification
            NotificationCompat.Builder builder = new NotificationCompat.Builder(context, notificationChannelId);
            builder
                    .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                    .setOnlyAlertOnce(true)
                    .setContentTitle(description.getTitle())
                    .setContentText(description.getSubtitle())
                    .setLargeIcon(description.getIconBitmap())
                    .setSmallIcon(icon)
                    .setContentIntent(controller.getSessionActivity())
                    .setDeleteIntent(MediaButtonReceiver.buildMediaButtonPendingIntent(
                            context,
                            PlaybackStateCompat.ACTION_STOP))
                    .addAction(skipBackward)
                    .addAction(action)
                    .addAction(skipForward)
                    .setStyle(style);

            // Create the notification channel, if needed
            if ( Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                // Initialize the channel with name, description, importance and ID
                CharSequence name = "flutter_sound";
                String channelDescription = "Media playback controls";
                int importance = NotificationManager.IMPORTANCE_LOW;
                NotificationChannel channel = new NotificationChannel(notificationChannelId, name, importance);
                channel.setDescription(channelDescription);
                channel.setShowBadge(false);
                channel.setLockscreenVisibility(Notification.VISIBILITY_PUBLIC);

                // Add the just created channel ID to the notification builder
                builder.setChannelId(notificationChannelId);

                // Get the notification manager and create the notification channel
                notificationManager = context.getSystemService(NotificationManager.class);
                notificationManager.createNotificationChannel(channel);
            }

            // Check whether a notification manager have already been created
            if (notificationManager == null) {
                // The notification manager has not been created yet, then create it now
                NotificationManagerCompat notificationManagerCompat = NotificationManagerCompat.from(context);
                // Send the notification
                notificationManagerCompat.notify(1, builder.build());
            } else {
                // The notification manager has already been created, then send the notification
                notificationManager.notify(1, builder.build());
            }

        }
    }


    private void initMediaSession() {
        ComponentName mediaButtonReceiver = new ComponentName(getApplicationContext(), MediaButtonReceiver.class);
        mMediaSessionCompat = new MediaSessionCompat(getApplicationContext(), "Tag", mediaButtonReceiver, null);

        mMediaSessionCompat.setCallback(mMediaSessionCallback);
        mMediaSessionCompat.setFlags( MediaSessionCompat.FLAG_HANDLES_MEDIA_BUTTONS | MediaSessionCompat.FLAG_HANDLES_TRANSPORT_CONTROLS );

        Intent mediaButtonIntent = new Intent(Intent.ACTION_MEDIA_BUTTON);
        mediaButtonIntent.setClass(this, MediaButtonReceiver.class);
        PendingIntent pendingIntent = PendingIntent.getBroadcast(this, 0, mediaButtonIntent, 0);
        mMediaSessionCompat.setMediaButtonReceiver(pendingIntent);

        setSessionToken(mMediaSessionCompat.getSessionToken());
    }

    private void setMediaPlaybackState(int state) {
        PlaybackStateCompat.Builder playbackstateBuilder = new PlaybackStateCompat.Builder();
        if( state == PlaybackStateCompat.STATE_PLAYING ) {
            playbackstateBuilder.setActions(PlaybackStateCompat.ACTION_PLAY_PAUSE | PlaybackStateCompat.ACTION_PAUSE);
        } else {
            playbackstateBuilder.setActions(PlaybackStateCompat.ACTION_PLAY_PAUSE | PlaybackStateCompat.ACTION_PLAY);
        }
        playbackstateBuilder.setState(state, PlaybackStateCompat.PLAYBACK_POSITION_UNKNOWN, 0);
        mMediaSessionCompat.setPlaybackState(playbackstateBuilder.build());
    }

    private void initMediaSessionMetadata() {
        MediaMetadataCompat.Builder metadataBuilder = new MediaMetadataCompat.Builder();
        //Notification icon in card
        metadataBuilder.putBitmap(MediaMetadataCompat.METADATA_KEY_DISPLAY_ICON, BitmapFactory.decodeResource(getResources(), R.mipmap.ic_launcher));
        metadataBuilder.putBitmap(MediaMetadataCompat.METADATA_KEY_ALBUM_ART, BitmapFactory.decodeResource(getResources(), R.mipmap.ic_launcher));

        //lock screen icon for pre lollipop
        metadataBuilder.putBitmap(MediaMetadataCompat.METADATA_KEY_ART, BitmapFactory.decodeResource(getResources(), R.mipmap.ic_launcher));
        metadataBuilder.putString(MediaMetadataCompat.METADATA_KEY_DISPLAY_TITLE, "Display Title");
        metadataBuilder.putString(MediaMetadataCompat.METADATA_KEY_DISPLAY_SUBTITLE, "Display Subtitle");
        metadataBuilder.putLong(MediaMetadataCompat.METADATA_KEY_TRACK_NUMBER, 1);
        metadataBuilder.putLong(MediaMetadataCompat.METADATA_KEY_NUM_TRACKS, 1);

        mMediaSessionCompat.setMetadata(metadataBuilder.build());
    }

    private boolean successfullyRetrievedAudioFocus() {
        AudioManager audioManager = (AudioManager) getSystemService(Context.AUDIO_SERVICE);

        int result = audioManager.requestAudioFocus(this,
                AudioManager.STREAM_MUSIC, AudioManager.AUDIOFOCUS_GAIN);

        return result == AudioManager.AUDIOFOCUS_GAIN;
    }


    /**
     * Starts the playback of the player (without requesting audio focus).
     */
    @SuppressWarnings("unchecked")
    private void startPlayerPlayback() {
        mMediaSessionCompat.setActive(true);
        setMediaPlaybackState(PlaybackStateCompat.STATE_PLAYING);

        // Show a notification to handle the media playback
        showPlayingNotification();

        // Start the audio player
        mMediaPlayer.start();

        // Update the playback state
        //playbackStateUpdater.apply(PLAYING_STATE);
    }



    //Not important for general audio service, required for class
    @Nullable
    @Override
    public BrowserRoot onGetRoot(@NonNull String clientPackageName, int clientUid, @Nullable Bundle rootHints) {
        if(TextUtils.equals(clientPackageName, getPackageName())) {
            return new BrowserRoot(getString(R.string.app_name), null);
        }

        return null;
    }

    //Not important for general audio service, required for class
    @Override
    public void onLoadChildren(@NonNull String parentId, @NonNull Result<List<MediaBrowserCompat.MediaItem>> result) {
        result.sendResult(null);
    }

    @Override
    public void onAudioFocusChange(int focusChange) {
        switch( focusChange ) {
            case AudioManager.AUDIOFOCUS_LOSS: {
                if( mMediaPlayer.isPlaying() ) {
                    mMediaPlayer.stop();
                }
                break;
            }
            case AudioManager.AUDIOFOCUS_LOSS_TRANSIENT: {
                mMediaPlayer.pause();
                break;
            }
            case AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK: {
                if( mMediaPlayer != null ) {
                    mMediaPlayer.setVolume(0.3f, 0.3f);
                }
                break;
            }
            case AudioManager.AUDIOFOCUS_GAIN: {
                if( mMediaPlayer != null ) {
                    if( !mMediaPlayer.isPlaying() ) {
                        mMediaPlayer.start();
                    }
                    mMediaPlayer.setVolume(1.0f, 1.0f);
                }
                break;
            }
        }
    }

    @Override
    public void onCompletion(MediaPlayer mediaPlayer) {
        if( mMediaPlayer != null ) {
            mMediaPlayer.release();
        }
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        MediaButtonReceiver.handleIntent(mMediaSessionCompat, intent);
        return super.onStartCommand(intent, flags, startId);
    }
}
