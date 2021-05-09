//
//  FlautoManager.m
//  flutter_sound
//
//  Created by larpoux on 14/05/2020.
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
#import "FlutterSoundManager.h"
#import <tau_core/Flauto.h>


@implementation FlutterSoundManager
{
        NSMutableArray* flautoPlayerSlots;
}

- (FlutterSoundManager*)init
{
        self = [super init];
        flautoPlayerSlots = [[NSMutableArray alloc] init];
        return self;
}

- (int) initPlugin: (Session*) session call:(FlutterMethodCall*)call
{
        int slotNo = [call.arguments[@"slotNo"] intValue];
        assert ( (slotNo >= 0) && (slotNo < [flautoPlayerSlots count]));
        assert (flautoPlayerSlots[slotNo] ==  [NSNull null] );
        flautoPlayerSlots[slotNo] = session;
        return slotNo;
}

- (void)freeSlot: (int)slotNo
{
        flautoPlayerSlots[slotNo] = [NSNull null];
        [flautoPlayerSlots replaceObjectAtIndex:slotNo withObject:[NSNull null]];
}

- (Session*)getSession: (FlutterMethodCall*)call
{

        int slotNo = [call.arguments[@"slotNo"] intValue];
        assert ( (slotNo >= 0) && (slotNo <= [flautoPlayerSlots count]));
        
        if (slotNo == [flautoPlayerSlots count])
        {
               [flautoPlayerSlots addObject: [NSNull null]];
        }

        return  flautoPlayerSlots[slotNo];
}


- (void)invokeMethod: (NSString*)methodName arguments: (NSDictionary*)call
{
        [channel invokeMethod: methodName arguments: call ];
}


- (void) resetPlugin: (FlutterMethodCall*)call result: (FlutterResult)result
{
        NSLog (@"iOS: ---> resetPlugin");
        for (int i = 0; i < [flautoPlayerSlots count]; ++i)
        {
                if ( flautoPlayerSlots[i] != [NSNull null] )
                {
                        NSLog (@"iOS: calling reset");
                        Session* session =  flautoPlayerSlots[i];
                        [ session reset: call result: result];
                }
        }
        flautoPlayerSlots = [[NSMutableArray alloc] init];
        result( [NSNumber numberWithInt: 0]);
        NSLog (@"iOS: <--- resetPlugin");
}

@end



//-------------------------------------------------------------------------------------------------------------------------------------------------------



@implementation Session
{
  
}


-(FlutterSoundManager*) getPlugin
{
        return nil; // Implented in subclass
}

- (Session*) init: (FlutterMethodCall*)call
{
        slotNo = [[self getPlugin] initPlugin: self call: call];
        hasFocus = FALSE;
        return [super init];
}

- (int) getSlotNo
{
        return slotNo;
}

- (void) releaseSession
{
        NSLog(@"iOS: ---> releaseSession");
        if (hasFocus)
                [[AVAudioSession sharedInstance]  setActive: FALSE error:nil] ;
        hasFocus = false;
 
        [[self getPlugin]freeSlot: slotNo];
        NSLog(@"iOS: <--- releaseSession");
  
}

- (void)invokeMethod: (NSString*)methodName stringArg: (NSString*)stringArg success: (bool)success
{
        NSObject* obj = stringArg;
        if (obj == nil)
                obj = [NSNull null];
        NSDictionary* dic =
        @{
                @"slotNo": [NSNumber numberWithInt: slotNo],
                @"arg": obj,
                @"state": [NSNumber numberWithInt:([self getStatus])],
                @"success": [NSNumber numberWithBool: success]
                
        };
        NSLog(@"iOS: invokeMethod %@ - state=%i", methodName, [self getStatus]);
        [[self getPlugin] invokeMethod: methodName arguments: dic ];
}


- (void)invokeMethod: (NSString*)methodName dico: (NSDictionary*)dico
{
        //[dico setObject:[NSNumber numberWithInt: slotNo] forKey:@"slotNo"];
        [[self getPlugin] invokeMethod: methodName arguments: dico ];
}


- (void)invokeMethod: (NSString*)methodName boolArg: (Boolean)boolArg success: (bool)success
{
        NSDictionary* dic =
        @{
                @"slotNo": [NSNumber numberWithInt: slotNo],
                @"arg": [NSNumber numberWithBool: boolArg] ,
                @"state": [NSNumber numberWithInt:([self getStatus])],
                @"success": [NSNumber numberWithBool: success]
        };
        NSLog(@"iOS: invokeMethod %@ - state=%i", methodName, [self getStatus]);
        [[self getPlugin] invokeMethod: methodName arguments: dic ];
}


- (void)invokeMethod: (NSString*)methodName numberArg: (NSNumber*)arg success: (bool)success
{
        NSDictionary* dic =
        @{
                @"slotNo": [NSNumber numberWithInt: slotNo],
                @"arg": arg,
                @"state": [NSNumber numberWithInt:([self getStatus])],
                @"success": [NSNumber numberWithBool: success]
        };
        NSLog(@"iOS: invokeMethod %@ - state=%i", methodName, [self getStatus]);
        [[self getPlugin] invokeMethod: methodName arguments: dic ];
}


- (BOOL)setAudioFocus: (FlutterMethodCall*)call
{


        NSString* tabCategory[] =
        {
                AVAudioSessionCategoryAmbient,
                AVAudioSessionCategoryMultiRoute,
                AVAudioSessionCategoryPlayAndRecord,
                AVAudioSessionCategoryPlayback,
                AVAudioSessionCategoryRecord,
                AVAudioSessionCategorySoloAmbient,
                // DEPRECATED // AVAudioSessionCategoryAudioProcessing
        };
        
        
        NSString*  tabSessionMode[] =
        {
                AVAudioSessionModeDefault,
                AVAudioSessionModeGameChat,
                AVAudioSessionModeMeasurement,
                AVAudioSessionModeMoviePlayback,
                AVAudioSessionModeSpokenAudio,
                AVAudioSessionModeVideoChat,
                AVAudioSessionModeVideoRecording,
                AVAudioSessionModeVoiceChat,
                // ONLY iOS 12.0 // AVAudioSessionModeVoicePrompt,
        };



        BOOL r = TRUE;
        t_AUDIO_FOCUS audioFocus = (t_AUDIO_FOCUS) [call.arguments[@"focus"] intValue];
        t_SESSION_CATEGORY category = (t_SESSION_CATEGORY)[call.arguments[@"category"] intValue];
        t_SESSION_MODE mode = (t_SESSION_MODE)[call.arguments[@"mode"] intValue];
        int flags = [call.arguments[@"audioFlags"] intValue];
        int sessionCategoryOption = 0;
        if ( audioFocus != abandonFocus && audioFocus != doNotRequestFocus && audioFocus != requestFocus)
        {
                //NSUInteger sessionCategoryOption = 0;
                switch (audioFocus)
                {
                        case requestFocusAndDuckOthers: sessionCategoryOption |= AVAudioSessionCategoryOptionDuckOthers; break;
                        case requestFocusAndKeepOthers: sessionCategoryOption |= AVAudioSessionCategoryOptionMixWithOthers; break;
                        case requestFocusAndInterruptSpokenAudioAndMixWithOthers: sessionCategoryOption |= AVAudioSessionCategoryOptionInterruptSpokenAudioAndMixWithOthers; break;
                        case requestFocusTransient:
                        case requestFocusTransientExclusive:
                        case requestFocus:
                        case abandonFocus:
                        case doNotRequestFocus:
                        case requestFocusAndStopOthers: sessionCategoryOption |= 0; break; // NOOP
                }
                
                if (flags & outputToSpeaker)
                        sessionCategoryOption |= AVAudioSessionCategoryOptionDefaultToSpeaker;
                if (flags & allowAirPlay)
                        sessionCategoryOption |= AVAudioSessionCategoryOptionAllowAirPlay;
                 if (flags & allowBlueTooth)
                        sessionCategoryOption |= AVAudioSessionCategoryOptionAllowBluetooth;
                if (flags & allowBlueToothA2DP)
                        sessionCategoryOption |= AVAudioSessionCategoryOptionAllowBluetoothA2DP;

                
                t_AUDIO_DEVICE device = (t_AUDIO_DEVICE)[call.arguments[@"device"] intValue];
                switch (device)
                {
                        case speaker: sessionCategoryOption |= AVAudioSessionCategoryOptionDefaultToSpeaker; break;
                        case airPlay: sessionCategoryOption |= AVAudioSessionCategoryOptionAllowAirPlay; break;
                        case blueTooth: sessionCategoryOption |= AVAudioSessionCategoryOptionAllowBluetooth; break;
                        case blueToothA2DP: sessionCategoryOption |= AVAudioSessionCategoryOptionAllowBluetoothA2DP; break;
                        case earPiece:
                        case headset: sessionCategoryOption |= 0; break;
                }
                
                r = [[AVAudioSession sharedInstance]
                        setCategory:  tabCategory[category] // AVAudioSessionCategoryPlayback
                        mode: tabSessionMode[mode]
                        options: sessionCategoryOption
                        error: nil
                ];
        }
        
        if (audioFocus != doNotRequestFocus)
        {
                hasFocus = (audioFocus != abandonFocus);
                r = [[AVAudioSession sharedInstance]  setActive: hasFocus error:nil] ;
        }
        return r;
}


@end

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------
