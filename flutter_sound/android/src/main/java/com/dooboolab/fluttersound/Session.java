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


package com.dooboolab.fluttersound;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothProfile;
import android.content.Context;
import android.media.AudioFocusRequest;
import android.media.AudioManager;
import android.os.Build;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

/// to control the focus mode.
enum AudioFocus {
	requestFocus,

	/// request focus and allow other audio
	/// to continue playing at their current volume.
	requestFocusAndKeepOthers,

	/// request focus and stop other audio playing
	requestFocusAndStopOthers,

	/// request focus and reduce the volume of other players
	/// In the Android world this is know as 'Duck Others'.
	requestFocusAndDuckOthers,

	requestFocusAndInterruptSpokenAudioAndMixWithOthers,

	requestFocusTransient,
	requestFocusTransientExclusive,

	/// relinquish the audio focus.
	abandonFocus,

	doNotRequestFocus,
}

enum AudioDevice {
	speaker,
	headset,
	earPiece,
	blueTooth,
	blueToothA2DP,
	airPlay
}



public abstract class Session
{
	final int outputToSpeaker = 1;
	final int allowHeadset = 2;
	final int allowEarPiece = 4;
	final int allowBlueTooth = 8;
	final int allowAirPlay = 16;
	final int allowBlueToothA2DP = 32;


	final static int CODEC_OPUS   = 2;
	final static int CODEC_VORBIS = 5;
	int slotNo;
	boolean hasFocus = false;
	AudioFocusRequest   audioFocusRequest = null;
	AudioManager        audioManager;



	void init( int slot)
	{
		slotNo = slot;
	}

	abstract FlautoManager getPlugin ();

	void releaseSession()
	{
		getPlugin().freeSlot(slotNo);
	}


	void invokeMethodWithString ( String methodName, String arg )
	{
		Map<String, Object> dic = new HashMap<String, Object>();
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


	void invokeMethodWithInteger ( String methodName, int arg )
	{
		Map<String, Object> dic = new HashMap<String, Object> ();
		dic.put ( "slotNo", slotNo );
		dic.put ( "arg", arg );
		getPlugin ().invokeMethod ( methodName, dic );
	}


	void invokeMethodWithBoolean ( String methodName, boolean arg )
	{
		Map<String, Object> dic = new HashMap<String, Object> ();
		dic.put ( "slotNo", slotNo );
		dic.put ( "arg", arg );
		getPlugin ().invokeMethod ( methodName, dic );
	}

	void invokeMethodWithMap ( String methodName, Map<String, Object>  dic )
	{
		dic.put ( "slotNo", slotNo );
		getPlugin ().invokeMethod ( methodName, dic );
	}


	boolean prepareFocus( final MethodCall call)
	{
		boolean r = true;
		audioManager = ( AudioManager ) FlautoPlayerManager.androidContext.getSystemService( Context.AUDIO_SERVICE );
		AudioFocus focus = AudioFocus.values()[(int)call.argument ( "focus" )];
		AudioDevice device = AudioDevice.values()[(int)call.argument( "device" )];

		int audioFlags = call.argument( "audioFlags" );
		if ( Build.VERSION.SDK_INT >= Build.VERSION_CODES.O )
		{
			if ( focus != AudioFocus.abandonFocus && focus != AudioFocus.doNotRequestFocus && focus != AudioFocus.requestFocus )
			{
				int focusGain = AudioManager.AUDIOFOCUS_GAIN;

				switch (focus)
				{
					case requestFocusAndDuckOthers: focusGain = AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK; ; break;
					case requestFocusAndKeepOthers: focusGain = AudioManager.AUDIOFOCUS_GAIN; ; break;
					case requestFocusTransient: focusGain = AudioManager.AUDIOFOCUS_GAIN_TRANSIENT; break;
					case requestFocusTransientExclusive: focusGain = AudioManager.AUDIOFOCUS_GAIN_TRANSIENT_EXCLUSIVE; break;
					case requestFocusAndInterruptSpokenAudioAndMixWithOthers: focusGain = AudioManager.AUDIOFOCUS_GAIN; break;
					case requestFocusAndStopOthers: focusGain = AudioManager.AUDIOFOCUS_GAIN; break;
				}
				audioFocusRequest = new AudioFocusRequest.Builder( focusGain )
					// .setAudioAttributes(mPlaybackAttributes)
					.build();

				// change the audio input/output device
				switch (device)
				{
					case speaker:
						if (isBluetoothHeadsetConnected())
							audioManager.setMode(AudioManager.MODE_IN_COMMUNICATION);
						else
							audioManager.setMode(AudioManager.MODE_NORMAL);
						audioManager.stopBluetoothSco();
						audioManager.setBluetoothScoOn(false);
						audioManager.setSpeakerphoneOn(true);
						break;
					case blueTooth:
					case blueToothA2DP:
						audioManager.setMode(AudioManager.MODE_IN_COMMUNICATION);
						if (isBluetoothHeadsetConnected())
						{
							audioManager.startBluetoothSco();
							audioManager.setBluetoothScoOn(true);
						}
						audioManager.setSpeakerphoneOn(false);
						break;
					case earPiece:
					case headset:
						audioManager.setMode(AudioManager.MODE_IN_COMMUNICATION);
						audioManager.stopBluetoothSco();
						audioManager.setBluetoothScoOn(false);
						audioManager.setSpeakerphoneOn(false);
				}


			}

			if (focus != AudioFocus.doNotRequestFocus)
			{
				hasFocus = (focus != AudioFocus.abandonFocus);
				if (hasFocus)
					audioManager.requestAudioFocus ( audioFocusRequest );
				else
					audioManager.abandonAudioFocusRequest ( audioFocusRequest );
			}
		}

		audioManager.setSpeakerphoneOn( (audioFlags &  outputToSpeaker) != 0);
		audioManager.setBluetoothScoOn( (audioFlags & allowBlueTooth) != 0);
		if ((audioFlags & allowBlueTooth) != 0)
			audioManager.startBluetoothSco();
		else
			audioManager.stopBluetoothSco();
		audioManager.setBluetoothA2dpOn(  (audioFlags & allowBlueToothA2DP) != 0 );
		audioManager.setMode( AudioManager.MODE_NORMAL );

		return r;
	}

	void setAudioFocus(final MethodCall call, final MethodChannel.Result result )
	{
		boolean r = prepareFocus(call);
		if (r)
			result.success ( r);
		else
			result.error ( "setFocus", "setFocus", "Failure to prepare focus");

	}


	boolean requestFocus ()
	{
		if ( Build.VERSION.SDK_INT >= Build.VERSION_CODES.O )
		{
			if ( audioFocusRequest == null )
			{
				audioFocusRequest = new AudioFocusRequest.Builder ( AudioManager.AUDIOFOCUS_GAIN )
					//.setAudioAttributes(mPlaybackAttributes)
					//.setAcceptsDelayedFocusGain(true)
					//.setWillPauseWhenDucked(true)
					//.setOnAudioFocusChangeListener(this, mMyHandler)
					.build ();
			}
			hasFocus = true;
			return ( audioManager.requestAudioFocus ( audioFocusRequest ) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED );
		} else
		{
			return false;
		}
	}

	boolean abandonFocus ()
	{
		if ( Build.VERSION.SDK_INT >= Build.VERSION_CODES.O )
		{
			if ( audioFocusRequest == null )
			{
				audioFocusRequest = new AudioFocusRequest.Builder ( AudioManager.AUDIOFOCUS_GAIN )
					//.setAudioAttributes(mPlaybackAttributes)
					//.setAcceptsDelayedFocusGain(true)
					//.setWillPauseWhenDucked(true)
					//.setOnAudioFocusChangeListener(this, mMyHandler)
					.build ();
			}
			hasFocus = false;
			return ( audioManager.abandonAudioFocusRequest ( audioFocusRequest ) == AudioManager.AUDIOFOCUS_REQUEST_GRANTED );
		} else
		{
			return false;
		}

	}

	private static boolean isBluetoothHeadsetConnected() {
		BluetoothAdapter adapter = BluetoothAdapter.getDefaultAdapter();
		if (adapter == null)
			return false;
		return (BluetoothProfile.STATE_CONNECTED == adapter.getProfileConnectionState(BluetoothProfile.HEADSET));
	}

}
