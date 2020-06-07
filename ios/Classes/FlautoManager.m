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
#import "FlautoManager.h"


/// Used by [AudioPlayer.audioFocus]
/// to control the focus mode.
enum AudioFocus {
  requestFocus,

  /// request focus and allow other audio
  /// to continue playing at their current volume.
  requestFocusAndKeepOthers,

  /// request focus and stop other audio playing
  requestFocusAndStopOthers,

  /// request focus and reduce the volume of other players
  /// In the Android world this is know as 'Duck Others'.
  requestFocusAndDuckOthers,
  
  requestFocusAndInterruptSpokenAudioAndMixWithOthers,
  
  requestFocusTransient,
  requestFocusTransientExclusive,


  /// relinquish the audio focus.
  abandonFocus,

  doNotRequestFocus,
};



enum SessionCategory {
  ambient,
  multiRoute,
  playAndRecord,
  playback,
  record,
  soloAmbient,
  audioProcessing,
};


enum SessionMode
{
  modeDefault, // 'AVAudioSessionModeDefault',
  modeGameChat, //'AVAudioSessionModeGameChat',
  modeMeasurement, //'AVAudioSessionModeMeasurement',
  modeMoviePlayback, //'AVAudioSessionModeMoviePlayback',
  modeSpokenAudio, //'AVAudioSessionModeSpokenAudio',
  modeVideoChat, //'AVAudioSessionModeVideoChat',
  modeVideoRecording, // 'AVAudioSessionModeVideoRecording',
  modeVoiceChat, // 'AVAudioSessionModeVoiceChat',
  modeVoicePrompt, // 'AVAudioSessionModeVoicePrompt',
};


enum AudioDevice {
  speaker,
  headset,
  earPiece,
  blueTooth,
  blueToothA2DP,
  airPlay
};


@implementation FlautoManager
{
        NSMutableArray* flautoPlayerSlots;
}

- (FlautoManager*)init
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


@end





@implementation Session
{
  
}


-(FlautoManager*) getPlugin
{
        return nil; // Implented in subclass
}

- (Session*) init: (FlutterMethodCall*)call
{
        slotNo = [[self getPlugin] initPlugin: self call: call];
        hasFocus = FALSE;
        return [super init];
}

- (void) releaseSession
{
       if (hasFocus)
                [[AVAudioSession sharedInstance]  setActive: FALSE error:nil] ;
 
        [[self getPlugin]freeSlot: slotNo];
  
}


- (void)invokeMethod: (NSString*)methodName stringArg: (NSString*)stringArg
{
        NSDictionary* dic = @{ @"slotNo": [NSNumber numberWithInt: slotNo], @"arg": stringArg};
        [[self getPlugin] invokeMethod: methodName arguments: dic ];
}


- (void)invokeMethod: (NSString*)methodName dico: (NSDictionary*)dico
{
        //[dico setObject:[NSNumber numberWithInt: slotNo] forKey:@"slotNo"];
        [[self getPlugin] invokeMethod: methodName arguments: dico ];
}


- (void)invokeMethod: (NSString*)methodName boolArg: (Boolean)boolArg
{
        NSDictionary* dic = @{ @"slotNo": [NSNumber numberWithInt: slotNo], @"arg": [NSNumber numberWithBool: boolArg]};
        [[self getPlugin] invokeMethod: methodName arguments: dic ];
}


- (void)invokeMethod: (NSString*)methodName numberArg: (NSNumber*)arg
{
        NSDictionary* dic = @{ @"slotNo": [NSNumber numberWithInt: slotNo], @"arg": arg};
        [[self getPlugin] invokeMethod: methodName arguments: dic ];
}


- (void)setAudioFocus: (FlutterMethodCall*)call result: (FlutterResult)result
{


        NSString* tabCategory[] =
        {
                AVAudioSessionCategoryAmbient,
                AVAudioSessionCategoryMultiRoute,
                AVAudioSessionCategoryPlayAndRecord,
                AVAudioSessionCategoryPlayback,
                AVAudioSessionCategoryRecord,
                AVAudioSessionCategorySoloAmbient,
                AVAudioSessionCategoryAudioProcessing
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
                AVAudioSessionModeVoicePrompt,
        };



        BOOL r = TRUE;
        enum AudioFocus audioFocus = (enum AudioFocus) [call.arguments[@"focus"] intValue];
        enum SessionCategory category = (enum SessionCategory)[call.arguments[@"category"] intValue];
        enum SessionMode mode = (enum SessionMode)[call.arguments[@"mode"] intValue];
        enum AudioDevice device = (enum AudioDevice)[call.arguments[@"device"] intValue];
        if ( audioFocus != abandonFocus && audioFocus != doNotRequestFocus && audioFocus != requestFocus)
        {
                NSUInteger sessionCategoryOption = 0;
                switch (audioFocus)
                {
                        case requestFocusAndDuckOthers: sessionCategoryOption |= AVAudioSessionCategoryOptionDuckOthers; break;
                        case requestFocusAndKeepOthers: sessionCategoryOption |= AVAudioSessionCategoryOptionMixWithOthers; break;
                        case requestFocusAndInterruptSpokenAudioAndMixWithOthers: sessionCategoryOption |= AVAudioSessionCategoryOptionInterruptSpokenAudioAndMixWithOthers; break;
                        case requestFocusTransient:
                        case requestFocusTransientExclusive:
                        case requestFocusAndStopOthers: sessionCategoryOption |= 0; break; // NOOP
                }
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
        if (r)
                result([NSNumber numberWithBool: r]);
        else
                [FlutterError
                                errorWithCode:@"Audio Player"
                                message:@"Open session failure"
                                details:nil];
}


@end
