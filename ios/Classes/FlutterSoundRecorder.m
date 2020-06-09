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





#import "FlutterSoundRecorder.h"
#import "AudioRecorder.h"
//#import "Flauto.h" // Just to register it
#import <AVFoundation/AVFoundation.h>



//FlutterMethodChannel* _flautoRecorderChannel;




//---------------------------------------------------------------------------------------------

@implementation FlautoRecorderManager
{
        //NSMutableArray* flautoRecorderSlots;
}

FlautoRecorderManager* flautoRecorderManager; // Singleton


+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar
{
        FlutterMethodChannel* aChannel = [FlutterMethodChannel methodChannelWithName:@"com.dooboolab.flutter_sound_recorder"
                                        binaryMessenger:[registrar messenger]];
        assert (flautoRecorderManager == nil);
        flautoRecorderManager = [[FlautoRecorderManager alloc] init];
        flautoRecorderManager ->channel = aChannel;
        [registrar addMethodCallDelegate:flautoRecorderManager channel:aChannel];
}


- (FlautoRecorderManager*)init
{
        self = [super init];
        //flautoRecorderSlots = [[NSMutableArray alloc] init];
        return self;
}

extern void FlautoRecorderReg(NSObject<FlutterPluginRegistrar>* registrar)
{
        [FlautoRecorderManager registerWithRegistrar: registrar];
}



- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result
{
        FlutterSoundRecorder* aFlautoRecorder = (FlutterSoundRecorder*)[ self getSession: call];
 
        if ([@"initializeFlautoRecorder" isEqualToString:call.method])
        {
                aFlautoRecorder = [[FlutterSoundRecorder alloc] init: call];
                [aFlautoRecorder initializeFlautoRecorder: call result:result];
        } else
        
        if ([@"setAudioFocus" isEqualToString:call.method])
        {
                [aFlautoRecorder setAudioFocus: call result:result];
        } else

        
         
        if ([@"releaseFlautoRecorder" isEqualToString:call.method])
        {
                [aFlautoRecorder releaseFlautoRecorder:call result:result];
        } else
         
        if ([@"isEncoderSupported" isEqualToString:call.method])
        {
                NSNumber* codec = (NSNumber*)call.arguments[@"codec"];
                [aFlautoRecorder isEncoderSupported:[codec intValue] result:result];
        } else
        
        if ([@"startRecorder" isEqualToString:call.method])
        {
                     [aFlautoRecorder startRecorder:call result:result];
        } else
        
        if ([@"stopRecorder" isEqualToString:call.method])
        {
                [aFlautoRecorder stopRecorder: result];
        } else
        
         
        if ([@"setSubscriptionDuration" isEqualToString:call.method])
        {
                //NSNumber* sec = (NSNumber*)call.arguments[@"sec"];
                [aFlautoRecorder setSubscriptionDuration:call result:result];
        } else
        
        if ([@"pauseRecorder" isEqualToString:call.method])
        {
                [aFlautoRecorder pauseRecorder:call result:result];
        } else
        
        if ([@"resumeRecorder" isEqualToString:call.method])
        {
                [aFlautoRecorder resumeRecorder:call result:result];
        } else
        
        {
                result(FlutterMethodNotImplemented);
        }
}


@end
//---------------------------------------------------------------------------------------------
