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
import android.media.AudioRecord;
import android.media.AudioTrack;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.os.SystemClock;
import android.util.Log;
import android.media.MediaRecorder;

import java.nio.ByteBuffer;
import java.util.Arrays;
import java.lang.Thread;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import com.dooboolab.TauEngine.Flauto.*;

//-------------------------------------------------------------------------------------------------------------



class FlautoPlayerEngineFromMic extends FlautoPlayerEngineInterface
{
	final static String             TAG                = "EngineFromMic";


	int[] tabCodec =
		{
			AudioFormat.ENCODING_DEFAULT, // DEFAULT
			AudioFormat.ENCODING_AAC_LC, // aacADTS
			0, // opusOGG
			0, // opusCAF
			AudioFormat.ENCODING_MP3, // MP3 // Not used
			0, // vorbisOGG
			AudioFormat.ENCODING_PCM_16BIT, // pcm16
			AudioFormat.ENCODING_PCM_16BIT, // pcm16WAV
			0, // pcm16AIFF
			0, // pcm16CAF
			0, // flac
			0, // aacMP4
			0, // amrNB
			0, // amrWB
		};


	AudioTrack audioTrack = null;
	int sessionId = 0;
	long mPauseTime = 0;
	long mStartPauseTime = -1;
	long systemTime = 0;
	int bufferSize = 0;
	FlautoPlayer mSession = null;

	AudioRecord recorder;
	FlautoRecorderCallback m_callBack ;
	public              int     subsDurationMillis    = 10;

	private boolean isRecording = false;
	_pollingRecordingData thePollingThread = null;



	public class _pollingRecordingData extends Thread
	{

		void _feed(byte[] data, int ln) throws Exception
		{
			int lnr = 0;
			if ( Build.VERSION.SDK_INT >= 23 )
			{
				 lnr = audioTrack.write(data, 0, ln, AudioTrack.WRITE_NON_BLOCKING);
			} else
			{
				 lnr = audioTrack.write(data, 0, ln);
			}
			if (lnr != ln)
			{
				Log.e( TAG, "feed error: some audio data are lost");
			}
		}

		public void run()
		{

			int n = 0;
			int r = 0;
			byte[] byteBuffer = new byte[bufferSize];
			while (isRecording)
			{
				try
				{
					if (Build.VERSION.SDK_INT >= 23)
					{
						n = recorder.read(byteBuffer, 0, bufferSize, AudioRecord.READ_BLOCKING);
					} else
					{
						n = recorder.read(byteBuffer, 0, bufferSize);
					}
					final int ln = n;

					if (n > 0)
					{
						r += n;

						try
						{
							_feed(byteBuffer, ln);
						} catch (Exception err)
						{
							Log.e(TAG, "feed error" + err.getMessage());
						}
					} else
					{
						Log.e(TAG, "feed error: ln = 0" );
						//break;
					}
				} catch (Exception e)
				{
					System.out.println(e);
					break;
				}
			}
			thePollingThread = null; // finished for me
		}

	}




	/* ctor */ FlautoPlayerEngineFromMic() throws Exception
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

	void startPlayerSide(int sampleRate, Integer numChannels, int blockSize) throws Exception
	{
		if ( Build.VERSION.SDK_INT >= 21 )
		{
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
			mSession.onPrepared();
		} else
		{
			throw new Exception("Need SDK 21");
		}

	}


	public void startRecorderSide
		(
			t_CODEC codec,
			Integer sampleRate,
			Integer numChannels,
			int _blockSize
		) throws Exception
	{
		if ( Build.VERSION.SDK_INT < 21)
			throw new Exception ("Need at least SDK 21");
		int channelConfig = (numChannels == 1) ? AudioFormat.CHANNEL_IN_MONO : AudioFormat.CHANNEL_IN_STEREO;
		int audioFormat = tabCodec[codec.ordinal()];
		bufferSize = AudioRecord.getMinBufferSize
			(
				sampleRate,
				channelConfig,
				tabCodec[codec.ordinal()]
			) ;// !!!!! * 2 ???


		recorder = new AudioRecord(
			MediaRecorder.AudioSource.MIC,
			sampleRate,
			channelConfig,
			audioFormat,
			bufferSize
		);

		if (recorder.getState() == AudioRecord.STATE_INITIALIZED)
		{
			recorder.startRecording();
			isRecording = true;
			assert (thePollingThread == null);
			thePollingThread = new _pollingRecordingData();
			thePollingThread.start();
		} else
		{
			throw new Exception("Cannot initialize the AudioRecord");
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
		mSession = theSession;
		startPlayerSide(sampleRate, numChannels, blockSize);
		startRecorderSide(Flauto.t_CODEC.pcm16, sampleRate, numChannels, blockSize);
	}


	void _stop()
	{

		if (null != recorder)
		{
			try
			{
				recorder.stop();
			} catch ( Exception e )
			{
			}

			try
			{
				isRecording = false;
				recorder.release();
			} catch ( Exception e )
			{
			}
			recorder = null;
		}

		if (audioTrack != null)
		{
			audioTrack.stop();
			audioTrack.release();
			audioTrack = null;
		}
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
		Log.e( TAG, "setVolume: not implemented" );
	}


	void _seekTo(long millisec)
	{
		Log.e( TAG, "seekTo: not implemented" );
	}


	boolean _isPlaying()
	{
		return audioTrack.getPlayState () == AudioTrack.PLAYSTATE_PLAYING;
	}


	long _getDuration()
	{
		return 0;
	}


	long _getCurrentPosition()
	{
		return 0;
	}

	int feed(byte[] data) throws Exception
	{
		Log.e( TAG, "feed error: not implemented");
		return -1;
	}

}
