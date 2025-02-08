/*
 * Copyright 2018, 2019, 2020, 2021 Dooboolab.
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




#import "FlutterSoundPlayer.h"
#import "FlutterSoundPlayerManager.h"
//#import "FlautoTrackPlayer.h"
#import <AVFoundation/AVFoundation.h>




//--------------------------------------------------------------------------------------------



@implementation FlutterSoundPlayerManager
{
        FlutterSoundPlayerManager* flutterSoundPlayerManager;
}

//FlutterSoundPlayerManager* flutterSoundPlayerManager = nil; // Singleton


+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar
{
        FlutterMethodChannel* aChannel = [FlutterMethodChannel methodChannelWithName:@"xyz.canardoux.flutter_sound_player"
                                        binaryMessenger:[registrar messenger]];
        //if (flutterSoundPlayerManager != nil)
        {
                //NSLog(@"ERROR during registerWithRegistrar: flutterSoundPlayerManager != nil");
                //assert(flutterSoundPlayerManager ->channel == aChannel);
                //return;
        }
        //if (flutterSoundPlayerManager ->channel != aChannel)
        {
                //NSLog(@"ERROR during registerWithRegistrar: flutterSoundPlayerManager ->channel != aChannel");
        }
        FlutterSoundPlayerManager* pm = [[FlutterSoundPlayerManager alloc] init];
        pm ->channel = aChannel;
        [registrar addMethodCallDelegate: pm channel: aChannel];
}


- (FlutterSoundPlayerManager*)init
{
        self = [super init];
        return self;
}

extern void FlutterSoundPlayerReg(NSObject<FlutterPluginRegistrar>* registrar)
{
        [FlutterSoundPlayerManager registerWithRegistrar: registrar];
}

- (FlutterSoundPlayerManager*)getManager
{
        return flutterSoundPlayerManager;
}


- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result
{
        if ([@"resetPlugin" isEqualToString:call.method])
        {
                [self resetPlugin: call result: result];
                return;
        }

        FlutterSoundPlayer* aFlautoPlayer = (FlutterSoundPlayer*)[ self getSession: call];

        if ([@"openPlayer" isEqualToString:call.method])
        {
                aFlautoPlayer = [[FlutterSoundPlayer alloc] init: call playerManager: self];
                //[aFlautoPlayer setPlayerManager: self];

                [aFlautoPlayer openPlayer: call result: result];
        } else

        if ([@"closePlayer" isEqualToString:call.method])
        {
                [aFlautoPlayer closePlayer: call result: result];
         } else

        if ([@"getPlayerState" isEqualToString:call.method])
        {
                [aFlautoPlayer getPlayerState: call result: result];
        } else


        if ([@"isDecoderSupported" isEqualToString:call.method])
        {
                NSNumber* codec = (NSNumber*)call.arguments[@"codec"];
                [aFlautoPlayer isDecoderSupported: (t_CODEC)[codec intValue] result: result];
        } else

        if ([@"startPlayer" isEqualToString: call.method])
        {
                [aFlautoPlayer startPlayer: call result: result];
        } else

        if ([@"startPlayerFromMic" isEqualToString: call.method])
        {
                [aFlautoPlayer startPlayerFromMic: call result: result];
        } else


        if ([@"stopPlayer" isEqualToString: call.method])
        {
                [aFlautoPlayer stopPlayer: call result: result];
        } else

        if ([@"pausePlayer" isEqualToString: call.method])
        {
                [aFlautoPlayer pausePlayer: result];
        } else

        if ([@"resumePlayer" isEqualToString: call.method])
        {
                [aFlautoPlayer resumePlayer: result];
        } else

        if ([@"seekToPlayer" isEqualToString: call.method])
        {
                //NSNumber* sec = (NSNumber*)call.arguments[@"sec"];
                [aFlautoPlayer seekToPlayer: call result: result];
        } else

        if ([@"setSubscriptionDuration" isEqualToString:call.method])
        {
                //NSNumber* sec = (NSNumber*)call.arguments[@"sec"];
                [aFlautoPlayer setSubscriptionDuration: call result: result];
        } else

        if ([@"setVolume" isEqualToString:call.method])
        {
                NSNumber* volume = (NSNumber*)call.arguments[@"volume"]; // Between 0.0 and 1.0
                NSNumber* fadeDuration = (NSNumber*)call.arguments[@"fadeDuration"]; // in milliseconds
                [aFlautoPlayer setVolume: [volume doubleValue] fadeDuration: [fadeDuration  doubleValue]/1000.0 result: result];
        } else

        if ([@"setVolumePan" isEqualToString:call.method])
        {
                NSNumber* volume = (NSNumber*)call.arguments[@"volume"]; // Between 0.0 and 1.0
                NSNumber* pan = (NSNumber*)call.arguments[@"pan"]; // Between -1.0 and 1.0
                NSNumber* fadeDuration = (NSNumber*)call.arguments[@"fadeDuration"]; // in milliseconds
                [aFlautoPlayer setVolumePan: [volume doubleValue] pan: [pan doubleValue] fadeDuration: [fadeDuration  doubleValue]/1000.0 result: result];
        } else

        if ([@"setSpeed" isEqualToString:call.method])
        {
                NSNumber* speed = (NSNumber*)call.arguments[@"speed"]; // Between 0.0 and 1.0
                [aFlautoPlayer setSpeed: [speed doubleValue] result: result];
        } else


        if ( [@"getResourcePath" isEqualToString:call.method] )
        {
                result( [[NSBundle mainBundle] resourcePath]);
        } else

 
        if ([@"getProgress" isEqualToString:call.method])
        {
                 [aFlautoPlayer getProgress: call result: result];
        } else
        
        if ([@"feed" isEqualToString: call.method])
        {
                 [aFlautoPlayer feed: call result: result];
        } else

        if ([@"feedFloat32" isEqualToString: call.method])
        {
                 [aFlautoPlayer feedFloat32: call result: result];
        } else

        if ([@"feedInt16" isEqualToString: call.method])
        {
                 [aFlautoPlayer feedInt16: call result: result];
        } else

        if ([@"setLogLevel" isEqualToString: call.method])
        {
                 [aFlautoPlayer setLogLevel: call result: result];
        } else


        {
                result(FlutterMethodNotImplemented);
        }
}

@end
