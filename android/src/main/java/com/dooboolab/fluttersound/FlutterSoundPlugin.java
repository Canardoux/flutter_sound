package com.dooboolab.fluttersound;

import android.Manifest;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.media.MediaRecorder;
import android.os.Build;
import android.os.Environment;
import android.os.Handler;
import android.os.SystemClock;
import android.support.v4.media.MediaMetadataCompat;
import android.support.v4.media.session.PlaybackStateCompat;
import android.util.Log;

import androidx.arch.core.util.Function;
import androidx.core.app.NotificationManagerCompat;
import androidx.media.session.MediaButtonReceiver;

import com.google.gson.Gson;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.Timer;
import java.util.TimerTask;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/**
 * FlutterSoundPlugin
 */
public class FlutterSoundPlugin implements MethodCallHandler, PluginRegistry.RequestPermissionsResultListener, AudioInterface {
    final static String TAG = "FlutterSoundPlugin";
    final static String RECORD_STREAM = "com.dooboolab.fluttersound/record";
    final static String PLAY_STREAM = "com.dooboolab.fluttersound/play";

    private static final String ERR_UNKNOWN = "ERR_UNKNOWN";
    private static final String ERR_PLAYER_IS_NULL = "ERR_PLAYER_IS_NULL";
    private static final String ERR_PLAYER_IS_PLAYING = "ERR_PLAYER_IS_PLAYING";
    private static final String ERR_RECORDER_IS_NULL = "ERR_RECORDER_IS_NULL";
    private static final String ERR_RECORDER_IS_RECORDING = "ERR_RECORDER_IS_RECORDING";
    private static Registrar reg;
    private static MethodChannel channel;
    private final ExecutorService taskScheduler = Executors.newSingleThreadExecutor();
    final private AudioModel model = new AudioModel();
    final private Handler recordHandler = new Handler();
    //mainThread handler
    final private Handler mainHandler = new Handler();
    final private Handler dbPeakLevelHandler = new Handler();
    private Timer mTimer = new Timer();

    private MediaBrowserHelper mMediaBrowserHelper;

    /**
     * Plugin registration.
     */
    public static void registerWith(Registrar registrar) {
        channel = new MethodChannel(registrar.messenger(), "flutter_sound");
        channel.setMethodCallHandler(new FlutterSoundPlugin());
        reg = registrar;
    }

    @Override
    public void onMethodCall(final MethodCall call, final Result result) {
        final String path = call.argument("path");

        switch (call.method) {
            case "startRecorder":
                taskScheduler.submit(() -> {
                    int sampleRate = call.argument("sampleRate");
                    int numChannels = call.argument("numChannels");
                    int androidEncoder = call.argument("androidEncoder");
                    Integer bitRate = call.argument("bitRate");
                    int androidAudioSource = call.argument("androidAudioSource");
                    int androidOutputFormat = call.argument("androidOutputFormat");
                    startRecorder(numChannels, sampleRate, bitRate, androidEncoder, androidAudioSource, androidOutputFormat, path, result);
                });
                break;
            case "stopRecorder":
                taskScheduler.submit(() -> stopRecorder(result));
                break;
            case "startPlayer":
                final String trackJson = call.argument("track");
                final Track track = new Gson().fromJson(trackJson, Track.class);

                boolean canSkipForward = call.argument("canSkipForward");
                boolean canSkipBackward = call.argument("canSkipBackward");
                this.startPlayer(track, canSkipForward, canSkipBackward, result);
                break;
            case "stopPlayer":
                this.stopPlayer(result);
                break;
            case "pausePlayer":
                this.pausePlayer(result);
                break;
            case "resumePlayer":
                this.resumePlayer(result);
                break;
            case "seekToPlayer":
                int sec = call.argument("sec");
                this.seekToPlayer(sec, result);
                break;
            case "setVolume":
                double volume = call.argument("volume");
                this.setVolume(volume, result);
                break;
            case "setDbPeakLevelUpdate":
                double intervalInSecs = call.argument("intervalInSecs");
                this.setDbPeakLevelUpdate(intervalInSecs, result);
                break;
            case "setDbLevelEnabled":
                boolean enabled = call.argument("enabled");
                this.setDbLevelEnabled(enabled, result);
                break;
            case "setSubscriptionDuration":
                if (call.argument("sec") == null) return;
                double duration = call.argument("sec");
                this.setSubscriptionDuration(duration, result);
                break;
            case "initializeMediaPlayer":
                this.initializeMediaPlayer(result);
                break;
            case "releaseMediaPlayer":
                this.releaseMediaPlayer(result);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    @Override
    public boolean onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        final int REQUEST_RECORD_AUDIO_PERMISSION = 200;
        switch (requestCode) {
            case REQUEST_RECORD_AUDIO_PERMISSION:
                if (grantResults[0] == PackageManager.PERMISSION_GRANTED)
                    return true;
                break;
        }
        return false;
    }

    @Override
    public void startRecorder(int numChannels, int sampleRate, Integer bitRate, int androidEncoder, int androidAudioSource, int androidOutputFormat, String path, final Result result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {

            if (
                    reg.activity().checkSelfPermission(Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED
                            || reg.activity().checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED
            ) {
                reg.activity().requestPermissions(new String[]{
                        Manifest.permission.RECORD_AUDIO,
                        Manifest.permission.WRITE_EXTERNAL_STORAGE,
                }, 0);
                result.error(TAG, "NO PERMISSION GRANTED", Manifest.permission.RECORD_AUDIO + " or " + Manifest.permission.WRITE_EXTERNAL_STORAGE);
                return;
            }
        }

        if (path == null) {
            path = AudioModel.DEFAULT_FILE_LOCATION;
        } else {
            path = Environment.getExternalStorageDirectory().getPath() + "/" + path;
        }

        if (this.model.getMediaRecorder() == null) {
            this.model.setMediaRecorder(new MediaRecorder());
            this.model.getMediaRecorder().setAudioSource(androidAudioSource);
            this.model.getMediaRecorder().setOutputFormat(androidOutputFormat);
            this.model.getMediaRecorder().setAudioEncoder(androidEncoder);
            this.model.getMediaRecorder().setAudioChannels(numChannels);
            this.model.getMediaRecorder().setAudioSamplingRate(sampleRate);

            this.model.getMediaRecorder().setOutputFile(path);

            // If bitrate is defined, the use it, otherwise use the OS default
            if (bitRate != null) {
                this.model.getMediaRecorder().setAudioEncodingBitRate(bitRate);
            }
        }

        try {
            this.model.getMediaRecorder().prepare();
            this.model.getMediaRecorder().start();

            // Remove all pending runnables, this is just for safety (should never happen)
            recordHandler.removeCallbacksAndMessages(null);
            final long systemTime = SystemClock.elapsedRealtime();
            this.model.setRecorderTicker(() -> {

                long time = SystemClock.elapsedRealtime() - systemTime;
//          Log.d(TAG, "elapsedTime: " + SystemClock.elapsedRealtime());
//          Log.d(TAG, "time: " + time);

//          DateFormat format = new SimpleDateFormat("mm:ss:SS", Locale.US);
//          String displayTime = format.format(time);
//          model.setRecordTime(time);
                try {
                    JSONObject json = new JSONObject();
                    json.put("current_position", String.valueOf(time));
                    channel.invokeMethod("updateRecorderProgress", json.toString());
                    recordHandler.postDelayed(model.getRecorderTicker(), model.subsDurationMillis);
                } catch (JSONException je) {
                    Log.d(TAG, "Json Exception: " + je.toString());
                }
            });
            recordHandler.post(this.model.getRecorderTicker());

            if (this.model.shouldProcessDbLevel) {
                dbPeakLevelHandler.removeCallbacksAndMessages(null);
                this.model.setDbLevelTicker(() -> {

                    MediaRecorder recorder = model.getMediaRecorder();
                    if (recorder != null) {
                        double maxAmplitude = recorder.getMaxAmplitude();

                        // Calculate db based on the following article.
                        // https://stackoverflow.com/questions/10655703/what-does-androids-getmaxamplitude-function-for-the-mediarecorder-actually-gi
                        //
                        double ref_pressure = 51805.5336;
                        double p = maxAmplitude / ref_pressure;
                        double p0 = 0.0002;

                        double db = 20.0 * Math.log10(p / p0);

                        // if the microphone is off we get 0 for the amplitude which causes
                        // db to be infinite.
                        if (Double.isInfinite(db))
                            db = 0.0;

                        Log.d(TAG, "rawAmplitude: " + maxAmplitude + " Base DB: " + db);

                        channel.invokeMethod("updateDbPeakProgress", db);
                        dbPeakLevelHandler.postDelayed(model.getDbLevelTicker(),
                                (FlutterSoundPlugin.this.model.peakLevelUpdateMillis));
                    }
                });
                dbPeakLevelHandler.post(this.model.getDbLevelTicker());
            }


            String finalPath = path;
            mainHandler.post(new Runnable() {
                @Override
                public void run() {
                    result.success(finalPath);
                }
            });
        } catch (Exception e) {
            Log.e(TAG, "Exception: ", e);
        }
    }

    @Override
    public void stopRecorder(final Result result) {
        // This remove all pending runnables
        recordHandler.removeCallbacksAndMessages(null);
        dbPeakLevelHandler.removeCallbacksAndMessages(null);

        if (this.model.getMediaRecorder() == null) {
            Log.d(TAG, "mediaRecorder is null");
            result.error(ERR_RECORDER_IS_NULL, ERR_RECORDER_IS_NULL, ERR_RECORDER_IS_NULL);
            return;
        }
        this.model.getMediaRecorder().stop();
        this.model.getMediaRecorder().reset();
        this.model.getMediaRecorder().release();
        this.model.setMediaRecorder(null);
        mainHandler.post(new Runnable() {
            @Override
            public void run() {
                result.success("recorder stopped.");
            }
        });

    }

    @Override
    public void initializeMediaPlayer(final Result result) {
        // Initialize the media browser if it hasn't already been initialized
        if (mMediaBrowserHelper == null) {
            // If the initialization will be successful, result.success will
            // be called, otherwise result.error will be called.
            mMediaBrowserHelper = new MediaBrowserHelper(
                    reg.activity(),
                    new MediaPlayerConnectionListener(result, true),
                    new MediaPlayerConnectionListener(result, false)
            );
            // Pass the playback state updater to the media browser
            mMediaBrowserHelper.setPlaybackStateUpdater(new PlaybackStateUpdater());
        } else {
            result.success("The player had already been initialized.");
        }
    }

    @Override
    public void releaseMediaPlayer(final Result result) {
        // Throw an error if the media player is not initialized
        if(mMediaBrowserHelper == null) {
            result.error(TAG, "The player cannot be released because it is not initialized.", null);
            return;
        }

        // Release the media browser
        mMediaBrowserHelper.releaseMediaBrowser();
        mMediaBrowserHelper = null;
        result.success("The player has been successfully released");
    }

    private boolean wasMediaPlayerInitialized(final Result result) {
        if(mMediaBrowserHelper == null) {
            Log.e(TAG, "initializePlayer() must be called before this method.");
            result.error(TAG, "initializePlayer() must be called before this method.", null);
            return false;
        }
        return true;
    }

    @Override
    public void startPlayer(final Track track,
                            boolean canSkipForward,
                            boolean canSkipBackward,
                            final Result result) {
        // Exit the method if a media browser helper was not initialized
        if (!wasMediaPlayerInitialized(result)) return;

        // Just resume the playback if it was paused
        PlaybackStateCompat playbackState = mMediaBrowserHelper.mediaControllerCompat.getPlaybackState();
        if (playbackState != null && playbackState.getState() == PlaybackStateCompat.STATE_PAUSED) {
            // The player was paused, then resume it
            mMediaBrowserHelper.playPlayback();
            result.success("player resumed");
            return;
        }

        // Get the path to the file audio to play
        final String path = track.getPath();

        mTimer = new Timer();

        // Add or remove the handlers for when the user tries to skip the current track
        if(canSkipForward) {
            mMediaBrowserHelper.setSkipTrackForwardHandler(new SkipTrackHandler(true));
        } else {
            mMediaBrowserHelper.removeSkipTrackForwardHandler();
        }
        if(canSkipBackward) {
            mMediaBrowserHelper.setSkipTrackBackwardHandler(new SkipTrackHandler(false));
        } else {
            mMediaBrowserHelper.removeSkipTrackBackwardHandler();
        }

        // Pass to the media browser the metadata to use in the notification
        mMediaBrowserHelper.setNotificationMetadata(track);

        // Add the listeners for the onPrepared and onCompletion events
        mMediaBrowserHelper.setMediaPlayerOnPreparedListener(new MediaPlayerOnPreparedListener(result, path));
        mMediaBrowserHelper.setMediaPlayerOnCompletionListener(new MediaPlayerOnCompletionListener());

        // Check whether a path to an audio file was given
        if (path == null) {
            // No paths were given, then use the default file
            mMediaBrowserHelper.mediaControllerCompat.getTransportControls()
                    .playFromMediaId(AudioModel.DEFAULT_FILE_LOCATION, null);
        } else {
            // A path was given, then send it to the media player
            mMediaBrowserHelper.mediaControllerCompat.getTransportControls()
                    .playFromMediaId(path, null);
        }

        // The media player is started in the on prepared callback
    }

    @Override
    public void stopPlayer(final Result result) {
        mTimer.cancel();

        // Exit the method if a media browser helper was not initialized
        if (!wasMediaPlayerInitialized(result)) return;

        try {
            // Stop the playback
            mMediaBrowserHelper.stop();
            result.success("stopped player.");
        } catch (Exception e) {
            Log.e(TAG, "stopPlay exception: " + e.getMessage());
            result.error(ERR_UNKNOWN, ERR_UNKNOWN, e.getMessage());
        }
    }

    @Override
    public void pausePlayer(final Result result) {
        // Exit the method if a media browser helper was not initialized
        if (!wasMediaPlayerInitialized(result)) return;

        try {
            // Pause the media player
            mMediaBrowserHelper.pausePlayback();
            result.success("paused player.");
        } catch (Exception e) {
            Log.e(TAG, "pausePlay exception: " + e.getMessage());
            result.error(ERR_UNKNOWN, ERR_UNKNOWN, e.getMessage());
        }
    }

    @Override
    public void resumePlayer(final Result result) {
        // Exit the method if a media browser helper was not initialized
        if (!wasMediaPlayerInitialized(result)) return;

        // Throw an error if we can't resume the media player because it is already playing
        PlaybackStateCompat playbackState = mMediaBrowserHelper.mediaControllerCompat.getPlaybackState();
        if (playbackState != null && playbackState.getState() == PlaybackStateCompat.STATE_PLAYING) {
            result.error(ERR_PLAYER_IS_PLAYING, ERR_PLAYER_IS_PLAYING, ERR_PLAYER_IS_PLAYING);
            return;
        }

        try {
            // Resume the player
            mMediaBrowserHelper.playPlayback();

            // Seek the player to the last position and resume it
            result.success("resumed player.");
        } catch (Exception e) {
            Log.e(TAG, "mediaPlayer resume: " + e.getMessage());
            result.error(ERR_UNKNOWN, ERR_UNKNOWN, e.getMessage());
        }
    }

    @Override
    public void seekToPlayer(int millis, final Result result) {
        // Exit the method if a media browser helper was not initialized
        if (!wasMediaPlayerInitialized(result)) return;

        // Get the current position of the media player in milliseconds, but only to log it
        // int currentMillis = this.model.getMediaPlayer().getCurrentPosition();
        // long currentMillis = mMediaBrowserHelper.mediaControllerCompat.getPlaybackState().getPosition();
        // Log.d(TAG, "currentMillis: " + currentMillis);
        // millis += currentMillis; [This was the problem for me]

        // Log.d(TAG, "seekTo: " + millis);

        // Seek the player to the given position
        mMediaBrowserHelper.seekTo(millis);

        // long newCurrentPos = mMediaBrowserHelper.mediaControllerCompat.getPlaybackState().getPosition();
        // Log.d(TAG, "new current position: " + newCurrentPos);

        result.success(String.valueOf(millis));
    }

    @Override
    public void setVolume(double volume, final Result result) {
        // Exit the method if a media browser helper was not initialized
        if (!wasMediaPlayerInitialized(result)) return;

        // Get the maximum value for the volume
        int maxVolume = mMediaBrowserHelper.mediaControllerCompat.getPlaybackInfo().getMaxVolume();
        // Get the value of the new volume level
        int newVolume = (int) Math.floor(volume * maxVolume);

        // Adjust the media player volume to the given level
        mMediaBrowserHelper.mediaControllerCompat.setVolumeTo(newVolume, 0);
        result.success("Set volume");
    }

    @Override
    public void setDbPeakLevelUpdate(double intervalInSecs, Result result) {
        this.model.peakLevelUpdateMillis = (long) (intervalInSecs * 1000);
        result.success("setDbPeakLevelUpdate: " + this.model.peakLevelUpdateMillis);
    }

    @Override
    public void setDbLevelEnabled(boolean enabled, MethodChannel.Result result) {
        this.model.shouldProcessDbLevel = enabled;
        result.success("setDbLevelEnabled: " + this.model.shouldProcessDbLevel);
    }

    @Override
    public void setSubscriptionDuration(double sec, Result result) {
        this.model.subsDurationMillis = (int) (sec * 1000);
        result.success("setSubscriptionDuration: " + this.model.subsDurationMillis);
    }

    /**
     * The callable instance to call when the media player is prepared.
     */
    private class MediaPlayerOnPreparedListener implements Callable<Void> {
        private Result mResult;
        private String mPath;

        private MediaPlayerOnPreparedListener(Result result, String path) {
            mResult = result;
            mPath = path;
        }

        @Override
        public Void call() throws Exception {
            // The content is ready to be played, then play it
            mMediaBrowserHelper.playPausePlayback();

            // Set timer task to send event to RN
            long trackDuration = mMediaBrowserHelper.mediaControllerCompat.getMetadata().getLong(MediaMetadataCompat.METADATA_KEY_DURATION);

            TimerTask mTask = new TimerTask() {
                @Override
                public void run() {
                    // long time = mp.getCurrentPosition();
                    // DateFormat format = new SimpleDateFormat("mm:ss:SS", Locale.US);
                    // final String displayTime = format.format(time);

                    try {
                        JSONObject json = new JSONObject();
                        PlaybackStateCompat playbackState = mMediaBrowserHelper.mediaControllerCompat.getPlaybackState();

                        if(playbackState == null) return;

                        long currentPosition =
                                playbackState.getPosition();

                        json.put("duration", String.valueOf(trackDuration));
                        json.put("current_position", String.valueOf(currentPosition));
                        mainHandler.post(new Runnable() {
                            @Override
                            public void run() {
                                channel.invokeMethod("updateProgress", json.toString());
                            }
                        });

                    } catch (JSONException je) {
                        Log.d(TAG, "Json Exception: " + je.toString());
                    }
                }
            };

            mTimer.schedule(mTask, 0, model.subsDurationMillis);
            String resolvedPath = mPath == null ? AudioModel.DEFAULT_FILE_LOCATION : mPath;
            mResult.success((resolvedPath));

            return null;
        }
    }

    /**
     * The callable instance to call when the media player calls the onCompletion event.
     */
    private class MediaPlayerOnCompletionListener implements Callable<Void> {
        MediaPlayerOnCompletionListener() {
        }

        @Override
        public Void call() throws Exception {
            // Reset the timer
            long trackDuration = mMediaBrowserHelper.mediaControllerCompat.getMetadata().getLong(MediaMetadataCompat.METADATA_KEY_DURATION);

            Log.d(TAG, "Plays completed.");
            try {
                JSONObject json = new JSONObject();
                long currentPosition =
                        mMediaBrowserHelper.mediaControllerCompat.getPlaybackState().getPosition();

                json.put("duration", String.valueOf(trackDuration));
                json.put("current_position", String.valueOf(currentPosition));
                channel.invokeMethod("audioPlayerDidFinishPlaying", json.toString());
            } catch (JSONException je) {
                Log.d(TAG, "Json Exception: " + je.toString());
            }
            mTimer.cancel();

            return null;
        }
    }

    /**
     * The callable instance to call when the media player has been connected.
     */
    private class MediaPlayerConnectionListener implements Callable<Void> {
        private Result mResult;
        // Whether this callback is called when the connection is successful
        private boolean mIsSuccessfulCallback;

        MediaPlayerConnectionListener(Result result, boolean isSuccessfulCallback) {
            mResult = result;
            mIsSuccessfulCallback = isSuccessfulCallback;
        }

        @Override
        public Void call() throws Exception {
            if(mIsSuccessfulCallback) {
                mResult.success("The media player has been successfully initialized");
            } else {
                mResult.error(TAG, "An error occurred while initializing the media player", null);
            }
            return null;
        }
    }

    /**
     * A listener that is triggered when the skip buttons in the notification are clicked.
     */
    private class SkipTrackHandler implements Callable<Void> {
        private boolean mIsSkippingForward;

        SkipTrackHandler(boolean isSkippingForward) {
            mIsSkippingForward = isSkippingForward;
        }

        @Override
        public Void call() throws Exception {
            if(mIsSkippingForward) {
                channel.invokeMethod("skipForward", null);
            } else {
                channel.invokeMethod("skipBackward", null);
            }

            return null;
        }
    }

    /**
     * A function that triggers a function in the Dart code to update the playback state.
     */
    private class PlaybackStateUpdater implements Function<Integer, Void> {
        @Override
        public Void apply(Integer newState) {
            channel.invokeMethod("updatePlaybackState", newState);
            return null;
        }
    }
}
