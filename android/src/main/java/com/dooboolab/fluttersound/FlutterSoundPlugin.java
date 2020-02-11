package com.dooboolab.fluttersound;

import android.Manifest;
import android.app.Activity;
import android.content.pm.PackageManager;
import android.media.MediaRecorder;
import android.os.Build;
import android.os.Handler;
import android.os.SystemClock;
import android.support.v4.media.MediaMetadataCompat;
import android.support.v4.media.session.PlaybackStateCompat;
import android.util.Log;

import androidx.arch.core.util.Function;
import androidx.core.app.ActivityCompat;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;
import java.io.FileOutputStream;
import java.util.HashMap;
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

// SDK compatibility
// -----------------

class sdkCompat {
    static final int AUDIO_ENCODER_VORBIS = 6;  // MediaRecorder.AudioEncoder.VORBIS added in API level 21
    static final int AUDIO_ENCODER_OPUS = 7;  // MediaRecorder.AudioEncoder.OPUS   added in API level 29
    static final int OUTPUT_FORMAT_OGG = 11; // MediaRecorder.OutputFormat.OGG    added in API level 29
    static final int VERSION_CODES_M = 23; // added in API level 23

    static int checkRecordPermission(Registrar reg) {
        if (Build.VERSION.SDK_INT >= sdkCompat.VERSION_CODES_M) {// Before Marshmallow, record permission was always granted.
            Activity activity = reg.activity();
            if (reg.context().checkCallingOrSelfPermission(Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(activity, new String[]{Manifest.permission.RECORD_AUDIO,}, 0);
                if (reg.context().checkCallingOrSelfPermission(Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED)
                    return PackageManager.PERMISSION_DENIED;
            }
        }
        return PackageManager.PERMISSION_GRANTED;
    }
}
// *****************


/** FlutterSoundPlugin */
public class FlutterSoundPlugin implements MethodCallHandler, PluginRegistry.RequestPermissionsResultListener, AudioInterface{
    final static String TAG = "FlutterSoundPlugin";
    final static String RECORD_STREAM = "com.dooboolab.fluttersound/record";
    final static String PLAY_STREAM= "com.dooboolab.fluttersound/play";

    private static final String ERR_UNKNOWN = "ERR_UNKNOWN";
    private static final String ERR_PLAYER_IS_NULL = "ERR_PLAYER_IS_NULL";
    private static final String ERR_PLAYER_IS_PLAYING = "ERR_PLAYER_IS_PLAYING";
    private static final String ERR_RECORDER_IS_NULL = "ERR_RECORDER_IS_NULL";
    private static final String ERR_RECORDER_IS_RECORDING = "ERR_RECORDER_IS_RECORDING";

    private final ExecutorService taskScheduler = Executors.newSingleThreadExecutor();

    private static Registrar reg;
    final private AudioModel model = new AudioModel();
    private Timer mTimer = new Timer();
    final private Handler recordHandler = new Handler();
    //mainThread handler
    final private Handler mainHandler = new Handler();
    final private Handler dbPeakLevelHandler = new Handler();
    private static MethodChannel channel;
    private MediaBrowserHelper mMediaBrowserHelper;

    final static int CODEC_OPUS = 2;
    final static int CODEC_VORBIS = 5;

    static boolean _isAndroidEncoderSupported [] = {
            true, // DEFAULT
            true, // AAC
            false, // OGG/OPUS
            false, // CAF/OPUS
            false, // MP3
            false, // OGG/VORBIS
            false, // WAV/PCM
    };

    static boolean _isAndroidDecoderSupported [] = {
            true, // DEFAULT
            true, // AAC
            true, // OGG/OPUS
            false, // CAF/OPUS
            true, // MP3
            true, // OGG/VORBIS
            true, // WAV/PCM
    };

    static int codecArray[] = {
            0 // DEFAULT
            , MediaRecorder.AudioEncoder.AAC
            , sdkCompat.AUDIO_ENCODER_OPUS
            , 0 // CODEC_CAF_OPUS (specific Apple)
            , 0 // CODEC_MP3 (not implemented)
            , sdkCompat.AUDIO_ENCODER_VORBIS
            , 0 // CODEC_PCM (not implemented)
    };

    static int formatsArray[] = {
            MediaRecorder.OutputFormat.MPEG_4 // DEFAULT
            , MediaRecorder.OutputFormat.MPEG_4 // CODEC_AAC
            , sdkCompat.OUTPUT_FORMAT_OGG       // CODEC_OPUS
            , 0                                 // CODEC_CAF_OPUS (this is apple specific)
            , 0                                 // CODEC_MP3
            , sdkCompat.OUTPUT_FORMAT_OGG       // CODEC_VORBIS
            , 0                                 // CODEC_PCM
    };

    static String pathArray[] = {
            "sound.acc"   // DEFAULT
            , "sound.acc"   // CODEC_AAC
            , "sound.opus"  // CODEC_OPUS
            , "sound.caf"   // CODEC_CAF_OPUS (this is apple specific)
            , "sound.mp3"   // CODEC_MP3
            , "sound.ogg"   // CODEC_VORBIS
            , "sound.wav"   // CODEC_PCM
    };

    String extentionArray[] = {
            "acc"   // DEFAULT
            , "acc"   // CODEC_AAC
            , "opus"  // CODEC_OPUS
            , "caf"   // CODEC_CAF_OPUS (this is apple specific)
            , "mp3"   // CODEC_MP3
            , "ogg"   // CODEC_VORBIS
            , "wav"   // CODEC_PCM
    };

    String finalPath;


    private FlutterSoundPlugin(Registrar registrar){
        channel = new MethodChannel(registrar.messenger(), "flutter_sound");
        channel.setMethodCallHandler(this);
        reg = registrar;
    }

    /** Plugin registration. */
    public static void registerWith(Registrar registrar) {
        FlutterSoundPlugin plugin = new FlutterSoundPlugin(registrar);
    }

    @Override
    public void onMethodCall(final MethodCall call, final Result result) {
        final String path = call.argument("path");
        switch (call.method) {
            case "isDecoderSupported": {
                int _codec = call.argument("codec");
                boolean b = _isAndroidDecoderSupported[_codec];
                if (Build.VERSION.SDK_INT < 23) {
                    if ( (_codec == CODEC_OPUS) || (_codec == CODEC_VORBIS) )
                        b = false;
                }

                result.success(b);
            }
            break;
            case "isEncoderSupported": {
                int _codec = call.argument("codec");
                boolean b = _isAndroidEncoderSupported[_codec];
                if (Build.VERSION.SDK_INT < 29) {
                    if ((_codec == CODEC_OPUS) || (_codec == CODEC_VORBIS))
                        b = false;
                }
                result.success(b);
            }
            break;
            case "startRecorder":
                taskScheduler.submit(() -> {
                    Integer sampleRate = call.argument("sampleRate");
                    Integer numChannels = call.argument("numChannels");
                    Integer bitRate = call.argument("bitRate");
                    int androidEncoder = call.argument("androidEncoder");
                    int _codec = call.argument("codec");
                    t_CODEC codec = t_CODEC.values()[_codec];
                    int androidAudioSource = call.argument("androidAudioSource");
                    int androidOutputFormat = call.argument("androidOutputFormat");
                    startRecorder(numChannels, sampleRate, bitRate, codec, androidEncoder, androidAudioSource, androidOutputFormat, path, result);
                });
                break;
            case "stopRecorder":
                taskScheduler.submit(() -> stopRecorder(result));
                break;
            case "startPlayer":
                final HashMap<String, Object> trackMap = call.argument("track");
                final Track track = new Track(trackMap);

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
                boolean includeAudioPlayerFeatures = call.argument("includeAudioPlayerFeatures");

                this.initializeMediaPlayer(includeAudioPlayerFeatures, result);
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
    public void startRecorder(Integer numChannels, Integer sampleRate, Integer bitRate, t_CODEC codec, int androidEncoder, int androidAudioSource, int androidOutputFormat, String path, final Result result) {
        final int v = Build.VERSION.SDK_INT;

        if (sdkCompat.checkRecordPermission(reg) != PackageManager.PERMISSION_GRANTED) {
            result.error(TAG, "NO PERMISSION GRANTED", Manifest.permission.RECORD_AUDIO + " or " + Manifest.permission.WRITE_EXTERNAL_STORAGE);
            return;
        }

        // The caller must be allowed to specify its path. We must not change it here
        // path = PathUtils.getDataDirectory(reg.context()) + "/" + path; // SDK 29 : you may not write in getExternalStorageDirectory() [LARPOUX]
        MediaRecorder mediaRecorder = model.getMediaRecorder();

        if (mediaRecorder == null) {
            model.setMediaRecorder(new MediaRecorder());
            mediaRecorder = model.getMediaRecorder();
        } else {
            mediaRecorder.reset();
        }
        mediaRecorder.setAudioSource(androidAudioSource);
        if (codecArray[codec.ordinal()] == 0) {
            result.error(TAG, "UNSUPPORTED", "Unsupported encoder");
            return;
        }
        androidEncoder = codecArray[codec.ordinal()];
        androidOutputFormat = formatsArray[codec.ordinal()];
        mediaRecorder.setOutputFormat(androidOutputFormat);

        if (path == null)
            path = pathArray[codec.ordinal()];

        mediaRecorder.setOutputFile(path);
        mediaRecorder.setAudioEncoder(androidEncoder);

        if (numChannels != null) {
            mediaRecorder.setAudioChannels(numChannels);
        }

        if (sampleRate != null) {
            mediaRecorder.setAudioSamplingRate(sampleRate);
        }

        // If bitrate is defined, then use it, otherwise use the OS default
        if (bitRate != null) {
            mediaRecorder.setAudioEncodingBitRate(bitRate);
        }


        try {
            mediaRecorder.prepare();
            mediaRecorder.start();

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
    public void initializeMediaPlayer(boolean includeAudioPlayerFeatures, final Result result) {
        // Initialize the media browser if it hasn't already been initialized
        if (mMediaBrowserHelper == null) {
            // If the initialization will be successful, result.success will
            // be called, otherwise result.error will be called.
            mMediaBrowserHelper = new MediaBrowserHelper(
                    reg.activity(),
                    includeAudioPlayerFeatures,
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
        if (mMediaBrowserHelper == null) {
            result.error(TAG, "The player cannot be released because it is not initialized.", null);
            return;
        }

        // Release the media browser
        mMediaBrowserHelper.releaseMediaBrowser();
        mMediaBrowserHelper = null;
        result.success("The player has been successfully released");
    }

    private boolean wasMediaPlayerInitialized(final Result result) {
        if (mMediaBrowserHelper == null) {
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
//        PlaybackStateCompat playbackState = mMediaBrowserHelper.mediaControllerCompat.getPlaybackState();
//        if (playbackState != null && playbackState.getState() == PlaybackStateCompat.STATE_PAUSED) {
//            // The player was paused, then resume it
//            mMediaBrowserHelper.playPlayback();
//            result.success("player resumed");
//            return;
//        }

        // Check whether the audio file is stored by a string or a buffer
        String path;
        if(track.isUsingPath()) {
            // The audio file is stored by a String, then get the path to the file audio to play
            path = track.getPath();
        } else {
            // The audio file is stored by a buffer, then save it as a file and get the path
            // to that file.
            try {
                File f = File.createTempFile("flutter_sound",
                        extentionArray[track.getBufferCodecIndex()]);
                FileOutputStream fos = new FileOutputStream(f);
                fos.write(track.getDataBuffer());
                path = f.getAbsolutePath();
            } catch (Exception e) {
                result.error(ERR_UNKNOWN, ERR_UNKNOWN, e.getMessage());
                return;
            }
        }

        mTimer = new Timer();

        // Add or remove the handlers for when the user tries to skip the current track
        if (canSkipForward) {
            mMediaBrowserHelper.setSkipTrackForwardHandler(new SkipTrackHandler(true));
        } else {
            mMediaBrowserHelper.removeSkipTrackForwardHandler();
        }
        if (canSkipBackward) {
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
        // This remove all pending runnables
        recordHandler.removeCallbacksAndMessages(null);
        dbPeakLevelHandler.removeCallbacksAndMessages(null);
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
            mMediaBrowserHelper.playPlayback();

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

                        if (playbackState == null) return;

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
            if (mIsSuccessfulCallback) {
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
            if (mIsSkippingForward) {
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