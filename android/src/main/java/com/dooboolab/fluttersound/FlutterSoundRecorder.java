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
import android.media.MediaRecorder;
import android.os.Build;
import android.os.Environment;
import android.os.Handler;
import android.os.SystemClock;
import android.util.Log;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;


class FlautoRecorderPlugin  extends AudioSessionManager
	implements MethodCallHandler
{

	static Context              androidContext;
	static FlautoRecorderPlugin flautoRecorderPlugin; // singleton


	static final String ERR_UNKNOWN               = "ERR_UNKNOWN";
	static final String ERR_RECORDER_IS_NULL      = "ERR_RECORDER_IS_NULL";
	static final String ERR_RECORDER_IS_RECORDING = "ERR_RECORDER_IS_RECORDING";


	public static void attachFlautoRecorder ( Context ctx, BinaryMessenger messenger )
	{
		assert ( flautoRecorderPlugin == null );
		flautoRecorderPlugin = new FlautoRecorderPlugin ();
		MethodChannel channel = new MethodChannel ( messenger, "com.dooboolab.flutter_sound_recorder" );
		flautoRecorderPlugin.init( channel);
		channel.setMethodCallHandler ( flautoRecorderPlugin );
		androidContext = ctx;
	}



	FlautoRecorderPlugin getManager ()
	{
		return flautoRecorderPlugin;
	}


	@Override
	public void onMethodCall ( final MethodCall call, final Result result )
	{

		FlutterSoundRecorder aRecorder = (FlutterSoundRecorder) getSession( call);
		switch ( call.method )
		{
			case "initializeFlautoRecorder":
			{
				aRecorder = new FlutterSoundRecorder (  );
				initSession( call, aRecorder );
				aRecorder.initializeFlautoRecorder ( call, result );
			}
			break;

			case "releaseFlautoRecorder":
			{
				aRecorder.releaseFlautoRecorder ( call, result );
			}
			break;

			case "isEncoderSupported":
			{
				aRecorder.isEncoderSupported ( call, result );
			}
			break;

			case "setAudioFocus":
			{
				aRecorder.setAudioFocus( call, result );
			}
			break;

			case "startRecorder":
			{
				aRecorder.startRecorder ( call, result );
			}
			break;

			case "stopRecorder":
			{
				aRecorder.stopRecorder ( call, result );
			}
			break;


			case "setSubscriptionDuration":
			{
				aRecorder.setSubscriptionDuration ( call, result );
			}
			break;

			case "pauseRecorder":
			{
				aRecorder.pauseRecorder ( call, result );
			}
			break;


			case "resumeRecorder":
			{
				aRecorder.resumeRecorder ( call, result );
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



class RecorderAudioModel
{
	final public static String  DEFAULT_FILE_LOCATION = Environment.getDataDirectory ().getPath () + "/default.aac"; // SDK
	public              int     subsDurationMillis    = 10;

	private      Runnable      recorderTicker;
	private      long          recordTime   = 0;
	public final double        micLevelBase = 2700;


	//public MediaRecorder getMediaRecorder ()
	//{
		//return mediaRecorder;
	//}

	//public void setMediaRecorder ( MediaRecorder mediaRecorder )
	//{
		//this.mediaRecorder = mediaRecorder;
	//}

	public Runnable getRecorderTicker ()
	{
		return recorderTicker;
	}

	public void setRecorderTicker ( Runnable recorderTicker )
	{
		this.recorderTicker = recorderTicker;
	}


	public long getRecordTime ()
	{
		return recordTime;
	}

	public void setRecordTime ( long recordTime )
	{
		this.recordTime = recordTime;
	}

}
//-----------------------------------------------------------------------------------------------------------------------------------------------

public class FlutterSoundRecorder extends Session
{
	static boolean _isAndroidEncoderSupported[] = {
		true, // DEFAULT
		true, // aacADTS
		false, // opusOGG
		false, // opusCAF
		false, // MP3
		false, // vorbisOGG
		true, // pcm16
		true, // pcm16WAV
		false, // pcm16AIFF
		false, // pcm16CAF
		false, // flac
		false, // aacMP4
		true,  // amrNB
		true   // amrWB
	};

	final static int CODEC_OPUS   = 2;
	final static int CODEC_VORBIS = 5;
	static final String ERR_UNKNOWN           = "ERR_UNKNOWN";


	static final String ERR_RECORDER_IS_NULL      = "ERR_RECORDER_IS_NULL";
	static final String ERR_RECORDER_IS_RECORDING = "ERR_RECORDER_IS_RECORDING";


	final static String             TAG                = "FlutterSoundRecorder";
	final        RecorderAudioModel model              = new RecorderAudioModel ();
	RecorderInterface recorder;
	final public Handler            recordHandler      = new Handler ();
	//String finalPath;
	private final ExecutorService taskScheduler = Executors.newSingleThreadExecutor ();
	long mPauseTime = 0;
	long mStartPauseTime = -1;

	FlutterSoundRecorder (  )
	{
	}


	FlautoRecorderPlugin getPlugin ()
	{
		return FlautoRecorderPlugin.flautoRecorderPlugin;
	}




	void initializeFlautoRecorder ( final MethodCall call, final Result result )
	{
		boolean r = prepareFocus(call);
		if (r)
			result.success ( r);
		else
			result.error ( ERR_UNKNOWN, ERR_UNKNOWN, "Failure to open session");

	}

	void releaseFlautoRecorder ( final MethodCall call, final Result result )
	{
		if (hasFocus)
			abandonFocus();
		releaseSession();
		result.success ( "Flauto Recorder Released" );
	}



	void isEncoderSupported ( final MethodCall call, final Result result )
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

	void invokeMethodWithString ( String methodName, String arg )
	{
		Map<String, Object> dic = new HashMap<String, Object> ();
		dic.put ( "slotNo", slotNo );
		dic.put ( "arg", arg );
		getPlugin ().invokeMethod ( methodName, dic );
	}

	void invokeMethodWithDouble ( String methodName, double arg )
	{
		Map<String, Object> dic = new HashMap<String, Object> ();
		dic.put ( "slotNo", slotNo );
		dic.put ( "arg", arg );
		getPlugin ().invokeMethod ( methodName, dic );
	}

	static boolean _isAudioRecorder[] = {
		false, // DEFAULT
		false, // aacADTS
		false, // opusOGG
		false, // opusCAF
		false , // MP3
		false, // vorbisOGG
		true, // pcm16
		true, // pcm16WAV
		false, // pcm16AIFF
		false, // pcm16CAF
		false, // flac
		false, // aacMP4
		false, // amrNB
		false, // amrWB
	};

	enum AudioSource {
		defaultSource,
		microphone,
		voiceDownlink, // (if someone can explain me what it is, I will be grateful ;-) )
		camCorder,
		remote_submix,
		unprocessed,
		voice_call,
		voice_communication,
		voice_performance,
		voice_recognition,
		voiceUpLink,
		bluetoothHFP,
		headsetMic,
		lineIn
	}

	int[] tabAudioSource =
		{
			MediaRecorder.AudioSource.DEFAULT,
			MediaRecorder.AudioSource.MIC,
			MediaRecorder.AudioSource.VOICE_DOWNLINK,
			MediaRecorder.AudioSource.CAMCORDER,
			MediaRecorder.AudioSource.REMOTE_SUBMIX,
			MediaRecorder.AudioSource.UNPROCESSED,
			MediaRecorder.AudioSource.VOICE_CALL,
			MediaRecorder.AudioSource.VOICE_COMMUNICATION,
			10, //MediaRecorder.AudioSource.VOICE_PERFORMANCE,,
			MediaRecorder.AudioSource.VOICE_RECOGNITION,
			MediaRecorder.AudioSource.VOICE_UPLINK,
			MediaRecorder.AudioSource.DEFAULT, // bluetoothHFP,
			MediaRecorder.AudioSource.DEFAULT, // headsetMic,
			MediaRecorder.AudioSource.DEFAULT, // lineIn

		};

	public void startRecorder ( final MethodCall call, final Result result )
	{
		//taskScheduler.submit ( () ->
		{
			Integer                         sampleRate          = call.argument ( "sampleRate" );
			Integer                         numChannels         = call.argument ( "numChannels" );
			Integer                         bitRate             = call.argument ( "bitRate" );
			int                             _codec              = call.argument ( "codec" );
			FlutterSoundCodec               codec               = FlutterSoundCodec.values()[ _codec ];
			final String                     path               = call.argument ( "path" );
			int                             _audioSource        = call.argument ( "audioSource" );
			int                             audioSource         = tabAudioSource[_audioSource];
			mPauseTime = 0;
			mStartPauseTime = -1;
			if (recorder != null)
			{
				recorder._stopRecorder (  );
			}
			if (_isAudioRecorder[codec.ordinal()])
			{
				recorder = new FlutterSoundAudioRecorder();
			} else
			{
				recorder = new FlutterSoundMediaRecorder();
			}
			try
			{
				recorder._startRecorder( numChannels, sampleRate, bitRate, codec, path, audioSource );
			} catch ( Exception e )
			{
				result.error( TAG, "Error starting recorder", e.getMessage() );
				return;
			}
			// Remove all pending runnables, this is just for safety (should never happen)
			recordHandler.removeCallbacksAndMessages ( null );
			final long systemTime = SystemClock.elapsedRealtime();
			this.model.setRecorderTicker ( () ->
			                               {

				                               long time = SystemClock.elapsedRealtime () - systemTime - mPauseTime;
				                               // Log.d(TAG, "elapsedTime: " + SystemClock.elapsedRealtime());
				                               // Log.d(TAG, "time: " + time);

				                               // DateFormat format = new SimpleDateFormat("mm:ss:SS", Locale.US);
				                               // String displayTime = format.format(time);
				                               // model.setRecordTime(time);
				                               try
				                               {
					                               double db = 0.0;
					                               if ( recorder != null )
					                               {
						                               double maxAmplitude = recorder.getMaxAmplitude ();

						                               // Calculate db based on the following article.
						                               // https://stackoverflow.com/questions/10655703/what-does-androids-getmaxamplitude-function-for-the-mediarecorder-actually-gi
						                               //
						                               double ref_pressure = 51805.5336;
						                               double p            = maxAmplitude / ref_pressure;
						                               double p0           = 0.0002;

						                               db = 20.0 * Math.log10 ( p / p0 );

						                               // if the microphone is off we get 0 for the amplitude which causes
						                               // db to be infinite.
						                               if ( Double.isInfinite ( db ) )
						                               {
							                               db = 0.0;
						                               }

					                               }



					                               Map<String, Object> dic = new HashMap<String, Object> ();
					                               dic.put ( "slotNo", slotNo );
					                               dic.put ( "duration", time );
					                               dic.put ( "dbPeakLevel", db );
					                               invokeMethodWithMap ( "updateRecorderProgress", dic );
					                               recordHandler.postDelayed ( model.getRecorderTicker (), model.subsDurationMillis );
				                               }
				                               catch (Exception e )
				                               {
					                               Log.d( TAG, " Exception: " + e.toString() );
				                               }
			                               } );
			recordHandler.post ( this.model.getRecorderTicker () );

			//finalPath = path;
			result.success ( "Media Recorder is started" );

		}
		//);

	}

	public void stopRecorder ( final MethodCall call, final Result result )
	{
		recordHandler.removeCallbacksAndMessages ( null );
		recorder._stopRecorder (  );
		recorder = null;
		result.success ( "Media Recorder is closed" );
	}

	public void pauseRecorder( final MethodCall call, final MethodChannel.Result result )
	{
		recordHandler.removeCallbacksAndMessages ( null );
		recorder.pauseRecorder( );
		mStartPauseTime = SystemClock.elapsedRealtime ();
		result.success( "Recorder is paused");
		//return true;
	}

	public void resumeRecorder( final MethodCall call, final MethodChannel.Result result )
	{
		recordHandler.post ( this.model.getRecorderTicker () );
		recorder.resumeRecorder();
		if (mStartPauseTime >= 0)
			mPauseTime += SystemClock.elapsedRealtime () - mStartPauseTime;
		mStartPauseTime = -1;
		result.success( "Recorder is resumed");

	}

public void setSubscriptionDuration ( final MethodCall call, final Result result )
	{
		if ( call.argument ( "duration" ) == null )
		{
			return;
		}
		int duration = call.argument ( "duration" );
		//double intervalInSecs = call.argument ( "intervalInSecs" );

		this.model.subsDurationMillis = duration;
		result.success ( "setSubscriptionDuration: " + this.model.subsDurationMillis );
	}


}
