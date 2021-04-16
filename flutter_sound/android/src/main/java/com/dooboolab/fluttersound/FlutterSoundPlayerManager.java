package com.dooboolab.fluttersound;
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




import android.content.Context;
import android.media.MediaPlayer;
import android.os.Build;
import android.os.Handler;
import android.util.Log;

import android.media.AudioFocusRequest;

import java.io.File;
import java.io.FileOutputStream;
import java.util.HashMap;
import java.util.Map;
import java.util.Timer;
import java.util.TimerTask;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

class FlutterSoundPlayerManager extends FlutterSoundManager
        implements MethodCallHandler
{
        final static String TAG = "FlutterPlayerPlugin";
        static Context            androidContext;
        static FlutterSoundPlayerManager flutterSoundPlayerPlugin; // singleton


        public static void attachFlautoPlayer (
                Context ctx, BinaryMessenger messenger
        )
        {
                assert ( flutterSoundPlayerPlugin == null );
                flutterSoundPlayerPlugin = new FlutterSoundPlayerManager();
                MethodChannel channel = new MethodChannel ( messenger, "com.dooboolab.flutter_sound_player" );
                flutterSoundPlayerPlugin.init(channel);
                channel.setMethodCallHandler ( flutterSoundPlayerPlugin );
                androidContext = ctx;
        }



        FlutterSoundPlayerManager getManager ()
        {
                return flutterSoundPlayerPlugin;
        }

        @Override
        public void onMethodCall ( final MethodCall call, final Result result )
        {
                switch ( call.method )
                {
                        case "resetPlugin":
                        {
                                resetPlugin(call, result);
                                return;
                        }
                }

                FlutterSoundPlayer aPlayer = (FlutterSoundPlayer)getSession(call);
                switch ( call.method )
                {
                        case "openPlayer":
                        {
                                //int withUI = call.argument("withUI");
                                aPlayer = new FlutterSoundPlayer (call );
                                initSession( call, aPlayer);
                                aPlayer.openPlayer ( call, result );

                        }
                        break;

                        case "closePlayer":
                        {
                                aPlayer.closePlayer ( call, result );
                        }
                        break;

                        case "isDecoderSupported":
                        {
                                aPlayer.isDecoderSupported ( call, result );
                        }
                        break;

                        case "setAudioFocus":
                        {
                                aPlayer.setAudioFocus( call, result );
                        }
                        break;


                        case "getPlayerState":
                        {
                                aPlayer.getPlayerState( call, result );
                        }
                        break;

                        case "getResourcePath":
                        {
                                aPlayer.getResourcePath( call, result );
                        }
                        break;


                        case "setUIProgressBar":
                        {
                                aPlayer.setUIProgressBar( call, result );
                        }
                        break;

                        case "nowPlaying":
                        {
                                aPlayer.nowPlaying( call, result );
                        }
                        break;

                        case "getProgress":
                        {
                                aPlayer.getProgress ( call, result );
                        }
                        break;

                        case "startPlayer":
                        {
                                aPlayer.startPlayer ( call, result );
                        }
                        break;

                        case "startPlayerFromMic":
                        {
                                aPlayer.startPlayerFromMic ( call, result );
                        }
                        break;

                        case "startPlayerFromTrack":
                        {
                                aPlayer.startPlayerFromTrack ( call, result );
                        }
                        break;


                        case "stopPlayer":
                        {
                                aPlayer.stopPlayer ( call, result );
                        }
                        break;


                        case "pausePlayer":
                        {
                                aPlayer.pausePlayer ( call, result );
                        }
                        break;

                        case "resumePlayer":
                        {
                                aPlayer.resumePlayer ( call, result );
                        }
                        break;

                        case "seekToPlayer":
                        {
                                aPlayer.seekToPlayer ( call, result );
                        }
                        break;

                        case "setVolume":
                        {
                                aPlayer.setVolume ( call, result );
                        }
                        break;

                        case "setSubscriptionDuration":
                        {
                                aPlayer.setSubscriptionDuration ( call, result );
                        }
                        break;

                        case "androidAudioFocusRequest":
                        {
                                aPlayer.androidAudioFocusRequest ( call, result );
                        }
                        break;

                        case "setActive":
                        {
                                aPlayer.setActive ( call, result );
                        }
                        break;

                        case "feed":
                        {
                                aPlayer.feed ( call, result );
                        }
                        break;

                        default:
                        {
                                result.notImplemented ();
                        }
                        break;
                }
        }

}
