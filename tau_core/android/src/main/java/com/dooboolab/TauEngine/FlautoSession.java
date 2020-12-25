/*
 * Copyright 2018, 2019, 2020 Dooboolab.
 *
 * This file is part of the Tau project.
 *
 * Tau is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License version 3 (LGPL-V3), as published by
 * the Free Software Foundation.
 *
 * Tau is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with the Tau project.  If not, see <https://www.gnu.org/licenses/>.
 */

package com.dooboolab.TauEngine;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothProfile;
import android.content.Context;
import android.media.AudioFocusRequest;
import android.media.AudioManager;
import android.os.Build;

import java.util.HashMap;
import java.util.Map;
import com.dooboolab.TauEngine.Flauto.*;


public abstract class FlautoSession
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



	public void releaseSession()
	{

	}


	public boolean setAudioFocus(t_AUDIO_FOCUS focus, t_SESSION_CATEGORY category, t_SESSION_MODE sessionMode, int audioFlags, t_AUDIO_DEVICE audioDevice)
	{
		boolean r = true;
		audioManager = ( AudioManager ) Flauto.androidContext.getSystemService( Context.AUDIO_SERVICE );
		if ( Build.VERSION.SDK_INT >= 26 )
		{
			if ( focus != t_AUDIO_FOCUS.abandonFocus && focus != t_AUDIO_FOCUS.doNotRequestFocus && focus != t_AUDIO_FOCUS.requestFocus )
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
				switch (audioDevice)
				{
					case speaker:
						//if (isBluetoothHeadsetConnected())
							//audioManager.setMode(AudioManager.MODE_IN_COMMUNICATION);
						//else
							//audioManager.setMode(AudioManager.MODE_NORMAL);
						audioManager.stopBluetoothSco();
						audioManager.setBluetoothScoOn(false);
						audioManager.setSpeakerphoneOn(true);
						break;
					case blueTooth:
					case blueToothA2DP:
						//audioManager.setMode(AudioManager.MODE_IN_COMMUNICATION);
						if (isBluetoothHeadsetConnected())
						{
							audioManager.startBluetoothSco();
							audioManager.setBluetoothScoOn(true);
						}
						audioManager.setSpeakerphoneOn(false);
						break;
					case earPiece:
					case headset:
						//audioManager.setMode(AudioManager.MODE_IN_COMMUNICATION);
						audioManager.stopBluetoothSco();
						audioManager.setBluetoothScoOn(false);
						audioManager.setSpeakerphoneOn(false);
				}


			}

			if (focus != t_AUDIO_FOCUS.doNotRequestFocus)
			{
				if ( audioFocusRequest == null )
				{
					audioFocusRequest = new AudioFocusRequest.Builder ( AudioManager.AUDIOFOCUS_GAIN )
						.build ();
				}

				hasFocus = (focus != t_AUDIO_FOCUS.abandonFocus);
				if (hasFocus)
					audioManager.requestAudioFocus ( audioFocusRequest );
				else
					audioManager.abandonAudioFocusRequest ( audioFocusRequest );
			}

			audioManager.setSpeakerphoneOn( (audioFlags &  outputToSpeaker) != 0);
			audioManager.setBluetoothScoOn( (audioFlags & allowBlueTooth) != 0);
			if ((audioFlags & allowBlueTooth) != 0)
				audioManager.startBluetoothSco();
			else
				audioManager.stopBluetoothSco();
			audioManager.setBluetoothA2dpOn(  (audioFlags & allowBlueToothA2DP) != 0 );
			audioManager.setMode( AudioManager.MODE_NORMAL );
		} else
			r = true; // BOF!

		return r;
	}


	public boolean requestFocus ()
	{
		if ( Build.VERSION.SDK_INT >= 26)
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

	public boolean abandonFocus ()
	{
		if ( Build.VERSION.SDK_INT >= 26)
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

	private static boolean isBluetoothHeadsetConnected()
	{
		BluetoothAdapter adapter = BluetoothAdapter.getDefaultAdapter();
		if (adapter == null)
			return false;
		return (BluetoothProfile.STATE_CONNECTED == adapter.getProfileConnectionState(BluetoothProfile.HEADSET));
	}

}
