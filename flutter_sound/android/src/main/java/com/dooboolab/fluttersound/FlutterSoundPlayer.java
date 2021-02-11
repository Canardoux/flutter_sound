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
import android.media.AudioAttributes;
import android.media.AudioFormat;
import android.media.AudioManager;
import android.media.AudioTrack;
import android.media.MediaPlayer;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.os.SystemClock;
import android.util.Log;
import android.media.AudioFocusRequest;

import java.io.File;
import java.io.FileOutputStream;
import java.util.HashMap;
import java.util.Map;
import java.util.Timer;
import java.util.TimerTask;
import java.lang.Thread;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.Result;

import static androidx.core.content.ContextCompat.getSystemService;

import com.dooboolab.TauEngine.FlautoPlayer;
import com.dooboolab.TauEngine.FlautoTrack;
import com.dooboolab.TauEngine.FlautoTrackPlayer;
import com.dooboolab.TauEngine.FlautoPlayerCallback;
import com.dooboolab.TauEngine.Flauto;
import com.dooboolab.TauEngine.Flauto.*;


public class FlutterSoundPlayer extends FlutterSoundSession implements  FlautoPlayerCallback
{

	static final String ERR_UNKNOWN           = "ERR_UNKNOWN";
	static final String ERR_PLAYER_IS_NULL    = "ERR_PLAYER_IS_NULL";
	static final String ERR_PLAYER_IS_PLAYING = "ERR_PLAYER_IS_PLAYING";
	final static  String           TAG         = "FlutterSoundPlugin";


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

	public void pause()
	{
		invokeMethodWithInteger( "pause", true, getPlayerState() );

	}

	public void resume()
	{
		invokeMethodWithInteger( "resume", true, getPlayerState() );

	}

	public void skipForward()
	{
		invokeMethodWithInteger( "skipForward", true, getPlayerState() );

	}

	public void skipBackward()
	{
		invokeMethodWithInteger( "skipBackward", true, getPlayerState() );

	}

	public void updatePlaybackState(t_PLAYER_STATE newState)
	{
		invokeMethodWithInteger( "updatePlaybackState", true, newState.ordinal() );
	}


//========================================================================================================================================

	/* ctor */ FlutterSoundPlayer (final MethodCall call)
	{
		int withUI  = call.argument("withUI");
		if (withUI != 0)
		{
			m_flautoPlayer = new FlautoTrackPlayer(this);
		} else
		{
			m_flautoPlayer = new FlautoPlayer(this);
		}
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
		int x1 = call.argument("focus");
		t_AUDIO_FOCUS focus = t_AUDIO_FOCUS.values()[x1];
		int x2 = call.argument("category");
		t_SESSION_CATEGORY category = t_SESSION_CATEGORY.values()[x2];
		int x3 = call.argument("mode");
		t_SESSION_MODE mode = t_SESSION_MODE.values()[x3];
		int x4 = call.argument("device");
		t_AUDIO_DEVICE audioDevice = t_AUDIO_DEVICE.values()[x4];
		int audioFlags = call.argument("audioFlags");

		boolean r = m_flautoPlayer.openPlayer
		(
			focus,
			category,
			mode,
			audioFlags,
			audioDevice
		);

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
		result.success ( getPlayerState() );
	}


	int getPlayerState()
	{
		return m_flautoPlayer.getPlayerState().ordinal();
	}

	public void startPlayerFromMic ( final MethodCall call, final Result result ) {
		Integer _blockSize = 4096;
		if (call.argument("blockSize") != null) {
			_blockSize = call.argument("blockSize");
		}

		Integer _sampleRate = 48000;
		if (call.argument("sampleRate") != null) {
			_sampleRate = call.argument("sampleRate");
		}
		Integer _numChannels = 1;
		if (call.argument("numChannels") != null) {
			_numChannels = call.argument("numChannels");
		}
		try {
			boolean b = m_flautoPlayer.startPlayerFromMic( _numChannels, _sampleRate, _blockSize);
			if (b)
				result.success(getPlayerState());
			else
				result.error(ERR_UNKNOWN, ERR_UNKNOWN, "startPlayer() error");
		} catch (Exception e) {
			Log.e(TAG, "startPlayerFromMic() exception");
			result.error(ERR_UNKNOWN, ERR_UNKNOWN, e.getMessage());
		}
	}


	public void startPlayer ( final MethodCall call, final Result result ) {
		Integer _codec = call.argument("codec");
		t_CODEC codec = t_CODEC.values()[(_codec != null) ? _codec : 0];
		byte[] dataBuffer = call.argument("fromDataBuffer");
		Integer _blockSize = 4096;
		if (call.argument("blockSize") != null) {
			_blockSize = call.argument("blockSize");
		}
		String _path = call.argument("fromURI");

		Integer _sampleRate = 16000;
		if (call.argument("sampleRate") != null) {
			_sampleRate = call.argument("sampleRate");
		}
		Integer _numChannels = 1;
		if (call.argument("numChannels") != null) {
			_numChannels = call.argument("numChannels");
		}

		try {
			boolean b = m_flautoPlayer.startPlayer(codec, _path, dataBuffer, _numChannels, _sampleRate, _blockSize);
			if (b)
				result.success(getPlayerState());
			else
				result.error(ERR_UNKNOWN, ERR_UNKNOWN, "startPlayer() error");
		} catch (Exception e) {
			Log.e(TAG, "startPlayer() exception");
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
			Log.e ( TAG, "feed() exception" );
			result.error ( ERR_UNKNOWN, ERR_UNKNOWN, e.getMessage () );
		}
	}


	public void startPlayerFromTrack ( final MethodCall call, final Result result )
	{
		final HashMap<String, Object> trackMap = call.argument( "track" );
		final FlautoTrack track = new FlautoTrack( trackMap );
		boolean canSkipForward = call.argument( "canSkipForward" );
		boolean canSkipBackward = call.argument( "canSkipBackward" );
		boolean canPause = call.argument( "canPause" );
		int progress = (call.argument( "progress" ) == null) ? -1 : call.argument( "progress" );
		int duration = (call.argument( "duration" ) == null) ? -1 : call.argument( "duration" );
		boolean removeUIWhenStopped = call.argument( "removeUIWhenStopped" );
		boolean defaultPauseResume = call.argument( "defaultPauseResume" );

		boolean r = m_flautoPlayer.startPlayerFromTrack
		(
			track,
			canPause,
			canSkipForward,
			canSkipBackward,
			progress,
			duration,
			removeUIWhenStopped,
			defaultPauseResume
		);
		if (r)
			result.success(getPlayerState());
		else
			result.error(ERR_UNKNOWN, ERR_UNKNOWN, "startPlayerFromTrack() error");
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
			Log.e ( TAG, "pausePlay exception: " + e.getMessage () );
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
			Log.e ( TAG, "mediaPlayer resume: " + e.getMessage () );
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


	public void setSubscriptionDuration ( final MethodCall call, Result result )
	{
		if ( call.argument ( "duration" ) != null )
		{
			int duration = call.argument("duration");
			m_flautoPlayer.setSubscriptionDuration(duration);
		}
		result.success ( getPlayerState());
	}

	void androidAudioFocusRequest ( final MethodCall call, final Result result )
	{
		Integer focusGain = call.argument ( "focusGain" );
		m_flautoPlayer.androidAudioFocusRequest(focusGain);

		result.success (getPlayerState() );
	}

	void setActive ( final MethodCall call, final Result result )
	{
		Boolean enabled = call.argument ( "enabled" );
		m_flautoPlayer.setActive(enabled);
		result.success (getPlayerState() );
	}

	void getProgress ( final MethodCall call, final Result result )
	{
		Map<String, Object> dic = m_flautoPlayer.getProgress();
		dic.put ( "slotNo", slotNo);
		result.success(dic);
	}

	void nowPlaying ( final MethodCall call, final Result result )
	{
		// TODO
		result.success (getPlayerState() );
	}


	void setUIProgressBar ( final MethodCall call, final Result result )
	{
		// TODO
		result.success (getPlayerState() );

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

	void setAudioFocus(final MethodCall call, final MethodChannel.Result result )
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
		boolean r = m_flautoPlayer.setAudioFocus(focus, category, mode, audioFlags, audioDevice);
		if (r)
			result.success ( r);
		else
			result.error ( "setFocus", "setFocus", "Failure to prepare focus");
	}

}
