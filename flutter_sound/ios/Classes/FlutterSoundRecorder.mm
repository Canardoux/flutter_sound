//
//  AudioRecorder.m
//  flutter_sound
//
//  Created by larpoux on 02/05/2020.
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




#import <Foundation/Foundation.h>

#import "FlutterSoundRecorder.h"
#import <tau_core/FlautoRecorder.h>


@implementation FlutterSoundRecorder
{
}

// ----------------------------------------------  callback ---------------------------------------------------------------------------


- (void)updateRecorderProgressDbPeakLevel: normalizedPeakLevel duration: duration;
{
        NSDictionary* dico = @{ @"slotNo": [NSNumber numberWithInt: slotNo], @"status": [NSNumber numberWithInt: -1], @"dbPeakLevel": normalizedPeakLevel, @"duration": duration};
        [self invokeMethod:@"updateRecorderProgress" dico: dico ];
}
 
- (void)recordingData: (NSData*)data
{
        NSDictionary* dico = @{ @"slotNo": [NSNumber numberWithInt: slotNo],  @"status": [NSNumber numberWithInt: -1], @"recordingData": data};
        [self invokeMethod:@"recordingData" dico: dico ];
  
}

- (void)startRecorderCompleted: (bool)success
{
        [self invokeMethod: @"startRecorderCompleted" boolArg: success success: success];
}

- (void)stopRecorderCompleted: (NSString*)path success: (bool)success
{
       [self invokeMethod: @"stopRecorderCompleted" stringArg: path success: success];

}

- (void)resumeRecorderCompleted: (bool)success
{
        [self invokeMethod: @"resumeRecorderCompleted" boolArg: success success: success];

}

- (void)pauseRecorderCompleted: (bool)success
{
        [self invokeMethod: @"pauseRecorderCompleted" boolArg: success success: success];

}

- (void)openRecorderCompleted: (bool)success
 {
       [self invokeMethod: @"openRecorderCompleted" boolArg: success success: success];
 
 }
 
 
- (void)closeRecorderCompleted: (bool)success
 {
       [self invokeMethod: @"closeRecorderCompleted" boolArg: success success: success];
 
 }

 /*
- (void)setDbPeakLevelUpdate:(double)intervalInSecs result: (FlutterResult)result
{
       [self invokeMethod: @"setDbPeakLevelUpdate" boolArg: false]; // TODO!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

}
*/

// ------------------------------------------------------------------------------------------------------------------------------------

- (FlutterSoundRecorder*)init: (FlutterMethodCall*)call
{
        flautoRecorder = [ [FlautoRecorder alloc] init: self];
        return [super init: call]; // Init Session
}

-(FlutterSoundRecorderManager*) getPlugin
{
        return flutterSoundRecorderManager;
}

- (void)openRecorder : (FlutterMethodCall*)call result:(FlutterResult)result
{
        [self setAudioFocus: call result: result];
        [self openRecorderCompleted:  [NSNumber numberWithBool: YES]]; // It should not be here, but in tau_core !!!
        result([NSNumber numberWithInt: [self getRecorderStatus]]);
}

- (void)reset: (FlutterMethodCall*)call result: (FlutterResult)result
{
        NSLog(@"iOS ---> reset (Recorder)");
        [self closeRecorder: call result: result];
        NSLog(@"iOS <--- reset (Recorder)");
}

- (void)closeRecorder : (FlutterMethodCall*)call result:(FlutterResult)result
{
        NSLog(@"iOS ---> closeRecorder");
        [flautoRecorder releaseFlautoRecorder];
        [super releaseSession];
        //[self closeRecorderCompleted:  [NSNumber numberWithBool: YES]]; // It should not be here, but in tau_core !!!
        result([NSNumber numberWithInt: [self getRecorderStatus]]);
        NSLog(@"iOS <--- closeRecorder");
}

- (void)isEncoderSupported: (t_CODEC)codec result: (FlutterResult)result
{
        NSNumber*  b = [NSNumber numberWithBool:[ flautoRecorder isEncoderSupported: codec] ];
        result(b);
}


- (void)setAudioFocus: (FlutterMethodCall*)call result: (FlutterResult)result
{
        NSLog(@"IOS:--> setAudioFocus");
        t_AUDIO_FOCUS focus = (t_AUDIO_FOCUS)( [(NSNumber*)call.arguments[@"focus"] intValue]);
        t_SESSION_CATEGORY category = (t_SESSION_CATEGORY)( [(NSNumber*)call.arguments[@"category"] intValue]);
        t_SESSION_MODE mode = (t_SESSION_MODE)( [(NSNumber*)call.arguments[@"mode"] intValue]);
        int flags =  [(NSNumber*)call.arguments[@"flags"] intValue];
        t_AUDIO_DEVICE device = (t_AUDIO_DEVICE)( [(NSNumber*)call.arguments[@"device"] intValue]);
        BOOL r = [flautoRecorder setAudioFocus: focus category: category mode: mode audioFlags: flags audioDevice:device];
        if (r)
                result([NSNumber numberWithInt: [self getRecorderStatus]]);
        else
                [FlutterError
                                errorWithCode:@"Audio Player"
                                message:@"Open session failure"
                                details:nil];
       NSLog(@"IOS:<-- setAudioFocus");
}


- (void)startRecorder: (FlutterMethodCall*)call result:(FlutterResult)result
{
        NSString* path = (NSString*)call.arguments[@"path"];
        NSNumber* sampleRateArgs = (NSNumber*)call.arguments[@"sampleRate"];
        NSNumber* numChannelsArgs = (NSNumber*)call.arguments[@"numChannels"];
        NSNumber* bitRateArgs = (NSNumber*)call.arguments[@"bitRate"];
        NSNumber* codec = (NSNumber*)call.arguments[@"codec"];
        NSNumber* audioSourceArgs = (NSNumber*)call.arguments[@"audioSource"] ;

        t_AUDIO_SOURCE audioSource = ([audioSourceArgs isKindOfClass:[NSNull class]]) ? defaultSource : (t_AUDIO_SOURCE)[audioSourceArgs intValue];

        t_CODEC coder = aacADTS;
        if (![codec isKindOfClass:[NSNull class]])
        {
                coder = (t_CODEC)([codec intValue]);
        }

        long sampleRate = 44100;
        if (![sampleRateArgs isKindOfClass:[NSNull class]])
        {
                sampleRate = [sampleRateArgs longValue];
        }

        long bitRate = -1;
        if (![bitRateArgs isKindOfClass:[NSNull class]])
        {
                bitRate = [bitRateArgs longValue];
        }

        int numChannels = 1;
        if (![numChannelsArgs isKindOfClass:[NSNull class]])
        {
                numChannels = (int)[numChannelsArgs integerValue];
        }

        bool b =
        [
                flautoRecorder startRecorderCodec: coder
                toPath: path
                channels: numChannels
                sampleRate: sampleRate
                bitRate: bitRate
                audioSource: audioSource
        ];
        if (b)
        {
                result([NSNumber numberWithInt: [self getRecorderStatus]]);
        } else
        {
                        [FlutterError
                        errorWithCode:@"Audio Player"
                        message:@"startPlayer failure"
                        details:nil];
        }

}


- (void)stopRecorder: (FlutterResult)result
{
        NSLog(@"iOS ---> stopRecorder");
        [flautoRecorder stopRecorder];
        result([NSNumber numberWithInt: [self getRecorderStatus]]);
        NSLog(@"iOS <--- stopRecorder");
}




// post fix with _FlutterSound to avoid conflicts with common libs including path_provider
- (NSString*) GetDirectoryOfType_FlutterSound: (NSSearchPathDirectory) dir
{
        NSArray* paths = NSSearchPathForDirectoriesInDomains(dir, NSUserDomainMask, YES);
        return [paths.firstObject stringByAppendingString:@"/"];
}


- (void)setSubscriptionDuration:(FlutterMethodCall*)call result: (FlutterResult)result
{
        NSNumber* milliSec = (NSNumber*)call.arguments[@"duration"];
        [flautoRecorder setSubscriptionDuration: [milliSec longValue] ];
        result([NSNumber numberWithInt: [self getRecorderStatus]]);
}

- (void)pauseRecorder: (FlutterMethodCall*)call result: (FlutterResult)result
{
        [flautoRecorder pauseRecorder];
        result([NSNumber numberWithInt: [self getRecorderStatus]]);
}

- (void)resumeRecorder: (FlutterMethodCall*)call result: (FlutterResult)result
{
        [flautoRecorder resumeRecorder];
        result([NSNumber numberWithInt: [self getRecorderStatus]]);
}

- (void)deleteRecord: (FlutterMethodCall*)call result: (FlutterResult)result
{
        NSString* path =  (NSString*)call.arguments[@"path"];
        bool b = [flautoRecorder deleteRecord: path];
        result([NSNumber numberWithInt: [self getRecorderStatus]]);
}

- (void)getRecordURL: (FlutterMethodCall*)call result: (FlutterResult)result
{
        NSString* path =  (NSString*)call.arguments[@"path"];
        NSString* r = [flautoRecorder getRecordURL: path];
        result(r);
}


- (int)getStatus
{
        return [flautoRecorder getStatus];
}


- (int)getRecorderStatus
{
        return [self getStatus];
}


@end


//---------------------------------------------------------------------------------------------
 
