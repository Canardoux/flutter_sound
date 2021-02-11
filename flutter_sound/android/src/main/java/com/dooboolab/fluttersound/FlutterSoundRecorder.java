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




import android.media.MediaRecorder;

import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.Result;

import com.dooboolab.TauEngine.FlautoRecorderCallback;
import com.dooboolab.TauEngine.FlautoRecorder;
import com.dooboolab.TauEngine.Flauto;
import com.dooboolab.TauEngine.Flauto.*;


public class FlutterSoundRecorder extends FlutterSoundSession implements FlautoRecorderCallback
{
	static final String ERR_UNKNOWN           = "ERR_UNKNOWN";
	static final String ERR_RECORDER_IS_NULL      = "ERR_RECORDER_IS_NULL";
	static final String ERR_RECORDER_IS_RECORDING = "ERR_RECORDER_IS_RECORDING";
	final static String             TAG                = "FlutterSoundRecorder";
	FlautoRecorder m_recorder;

// =============================================================  callback ===============================================================


	public void openRecorderCompleted(boolean success)
	{
		invokeMethodWithBoolean( "openRecorderCompleted", success, success );
	}
	public void closeRecorderCompleted(boolean success)
	{
		invokeMethodWithBoolean( "closeRecorderCompleted", success, success );
	}
	public void stopRecorderCompleted(boolean success, String url)
	{
		invokeMethodWithString( "stopRecorderCompleted", success, url );
	}
	public void pauseRecorderCompleted(boolean success)
	{
		invokeMethodWithBoolean( "pauseRecorderCompleted", success, success );
	}
	public void resumeRecorderCompleted(boolean success)
	{
		invokeMethodWithBoolean( "resumeRecorderCompleted", success, success );
	}

	public void startRecorderCompleted (boolean success)
	{
		invokeMethodWithBoolean( "startRecorderCompleted", success, success );
	}



	public void updateRecorderProgressDbPeakLevel(double normalizedPeakLevel, long duration)
      {
	      Map<String, Object> dic = new HashMap<String, Object>();
	      dic.put("duration", duration);
	      dic.put("dbPeakLevel", normalizedPeakLevel);
	      invokeMethodWithMap("updateRecorderProgress", true, dic);
      }

      public void recordingData ( byte[] data)
      {
	      Map<String, Object> dic = new HashMap<String, Object>();
	      dic.put("recordingData", data);
	      invokeMethodWithMap("recordingData", true, dic);

      }

//-----------------------------------------------------------------------------------------------------------------------------------------------

	/* ctor */ FlutterSoundRecorder (final MethodCall call)
	{
		m_recorder = new FlautoRecorder(this);
	}


	FlutterSoundManager getPlugin ()
	{
		return FlutterSoundRecorderManager.flutterSoundRecorderPlugin;
	}




	void openRecorder ( final MethodCall call, final Result result )
	{
		int x1 = call.argument("focus");
		t_AUDIO_FOCUS focus = t_AUDIO_FOCUS.values()[x1];
		int x2 = call.argument("category");
		t_SESSION_CATEGORY category = t_SESSION_CATEGORY.values()[x2];
		int x3 = call.argument("mode");
		t_SESSION_MODE mode = t_SESSION_MODE.values()[x3];
		int x4 = call.argument("device");
		t_AUDIO_DEVICE audioDevice = t_AUDIO_DEVICE.values()[x4];
		int audioFlags = call.argument("audioFlags");

		boolean r = m_recorder.openRecorder
			(
				focus,
				category,
				mode,
				audioFlags,
				audioDevice
			);

		if (r)
		{

			result.success("openRecorder");
		} else
			result.error ( ERR_UNKNOWN, ERR_UNKNOWN, "Failure to open session");
	}

	void closeRecorder ( final MethodCall call, final Result result )
	{
		m_recorder.closeRecorder();
		result.success ( "closeRecorder" );

	}
	void reset(final MethodCall call, final MethodChannel.Result result)
	{
		m_recorder.closeRecorder();
		result.success ( "reset" );

	}


	void isEncoderSupported ( final MethodCall call, final Result result )
	{
		int     _codec = call.argument ( "codec" );
		boolean b      = m_recorder.isEncoderSupported(t_CODEC.values()[_codec]);
		//if ( Build.VERSION.SDK_INT < 29 )
		{
			//if ( ( _codec == CODEC_OPUS ) || ( _codec == CODEC_VORBIS ) )
			{
				//b = false;
			}
		}
		result.success ( b );
	}

	void invokeMethodWithString ( String methodName, String arg )
	{
		Map<String, Object> dic = new HashMap<String, Object> ();
		dic.put ( "slotNo", slotNo );
		dic.put ( "arg", arg );
		dic.put ( "state", getStatus() );
		getPlugin ().invokeMethod ( methodName, dic );
	}

	void invokeMethodWithDouble ( String methodName, double arg )
	{
		Map<String, Object> dic = new HashMap<String, Object> ();
		dic.put ( "slotNo", slotNo );
		dic.put ( "arg", arg );
		dic.put ( "state", getStatus() );
		getPlugin ().invokeMethod ( methodName, dic );
	}

	int getStatus()
	{
		return m_recorder.getRecorderState().ordinal();
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
			t_CODEC               		codec               = t_CODEC.values()[ _codec ];
			final String                     path               = call.argument ( "path" );
			int                             _audioSource        = call.argument ( "audioSource" );
			t_AUDIO_SOURCE                  audioSource         = t_AUDIO_SOURCE.values()[_audioSource];
			int 				toStream	    = call.argument ( "toStream");

			boolean r = m_recorder.startRecorder(codec, sampleRate, numChannels, bitRate, path, audioSource, toStream != 0);
			if (r)
				result.success ( "Media Recorder is started" );
			else
				result.error ( "startRecorder", "startRecorder", "Failure to start recorder");

		}
		//);

	}


	public void stopRecorder ( final MethodCall call, final Result result )
	{
		m_recorder.stopRecorder();
		result.success ( "Media Recorder is closed" );
	}

	public void pauseRecorder( final MethodCall call, final MethodChannel.Result result )
	{
		m_recorder.pauseRecorder( );
		result.success( "Recorder is paused");
	}

	public void resumeRecorder( final MethodCall call, final MethodChannel.Result result )
	{
		m_recorder.resumeRecorder();
		result.success( "Recorder is resumed");

	}

	public void setSubscriptionDuration ( final MethodCall call, final Result result )
	{
		if ( call.argument ( "duration" ) == null )
		{
			return;
		}
		int duration = call.argument ( "duration" );

		m_recorder.setSubscriptionDuration(duration);
		result.success ( "setSubscriptionDuration: " + duration );
	}

	void setAudioFocus(final MethodCall call, final MethodChannel.Result result )
	{
		int x1 = call.argument("focus");
		Flauto.t_AUDIO_FOCUS focus = Flauto.t_AUDIO_FOCUS.values()[x1];
		int x2 = call.argument("category");
		Flauto.t_SESSION_CATEGORY category = Flauto.t_SESSION_CATEGORY.values()[x2];
		int x3 = call.argument("mode");
		Flauto.t_SESSION_MODE mode = Flauto.t_SESSION_MODE.values()[x3];
		int x4 = call.argument("device");
		Flauto.t_AUDIO_DEVICE audioDevice = Flauto.t_AUDIO_DEVICE.values()[x4];
		int audioFlags = call.argument("audioFlags");
		boolean r = m_recorder.setAudioFocus(focus, category, mode, audioFlags, audioDevice);
		if (r)
			result.success ( r);
		else
			result.error ( "setFocus", "setFocus", "Failure to prepare focus");
	}

	public void getRecordURL (final MethodCall call, final MethodChannel.Result result )
	{
		String path =  call.argument ( "path" );
		String r = m_recorder.temporayFile(path);
		result.success( r );
	}


	public void deleteRecord (final MethodCall call, final MethodChannel.Result result )
	{
		String path =  call.argument ( "path" );
		boolean r = m_recorder.deleteRecord(path);
		result.success( r );
	}

}
