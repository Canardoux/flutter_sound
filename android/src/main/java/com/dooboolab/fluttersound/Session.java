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
import android.media.MediaRecorder;
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

	abstract AudioSessionManager getPlugin ();

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

	void invokeMethodWithMap ( String methodName, Map<String, Object>  dic )
	{
		dic.put ( "slotNo", slotNo );
		getPlugin ().invokeMethod ( methodName, dic );
	}


	boolean prepareFocus( final MethodCall call)
	{
		boolean r = true;
		audioManager = ( AudioManager ) FlautoPlayerPlugin.androidContext.getSystemService( Context.AUDIO_SERVICE );
		AudioFocus focus = AudioFocus.values()[(int)call.argument ( "focus" )];
		AudioDevice device = AudioDevice.values()[(int)call.argument( "device" )];

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

				/*
				if (flags & outputToSpeaker)
					sessionCategoryOption |= AVAudioSessionCategoryOptionDefaultToSpeaker;
				if (flags & allowAirPlay)
					sessionCategoryOption |= AVAudioSessionCategoryOptionAllowAirPlay;
				if (flags & allowBlueTooth)
					sessionCategoryOption |= AVAudioSessionCategoryOptionAllowBluetooth;
				if (flags & allowBlueToothA2DP)
					sessionCategoryOption |= AVAudioSessionCategoryOptionAllowBluetoothA2DP;
				 */
			}

			if (focus != AudioFocus.doNotRequestFocus)
			{
				hasFocus = (focus != AudioFocus.abandonFocus);
				//r = [[AVAudioSession sharedInstance]  setActive: hasFocus error:nil] ;
				if (hasFocus)
					audioManager.requestAudioFocus ( audioFocusRequest );
				else
					audioManager.abandonAudioFocusRequest ( audioFocusRequest );
			}
		}
		return r;
	}

	void setAudioFocus(final MethodCall call, final MethodChannel.Result result )
	{
		boolean r = prepareFocus(call);
		if (r)
			result.success ( r );
		else
			result.error ( "setAudioFocus", "setAudioFocus", "Failure to prepare focus") ;
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
		return BluetoothProfile.STATE_CONNECTED == adapter.getProfileConnectionState(BluetoothProfile.HEADSET);
	}

}
