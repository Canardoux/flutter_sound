package xyz.canardoux.flauto;
/*
 * This file is part of Flauto.
 *
 *   Flauto is free software: you can redistribute it and/or modify
 *   it under the terms of the Lesser GNU General Public License
 *   version 3 (LGPL3) as published by the Free Software Foundation.
 *
 *   Flauto is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the Lesser GNU General Public License
 *   along with Flauto.  If not, see <https://www.gnu.org/licenses/>.
 */


import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;
import android.media.MediaPlayer;
import android.media.MediaRecorder;
import android.media.AudioManager;
import android.os.Build;
import android.os.Environment;
import android.os.Handler;
import android.os.SystemClock;
import android.support.v4.media.MediaMetadataCompat;
import android.support.v4.media.session.PlaybackStateCompat;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.arch.core.util.Function;
import androidx.core.app.ActivityCompat;

import android.media.AudioFocusRequest;

import java.io.*;

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

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import java.util.concurrent.Callable;

import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;


class FlautoRecorderPlugin
	implements MethodCallHandler
{
	public static MethodChannel        channel;
	static        Context              androidContext;
	static        FlautoRecorderPlugin flautoRecorderPlugin; // singleton
	FlautoRecorder theFlautoRecorder; // Temporary !!!!!!!!!!!
	static boolean _isAndroidEncoderSupported[] = {
		true, // DEFAULT
		true, // AAC
		false, // OGG/OPUS
		false, // CAF/OPUS
		false, // MP3
		false, // OGG/VORBIS
		false, // WAV/PCM
	};

	final static int CODEC_OPUS   = 2;
	final static int CODEC_VORBIS = 5;

	static final String ERR_UNKNOWN               = "ERR_UNKNOWN";
	static final String ERR_RECORDER_IS_NULL      = "ERR_RECORDER_IS_NULL";
	static final String ERR_RECORDER_IS_RECORDING = "ERR_RECORDER_IS_RECORDING";



	public static void attachFlautoRecorder (
		Context ctx,
		BinaryMessenger messenger
	                                        )
	{
		flautoRecorderPlugin = new FlautoRecorderPlugin ();
		channel              = new MethodChannel ( messenger, "xyz.canardoux.flauto_recorder" );
		channel.setMethodCallHandler ( flautoRecorderPlugin );
		androidContext = ctx;

	}


	@Override
	public void onMethodCall (
		final MethodCall call,
		final Result result
	                         )
	{
		//final String path = call.argument ( "path" );
		switch ( call.method )
		{

			case "initializeFlautoRecorder":
				theFlautoRecorder = new FlautoRecorder ();
				theFlautoRecorder.initializeFlautoRecorder ( call, result );
				result.success ( true );
				break;

			case "releaseFlautoRecorder":
				theFlautoRecorder.releaseFlautoRecorder ( call, result );
				result.success ( true );
				break;

			case "isEncoderSupported":
			{
				int     _codec = call.argument ( "codec" );
				boolean b      = _isAndroidEncoderSupported[ _codec ];
				if ( Build.VERSION.SDK_INT < 29 )
				{
					if ( ( _codec == CODEC_OPUS ) || ( _codec == CODEC_VORBIS ) )
					{
						b = false;
					}
				}
				result.success ( b );
			}
			break;
			case "startRecorder":
			{
				theFlautoRecorder.startRecorder(call, result);
			}
			break;

			case "stopRecorder":
			{
				theFlautoRecorder.stopRecorder ( result );
			}
			break;


			case "setDbPeakLevelUpdate":
			{
				double intervalInSecs = call.argument ( "intervalInSecs" );
				theFlautoRecorder.setDbPeakLevelUpdate ( intervalInSecs, result );
			}
			break;

			case "setDbLevelEnabled":
			{
				boolean enabled = call.argument ( "enabled" );
				theFlautoRecorder.setDbLevelEnabled ( enabled, result );
			}
			break;

			case "setSubscriptionDuration":
			{
				if ( call.argument ( "sec" ) == null )
				{
					return;
				}
				double duration = call.argument ( "sec" );
				theFlautoRecorder.setSubscriptionDuration ( duration, result );
			}
			break;


			default:
			{
				result.notImplemented ();
			}
			break;
		}
	}

}


class RecorderAudioModel {
	final public static String DEFAULT_FILE_LOCATION = Environment.getDataDirectory ().getPath () + "/default.aac"; // SDK
	public int subsDurationMillis = 10;
	public long peakLevelUpdateMillis = 800;
	public boolean shouldProcessDbLevel = true;

	private MediaRecorder mediaRecorder;
	private Runnable recorderTicker;
	private Runnable dbLevelTicker;
	private long recordTime = 0;
	public final double micLevelBase = 2700;


	public MediaRecorder getMediaRecorder() {
		return mediaRecorder;
	}

	public void setMediaRecorder(MediaRecorder mediaRecorder) {
		this.mediaRecorder = mediaRecorder;
	}

	public Runnable getRecorderTicker() {
		return recorderTicker;
	}

	public void setRecorderTicker(Runnable recorderTicker) {
		this.recorderTicker = recorderTicker;
	}

	public Runnable getDbLevelTicker() {
		return dbLevelTicker;
	}

	public void setDbLevelTicker(Runnable ticker) {
		this.dbLevelTicker = ticker;
	}

	public long getRecordTime() {
		return recordTime;
	}

	public void setRecordTime(long recordTime) {
		this.recordTime = recordTime;
	}

}
//-----------------------------------------------------------------------------------------------------------------------------------------------

public class FlautoRecorder
{

	static int codecArray[] = {
		0 // DEFAULT
		, MediaRecorder.AudioEncoder.AAC, sdkCompat.AUDIO_ENCODER_OPUS, 0, // CODEC_CAF_OPUS (specific Apple)
		0,// CODEC_MP3 (not implemented)
		sdkCompat.AUDIO_ENCODER_VORBIS, 0 // CODEC_PCM (not implemented)
	};


	static int formatsArray[] = {
		MediaRecorder.OutputFormat.AAC_ADTS // DEFAULT
		, MediaRecorder.OutputFormat.AAC_ADTS // CODEC_AAC
		, sdkCompat.OUTPUT_FORMAT_OGG // CODEC_OPUS
		, 0 // CODEC_CAF_OPUS (this is apple specific)
		, 0 // CODEC_MP3
		, sdkCompat.OUTPUT_FORMAT_OGG // CODEC_VORBIS
		, 0 // CODEC_PCM
	};

	static String pathArray[] = {
		"sound.aac" // DEFAULT
		, "sound.aac" // CODEC_AAC
		, "sound.opus" // CODEC_OPUS
		, "sound.caf" // CODEC_CAF_OPUS (this is apple specific)
		, "sound.mp3" // CODEC_MP3
		, "sound.ogg" // CODEC_VORBIS
		, "sound.wav" // CODEC_PCM
	};
	static final String ERR_RECORDER_IS_NULL = "ERR_RECORDER_IS_NULL";
	static final String ERR_RECORDER_IS_RECORDING = "ERR_RECORDER_IS_RECORDING";


	final static String TAG           = "FlutterSoundPlugin";
	final         RecorderAudioModel model = new RecorderAudioModel ();
	final public Handler      recordHandler      = new Handler ();
	final public Handler      dbPeakLevelHandler = new Handler ();
	String finalPath;
	private final ExecutorService taskScheduler = Executors.newSingleThreadExecutor();




	void initializeFlautoRecorder (
		final MethodCall call,
		final Result result
	                              )
	{
	}

	void releaseFlautoRecorder (
		final MethodCall call,
		final Result result
	                           )
	{
	}

	MethodChannel getChannel ()
	{
		return FlautoRecorderPlugin.channel;
	}


public void startRecorder(	final MethodCall call,
                                  final Result result )
{
	//taskScheduler.submit ( () ->
	                       {
		                       Integer sampleRate          = call.argument ( "sampleRate" );
		                       Integer numChannels         = call.argument ( "numChannels" );
		                       Integer bitRate             = call.argument ( "bitRate" );
		                       int     androidEncoder      = call.argument ( "androidEncoder" );
		                       int     _codec              = call.argument ( "codec" );
		                       t_CODEC codec               = t_CODEC.values ()[ _codec ];
		                       int     androidAudioSource  = call.argument ( "androidAudioSource" );
		                       int     androidOutputFormat = call.argument ( "androidOutputFormat" );
		                       final String path = call.argument ( "path" );
		                       _startRecorder ( numChannels, sampleRate, bitRate, codec, androidEncoder, androidAudioSource, androidOutputFormat, path, result );
	                       }
	                     //);

}

	public void _startRecorder (
		Integer numChannels,
		Integer sampleRate,
		Integer bitRate,
		t_CODEC codec,
		int androidEncoder,
		int androidAudioSource,
		int androidOutputFormat,
		String path,
		final Result result
	                          )
	{
		final int v = Build.VERSION.SDK_INT;
		// The caller must be allowed to specify its path. We must not change it here
		// path = PathUtils.getDataDirectory(reg.context()) + "/" + path; // SDK 29 :
		// you may not write in getExternalStorageDirectory()
		MediaRecorder mediaRecorder = model.getMediaRecorder ();

		if ( mediaRecorder == null )
		{
			model.setMediaRecorder ( new MediaRecorder () );
			mediaRecorder = model.getMediaRecorder ();
		} else
		{
			mediaRecorder.reset ();
		}

		try
		{
			if ( codecArray[ codec.ordinal () ] == 0 )
			{
				result.error ( TAG, "UNSUPPORTED", "Unsupported encoder" );
				return;
			}
			mediaRecorder.setAudioSource ( androidAudioSource );
			androidEncoder      = codecArray[ codec.ordinal () ];
			androidOutputFormat = formatsArray[ codec.ordinal () ];
			mediaRecorder.setOutputFormat ( androidOutputFormat );

			if ( path == null )
			{
				path = pathArray[ codec.ordinal () ];
			}

			mediaRecorder.setOutputFile ( path );
			mediaRecorder.setAudioEncoder ( androidEncoder );

			if ( numChannels != null )
			{
				mediaRecorder.setAudioChannels ( numChannels );
			}

			if ( sampleRate != null )
			{
				mediaRecorder.setAudioSamplingRate ( sampleRate );
			}

			// If bitrate is defined, then use it, otherwise use the OS default
			if ( bitRate != null )
			{
				mediaRecorder.setAudioEncodingBitRate ( bitRate );
			}

			mediaRecorder.prepare ();
			mediaRecorder.start ();

			// Remove all pending runnables, this is just for safety (should never happen)
			recordHandler.removeCallbacksAndMessages ( null );
			final long systemTime = SystemClock.elapsedRealtime ();
			this.model.setRecorderTicker ( () ->
			                               {

				                               long time = SystemClock.elapsedRealtime () - systemTime;
				                               // Log.d(TAG, "elapsedTime: " + SystemClock.elapsedRealtime());
				                               // Log.d(TAG, "time: " + time);

				                               // DateFormat format = new SimpleDateFormat("mm:ss:SS", Locale.US);
				                               // String displayTime = format.format(time);
				                               // model.setRecordTime(time);
				                               try
				                               {
					                               JSONObject json = new JSONObject ();
					                               json.put ( "current_position", String.valueOf ( time ) );
					                               getChannel ().invokeMethod ( "updateRecorderProgress", json.toString () );
					                               recordHandler.postDelayed ( model.getRecorderTicker (), model.subsDurationMillis );
				                               }
				                               catch ( JSONException je )
				                               {
					                               Log.d ( TAG, "Json Exception: " + je.toString () );
				                               }
			                               } );
			recordHandler.post ( this.model.getRecorderTicker () );

			if ( this.model.shouldProcessDbLevel )
			{
				dbPeakLevelHandler.removeCallbacksAndMessages ( null );
				this.model.setDbLevelTicker ( () ->
				                              {

					                              MediaRecorder recorder = model.getMediaRecorder ();
					                              if ( recorder != null )
					                              {
						                              double maxAmplitude = recorder.getMaxAmplitude ();

						                              // Calculate db based on the following article.
						                              // https://stackoverflow.com/questions/10655703/what-does-androids-getmaxamplitude-function-for-the-mediarecorder-actually-gi
						                              //
						                              double ref_pressure = 51805.5336;
						                              double p            = maxAmplitude / ref_pressure;
						                              double p0           = 0.0002;

						                              double db = 20.0 * Math.log10 ( p / p0 );

						                              // if the microphone is off we get 0 for the amplitude which causes
						                              // db to be infinite.
						                              if ( Double.isInfinite ( db ) )
						                              {
							                              db = 0.0;
						                              }

						                              Log.d ( TAG, "rawAmplitude: " + maxAmplitude + " Base DB: " + db );

						                              getChannel ().invokeMethod ( "updateDbPeakProgress", db );
						                              dbPeakLevelHandler.postDelayed ( model.getDbLevelTicker (), ( model.peakLevelUpdateMillis ) );
					                              }
				                              } );
				dbPeakLevelHandler.post ( model.getDbLevelTicker () );
			}

			finalPath = path;
			//mainHandler.post ( new Runnable ()
			{
				//@Override
				//public void run ()
				{
					result.success ( finalPath );
				}
			}
			//);
		}
		catch ( Exception e )
		{
			Log.e ( TAG, "Exception: ", e );
		}
	}

	public void stopRecorder ( final Result result )
	{
		//taskScheduler.submit ( () -> _stopRecorder ( result ) );
		_stopRecorder ( result );
	}

	public void _stopRecorder ( final Result result )
	{
		// This remove all pending runnables
		recordHandler.removeCallbacksAndMessages ( null );
		dbPeakLevelHandler.removeCallbacksAndMessages ( null );

		if ( this.model.getMediaRecorder () == null )
		{
			Log.d ( TAG, "mediaRecorder is null" );
			result.error ( ERR_RECORDER_IS_NULL, ERR_RECORDER_IS_NULL, ERR_RECORDER_IS_NULL );
			return;
		}
		this.model.getMediaRecorder ().stop ();
		this.model.getMediaRecorder ().reset ();
		this.model.getMediaRecorder ().release ();
		this.model.setMediaRecorder ( null );
		//mainHandler.post ( new Runnable ()
		{
			//@Override
			//public void run ()
			{
				result.success ( finalPath );
			}
		}
		//);

	}


	public void setDbPeakLevelUpdate (
		double intervalInSecs,
		Result result
	                                 )
	{
		this.model.peakLevelUpdateMillis = ( long ) ( intervalInSecs * 1000 );
		result.success ( "setDbPeakLevelUpdate: " + this.model.peakLevelUpdateMillis );
	}

	public void setDbLevelEnabled (
		boolean enabled,
		MethodChannel.Result result
	                              )
	{
		this.model.shouldProcessDbLevel = enabled;
		result.success ( "setDbLevelEnabled: " + this.model.shouldProcessDbLevel );
	}

	public void setSubscriptionDuration (
		double sec,
		Result result
	                                    )
	{
		this.model.subsDurationMillis = ( int ) ( sec * 1000 );
		result.success ( "setSubscriptionDuration: " + this.model.subsDurationMillis );
	}


}
