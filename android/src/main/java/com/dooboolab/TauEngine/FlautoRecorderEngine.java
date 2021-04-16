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


import android.media.AudioFormat;
import android.media.AudioRecord;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;

import java.io.FileOutputStream;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.nio.ByteBuffer;
import java.nio.ShortBuffer;
import java.util.HashMap;
import java.util.Map;
import java.util.Arrays;

import com.dooboolab.TauEngine.Flauto.*;


public class FlautoRecorderEngine
	implements FlautoRecorderInterface
{
	private AudioRecord recorder = null;
	//private Thread recordingThread = null;
	private boolean isRecording = false;
	private double maxAmplitude = 0;
	String filePath;
	int totalBytes = 0;
	t_CODEC codec;
	Runnable p;
	FlautoRecorder session = null;
	FileOutputStream outputStream = null;
	final private Handler mainHandler = new Handler (Looper.getMainLooper ());




	private short getShort(byte argB1, byte argB2) {
		return (short)(argB1 | (argB2 << 8));
	}

	private void writeAudioDataToFile(t_CODEC codec, int sampleRate, String aFilePath) throws IOException
	{
		// Write the output audio in byte
		System.out.println("---> writeAudioDataToFile");
		totalBytes = 0;
		outputStream = null;
		filePath = aFilePath;
		if (filePath != null)
		{
			outputStream = new FileOutputStream(filePath);

			if (codec == t_CODEC.pcm16WAV) {
				FlautoWaveHeader header = new FlautoWaveHeader
					(
						FlautoWaveHeader.FORMAT_PCM,
						(short) 1, // numChannels
						sampleRate,
						(short) 16,
						100000 // total number of bytes

					);
				header.write(outputStream);
			}
		}
		System.out.println("<--- writeAudioDataToFile");
	}

	void closeAudioDataFile(String filepath) throws Exception
	{

		if (outputStream != null) {
			outputStream.close();
			if (codec == t_CODEC.pcm16WAV) {
				RandomAccessFile fh = new RandomAccessFile(filePath, "rw");
				fh.seek(4);
				int x = totalBytes + 36;
				fh.write(x >> 0);
				fh.write(x >> 8);
				fh.write(x >> 16);
				fh.write(x >> 24);


				fh.seek(FlautoWaveHeader.HEADER_LENGTH - 4);
				fh.write(totalBytes >> 0);
				fh.write(totalBytes >> 8);
				fh.write(totalBytes >> 16);
				fh.write(totalBytes >> 24);
				fh.close();
			}
		}

	}

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
					totalBytes += n;
					r += n;
					if (outputStream != null) {
						//System.out.println("Writing : n = " + n);
						outputStream.write(byteBuffer.array(), 0, ln);
					} else {
						mainHandler.post(new Runnable() {
							@Override
							public void run() {

								session.recordingData(Arrays.copyOfRange(byteBuffer.array(), 0, ln));
							}
						});
					}
					for (int i = 0; i < n / 2; ++i) {
						short curSample = getShort(byteBuffer.array()[i * 2], byteBuffer.array()[i * 2 + 1]);
						if (curSample > maxAmplitude) {
							maxAmplitude = curSample;
						}
					}
				//} else if (n == AudioRecord.ERROR_INVALID_OPERATION || n ==
					//AudioRecord.ERROR_BAD_VALUE || n == 0) {
					//continue;
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


	public void _startRecorder
		(
			Integer numChannels,
			Integer sampleRate,
			Integer bitRate,
			t_CODEC theCodec,
			String path,
			int audioSource,
			FlautoRecorder theSession

		) throws Exception
	{
		if ( Build.VERSION.SDK_INT < 21)
			throw new Exception ("Need at least SDK 21");
		session = theSession;
		codec = theCodec;
		int channelConfig = (numChannels == 1) ? AudioFormat.CHANNEL_IN_MONO : AudioFormat.CHANNEL_IN_STEREO;
		int audioFormat = tabCodec[codec.ordinal()];
		int bufferSize = AudioRecord.getMinBufferSize
			(
				sampleRate,
			      	channelConfig,
				tabCodec[codec.ordinal()]
			) * 2;


		recorder = new AudioRecord( 	audioSource,
						sampleRate,
						channelConfig,
		                            	audioFormat,
		                            	bufferSize
					);

		if (recorder.getState() == AudioRecord.STATE_INITIALIZED)
		{
			recorder.startRecording();
			isRecording = true;
			try {
				writeAudioDataToFile(codec, sampleRate, path);
			} catch (Exception e) {
				e.printStackTrace();
			}
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

	public void _stopRecorder (  ) throws Exception
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
		closeAudioDataFile(filePath);
	}

	public boolean pauseRecorder( )
	{
		try
		{
			recorder.stop();
			return true;
		} catch(Exception e)
		{
			e.printStackTrace();
			return false;
		}
	}

	public boolean resumeRecorder(  )
	{
		try
		{
			recorder.startRecording();
			return true;
		} catch(Exception e)
		{
			e.printStackTrace();
			return false;
		}
	}

	public double getMaxAmplitude ()
	{
		double r = maxAmplitude;
		maxAmplitude = 0;
		return r;
	}

}
