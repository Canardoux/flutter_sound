package com.dooboolab.fluttersound;
/*
 * This file is part of Flutter-Sound (Flauto).
 *
 *   Flutter-Sound (Flauto) is free software: you can redistribute it and/or modify
 *   it under the terms of the Lesser GNU General Public License
 *   version 3 (LGPL3) as published by the Free Software Foundation.
 *
 *   Flutter-Sound (Flauto) is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the Lesser GNU General Public License
 *   along with Flutter-Sound (Flauto).  If not, see <https://www.gnu.org/licenses/>.
 */

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;

import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;
import android.media.MediaPlayer;
import android.media.MediaRecorder;
import android.media.AudioManager;
import android.os.Build;
import android.os.Handler;
import android.os.SystemClock;
import android.support.v4.media.MediaMetadataCompat;
import android.support.v4.media.session.PlaybackStateCompat;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.arch.core.util.Function;
import androidx.core.app.ActivityCompat;

import android.media.AudioFocusRequest;

import java.io.*;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;
import java.io.FileOutputStream;
import java.util.HashMap;
import java.util.Timer;
import java.util.TimerTask;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import java.util.concurrent.Callable;

import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import com.dooboolab.fluttersound.FlutterSoundPlayer;


// this enum MUST be synchronized with lib/flutter_sound.dart and ios/Classes/FlutterSoundPlugin.h
enum t_CODEC
{
  	  DEFAULT
  	, AAC
  	, OPUS
  	, CODEC_CAF_OPUS // Apple encapsulates its bits in its own special envelope : .caf instead of a regular ogg/opus (.opus). This is completely stupid, this is Apple.
  	, MP3
  	, VORBIS
  	, PCM
}

public class Flauto
	implements FlutterPlugin,
	           ActivityAware
{
	static Context ctx;
	static Registrar reg;
	static Activity androidActivity;


	@Override
	public void onAttachedToEngine ( FlutterPlugin.FlutterPluginBinding binding )
	{
		ctx = binding.getApplicationContext ();
		//audioManager = ( AudioManager ) ctx.getSystemService ( Context.AUDIO_SERVICE );
		//channel = new MethodChannel ( binding.getBinaryMessenger (), "flutter_sound" );
		//channel.setMethodCallHandler ( flutterSoundPlugin );
		FlautoPlayerPlugin.attachFlautoPlayer ( ctx, binding.getBinaryMessenger () );
		FlautoRecorderPlugin.attachFlautoRecorder ( ctx, binding.getBinaryMessenger () );
		TrackPlayerPlugin.attachTrackPlayer ( ctx, binding.getBinaryMessenger () );
	}


	/**
	 * Plugin registration.
	 */
	public static void registerWith ( Registrar registrar )
	{
		reg = registrar;
		ctx = registrar.context ();
		//flutterSoundPlugin.audioManager = (AudioManager) flutterSoundPlugin.ctx
		//.getSystemService(Context.AUDIO_SERVICE);
		//audioManager = (AudioManager) ctx.getSystemService(Context.AUDIO_SERVICE);
		//channel = new MethodChannel(registrar.messenger(), "flutter_sound");
		//channel.setMethodCallHandler(flutterSoundPlugin);
		androidActivity = registrar.activity ();
		FlautoPlayerPlugin.attachFlautoPlayer ( ctx, registrar.messenger () );
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
