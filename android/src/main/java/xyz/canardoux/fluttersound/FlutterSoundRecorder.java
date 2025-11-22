package xyz.canardoux.fluttersound;
/*
 * Copyright 2018, 2019, 2020, 2021 canardoux.
 *
 * This file is part of Flutter-Sound.
 *
 * Flutter-Sound is free software: you can redistribute it and/or modify
 * it under the terms of the Mozilla Public License version 2 (MPL2.0),
 * as published by the Mozilla organization.
 *
 * Flutter-Sound is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * MPL General Public License for more details.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */


import android.media.MediaRecorder;

import java.nio.FloatBuffer;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.Result;

import xyz.canardoux.TauEngine.FlautoRecorderCallback;
import xyz.canardoux.TauEngine.FlautoRecorder;
import xyz.canardoux.TauEngine.Flauto;
import xyz.canardoux.TauEngine.Flauto.*;


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
	      dic.put("data", data);
	      invokeMethodWithMap("recordingData", true, dic);
      }


	public void recordingDataFloat32(ArrayList<float[]> data)
	{
		Map<String, Object> dic = new HashMap<String, Object>();
		dic.put("data", data);
		invokeMethodWithMap("recordingDataFloat32", true, dic);
	}


	public void recordingDataInt16(ArrayList<byte[]> data)
	{
		Map<String, Object> dic = new HashMap<String, Object>();
		dic.put("data", data);
		invokeMethodWithMap("recordingDataInt16", true, dic);
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
		boolean r = m_recorder.openRecorder();
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
		// don't set the result here, because this function is called recursively for several player/recorder
		// and this result is set by the caller (in FlutterSoundManager.java)
		//result.success ( 0 );

	}


	void isEncoderSupported ( final MethodCall call, final Result result )
	{
		int     _codec = call.argument ( "codec" );
		boolean b      = m_recorder.isEncoderSupported(t_CODEC.values()[_codec]);
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

	static boolean _isAudioRecorder[] =
	{
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





	public void startRecorder ( final MethodCall call, final Result result )
	{
		//taskScheduler.submit ( () ->
		{
			Integer                         sampleRate          = call.argument ( "sampleRate" );
			Integer                         numChannels         = call.argument ( "numChannels" );
			Integer                         bitRate             = call.argument ( "bitRate" );
			Integer 						bufferSize 	    	= call.argument ( "bufferSize");
			int                             _codec              = call.argument ( "codec" );
			t_CODEC               			codec               = t_CODEC.values()[ _codec ];
			final String                     path               = call.argument ( "path" );
			int                             _audioSource        = call.argument ( "audioSource" );
			t_AUDIO_SOURCE                  audioSource         = t_AUDIO_SOURCE.values()[_audioSource];
			boolean 						toStream	    	= call.argument ( "toStream");
			boolean							interleaved			= call.argument ( "interleaved");
			boolean							noiseSuppression	= call.argument ( "enableNoiseSuppression");
			boolean							echoCancellation	= call.argument ( "enableEchoCancellation");

			boolean r = m_recorder.startRecorder(codec, sampleRate, numChannels, interleaved, bitRate, bufferSize, path, audioSource, toStream,
					noiseSuppression, echoCancellation);
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

	public void setLogLevel (final MethodCall call, final MethodChannel.Result result )
	{
	}



}
