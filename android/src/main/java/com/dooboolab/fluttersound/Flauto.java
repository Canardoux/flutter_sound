package com.dooboolab.fluttersound;
import com.dooboolab.ffmpeg.FlutterFFmpegPlugin;
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

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;

import android.app.Activity;
import android.content.Context;

import androidx.annotation.NonNull;


import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.PluginRegistry.Registrar;


// this enum MUST be synchronized with lib/flutter_sound.dart and ios/Classes/FlutterSoundPlugin.h
enum FlutterSoundCodec
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
}

public class Flauto
	implements FlutterPlugin,
	           ActivityAware
{
    public static final boolean FULL_FLAVOR = true;
	static Context ctx;
	static Registrar reg;
	static Activity androidActivity;


	@Override
	public void onAttachedToEngine ( FlutterPlugin.FlutterPluginBinding binding )
	{
		ctx = binding.getApplicationContext ();

		//androidActivity = ???

		FlautoPlayerPlugin.attachFlautoPlayer ( ctx, binding.getBinaryMessenger () );
		FlautoRecorderPlugin.attachFlautoRecorder ( ctx, binding.getBinaryMessenger () );
		//TrackPlayerPlugin.attachTrackPlayer ( ctx, binding.getBinaryMessenger () );
        if (FULL_FLAVOR) {FlutterFFmpegPlugin.attachFFmpegPlugin( ctx, binding.getBinaryMessenger() );}
	}


	/**
	 * Plugin registration.
	 */
	public static void registerWith ( Registrar registrar )
	{
		reg = registrar;
		ctx = registrar.context ();
		androidActivity = registrar.activity ();

		FlautoPlayerPlugin.attachFlautoPlayer ( ctx, registrar.messenger () );
		FlautoRecorderPlugin.attachFlautoRecorder ( ctx, registrar.messenger ()  );
		//TrackPlayerPlugin.attachTrackPlayer ( ctx, registrar.messenger ()  );
        if (FULL_FLAVOR) {FlutterFFmpegPlugin.attachFFmpegPlugin(ctx,registrar.messenger ()  );}

	}


	@Override
	public void onDetachedFromEngine ( FlutterPlugin.FlutterPluginBinding binding )
	{
	}

	@Override
	public void onDetachedFromActivity ()
	{
	}

	@Override
	public void onReattachedToActivityForConfigChanges (
		@NonNull
			ActivityPluginBinding binding
	                                                   )
	{

	}

	@Override
	public void onDetachedFromActivityForConfigChanges ()
	{

	}

	@Override
	public void onAttachedToActivity (
		@NonNull
			ActivityPluginBinding binding
	                                 )
	{
		androidActivity = binding.getActivity ();
	}


}
