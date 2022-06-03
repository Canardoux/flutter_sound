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
#import <AVFoundation/AVFoundation.h>
#import <flutter_sound_core/FlautoPlayer.h>
#import "FlutterSoundPlayerManager.h"
         
 
//-------------------------------------------------------------------------------------------------------------------------------

@implementation FlutterSoundPlayer
{
}

// ----------------------------------------------  callback ---------------------------------------------------------------------------

- (void)openPlayerCompleted: (bool)success
{
       [self invokeMethod: @"openPlayerCompleted" boolArg: success success: success];
}


- (void)closePlayerCompleted: (bool)success
{
       [self invokeMethod: @"closePlayerCompleted" boolArg: success success: success];
}


- (void)startPlayerCompleted: (bool)success duration: (long)duration
{
     
        int d = (int)duration;
        NSNumber* nd = [NSNumber numberWithInt: d];
        NSDictionary* dico = @{ @"slotNo": [NSNumber numberWithInt: slotNo], @"state":  [self getPlayerStatus], @"duration": nd, @"success": @YES };
        [self invokeMethod:@"startPlayerCompleted" dico: dico ];
}

- (void)pausePlayerCompleted: (bool)success
{
       [self invokeMethod: @"pausePlayerCompleted" boolArg: success success: success];
}

- (void)resumePlayerCompleted: (bool)success
{
       [self invokeMethod: @"resumePlayerCompleted" boolArg: success success: success];
}


- (void)stopPlayerCompleted: (bool)success
{
       [self invokeMethod: @"stopPlayerCompleted" boolArg: success success: success];
}



- (void)needSomeFood: (int) ln
{
        [self invokeMethod:@"needSomeFood" numberArg: [NSNumber numberWithInt: ln]  success: @YES ];
}

- (void)updateProgressPosition: (long)position duration: (long)duration
{
                NSNumber* p = [NSNumber numberWithLong: position];
                NSNumber* d = [NSNumber numberWithLong: duration];
                NSDictionary* dico = @{ @"slotNo": [NSNumber numberWithInt: self ->slotNo], @"state": [self getPlayerStatus], @"position": p, @"duration": d, @"playerStatus": [self getPlayerStatus] };
                [self invokeMethod:@"updateProgress" dico: dico  ];
}

- (void)audioPlayerDidFinishPlaying: (BOOL)flag
{
        [self log: DBG msg: @"IOS:--> @audioPlayerDidFinishPlaying"];
        [self invokeMethod:@"audioPlayerFinishedPlaying" numberArg: [self getPlayerStatus] success: YES];
        [self log: DBG msg: @"IOS:<-- @audioPlayerDidFinishPlaying"];
}

- (void)pause
{
        [self invokeMethod:@"pause" numberArg: [self getPlayerStatus] success: @YES ];
}

- (void)resume
{
        [self invokeMethod:@"resume" numberArg: [self getPlayerStatus]  success: @YES ];
}

- (void)skipForward
{
        [self invokeMethod:@"skipForward" numberArg: [self getPlayerStatus]  success: @YES ];

}

- (void)skipBackward
{
        [self invokeMethod:@"skipBackward" numberArg: [self getPlayerStatus]  success: @YES ];

}


// --------------------------------------------------------------------------------------------------------------------------

// BE CAREFUL : TrackPlayer must instance FlautoTrackPlayer !!!!!
- (FlutterSoundPlayer*)init: (FlutterMethodCall*)call  playerManager: (FlutterSoundPlayerManager*)pm
{
        flautoPlayer = [ [FlautoPlayer alloc] init: self];
        flutterSoundPlayerManager = pm;
        bool voiceProcessing = [[call.arguments[@"voiceProcessing"] description] isEqualToString: @"1"];
        [flautoPlayer setVoiceProcessing: voiceProcessing];
        return [super init: call]; // Init Session
}

- (void)setPlayerManager: (FlutterSoundPlayerManager*)pm
{
        flutterSoundPlayerManager = pm;
}


//- (FlutterSoundPlayer*) init
//{
//        return [super init];
//}

- (void)isDecoderSupported:(t_CODEC)codec result: (FlutterResult)result
{
        [self log: DBG msg: @"IOS:--> isDecoderSupported"];

        NSNumber*  b = [NSNumber numberWithBool:[ flautoPlayer isDecoderSupported: codec] ];
        result(b);
        [self log: DBG msg: @"IOS:<-- isDecoderSupported"];
}



-(FlutterSoundPlayerManager*) getPlugin
{
        return flutterSoundPlayerManager;
}


- (void)openPlayer: (FlutterMethodCall*)call result: (FlutterResult)result
{
        [self log: DBG msg: @"IOS:--> initializeFlautoPlayer"];
        [self openPlayerCompleted: YES];
        result( [self getPlayerStatus]);
        [self log: DBG msg: @"IOS:<-- initializeFlautoPlayer"];
}


- (void)reset: (FlutterMethodCall*)call result: (FlutterResult)result
{
        [self log: DBG msg: @"IOS:--> reset (Player)"];
        [self closePlayer: call result: result];
        result([NSNumber numberWithInt: 0]);
        [self log: DBG msg: @"IOS:<-- reset (Player)"];
}

- (void)closePlayer: (FlutterMethodCall*)call result: (FlutterResult)result
{
        [self log: DBG msg: @"IOS:--> releaseFlautoPlayer"];
        [flautoPlayer releaseFlautoPlayer];
        [super releaseSession];
        result([self getPlayerStatus]);
        [self log: DBG msg: @"IOS:<-- releaseFlautoPlayer"];

}


- (void)stopPlayer:(FlutterMethodCall*)call  result:(FlutterResult)result
{
        [self log: DBG msg: @"IOS:--> stopPlayer"];
        [flautoPlayer stopPlayer];
        NSNumber* status = [self getPlayerStatus];
        result(status);
        [self log: DBG msg: @"IOS:<-- stopPlayer"];
}



- (void)getPlayerState:(FlutterMethodCall*)call result: (FlutterResult)result
{
                result([self getPlayerStatus]);
}




- (void)startPlayer:(FlutterMethodCall*)call result: (FlutterResult)result
{
        [self log: DBG msg: @"IOS:--> startPlayer"];
        NSString* path = (NSString*)call.arguments[@"fromURI"];
        NSNumber* numChannels = (NSNumber*)call.arguments[@"numChannels"];
        NSNumber* sampleRate = (NSNumber*)call.arguments[@"sampleRate"];
        t_CODEC codec = (t_CODEC)([(NSNumber*)call.arguments[@"codec"] intValue]);
        FlutterStandardTypedData* dataBuffer = (FlutterStandardTypedData*)call.arguments[@"fromDataBuffer"];
        NSData* data = nil;
        if ([dataBuffer class] != [NSNull class])
                data = [dataBuffer data];
        int channels = ([numChannels class] != [NSNull class]) ? [numChannels intValue] : 1;
        long samplerateLong = ([sampleRate class] != [NSNull class]) ? [sampleRate longValue] : 44000;
  
        bool b =
        [
                flautoPlayer startPlayerCodec: codec
                fromURI: path
                fromDataBuffer: data
                channels: channels
                sampleRate: samplerateLong
        ];
        if (b)
        {
                        NSNumber* status = [self getPlayerStatus];
                        result(status);
        } else
        {
                        result(
                        [FlutterError
                        errorWithCode:@"Audio Player"
                        message:@"startPlayer failure"
                        details:nil]);
        }
        [self log: DBG msg: @"IOS:<-- startPlayer"];
}


- (void)startPlayerFromMic:(FlutterMethodCall*)call result: (FlutterResult)result
{
        [self log: DBG msg: @"IOS:--> startPlayerFromMic"];
        NSNumber* numChannels = (NSNumber*)call.arguments[@"numChannels"];
        NSNumber* sampleRate = (NSNumber*)call.arguments[@"sampleRate"];
        long samplerateLong = ([sampleRate class] != [NSNull class]) ? [sampleRate longValue] : 44000;
        int channels = ([numChannels class] != [NSNull class]) ? [numChannels intValue] : 1;
        bool b =
        [
                flautoPlayer startPlayerFromMicSampleRate: samplerateLong
                nbChannels: channels
        ];
        if (b)
        {
                result([self getPlayerStatus]);
        } else
        {
                        result([FlutterError
                        errorWithCode:@"Audio Player"
                        message:@"startPlayerFromMic failure"
                        details:nil]);
        }
        [self log: DBG msg: @"IOS:<-- startPlayer"];
}

     

- (void)pausePlayer:(FlutterResult)result
{
        [self log: DBG msg: @"IOS:--> pausePlayer"];

        if ([flautoPlayer pausePlayer])
        {
                result([self getPlayerStatus]);
        } else
        {
                       result([FlutterError
                                  errorWithCode:@"Audio Player"
                                  message:@"audioPlayer pause failure"
                                  details:nil]);

        }
        [self log: DBG msg: @"IOS:<-- pausePlayer"];

}

- (void)resumePlayer:(FlutterResult)result
{
        [self log: DBG msg: @"IOS:--> resumePlayer"];

        if ([flautoPlayer resumePlayer])
        {
                result([self getPlayerStatus]);
        } else
        {
                       result([FlutterError
                                  errorWithCode:@"Audio Player"
                                  message:@"audioPlayer resumePlayer failure"
                                  details:nil]);

        }
        [self log: DBG msg: @"IOS:<-- resumePlayer"];
}



- (void)feed:(FlutterMethodCall*)call result: (FlutterResult)result
{
                int r = -1;
                FlutterStandardTypedData* x = call.arguments[ @"data" ] ;
                assert ([x elementSize] == 1);
                NSData* data = [x data];
                assert ([data length] == [x elementCount]);
                r = [flautoPlayer feed: data];
                if (r >= 0)
                {
			result([NSNumber numberWithInt: r]);
                } else
                {
                        result([FlutterError
                                errorWithCode:@"feed"
                                message:@"error"
                                details:nil]);
                
                }

}

- (void)seekToPlayer:(FlutterMethodCall*)call result: (FlutterResult)result
{
                [self log: DBG msg: @"IOS:--> seekToPlayer"];

                NSNumber* milli = (NSNumber*)(call.arguments[@"duration"]);
                long t = [milli longValue];
                [flautoPlayer seekToPlayer: t];
                result([self getPlayerStatus]);
                [self log: DBG msg: @"IOS:<-- seekToPlayer"];

}

- (void)setVolume:(double) volume  fadeDuration: (double)fadeDuration result: (FlutterResult)result // Volume is between 0.0 and 1.0
{
                [self log: DBG msg: @"IOS:--> setVolume"];

                [flautoPlayer setVolume: volume fadeDuration: fadeDuration];
                result([self getPlayerStatus]);
                [self log: DBG msg: @"IOS:<-- setVolume"];
}

- (void)setSpeed:(double) speed  result: (FlutterResult)result // speed is 0.0 to 1.0 to slow and 1.0 to n to speed
{
        [self log: DBG msg: @"IOS:--> setSpeed"];

        [flautoPlayer setSpeed: speed];
        result([self getPlayerStatus]);
        [self log: DBG msg: @"IOS:<-- setSpeed"];

}


- (void)getProgress:(FlutterMethodCall*)call result: (FlutterResult)result
{
        [self log: DBG msg: @"IOS:--> getProgress"];
        NSDictionary* dico = [flautoPlayer getProgress];
        result(dico);
        [self log: DBG msg: @"IOS:--> getProgress"];

}


- (void)setSubscriptionDuration:(FlutterMethodCall*)call  result: (FlutterResult)result
{
        [self log: DBG msg: @"IOS:--> setSubscriptionDuration"];
        NSNumber* milliSec = (NSNumber*)call.arguments[@"duration"];
        [flautoPlayer setSubscriptionDuration: [milliSec longValue]];
        result([self getPlayerStatus]);
        [self log: DBG msg: @"IOS:<-- setSubscriptionDuration"];
}


// post fix with _FlutterSound to avoid conflicts with common libs including path_provider
- (NSString*) GetDirectoryOfType_FlutterSound: (NSSearchPathDirectory) dir
{
        NSArray* paths = NSSearchPathForDirectoriesInDomains(dir, NSUserDomainMask, YES);
        return [paths.firstObject stringByAppendingString:@"/"];
}



- (int)getStatus
{
         return [flautoPlayer getStatus];
}

- (NSNumber*)getPlayerStatus
{
        return [NSNumber numberWithInt: [self getStatus]];
}


- (void)setLogLevel: (FlutterMethodCall*)call result: (FlutterResult)result
{
    //TODO
}

@end
//---------------------------------------------------------------------------------------------

