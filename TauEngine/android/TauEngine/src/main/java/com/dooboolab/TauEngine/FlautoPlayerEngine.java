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

//import static androidx.core.content.ContextCompat.getSystemService;

//-------------------------------------------------------------------------------------------------------------



class FlautoPlayerEngine extends FlautoPlayerEngineInterface
{
	AudioTrack audioTrack = null;
	int sessionId = 0;
	long mPauseTime = 0;
	long mStartPauseTime = -1;
	long systemTime = 0;
	WriteBlockThread blockThread = null;
	FlautoPlayer mSession = null;

	class WriteBlockThread extends Thread
	{
		byte[] mData = null;
		/* ctor */ WriteBlockThread(byte[] data)
		{
			mData = data;
		}
		public void run()
		{
			int ln =  mData.length;
			int total = 0;
			int written = 0;
			while (audioTrack != null && ln > 0)
			{
				try
				{
					if (Build.VERSION.SDK_INT >= 23) {
						written = audioTrack.write(mData, 0, ln, AudioTrack.WRITE_BLOCKING);
					} else {
						written = audioTrack.write(mData, 0, mData.length);
					}
					if (written > 0) {
						ln -= written;
						total += written;
					}
				} catch (Exception e )
				{
					System.out.println(e.toString());
					return;
				}
			}
			if (total < 0)
				throw new RuntimeException();

			mSession.needSomeFood(total);
			blockThread = null;

		}
	}

	/* ctor */ FlautoPlayerEngine() throws Exception
	{
		if ( Build.VERSION.SDK_INT >= 21 )
		{

			AudioManager audioManager = (AudioManager) Flauto.androidContext.getSystemService(Context.AUDIO_SERVICE);
			sessionId = audioManager.generateAudioSessionId();
		} else
		{
			throw new Exception("Need SDK 21");
		}
	}


	void _startPlayer
		(
			String path,
			int sampleRate,
			int numChannels,
			int blockSize,
			FlautoPlayer theSession
		) throws Exception
	{
		if ( Build.VERSION.SDK_INT >= 21 )
		{
			mSession = theSession;
			AudioAttributes attributes = new AudioAttributes.Builder()
				.setLegacyStreamType(AudioManager.STREAM_MUSIC)
				.setUsage(AudioAttributes.USAGE_MEDIA)
				.setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
				.build();

			AudioFormat format = new AudioFormat.Builder()
				.setEncoding(AudioFormat.ENCODING_PCM_16BIT)
				.setSampleRate(sampleRate)
				.setChannelMask(numChannels == 1 ? AudioFormat.CHANNEL_OUT_MONO : AudioFormat.CHANNEL_OUT_STEREO)
				.build();
			audioTrack = new AudioTrack(attributes, format, blockSize, AudioTrack.MODE_STREAM, sessionId);
			mPauseTime = 0;
			mStartPauseTime = -1;
			systemTime = SystemClock.elapsedRealtime();

			audioTrack.play();
			theSession.onPrepared();
		} else
		{
			throw new Exception("Need SDK 21");
		}
	}


	void _stop()
	{
		if (audioTrack != null)
		{
			audioTrack.stop();
			audioTrack.release();
			audioTrack = null;
		}
		blockThread = null;
	}

	void _finish()
	{
	}



	void _pausePlayer() throws Exception
	{
		mStartPauseTime = SystemClock.elapsedRealtime ();
		audioTrack.pause();
	}


	void _resumePlayer() throws Exception
	{
		if (mStartPauseTime >= 0)
			mPauseTime += SystemClock.elapsedRealtime () - mStartPauseTime;
		mStartPauseTime = -1;

		audioTrack.play();

	}


	void _setVolume(float volume)  throws Exception
	{

		if ( Build.VERSION.SDK_INT >= 21 )
		{
			audioTrack.setVolume(volume);
		} else
		{
			throw new Exception("Need SDK 21");
		}

	}


	void _seekTo(long millisec)
	{

	}


	boolean _isPlaying()
	{
		return audioTrack.getPlayState () == AudioTrack.PLAYSTATE_PLAYING;
	}


	long _getDuration()
	{
		return _getCurrentPosition(); // It would be better if we add what is in the input buffers and not still played
	}


	long _getCurrentPosition()
	{
		long time ;
		if (mStartPauseTime >= 0)
			time =   mStartPauseTime - systemTime - mPauseTime ;
		else
			time = SystemClock.elapsedRealtime() - systemTime - mPauseTime;
		return time;
	}


	int feed(byte[] data) throws Exception
	{
		int ln = 0;
		if ( Build.VERSION.SDK_INT >= 23 )
		{
			ln = audioTrack.write(data, 0, data.length, AudioTrack.WRITE_NON_BLOCKING);
		} else
		{
			ln = 0;
		}
		if (ln == 0)
		{
			if (blockThread != null)
			{
				System.out.println("Audio packet Lost !");
			}
			blockThread = new WriteBlockThread(data);
			blockThread.start();
		}
		return ln;
	}
}
