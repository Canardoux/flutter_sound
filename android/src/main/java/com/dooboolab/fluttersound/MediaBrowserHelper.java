package com.dooboolab.fluttersound;

import android.app.Activity;
import android.content.ComponentName;
import android.content.Context;
import android.os.RemoteException;
import android.support.v4.media.MediaBrowserCompat;
import android.support.v4.media.session.MediaControllerCompat;
import android.support.v4.media.session.PlaybackStateCompat;

import androidx.arch.core.util.Function;

import java.util.concurrent.Callable;


public class MediaBrowserHelper {
    private static final int STATE_PAUSED = 0;
    private static final int STATE_PLAYING = 1;
    private static final int STATE_STOPPED = 2;


    MediaControllerCompat mediaControllerCompat;

    private int mCurrentState;
    private MediaBrowserCompat mMediaBrowserCompat;
    private Activity mActivity;
    // The function to call when the media browser successfully connects
    // to the service.
    private Callable<Void> mServiceConnectionSuccessCallback;
    // The function to call when the media browser is unable to connect
    // to the service.
    private Callable<Void> mServiceConnectionUnsuccessfulCallback;

    private MediaControllerCompat.Callback mMediaControllerCompatCallback = new MediaControllerCompat.Callback() {

        @Override
        public void onPlaybackStateChanged(PlaybackStateCompat state) {
            super.onPlaybackStateChanged(state);
            if (state == null) {
                return;
            }

            switch (state.getState()) {
                case PlaybackStateCompat.STATE_PLAYING: {
                    mCurrentState = STATE_PLAYING;
                    break;
                }
                case PlaybackStateCompat.STATE_PAUSED: {
                    mCurrentState = STATE_PAUSED;
                    break;
                }
            }
        }
    };

    private MediaBrowserCompat.ConnectionCallback mMediaBrowserCompatConnectionCallback = new MediaBrowserCompat.ConnectionCallback() {
        @Override
        public void onConnected() {
            super.onConnected();
            // A new MediaBrowserCompat object is created and connected. Then, initialize a
            // MediaControllerCompat object and associate it with MediaSessionCompat. Once completed,
            // start the audio playback.
            try {
                mediaControllerCompat = new MediaControllerCompat(mActivity, mMediaBrowserCompat.getSessionToken());
                mediaControllerCompat.registerCallback(mMediaControllerCompatCallback);
                MediaControllerCompat.setMediaController(mActivity, mediaControllerCompat);

                // Start the audio playback
                // MediaControllerCompat.getMediaController(mActivity).getTransportControls().playFromMediaId("http://path-to-audio-file.com", null);

            } catch (RemoteException e) {

            }

            // Call the successful connection callback if it was provided
            if(mServiceConnectionSuccessCallback != null) {
                try {
                    mServiceConnectionSuccessCallback.call();
                    // Remove the callback
                    mServiceConnectionSuccessCallback = null;
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        }

        @Override
        public void onConnectionFailed() {
            super.onConnectionFailed();

            // Call the unsuccessful connection callback if it was provided
            if(mServiceConnectionUnsuccessfulCallback != null) {
                try {
                    mServiceConnectionUnsuccessfulCallback.call();
                    // Remove the callback
                    mServiceConnectionUnsuccessfulCallback = null;
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        }
    };

    MediaBrowserHelper(Activity activity, Callable<Void> serviceSuccConnectionCallback, Callable<Void> serviceUnsuccConnectionCallback) {
        mActivity = activity;
        mServiceConnectionSuccessCallback = serviceSuccConnectionCallback;
        mServiceConnectionUnsuccessfulCallback = serviceUnsuccConnectionCallback;

        initMediaBrowser();
    }


    /**
     * Initialize the media browser in this class
     */
    private void initMediaBrowser() {
        // Create and connect a MediaBrowserCompat
        mMediaBrowserCompat = new MediaBrowserCompat(
                mActivity,
                new ComponentName(mActivity, BackgroundAudioService.class),
                mMediaBrowserCompatConnectionCallback,
                mActivity.getIntent().getExtras()
        );

        mMediaBrowserCompat.connect();
    }

    /**
     * Clean up the resources taken by the media browser.
     *
     * Call this in onDestroy().
     */
    void releaseMediaBrowser() {
        // Pause the media player if it is playing
        if (mediaControllerCompat.getPlaybackState().getState() == PlaybackStateCompat.STATE_PLAYING) {
            mediaControllerCompat.getTransportControls().pause();
        }

        mMediaBrowserCompat.disconnect();
    }

    /**
     * Plays the playback if it is paused and pauses it if it is playing
     */
    void playPausePlayback() {
        if (mCurrentState == STATE_PLAYING) {
            pausePlayback();
        } else {
            playPlayback();
        }
    }

    void playPlayback() {
        mediaControllerCompat.getTransportControls().play();
        mCurrentState = STATE_PLAYING;
    }

    void pausePlayback() {
        if (mediaControllerCompat.getPlaybackState().getState() == PlaybackStateCompat.STATE_PLAYING) {
            mediaControllerCompat.getTransportControls().pause();
            mCurrentState = STATE_PAUSED;
        }
    }

    void seekTo(long newPosition) {
        mediaControllerCompat.getTransportControls().seekTo(newPosition);
    }

    void stop() {
        mediaControllerCompat.getTransportControls().stop();
        mCurrentState = STATE_STOPPED;
    }

    void setMediaPlayerOnPreparedListener(Callable<Void> callback) {
        BackgroundAudioService.mediaPlayerOnPreparedListener = callback;
    }

    void setMediaPlayerOnCompletionListener(Callable<Void> callback) {
        BackgroundAudioService.mediaPlayerOnCompletionListener = callback;
    }

    /**
     * Add a handler for when the user taps the button to skip the track forward.
     */
    void setSkipTrackForwardHandler(Callable<Void> handler) {
        BackgroundAudioService.skipTrackForwardHandler = handler;
    }

    /**
     * Remove the handler for when the user taps the button to skip the track forward.
     */
    void removeSkipTrackForwardHandler() {
        BackgroundAudioService.skipTrackForwardHandler = null;
    }

    /**
     * Add a handler for when the user taps the button to skip the track backward.
     */
    void setSkipTrackBackwardHandler(Callable<Void> handler) {
        BackgroundAudioService.skipTrackBackwardHandler = handler;
    }

    /**
     * Remove the handler for when the user taps the button to skip the track backward.
     */
    void removeSkipTrackBackwardHandler() {
        BackgroundAudioService.skipTrackBackwardHandler = null;
    }

    /**
     * Passes the currently playing track to the media browser, in order to show the
     * notification properly.
     *
     * @param track The currently playing track.
     */
    void setNotificationMetadata(Track track) {
        BackgroundAudioService.currentTrack = track;
    }

    /**
     * Passes to the media browser the function to execute to update the playback state in the
     * Flutter code.
     *
     * @param playbackStateUpdater The function to execute to update the playback state in the
     *                            Flutter code.
     */
    void setPlaybackStateUpdater(Function playbackStateUpdater) {
        BackgroundAudioService.playbackStateUpdater = playbackStateUpdater;
    }
}
