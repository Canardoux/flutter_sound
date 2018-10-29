package com.dooboolab.fluttersound;

import android.Manifest;
import android.content.pm.PackageManager;
import android.media.MediaPlayer;
import android.media.MediaRecorder;
import android.os.Build;
import android.os.Handler;
import android.os.SystemClock;
import android.util.Log;

import org.json.JSONException;
import org.json.JSONObject;

import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Locale;
import java.util.Timer;
import java.util.TimerTask;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** FlutterSoundPlugin */
public class FlutterSoundPlugin implements MethodCallHandler, PluginRegistry.RequestPermissionsResultListener, AudioInterface{ ;
  final static String TAG = "FlutterSoundPlugin";
  final static String RECORD_STREAM = "com.dooboolab.fluttersound/record";
  final static String PLAY_STREAM= "com.dooboolab.fluttersound/play";

  private static final String ERR_UNKNOWN = "ERR_UNKNOWN";
  private static final String ERR_PLAYER_IS_NULL = "ERR_PLAYER_IS_NULL";
  private static final String ERR_PLAYER_IS_PLAYING = "ERR_PLAYER_IS_PLAYING";
  private static final String ERR_RECORDER_IS_NULL = "ERR_RECORDER_IS_NULL";
  private static final String ERR_RECORDER_IS_RECORDING = "ERR_RECORDER_IS_RECORDING";


  private static Registrar reg;
  final private AudioModel model = new AudioModel();
  private Timer mTimer = new Timer();
  final private Handler recordHandler = new Handler();
  private static MethodChannel channel;

  /** Plugin registration. */
  public static void registerWith(Registrar registrar) {
    channel = new MethodChannel(registrar.messenger(), "flutter_sound");
    channel.setMethodCallHandler(new FlutterSoundPlugin());
    reg = registrar;
  }

  @Override
  public void onMethodCall(MethodCall call, Result result) {
    String path = call.argument("path");
    switch (call.method) {
      case "getPlatformVersion":
        result.success("Android " + android.os.Build.VERSION.RELEASE);
        break;
      case "startRecorder":
        this.startRecorder(path, result);
        break;
      case "stopRecorder":
        this.stopRecorder(result);
        break;
      case "startPlayer":
        this.startPlayer(path, result);
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
      case "seekPlayer":
        int sec = call.argument("sec");
        this.seekToPlayer(sec, result);
        break;
      case "setVolume":
        double volume = call.argument("volume");
        this.setVolume(volume, result);
        break;
      case "setSubscriptionDuration":
        if (call.argument("sec") == null) return;
        double duration = call.argument("sec");
        this.setSubscriptionDuration(duration, result);
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
  public void startRecorder(String path, final Result result) {
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

    Log.d(TAG, "startRecorder");

    if (path == null) {
      path = AudioModel.DEFAULT_FILE_LOCATION;
    }

    if (this.model.getMediaRecorder() == null) {
      this.model.setMediaRecorder(new MediaRecorder());
      this.model.getMediaRecorder().setAudioSource(MediaRecorder.AudioSource.MIC);
      this.model.getMediaRecorder().setOutputFormat(MediaRecorder.OutputFormat.MPEG_4);
      this.model.getMediaRecorder().setAudioEncoder(MediaRecorder.AudioEncoder.DEFAULT);
      this.model.getMediaRecorder().setOutputFile(path);
    }

    try {
      this.model.getMediaRecorder().prepare();
      this.model.getMediaRecorder().start();

      final long systemTime = SystemClock.elapsedRealtime();
      this.model.setRecorderTicker(new Runnable() {
        @Override
        public void run() {

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
        }
      });
      this.model.getRecorderTicker().run();
      result.success(path);
    } catch (Exception e) {
      Log.e(TAG, "Exception: ", e);
    }
  }

  @Override
  public void stopRecorder(final Result result) {
    recordHandler.removeCallbacks(this.model.getRecorderTicker());
    if (this.model.getMediaRecorder() == null) {
      Log.d(TAG, "mediaRecorder is null");
      result.error(ERR_RECORDER_IS_NULL, ERR_RECORDER_IS_NULL, ERR_RECORDER_IS_NULL);
      return;
    }
    this.model.getMediaRecorder().stop();
    this.model.getMediaRecorder().release();
    this.model.setMediaRecorder(null);
    result.success("recorder stopped.");
  }

  @Override
  public void startPlayer(final String path, final Result result) {
    if (this.model.getMediaPlayer() != null) {
      Boolean isPaused = !this.model.getMediaPlayer().isPlaying()
          && this.model.getMediaPlayer().getCurrentPosition() > 1;

      if (isPaused) {
        this.model.getMediaPlayer().start();
        result.success("player resumed.");
        return;
      }

      Log.e(TAG, "Player is already running. Stop it first.");
      result.success("player is already running.");
      return;
    } else {
      this.model.setMediaPlayer(new MediaPlayer());
    }
    mTimer = new Timer();

    try {
      if (path == null) {
        this.model.getMediaPlayer().setDataSource(AudioModel.DEFAULT_FILE_LOCATION);
      } else {
        this.model.getMediaPlayer().setDataSource(path);
      }

      this.model.getMediaPlayer().setOnPreparedListener(new MediaPlayer.OnPreparedListener() {
        @Override
        public void onPrepared(final MediaPlayer mp) {
          Log.d(TAG, "mediaPlayer prepared and start");
          mp.start();

          /*
           * Set timer task to send event to RN.
           */
          TimerTask mTask = new TimerTask() {
            @Override
            public void run() {
              // long time = mp.getCurrentPosition();
              // DateFormat format = new SimpleDateFormat("mm:ss:SS", Locale.US);
              // final String displayTime = format.format(time);
              try {
                JSONObject json = new JSONObject();
                json.put("duration", String.valueOf(mp.getDuration()));
                json.put("current_position", String.valueOf(mp.getCurrentPosition()));
                channel.invokeMethod("updateProgress", json.toString());
              } catch (JSONException je) {
                Log.d(TAG, "Json Exception: " + je.toString());
              }
            }
          };

          mTimer.schedule(mTask, 0, model.subsDurationMillis);
          String resolvedPath = path == null ? AudioModel.DEFAULT_FILE_LOCATION : path;
          result.success((resolvedPath));
        }
      });
      /*
       * Detect when finish playing.
       */
      this.model.getMediaPlayer().setOnCompletionListener(new MediaPlayer.OnCompletionListener() {
        @Override
        public void onCompletion(MediaPlayer mp) {
          /*
           * Reset player.
           */
          Log.d(TAG, "Plays completed.");
          try {
            JSONObject json = new JSONObject();
            json.put("duration", String.valueOf(mp.getDuration()));
            json.put("current_position", String.valueOf(mp.getCurrentPosition()));
            channel.invokeMethod("audioPlayerDidFinishPlaying", json.toString());
          } catch (JSONException je) {
            Log.d(TAG, "Json Exception: " + je.toString());
          }
          mTimer.cancel();
          mp.stop();
          mp.release();
          model.setMediaPlayer(null);
        }
      });
      this.model.getMediaPlayer().prepare();
    } catch (Exception e) {
      Log.e(TAG, "startPlayer() exception");
      result.error(ERR_UNKNOWN, ERR_UNKNOWN, e.getMessage());
    }
  }

  @Override
  public void stopPlayer(final Result result) {
    mTimer.cancel();

    if (this.model.getMediaPlayer() == null) {
      result.error(ERR_PLAYER_IS_NULL, ERR_PLAYER_IS_NULL, ERR_PLAYER_IS_NULL);
      return;
    }

    try {
      this.model.getMediaPlayer().stop();
      this.model.getMediaPlayer().release();
      this.model.setMediaPlayer(null);
      result.success("stopped player.");
    } catch (Exception e) {
      Log.e(TAG, "stopPlay exception: " + e.getMessage());
      result.error(ERR_UNKNOWN, ERR_UNKNOWN, e.getMessage());
    }
  }

  @Override
  public void pausePlayer(final Result result) {
    if (this.model.getMediaPlayer() == null) {
      result.error(ERR_PLAYER_IS_NULL, ERR_PLAYER_IS_NULL, ERR_PLAYER_IS_NULL);
      return;
    }

    try {
      this.model.getMediaPlayer().pause();
      result.success("paused player.");
    } catch (Exception e) {
      Log.e(TAG, "pausePlay exception: " + e.getMessage());
      result.error(ERR_UNKNOWN, ERR_UNKNOWN, e.getMessage());
    }
  }

  @Override
  public void resumePlayer(final Result result) {
    if (this.model.getMediaPlayer() == null) {
      result.error(ERR_PLAYER_IS_NULL, ERR_PLAYER_IS_NULL, ERR_PLAYER_IS_NULL);
      return;
    }

    if (this.model.getMediaPlayer().isPlaying()) {
      result.error(ERR_PLAYER_IS_PLAYING, ERR_PLAYER_IS_PLAYING, ERR_PLAYER_IS_PLAYING);
      return;
    }

    try {
      this.model.getMediaPlayer().seekTo(this.model.getMediaPlayer().getCurrentPosition());
      this.model.getMediaPlayer().start();
      result.success("resumed player.");
    } catch (Exception e) {
      Log.e(TAG, "mediaPlayer resume: " + e.getMessage());
      result.error(ERR_UNKNOWN, ERR_UNKNOWN, e.getMessage());
    }
  }

  @Override
  public void seekToPlayer(int sec, final Result result) {
    if (this.model.getMediaPlayer() == null) {
      result.error(ERR_PLAYER_IS_NULL, ERR_PLAYER_IS_NULL, ERR_PLAYER_IS_NULL);
      return;
    }

    int currentMillis = this.model.getMediaPlayer().getCurrentPosition();
    int millis = sec * 1000 + currentMillis;

    Log.d(TAG, "seekTo: " + millis);

    this.model.getMediaPlayer().seekTo(millis);
    result.success(String.valueOf(millis));
  }

  @Override
  public void setVolume(double volume, final Result result) {
    if (this.model.getMediaPlayer() == null) {
      result.error(ERR_PLAYER_IS_NULL, ERR_PLAYER_IS_NULL, ERR_PLAYER_IS_NULL);
      return;
    }

    float mVolume = (float) volume;
    this.model.getMediaPlayer().setVolume(mVolume, mVolume);
    result.success("Set volume");
  }

  @Override
  public void setSubscriptionDuration(double sec, Result result) {
    this.model.subsDurationMillis = (int) (sec * 1000);
    result.success("setSubscriptionDuration: " + this.model.subsDurationMillis);
  }
}
