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

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothProfile;
import android.content.Context;
import android.media.AudioFocusRequest;
import android.media.AudioManager;
import android.os.Build;

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



}
