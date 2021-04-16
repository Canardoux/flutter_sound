package com.dooboolab.TauEngine;
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

import android.app.Activity;
import android.content.Context;

import java.io.File;
//import androidx.annotation.NonNull;



public class Flauto
{

	public enum t_CODEC
	{
		defaultCodec,
		aacADTS,
		opusOGG,
		opusCAF, // Apple encapsulates its bits in its own special envelope : .caf instead of a regular ogg/opus (.opus). This is completely stupid, this is Apple.
		mp3,
		vorbisOGG,
		pcm16,
		pcm16WAV,
		pcm16AIFF,
		pcm16CAF,
		flac,
		aacMP4,
		amrNB,
		amrWB,
		pcm8,
		pcmFloat32,
		pcmWebM,
		opusWebM,
		vorbisWebM,
	}

	public enum t_AUDIO_FOCUS
	{
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


	public enum t_AUDIO_DEVICE
	{
		speaker,
		headset,
		earPiece,
		blueTooth,
		blueToothA2DP,
		airPlay
	}


	public enum t_PLAYER_STATE
	{
		PLAYER_IS_STOPPED,
		PLAYER_IS_PLAYING,
		PLAYER_IS_PAUSED
	}


	public enum t_RECORDER_STATE
	{
		RECORDER_IS_STOPPED,
		RECORDER_IS_PAUSED,
		RECORDER_IS_RECORDING,
	}





	public enum t_SESSION_CATEGORY
	{
		ambient,
		multiRoute,
		playAndRecord,
		playback,
		record,
		soloAmbient,
		audioProcessing,
	}


	public enum   t_SESSION_MODE
	{
		modeDefault, // 'AVAudioSessionModeDefault',
		modeGameChat, //'AVAudioSessionModeGameChat',
		modeMeasurement, //'AVAudioSessionModeMeasurement',
		modeMoviePlayback, //'AVAudioSessionModeMoviePlayback',
		modeSpokenAudio, //'AVAudioSessionModeSpokenAudio',
		modeVideoChat, //'AVAudioSessionModeVideoChat',
		modeVideoRecording, // 'AVAudioSessionModeVideoRecording',
		modeVoiceChat, // 'AVAudioSessionModeVoiceChat',
		// ONLY iOS 12.0 // modeVoicePrompt, // 'AVAudioSessionModeVoicePrompt',
	}


	public enum t_AUDIO_SOURCE
	{
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



	public static Activity androidActivity;
	public static Context androidContext;

	public static String temporayFile(String radical)
	{
		File outputDir = Flauto.androidContext.getCacheDir(); // context being the Activity pointer
		return outputDir + "/" + radical;

	}

	public static String getPath(String path)
	{
		if (path == null)
			return null;
		boolean isFound = path.contains("/");
		if (!isFound)
		{
			path = temporayFile(path);
		}
		return path;
	}

}
