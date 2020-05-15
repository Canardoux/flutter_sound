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


public class AudioSessionManager
{
	public MethodChannel            channel;
	public List<Session> slots;

	void init(MethodChannel aChannel)
	{
		assert ( slots == null );
		slots   = new ArrayList<Session>();
		channel = aChannel;
	}


	void invokeMethod ( String methodName, Map dic )
	{
		//Log.d(TAG, "FlutterAutoPlugin: invokeMethod" + methodName);
		channel.invokeMethod ( methodName, dic );
	}

	void freeSlot ( int slotNo )
	{
		slots.set ( slotNo, null );
	}


	Session getSession(final MethodCall call)
	{
		int slotNo = call.argument ( "slotNo" );
		assert ( ( slotNo >= 0 ) && ( slotNo <= slots.size () ) );

		if ( slotNo == slots.size () )
		{
			slots.add ( slotNo, null );
		}

		return slots.get ( slotNo );
	}

	void initSession( final MethodCall call, Session aPlayer)
	{
		int slot =  call.argument ( "slotNo" );
		slots.set ( slot, aPlayer );
		aPlayer.init( slot );

	}

}
