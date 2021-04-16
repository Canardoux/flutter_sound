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


import android.content.pm.PackageManager;
import android.media.MediaRecorder;
import android.os.Build;
import android.util.Log;
import androidx.core.content.ContextCompat;
import java.io.IOException;
import com.dooboolab.TauEngine.Flauto.t_CODEC;
import static android.Manifest.permission.RECORD_AUDIO;


public class FlautoRecorderMedia
	implements FlautoRecorderInterface
{
	final static String             TAG                = "SoundMediaRecorder";

	static int codecArray[] =
	{
		MediaRecorder.AudioEncoder.DEFAULT,
		MediaRecorder.AudioEncoder.AAC,
		MediaRecorder.AudioEncoder.OPUS,
		0, // CODEC_CAF_OPUS (specific Apple)
		0,// CODEC_MP3 (not implemented)
		MediaRecorder.AudioEncoder.VORBIS,
		7, // MediaRecorder.AudioEncoder.DEFAULT // CODEC_PCM (not implemented)
		0, // wav
		0, // aiff
		0, // pcmCAF
		0, // flac
		MediaRecorder.AudioEncoder.AAC, // aacMP4
		MediaRecorder.AudioEncoder.AMR_NB,
		MediaRecorder.AudioEncoder.AMR_WB,
		0, // pcm8
		0, // pcmFloat32
		0, // pcmWebM
		MediaRecorder.AudioEncoder.OPUS, // opusWebM
		MediaRecorder.AudioEncoder.VORBIS, // vorbisWebM
	};



	static int formatsArray[] =
	{
		MediaRecorder.OutputFormat.DEFAULT // DEFAULT
		, MediaRecorder.OutputFormat.AAC_ADTS // CODEC_AAC
		, MediaRecorder.OutputFormat.OGG // CODEC_OPUS
		, 0 // CODEC_CAF_OPUS (this is apple specific)
		, 0 // CODEC_MP3
		, MediaRecorder.OutputFormat.OGG // CODEC_VORBIS
		, 0 //ENCODING_PCM_16BIT// CODEC_PCM
		, 0 // wav
		, 0 // aiff
		, 0 // pcmCAF
		, 0 // flac
		, MediaRecorder.OutputFormat.MPEG_4 // aacMP4
		, MediaRecorder.OutputFormat.AMR_NB
		, MediaRecorder.OutputFormat.AMR_WB
		, 0 // pcm8
		, 0 // pcmFloat32
		, MediaRecorder.OutputFormat.WEBM // pcmWebM
		, MediaRecorder.OutputFormat.WEBM // opusWebM
		, MediaRecorder.OutputFormat.WEBM // vorbisWebM
	};

	static       String pathArray[]               =
	{
		"sound.fs" // DEFAULT
		, "sound.aac" // CODEC_AAC
		, "sound.opus" // CODEC_OPUS
		, "sound_opus.caf" // CODEC_CAF_OPUS (this is apple specific)
		, "sound.mp3" // CODEC_MP3
		, "sound.ogg" // CODEC_VORBIS
		, "sound.pcm" // CODEC_PCM
		, "sound.wav" // pcm16WAV
		, "sound.aiff" // pcm16AIFF
		, "sound_pcm.caf" // pcm16CAF
		, "sound.flac" // flac
		, "sound.mp4" // aacMP4
		, "sound.amr" // amrNB
		, "sound.amr" // amrWB
		, "sound.pcm" // pcm8
		, "sound.pcm" // pcmFloat32
		, "sound.webm" // pcmWebM
		, "sound.opus" // opusWebM
		, "sound.vorbis" // vorbisWebM

	};


	MediaRecorder mediaRecorder;

	public boolean CheckPermissions()
	{
		//int result = ContextCompat.checkSelfPermission(getApplicationContext(), WRITE_EXTERNAL_STORAGE);
		int result1 = ContextCompat.checkSelfPermission(Flauto.androidContext, RECORD_AUDIO);
		return result1 == PackageManager.PERMISSION_GRANTED;
	}


	public void _startRecorder
		(
			Integer numChannels,
			Integer sampleRate,
			Integer bitRate,
			t_CODEC codec,
			String path,
			int audioSource,
			FlautoRecorder session
                )
		throws
		IOException, Exception
	{
		// The caller must be allowed to specify its path. We must not change it here
		// path = PathUtils.getDataDirectory(reg.context()) + "/" + path; // SDK 29 :
		// you may not write in getExternalStorageDirectory()

		if ( mediaRecorder != null )
		{
			mediaRecorder.reset ();
		} else
		{
			mediaRecorder = new MediaRecorder ();
		}

		if (!CheckPermissions())
		{
			throw new Exception("Check Permission: Recording permission is not granted");
		}

		try
		{
			mediaRecorder.reset();
			mediaRecorder.setAudioSource (audioSource );
			int androidEncoder      = codecArray[ codec.ordinal () ];
			int androidOutputFormat = formatsArray[ codec.ordinal () ];
			mediaRecorder.setOutputFormat ( androidOutputFormat );

			if ( path == null )
			{
				path = pathArray[ codec.ordinal () ];
			}

			mediaRecorder.setOutputFile ( path );
			mediaRecorder.setAudioEncoder ( androidEncoder );

			if ( numChannels != null )
			{
				mediaRecorder.setAudioChannels ( numChannels );
			}

			if ( sampleRate != null )
			{
				mediaRecorder.setAudioSamplingRate ( sampleRate );
			}

			// If bitrate is defined, then use it, otherwise use the OS default
			if ( bitRate != null )
			{
				mediaRecorder.setAudioEncodingBitRate ( bitRate );
			}

			mediaRecorder.prepare ();
			mediaRecorder.start ();

		}
		catch ( Exception e )
		{
			Log.e ( TAG, "Exception: ", e );
			//
			try
			{
				_stopRecorder( );

			} catch (Exception e2)
			{

			}
			throw(e);
		}
	}

	public void _stopRecorder (  )
	{
		// This remove all pending runnables

		if ( mediaRecorder == null )
		{
			Log.d ( TAG, "mediaRecorder is null" );
			return ;
		}
		try
		{
			if ( Build.VERSION.SDK_INT >= 24 )
			{

				try
				{
					mediaRecorder.resume(); // This is stupid, but cannot reset() if Pause Mode !
				}
				catch ( Exception e )
				{
				}
			}
			mediaRecorder.stop();
			mediaRecorder.reset();
			mediaRecorder.release();
			mediaRecorder = null;
		} catch  ( Exception e )
		{
			Log.d ( TAG, "Error Stop Recorder" );

		}
	}


	public boolean pauseRecorder(  )
	{
		if ( mediaRecorder == null )
		{
			Log.d ( TAG, "mediaRecorder is null" );

			return false;
		}
		if ( Build.VERSION.SDK_INT < 24 )
		{
			Log.d ( TAG, "\"Pause/Resume needs at least Android API 24\"");
			return false;
		} else
		{
			mediaRecorder.pause();
			return true;
		}
	}


	public boolean resumeRecorder( )
	{
		if ( mediaRecorder == null )
		{
			Log.d ( TAG, "mediaRecorder is null" );
			//result.error ( TAG, "Recorder is closed", "\"Recorder is closed\"" );
			return false;
		}
		if ( Build.VERSION.SDK_INT < 24 )
		{
			Log.d ( TAG, "\"Pause/Resume needs at least Android API 24\"");
			//result.error ( TAG, "Bad Android API level", "\"Pause/Resume needs at least Android API 24\"" );
			return false;
		} else
		{
			mediaRecorder.resume();

			return true;
		}
	}
	public double getMaxAmplitude ()
	{
		return mediaRecorder.getMaxAmplitude();
	}

}
