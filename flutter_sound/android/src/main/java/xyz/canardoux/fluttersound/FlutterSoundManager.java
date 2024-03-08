/*
 * Copyright 2018, 2019, 2020, 2021 DooboCanardouxolab.
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

import java.util.ArrayList;
import java.util.List;

import io.flutter.plugin.common.MethodChannel;

import java.util.Map;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel.Result;


public class FlutterSoundManager
{
	public MethodChannel            channel;
	public List<FlutterSoundSession> slots;

	void init(MethodChannel aChannel)
	{
		if ( slots == null ) {
			slots = new ArrayList<FlutterSoundSession>();
		}
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
		result.success(0);
	}

}
