package xyz.canardoux.fluttersound;
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


import android.content.Context;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;


class FlutterSoundRecorderManager extends FlutterSoundManager
        implements MethodCallHandler
{

        static Context              androidContext;
        static FlutterSoundRecorderManager flutterSoundRecorderPlugin; // singleton


        static final String ERR_UNKNOWN               = "ERR_UNKNOWN";
        static final String ERR_RECORDER_IS_NULL      = "ERR_RECORDER_IS_NULL";
        static final String ERR_RECORDER_IS_RECORDING = "ERR_RECORDER_IS_RECORDING";


        public static void attachFlautoRecorder ( Context ctx, BinaryMessenger messenger )
        {
                if (flutterSoundRecorderPlugin == null) {
                        flutterSoundRecorderPlugin = new FlutterSoundRecorderManager();
                }
                MethodChannel channel = new MethodChannel ( messenger, "xyz.canardoux.flutter_sound_recorder" );
                flutterSoundRecorderPlugin.init( channel);
                channel.setMethodCallHandler ( flutterSoundRecorderPlugin );
                androidContext = ctx;
        }



        FlutterSoundRecorderManager getManager ()
        {
                return flutterSoundRecorderPlugin;
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

                FlutterSoundRecorder aRecorder = (FlutterSoundRecorder) getSession( call);
                switch ( call.method )
                {
                        case "openRecorder":
                        {
                                aRecorder = new FlutterSoundRecorder ( call );
                                initSession( call, aRecorder );
                                aRecorder.openRecorder ( call, result );
                        }
                        break;

                        case "closeRecorder":
                        {
                                aRecorder.closeRecorder ( call, result );
                        }
                        break;

                        case "isEncoderSupported":
                        {
                                aRecorder.isEncoderSupported ( call, result );
                        }
                        break;


                        case "startRecorder":
                        {
                                aRecorder.startRecorder ( call, result );
                        }
                        break;

                        case "stopRecorder":
                        {
                                aRecorder.stopRecorder ( call, result );
                        }
                        break;


                        case "setSubscriptionDuration":
                        {
                                aRecorder.setSubscriptionDuration ( call, result );
                        }
                        break;

                        case "pauseRecorder":
                        {
                                aRecorder.pauseRecorder ( call, result );
                        }
                        break;


                        case "resumeRecorder":
                        {
                                aRecorder.resumeRecorder ( call, result );
                        }
                        break;

                        case "getRecordURL":
                        {
                                aRecorder.getRecordURL ( call, result );
                        }
                        break;

                        case "deleteRecord":
                        {
                                aRecorder.deleteRecord ( call, result );
                        }
                        break;

                        case "setLogLevel":
                        {
                                aRecorder.setLogLevel ( call, result );
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


