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



import android.media.AudioFormat;
import android.media.AudioRecord;
import android.media.MediaRecorder;

import java.io.FileOutputStream;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.nio.ByteBuffer;


public class FlutterSoundAudioRecorder
	implements RecorderInterface
{
	private AudioRecord recorder = null;
	private Thread recordingThread = null;
	private boolean isRecording = false;
	private double maxAmplitude = 0;
	//int BufferElements2Rec = 1024; // want to play 2048 (2K) since 2 bytes we use only 1024
	//int BytesPerElement = 2; // 2 bytes in 16bit format


	//private static final int CHANNEL_CONFIG = AudioFormat.CHANNEL_IN_MONO;

	//private static final int AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT;



	//convert short to byte
	private byte[] short2byte(short[] sData)
	{
		int shortArrsize = sData.length;
		byte[] bytes = new byte[shortArrsize * 2];
		for (int i = 0; i < shortArrsize; i++) {
			bytes[i * 2] = (byte) (sData[i] & 0x00FF);
			bytes[(i * 2) + 1] = (byte) (sData[i] >> 8);
			sData[i] = 0;
		}
		return bytes;

	}


	private short getShort(byte argB1, byte argB2) {
		return (short)(argB1 | (argB2 << 8));
	}

	private void writeAudioDataToFile(FlutterSoundCodec codec, int sampleRate, String filePath, int bufferSize) throws IOException
	{
		// Write the output audio in byte

		byte[] tempBuffer = new byte[bufferSize];

		FileOutputStream os = null;
		os = new FileOutputStream(filePath);

		if (codec == FlutterSoundCodec.pcm16WAV)
		{
			WaveHeader header = new WaveHeader
				(
					WaveHeader.FORMAT_PCM,
					(short)1, // numChannels
					sampleRate,
					(short)16,
					100000 // total number of bytes

				);
			header.write( os);
		}
		int              totalBytes = 0;
		final ByteBuffer buffer     = ByteBuffer.allocateDirect( bufferSize );
		int n = 0;
		while (isRecording || n > 0)
		{
			// gets the voice output from microphone to byte format
			n = recorder.read(tempBuffer, 0, bufferSize);

			if (n > 0)
			{
				totalBytes += n;
				os.write(tempBuffer, 0, n);
				for (int i = 0; i < n/2; ++i)
				{
					short curSample = getShort( tempBuffer[ i * 2 ], tempBuffer[ i * 2 + 1 ] );
					if ( curSample > maxAmplitude )
					{
						maxAmplitude = curSample;
					}
				}
			} else
			if (n == AudioRecord.ERROR_INVALID_OPERATION || n ==
				AudioRecord.ERROR_BAD_VALUE || n == 0)
			{
				continue;
			} else
			{
				break;
			}

		}

		os.close();
		if (codec == FlutterSoundCodec.pcm16WAV)
		{
			RandomAccessFile fh = new RandomAccessFile( filePath, "rw" );
			fh.seek( 4 );
			int x = totalBytes + 36;
			fh.write( x >> 0 );
			fh.write( x >> 8 );
			fh.write( x >> 16 );
			fh.write( x >> 24 );


			fh.seek( WaveHeader.HEADER_LENGTH - 4 );
			fh.write( totalBytes >> 0 );
			fh.write( totalBytes >> 8 );
			fh.write( totalBytes >> 16 );
			fh.write( totalBytes >> 24 );
			fh.close();
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



	public void _startRecorder
		(
			Integer numChannels,
			Integer sampleRate,
			Integer bitRate,
			FlutterSoundCodec codec,
			String path,
			int audioSource
		)
	{
		/**
		 * Size of the buffer where the audio data is stored by Android
		 */
		int channelConfig = (numChannels == 1) ? AudioFormat.CHANNEL_IN_MONO : AudioFormat.CHANNEL_IN_STEREO;
		int audioFormat = tabCodec[codec.ordinal()];
		int bufferSize = AudioRecord.getMinBufferSize(sampleRate,
		                                              channelConfig, tabCodec[codec.ordinal()]) * 2;


		recorder = new AudioRecord( audioSource,
		                            sampleRate,
		                            channelConfig,
		                            audioFormat,
		                            bufferSize);

		recorder.startRecording();
		isRecording = true;
		recordingThread = new Thread(new Runnable()
		{
			public void run()
			{
				try
				{
					writeAudioDataToFile(codec, sampleRate, path, bufferSize);
				} catch (IOException e)
				{
					e.printStackTrace();
				}
			}
		}, "AudioRecorder Thread");
		recordingThread.start();
	}

	public void _stopRecorder (  )
	{
		if (null != recorder)
		{
			try
			{
				recorder.stop();
				isRecording = false;
				recordingThread.join();
				recorder.release();
				recorder = null;
				recordingThread = null;
			} catch ( Exception e )
			{

			}
		}
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
