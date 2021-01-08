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
import android.media.MediaPlayer;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.os.SystemClock;
import android.util.Log;
import android.media.MediaRecorder;

import android.media.AudioFocusRequest;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;
import java.util.Timer;
import java.util.TimerTask;
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
	WriteBlockThread blockThread = null;
	FlautoPlayer mSession = null;

	AudioRecord recorder;
	public Handler            recordHandler   ;
	FlautoRecorderCallback m_callBack ;
	private final ExecutorService taskScheduler = Executors.newSingleThreadExecutor ();
	final private Handler          mainHandler = new Handler (Looper.getMainLooper ());

	public              int     subsDurationMillis    = 10;

	private      Runnable      recorderTicker;
	Runnable p;
	private boolean isRecording = false;



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
			int blockSize
		) throws Exception
	{
		if ( Build.VERSION.SDK_INT < 21)
			throw new Exception ("Need at least SDK 21");
		int channelConfig = (numChannels == 1) ? AudioFormat.CHANNEL_IN_MONO : AudioFormat.CHANNEL_IN_STEREO;
		int audioFormat = tabCodec[codec.ordinal()];
		int bufferSize = AudioRecord.getMinBufferSize
			(
				sampleRate,
				channelConfig,
				tabCodec[codec.ordinal()]
			) * 2;


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
			p = new Runnable() {
				@Override
				public void run() {

					if (isRecording) {
						int n = writeData(bufferSize);

					}
				}
			};
			mainHandler.post(p);
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
			blockThread = new FlautoPlayerEngineFromMic.WriteBlockThread(data);
			blockThread.start();
		}
		return ln;
	}

	int writeData(int bufferSize)
	{
		int n = 0;
		int r = 0;
		while (isRecording ) {
			//ShortBuffer shortBuffer = ShortBuffer.allocate(bufferSize/2);
			ByteBuffer byteBuffer = ByteBuffer.allocate(bufferSize);
			try {
				// gets the voice output from microphone to byte format
				if ( Build.VERSION.SDK_INT >= 23 )
				{
					//n = recorder.read(shortBuffer.array(), 0, bufferSize/2, AudioRecord.READ_NON_BLOCKING);
					n = recorder.read(byteBuffer.array(), 0, bufferSize, AudioRecord.READ_NON_BLOCKING);
/*
					for (int i = 0; i < n; ++ i)
					{
						byteBuffer.array()[2*i] = (byte)shortBuffer.array()[i];
						byteBuffer.array()[2*i+1] = (byte)(shortBuffer.array()[i] >> 8);
					}


 */
					//byteBuffer.asShortBuffer().put(shortBuffer.array(), 0, n);
					//n *= 2;

				}
				else
				{
					n = recorder.read(byteBuffer.array(), 0, bufferSize);
				}
				//System.out.println("n = " + n);
				final int ln = n;//2 * n;

				if (n > 0) {
					r += n;
					mainHandler.post(new Runnable() {
						@Override
						public void run() {

							// TODO !!!!!!!! session.recordingData(Arrays.copyOfRange(byteBuffer.array(), 0, ln));
							try {
								feed(Arrays.copyOfRange(byteBuffer.array(), 0, ln));
							}
							catch(Exception err)
							{
								Log.e( TAG, "feed error" + err.getMessage());
							}
						}
					});
				} else
				{
					break;
				}
				if ( Build.VERSION.SDK_INT < 23 ) // We must break the loop, because n is always 1024 (READ_BLOCKING_MODE)
					break;
			} catch (Exception e) {
				System.out.println(e);
				break;
			}
		}
		if (isRecording)
			mainHandler.post(p);

		return r;

	}



}
