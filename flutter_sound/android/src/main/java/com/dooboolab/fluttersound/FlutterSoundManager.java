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


package com.dooboolab.fluttersound;

import java.util.ArrayList;
import java.util.List;

import io.flutter.plugin.common.MethodChannel;


import android.content.Context;
import android.media.MediaPlayer;
import android.media.AudioManager;
import android.os.Build;
import android.os.Environment;
import android.os.Handler;
import android.util.Log;

import android.media.AudioFocusRequest;

import org.json.JSONObject;

import java.io.File;
import java.io.FileOutputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Timer;
import java.util.TimerTask;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;


public class FlutterSoundManager
{
	public MethodChannel            channel;
	public List<FlutterSoundSession> slots;

	void init(MethodChannel aChannel)
	{
		if ( slots != null )
			throw new RuntimeException();
		slots   = new ArrayList<FlutterSoundSession>();
		channel = aChannel;
	}


	void invokeMethod ( String methodName, Map dic )
	{
		channel.invokeMethod ( methodName, dic );
	}

	void freeSlot ( int slotNo )
	{
		slots.set ( slotNo, null );
	}


	public FlutterSoundSession getSession(final MethodCall call)
	{
		int slotNo = call.argument ( "slotNo" );
		if ( ( slotNo < 0 ) || ( slotNo > slots.size () ) )
			throw new RuntimeException();

		if ( slotNo == slots.size () )
		{
			slots.add ( slotNo, null );
		}

		return slots.get ( slotNo );
	}

	public void initSession( final MethodCall call, FlutterSoundSession aPlayer)
	{
		int slot =  call.argument ( "slotNo" );
		slots.set ( slot, aPlayer );
		aPlayer.init( slot );
	}
	
	public void resetPlugin( final MethodCall call, final Result result )
	{
		for (int i = 0; i < slots.size () ; ++i)
		{
			if (slots.get ( i ) != null)
			{
				slots.get ( i ).reset(call, result);
			}
			slots   = new ArrayList<FlutterSoundSession>();
		}
		result.success(true);
	}

}
