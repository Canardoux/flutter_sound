package xyz.canardoux.fluttersound;
/*
 * Copyright 2018, 2019, 2020, 2021 Canardoux.
 *
 * This file is part of Flutter-Sound.
 *
 * Flutter-Sound is free software: you can redistribute it and/or modify
 * it under the terms of the Mozilla Public License version 2 (MPL2.0),
 * as published by the Mozilla organization.
 *
 * Flutter-Sound is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * MPL General Public License for more details.
 *
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/.
 */

import android.app.Activity;
import android.content.Context;
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
//import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import xyz.canardoux.TauEngine.Flauto;

public class FlutterSound
	implements FlutterPlugin,
	           ActivityAware
{
	FlutterPlugin.FlutterPluginBinding pluginBinding;

	@Override
	public void onAttachedToEngine ( FlutterPlugin.FlutterPluginBinding binding )
	{
		this.pluginBinding = binding;

		new MethodChannel(binding.getBinaryMessenger(), "xyz.canardoux.flutter_sound_bgservice").setMethodCallHandler(new MethodCallHandler() {
			@Override
			public void onMethodCall ( final MethodCall call, final Result result )
			{
				if (call.method.equals("setBGService")) {
					attachFlauto();
				}
				result.success(0);
			}
		});
	}


	/**
	 * Plugin registration.
	 */
	/*
	public static void registerWith ( Registrar registrar )
	{
		if (registrar.activity() == null) {
			return;
		}
		Flauto.androidContext = registrar.context ();
		Flauto.androidActivity = registrar.activity ();

		FlutterSoundPlayerManager.attachFlautoPlayer ( Flauto.androidContext, registrar.messenger () );
		FlutterSoundRecorderManager.attachFlautoRecorder ( Flauto.androidContext, registrar.messenger ()  );
	}

	 */


	@Override
	public void onDetachedFromEngine ( FlutterPlugin.FlutterPluginBinding binding )
	{
	}

	@Override
	public void onDetachedFromActivity ()
	{
		//Flauto.androidActivity = null;
	}

	@Override
	public void onReattachedToActivityForConfigChanges (
		@NonNull
			ActivityPluginBinding binding
	                                                   )
	{
		//Flauto.androidActivity = binding.getActivity ();
	}

	@Override
	public void onDetachedFromActivityForConfigChanges ()
	{
		//Flauto.androidActivity = null;
	}

	@Override
	public void onAttachedToActivity (
			@NonNull
			ActivityPluginBinding binding
	)
	{
		//Flauto.androidActivity = binding.getActivity ();
		attachFlauto();
	}

	public void attachFlauto() {
		Flauto.androidContext = pluginBinding.getApplicationContext ();
		FlutterSoundPlayerManager.attachFlautoPlayer ( Flauto.androidContext, pluginBinding.getBinaryMessenger () );
		FlutterSoundRecorderManager.attachFlautoRecorder ( Flauto.androidContext, pluginBinding.getBinaryMessenger () );
	}


}
