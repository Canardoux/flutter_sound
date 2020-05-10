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
 * it under the terms of the GNU General Public License version 3, as published by
 * the Free Software Foundation.
 *
 * Flutter-Sound is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Flutter-Sound.  If not, see <https://www.gnu.org/licenses/>.
 */




#import "FlutterSoundRecorder.h"
#import "AudioRecorder.h"
#import "flauto.h" // Just to register it
#import <AVFoundation/AVFoundation.h>



//FlutterMethodChannel* _flautoRecorderChannel;

static FlutterMethodChannel* _channel;



//---------------------------------------------------------------------------------------------

@implementation FlautoRecorderManager
{
        NSMutableArray* flautoRecorderSlots;
}

FlautoRecorderManager* flautoRecorderManager; // Singleton


+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar
{
        _channel = [FlutterMethodChannel methodChannelWithName:@"com.dooboolab.flutter_sound_recorder"
                                        binaryMessenger:[registrar messenger]];
        assert (flautoRecorderManager == nil);
        flautoRecorderManager = [[FlautoRecorderManager alloc] init];
        [registrar addMethodCallDelegate:flautoRecorderManager channel:_channel];
}


- (FlautoRecorderManager*)init
{
        self = [super init];
        flautoRecorderSlots = [[NSMutableArray alloc] init];
        return self;
}

extern void FlautoRecorderReg(NSObject<FlutterPluginRegistrar>* registrar)
{
        [FlautoRecorderManager registerWithRegistrar: registrar];
}



- (void)invokeMethod: (NSString*)methodName arguments: (NSDictionary*)call
{
        [_channel invokeMethod: methodName arguments: call ];
}


- (void)freeSlot: (int)slotNo
{
        flautoRecorderSlots[slotNo] = [NSNull null];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result
{
        int slotNo = [call.arguments[@"slotNo"] intValue];
        assert ( (slotNo >= 0) && (slotNo <= [flautoRecorderSlots count]));
        if (slotNo == [flautoRecorderSlots count])
        {
                 [flautoRecorderSlots addObject: [NSNull null] ];
        }
        FlutterSoundRecorder* aFlautoRecorder = flautoRecorderSlots[slotNo];
        
        if ([@"initializeFlautoRecorder" isEqualToString:call.method])
        {
                assert (flautoRecorderSlots[slotNo] ==  [NSNull null] );
                aFlautoRecorder = [[FlutterSoundRecorder alloc] init: slotNo];
                flautoRecorderSlots[slotNo] =aFlautoRecorder;
                [aFlautoRecorder initializeFlautoRecorder: call result:result];
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
        
        if ([@"setDbPeakLevelUpdate" isEqualToString:call.method])
        {
                NSNumber* intervalInSecs = (NSNumber*)call.arguments[@"intervalInSecs"];
                [aFlautoRecorder setDbPeakLevelUpdate:[intervalInSecs doubleValue] result:result];
        } else
        
        if ([@"setDbLevelEnabled" isEqualToString:call.method])
        {
                BOOL enabled = [call.arguments[@"enabled"] boolValue];
                [aFlautoRecorder setDbLevelEnabled:enabled result:result];
        } else
        
        if ([@"setSubscriptionDuration" isEqualToString:call.method])
        {
                NSNumber* sec = (NSNumber*)call.arguments[@"sec"];
                [aFlautoRecorder setSubscriptionDuration:[sec doubleValue] result:result];
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
