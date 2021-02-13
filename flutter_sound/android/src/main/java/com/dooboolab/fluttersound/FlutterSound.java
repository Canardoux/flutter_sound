package com.dooboolab.fluttersound;
import com.dooboolab.ffmpeg.FlutterSoundFFmpeg;
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


import android.app.Activity;
import android.content.Context;
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;

import com.dooboolab.TauEngine.Flauto;

public class FlutterSound
	implements FlutterPlugin,
	           ActivityAware
{
    public static final boolean FULL_FLAVOR = true;
	//static Context ctx;
	//static Registrar reg;
	//static Activity androidActivity;
	FlutterPlugin.FlutterPluginBinding pluginBinding;

	@Override
	public void onAttachedToEngine ( FlutterPlugin.FlutterPluginBinding binding )
	{
		this.pluginBinding = binding;
	}


	/**
	 * Plugin registration.
	 */
	public static void registerWith ( Registrar registrar )
	{
		if (registrar.activity() == null) {
			return;
		}
		//reg = registrar;
		Flauto.androidContext = registrar.context ();
		Flauto.androidActivity = registrar.activity ();

		FlutterSoundPlayerManager.attachFlautoPlayer ( Flauto.androidContext, registrar.messenger () );
		FlutterSoundRecorderManager.attachFlautoRecorder ( Flauto.androidContext, registrar.messenger ()  );
        if (FULL_FLAVOR) { FlutterSoundFFmpeg.attachFFmpegPlugin( Flauto.androidContext, registrar.messenger ()  ); }
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
		Flauto.androidActivity = binding.getActivity ();

		// Only register if activity exists (the application is not running in background)
		Flauto.androidContext = pluginBinding.getApplicationContext ();
		FlutterSoundPlayerManager.attachFlautoPlayer ( Flauto.androidContext, pluginBinding.getBinaryMessenger () );
		FlutterSoundRecorderManager.attachFlautoRecorder ( Flauto.androidContext, pluginBinding.getBinaryMessenger () );
        if (FULL_FLAVOR) { FlutterSoundFFmpeg.attachFFmpegPlugin( Flauto.androidContext, pluginBinding.getBinaryMessenger () ); }
	}


}
