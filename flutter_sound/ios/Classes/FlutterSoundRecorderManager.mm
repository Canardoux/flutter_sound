//
//  SoundRecorder.m
//  flauto
//
//  Created by larpoux on 24/03/2020.
//
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





#import <tau_core/FlautoRecorder.h>
#import <AVFoundation/AVFoundation.h>
#import <Flutter/Flutter.h>
#import "FlutterSoundRecorder.h"
#import "FlutterSoundRecorderManager.h"



extern void FlutterSoundRecorderReg(NSObject<FlutterPluginRegistrar>* registrar)
{
        [FlutterSoundRecorderManager registerWithRegistrar: registrar];
}



//---------------------------------------------------------------------------------------------

@implementation FlutterSoundRecorderManager
{
}

FlutterSoundRecorderManager* flutterSoundRecorderManager = nil; // Singleton


+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar
{
        FlutterMethodChannel* aChannel = [FlutterMethodChannel methodChannelWithName:@"com.dooboolab.flutter_sound_recorder"
                                        binaryMessenger:[registrar messenger]];
        if (flutterSoundRecorderManager != nil)
                NSLog(@"ERROR during registerWithRegistrar: flutterSoundRecorderManager != nil");
        flutterSoundRecorderManager = [[FlutterSoundRecorderManager alloc] init];
        flutterSoundRecorderManager ->channel = aChannel;
        [registrar addMethodCallDelegate: flutterSoundRecorderManager channel:aChannel];
}


- (FlutterSoundRecorderManager*)init
{
        self = [super init];
        return self;
}




- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result
{
        if ([@"resetPlugin" isEqualToString:call.method])
        {
                NSLog (@"@resetPlugin");
                [self resetPlugin: call result: result];
                return;
        }

        FlutterSoundRecorder* aFlautoRecorder = (FlutterSoundRecorder*)[ self getSession: call];
 
        if ([@"openRecorder" isEqualToString: call.method])
        {
                NSLog(@"@openRecorder");
                aFlautoRecorder = [[FlutterSoundRecorder alloc] init: call];
                [aFlautoRecorder openRecorder: call result: result];
        } else
        
        if ([@"setAudioFocus" isEqualToString: call.method])
        {
                [aFlautoRecorder setAudioFocus: call result:result];
        } else

        
         
        if ([@"closeRecorder" isEqualToString: call.method])
        {
                if (aFlautoRecorder != [NSNull null])
                        [aFlautoRecorder closeRecorder: call result: result];
        } else
         
        if ([@"isEncoderSupported" isEqualToString:call.method])
        {
                NSNumber* codec = (NSNumber*)call.arguments[@"codec"];
                [aFlautoRecorder isEncoderSupported: (t_CODEC)[codec intValue] result:result];
        } else
        
        if ([@"startRecorder" isEqualToString: call.method])
        {
                     [aFlautoRecorder startRecorder: call result:result];
        } else
        
        if ([@"stopRecorder" isEqualToString: call.method])
        {
                [aFlautoRecorder stopRecorder: result];
        } else
        
         
        if ([@"setSubscriptionDuration" isEqualToString: call.method])
        {
                //NSNumber* sec = (NSNumber*)call.arguments[@"sec"];
                [aFlautoRecorder setSubscriptionDuration: call result:result];
        } else
        
        if ([@"pauseRecorder" isEqualToString: call.method])
        {
                [aFlautoRecorder pauseRecorder: call result:result];
        } else
        
        if ([@"resumeRecorder" isEqualToString: call.method])
        {
                [aFlautoRecorder resumeRecorder: call result:result];
        } else
        
        if ([@"getRecordURL" isEqualToString: call.method])
        {
                [aFlautoRecorder getRecordURL: call result:result];
        } else
        
        if ([@"deleteRecord" isEqualToString: call.method])
        {
                [aFlautoRecorder deleteRecord: call result:result];
        } else
        
        {
                result(FlutterMethodNotImplemented);
        }
}


@end
//---------------------------------------------------------------------------------------------
