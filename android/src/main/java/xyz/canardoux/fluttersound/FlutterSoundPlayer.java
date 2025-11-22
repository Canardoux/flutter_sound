package xyz.canardoux.fluttersound;
/*
 * Copyright 2018, 2019, 2020, 2021 Dooboolab.
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


import java.util.HashMap;
import java.util.Map;
import java.util.ArrayList;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.Result;

import xyz.canardoux.TauEngine.Flauto;
import xyz.canardoux.TauEngine.FlautoPlayer;
import xyz.canardoux.TauEngine.FlautoPlayerCallback;
import xyz.canardoux.TauEngine.Flauto.*;


public class FlutterSoundPlayer extends FlutterSoundSession implements  FlautoPlayerCallback
{

	static final String ERR_UNKNOWN           = "ERR_UNKNOWN";
	static final String ERR_PLAYER_IS_NULL    = "ERR_PLAYER_IS_NULL";
	static final String ERR_PLAYER_IS_PLAYING = "ERR_PLAYER_IS_PLAYING";
	final static String           TAG         = "FlutterSoundPlugin";


	FlautoPlayer m_flautoPlayer;

// =============================================================  callback ===============================================================

	public void openPlayerCompleted(boolean success)
	{
		invokeMethodWithBoolean( "openPlayerCompleted", success, success );
	}
	public void closePlayerCompleted(boolean success)
	{
		invokeMethodWithBoolean( "closePlayerCompleted", success, success );
	}
	public void stopPlayerCompleted(boolean success)
	{
		invokeMethodWithBoolean( "stopPlayerCompleted", success, success );
	}
	public void pausePlayerCompleted(boolean success)
	{
		invokeMethodWithBoolean( "pausePlayerCompleted", success, success );
	}
	public void resumePlayerCompleted(boolean success)
	{
		invokeMethodWithBoolean( "resumePlayerCompleted", success, success );
	}

	public void startPlayerCompleted (boolean success, long duration)
	{
		Map<String, Object> dico = new HashMap<String, Object> ();
		dico.put( "duration", (int) duration);
		dico.put( "state",  (int)getPlayerState());
		invokeMethodWithMap( "startPlayerCompleted", success, dico);

	}

	public void needSomeFood (int ln)
	{
		invokeMethodWithInteger("needSomeFood", true, ln);
	}

	public void updateProgress(long position, long duration)
	{
		Map<String, Object> dic = new HashMap<String, Object>();
		dic.put("position", position);
		dic.put("duration", duration);
		dic.put("playerStatus", getPlayerState());

		invokeMethodWithMap("updateProgress", true, dic);

	}

	public void audioPlayerDidFinishPlaying (boolean flag)
	{
		invokeMethodWithInteger("audioPlayerFinishedPlaying", true, getPlayerState() );
	}

	public void updatePlaybackState(t_PLAYER_STATE newState)
	{
		invokeMethodWithInteger( "updatePlaybackState", true, newState.ordinal() );
	}


	//========================================================================================================================================

	/* ctor */ FlutterSoundPlayer (final MethodCall call)
	{
			m_flautoPlayer = new FlautoPlayer(this);
	}

	FlutterSoundManager getPlugin ()
	{
		return FlutterSoundPlayerManager.flutterSoundPlayerPlugin;
	}

	int getStatus()
	{
		return getPlayerState();
	}


	void openPlayer ( final MethodCall call, final Result result )
	{

		boolean r = m_flautoPlayer.openPlayer();

		if (r)
		{

			result.success(getPlayerState());
		} else
			result.error ( ERR_UNKNOWN, ERR_UNKNOWN, "Failure to open session");

	}

	void closePlayer ( final MethodCall call, final Result result )
	{
		m_flautoPlayer.closePlayer();
		result.success ( getPlayerState() );
	}

	void reset(final MethodCall call, final MethodChannel.Result result)
	{
		m_flautoPlayer.closePlayer();
		// don't set the result here, because this function is called recursively for several player/recorder
		// and this result is set by the caller (in FlutterSoundManager.java)
		//result.success ( getPlayerState() );
	}


	int getPlayerState()
	{
		return m_flautoPlayer.getPlayerState().ordinal();
	}

	public void startPlayerFromMic ( final MethodCall call, final Result result ) {
		Integer _bufferSize = 8192;
		if (call.argument("bufferSize") != null) {
			_bufferSize = call.argument("bufferSize");
		}

		Integer _sampleRate = 48000;
		if (call.argument("sampleRate") != null) {
			_sampleRate = call.argument("sampleRate");
		}
		Integer _numChannels = 1;
		if (call.argument("numChannels") != null) {
			_numChannels = call.argument("numChannels");
		}

		boolean enableVoiceProcessing = false; // not used on Android
		if (call.argument("enableVoiceProcessing") != null) {
			int voiceProcessing = call.argument("enableVoiceProcessing");
			enableVoiceProcessing = voiceProcessing != 0;
		}



		try {
			boolean b = m_flautoPlayer.startPlayerFromMic( t_CODEC.pcm16, _numChannels, true,  _sampleRate, _bufferSize, enableVoiceProcessing);
			if (b)
				result.success(getPlayerState());
			else
				result.error(ERR_UNKNOWN, ERR_UNKNOWN, "startPlayer() error");
		} catch (Exception e) {
			log(t_LOG_LEVEL.ERROR, "startPlayerFromMic() exception");
			result.error(ERR_UNKNOWN, ERR_UNKNOWN, e.getMessage());
		}
	}


	public void startPlayer ( final MethodCall call, final Result result ) {
		Integer _codec = call.argument("codec");
		Integer _bufferSize = 8192;
		t_CODEC codec = t_CODEC.values()[(_codec != null) ? _codec : 0];
		byte[] dataBuffer = call.argument("fromDataBuffer");
		//Integer _blockSize = 8192;
		if (call.argument("bufferSize") != null) {
			_bufferSize = call.argument("bufferSize");
		}
		String _path = call.argument("fromURI");

		Integer _sampleRate = 16000;
		if (call.argument("sampleRate") != null) {
			_sampleRate = call.argument("sampleRate");
		}
		Boolean interleaved = true;
		if (call.argument("interleaved") != null) {
			interleaved = call.argument("interleaved");
		}

		Integer _numChannels = 1;
		if (call.argument("numChannels") != null) {
			_numChannels = call.argument("numChannels");
		}

		boolean enableNoiseSuppression = false;
		if (call.argument("noiseSuppression") != null) {
			//int noiseSuppression = call.argument("noiseSuppression");
			//enableNoiseSuppression = noiseSuppression != 0;
			enableNoiseSuppression = call.argument("noiseSuppression");
		}

		boolean enableEchoCancellation = false;
		if (call.argument("echoCancellation") != null) {
			//int echoCancellation = call.argument("echoCancellation");
			//enableEchoCancellation = echoCancellation != 0;
			enableEchoCancellation = call.argument("echoCancellation");
		}



		try {
			boolean b = m_flautoPlayer.startPlayer(codec, _path, dataBuffer, _numChannels, interleaved, _sampleRate, _bufferSize);
			if (b)
			{
				result.success(getPlayerState());
			}
			else
				result.error(ERR_UNKNOWN, ERR_UNKNOWN, "startPlayer() error");
		} catch (Exception e) {
			log(t_LOG_LEVEL.ERROR,  "startPlayer() exception");
			result.error(ERR_UNKNOWN, ERR_UNKNOWN, e.getMessage());
		}
	}

	public void feed ( final MethodCall call, final Result result )
	{
		try
		{
			byte[] data = call.argument ( "data" );

			int ln = m_flautoPlayer.feed(data);
			assert(ln >= 0);
			result.success (ln);
		} catch (Exception e)
		{
			log(t_LOG_LEVEL.ERROR,  "feed() exception" );
			result.error ( ERR_UNKNOWN, ERR_UNKNOWN, e.getMessage () );
		}
	}

	public void feedInt16 ( final MethodCall call, final Result result )
	{
		try
		{
			ArrayList<byte[]> data = call.argument ( "data" );

			int ln = m_flautoPlayer.feedInt16(data); // TODO
			assert(ln >= 0);
			result.success (ln);
		} catch (Exception e)
		{
			log(t_LOG_LEVEL.ERROR,  "feed() exception" );
			result.error ( ERR_UNKNOWN, ERR_UNKNOWN, e.getMessage () );
		}
	}

	public void feedFloat32 ( final MethodCall call, final Result result )
	{
		try
		{
			ArrayList<float[]> data = call.argument ( "data" );

			int ln = m_flautoPlayer.feedFloat32(data);
			assert(ln >= 0);
			result.success (ln);
		} catch (Exception e)
		{
			log(t_LOG_LEVEL.ERROR,  "feed() exception" );
			result.error ( ERR_UNKNOWN, ERR_UNKNOWN, e.getMessage () );
		}
	}




	public void stopPlayer ( final MethodCall call, final Result result )
	{
		m_flautoPlayer.stopPlayer();
		result.success ( getPlayerState());
	}



	public void isDecoderSupported ( final MethodCall call, final Result result )
	{
		int     _codec = call.argument ( "codec" );
		boolean b      = m_flautoPlayer.isDecoderSupported(t_CODEC.values()[_codec]);
		result.success (b );

	}

	public void pausePlayer ( final MethodCall call, final Result result )
	{
		try
		{
			if (m_flautoPlayer.pausePlayer())
				result.success ( getPlayerState());
			else
				result.error( ERR_UNKNOWN, ERR_UNKNOWN, "Pause failure");
		}
		catch ( Exception e )
		{
			log(t_LOG_LEVEL.ERROR, "pausePlay exception: " + e.getMessage () );
			result.error ( ERR_UNKNOWN, ERR_UNKNOWN, e.getMessage () );
		}

	}

	public void resumePlayer ( final MethodCall call, final Result result )
	{
		try
		{
			if (m_flautoPlayer.resumePlayer())
				result.success ( getPlayerState());
			else
				result.error ( ERR_UNKNOWN, ERR_UNKNOWN, "Resume failure" );
		}
		catch ( Exception e )
		{
			log(t_LOG_LEVEL.ERROR, "mediaPlayer resume: " + e.getMessage () );
			result.error ( ERR_UNKNOWN, ERR_UNKNOWN, e.getMessage () );
		}
	}

	public void seekToPlayer ( final MethodCall call, final Result result )
	{
		int millis = call.argument ( "duration" ) ;

		m_flautoPlayer.seekToPlayer(millis);
		result.success (getPlayerState() );
	}

	public void setVolume ( final MethodCall call, final Result result )
	{
		try
		{
			double volume = call.argument("volume");
			m_flautoPlayer.setVolume(volume);
			result.success(getPlayerState());
		} catch(Exception e)
		{
			result.error ( ERR_UNKNOWN, ERR_UNKNOWN, e.getMessage () );
		}
	}

	public void setVolumePan ( final MethodCall call, final Result result )
	{
		try
		{
			double volume = call.argument("volume");
			double pan = call.argument("pan");
			m_flautoPlayer.setVolumePan(volume,pan);
			result.success(getPlayerState());
		} catch(Exception e)
		{
			result.error ( ERR_UNKNOWN, ERR_UNKNOWN, e.getMessage () );
		}
	}


	public void setSpeed ( final MethodCall call, final Result result )
	{
		try
		{
			double speed = call.argument("speed");
			m_flautoPlayer.setSpeed(speed);
			result.success(getPlayerState());
		} catch(Exception e)
		{
			result.error ( ERR_UNKNOWN, ERR_UNKNOWN, e.getMessage () );
		}
	}



	public void setSubscriptionDuration ( final MethodCall call, Result result )
	{
		if ( call.argument ( "duration" ) != null )
		{
			int duration = call.argument("duration");
			m_flautoPlayer.setSubscriptionDuration(duration);
		}
		result.success ( getPlayerState());
	}


	void getProgress ( final MethodCall call, final Result result )
	{
		Map<String, Object> dic = m_flautoPlayer.getProgress();
		dic.put ( "slotNo", slotNo);
		result.success(dic);
	}


	void getResourcePath ( final MethodCall call, final Result result )
	{
		// TODO
		result.success ("");

	}

	void getPlayerState ( final MethodCall call, final Result result )
	{
		result.success (getPlayerState());
	}


	public void setLogLevel (final MethodCall call, final MethodChannel.Result result )
	{
	}

}
