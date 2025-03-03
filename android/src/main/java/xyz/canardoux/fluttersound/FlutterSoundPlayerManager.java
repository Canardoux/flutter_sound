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



import android.content.Context;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import xyz.canardoux.fluttersound.FlutterSoundManager;

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
                if (flutterSoundPlayerPlugin == null) {
                        flutterSoundPlayerPlugin = new FlutterSoundPlayerManager();
                }
                MethodChannel channel = new MethodChannel ( messenger, "xyz.canardoux.flutter_sound_player" );
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

                        case "setVolumePan":
                        {
                                aPlayer.setVolumePan ( call, result );
                        }                        
                        break;

                        case "setSpeed":
                        {
                                aPlayer.setSpeed ( call, result );
                        }
                        break;

                        case "setSubscriptionDuration":
                        {
                                aPlayer.setSubscriptionDuration ( call, result );
                        }
                        break;


                        case "feedInt16":
                        {
                                aPlayer.feedInt16 ( call, result );
                        } break;

                        case "feed":
                        {
                                aPlayer.feed ( call, result );
                        } break;

                        case "feedFloat32":
                        {
                                aPlayer.feedFloat32 ( call, result );
                        }
                        break;


                        case "setLogLevel":
                        {
                                aPlayer.setLogLevel ( call, result );
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
