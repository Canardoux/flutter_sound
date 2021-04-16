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





#import "FlutterSoundPlayer.h"
#import "FlutterSoundPlayerManager.h"
//#import "FlautoTrackPlayer.h"
#import <AVFoundation/AVFoundation.h>




//--------------------------------------------------------------------------------------------



@implementation FlutterSoundPlayerManager
{
}

FlutterSoundPlayerManager* flutterSoundPlayerManager = nil; // Singleton


+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar
{
        FlutterMethodChannel* aChannel = [FlutterMethodChannel methodChannelWithName:@"com.dooboolab.flutter_sound_player"
                                        binaryMessenger:[registrar messenger]];
        if (flutterSoundPlayerManager != nil)
                NSLog(@"ERROR during registerWithRegistrar: flutterSoundPlayerManager != nil");
        flutterSoundPlayerManager = [[FlutterSoundPlayerManager alloc] init];
        flutterSoundPlayerManager ->channel = aChannel;
        [registrar addMethodCallDelegate: flutterSoundPlayerManager channel: aChannel];
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
         //NSLog(@"IOS:--> rcv: %@", call.method);

        if ([@"openPlayer" isEqualToString:call.method])
        {
                aFlautoPlayer = [[FlutterSoundPlayer alloc] init: call];
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

        if ([@"setAudioFocus" isEqualToString:call.method])
        {
                [aFlautoPlayer setAudioFocus: call result: result];
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

        if ([@"startPlayerFromTrack" isEqualToString: call.method])
        {
                 [aFlautoPlayer startPlayerFromTrack: call result: result];
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
                NSNumber* volume = (NSNumber*)call.arguments[@"volume"];
                [aFlautoPlayer setVolume: [volume doubleValue] result: result];
        } else

        if ([@"iosSetCategory" isEqualToString:call.method])
        {
                [aFlautoPlayer setCategory: call result: result];
        } else

        if ([@"setActive" isEqualToString:call.method])
        {
                [aFlautoPlayer setActive: call result: result];
        } else

        if ( [@"getResourcePath" isEqualToString:call.method] )
        {
                result( [[NSBundle mainBundle] resourcePath]);
        } else

        if ([@"setUIProgressBar" isEqualToString:call.method])
        {
                 [aFlautoPlayer setUIProgressBar: call result: result];
        } else

        if ([@"nowPlaying" isEqualToString:call.method])
        {
                 [aFlautoPlayer nowPlaying: call result: result];
        } else

        if ([@"getProgress" isEqualToString:call.method])
        {
                 [aFlautoPlayer getProgress: call result: result];
        } else
        
        if ([@"feed" isEqualToString: call.method])
        {
                 [aFlautoPlayer feed: call result: result];
        } else


        {
                result(FlutterMethodNotImplemented);
        }
         //NSLog(@"IOS:<-- rcv: %@", call.method);
}

@end
