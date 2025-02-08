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

package xyz.canardoux.fluttersound;

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothProfile;
import android.content.Context;
import android.media.AudioFocusRequest;
import android.media.AudioManager;
import android.os.Build;
import xyz.canardoux.TauEngine.Flauto.*;


import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;




public abstract class FlutterSoundSession
{
	int slotNo;

	void init( int slot)
	{
		slotNo = slot;
	}

	abstract FlutterSoundManager getPlugin ();

	void releaseSession()
	{
		getPlugin().freeSlot(slotNo);
	}

	abstract int getStatus();

	abstract void reset(final MethodCall call, final MethodChannel.Result result);

	void invokeMethodWithString ( String methodName, boolean success, String arg )
	{
		Map<String, Object> dic = new HashMap<String, Object>();
		dic.put ( "slotNo", slotNo );
		dic.put ( "state", getStatus() );
		dic.put ( "arg", arg );
		dic.put ( "success", success );
		getPlugin ().invokeMethod ( methodName, dic );
	}

	void invokeMethodWithDouble ( String methodName, boolean success, double arg )
	{
		Map<String, Object> dic = new HashMap<String, Object> ();
		dic.put ( "slotNo", slotNo );
		dic.put ( "state", getStatus() );
		dic.put ( "arg", arg );
		dic.put ( "success", success );
		getPlugin ().invokeMethod ( methodName, dic );
	}


	void invokeMethodWithInteger ( String methodName, boolean success, int arg )
	{
		Map<String, Object> dic = new HashMap<String, Object> ();
		dic.put ( "slotNo", slotNo );
		dic.put ( "state", getStatus() );
		dic.put ( "arg", arg );
		dic.put ( "success", success );
		getPlugin ().invokeMethod ( methodName, dic );
	}


	void invokeMethodWithBoolean ( String methodName, boolean success, boolean arg )
	{
		Map<String, Object> dic = new HashMap<String, Object> ();
		dic.put ( "slotNo", slotNo );
		dic.put ( "state", getStatus() );
		dic.put ( "arg", arg );
		dic.put ( "success", success );
		getPlugin ().invokeMethod ( methodName, dic );
	}

	void invokeMethodWithMap ( String methodName, boolean success, Map<String, Object>  dic )
	{
		dic.put ( "slotNo", slotNo );
		dic.put ( "state", getStatus() );
		dic.put ( "success", success );
		getPlugin ().invokeMethod ( methodName, dic );
	}

	public void log(t_LOG_LEVEL level, String msg)
	{
		int[] levelToEnum =
				{
						999, //VERBOSE,
						2000, //DBG,
						3000, //INFO,
						4000, //WARNING,
						5000, //ERROR,
						5999, //WTF,
						9999, //NOTHING,
				};
		Map<String, Object> dic = new HashMap<String, Object> ();
		dic.put ( "slotNo", slotNo );
		dic.put ( "state", getStatus() );
		dic.put ( "level", levelToEnum[level.ordinal()] );
		dic.put ("msg", "[android]: " + msg);
		dic.put ( "success", true );
		getPlugin ().invokeMethod ( "log", dic );

	}

}
