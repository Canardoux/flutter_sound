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
#import "AudioSession.h"

@implementation AudioSession


- (bool) setAudioFocus:
                (AudioFocus)focus
                category: (SessionCategory)category
                mode: (SessionMode)mode
                audioFlags: (int)audioFlags
                audioDevice: (AudioDevice)audioDevice

{
        NSLog(@"IOS:--> initializeFlautoPlayer");
  
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


// Audio Flags
// -----------
const int outputToSpeaker = 1;
const int allowHeadset = 2;
const int allowEarPiece = 4;
const int allowBlueTooth = 8;
const int allowAirPlay = 16;
const int allowBlueToothA2DP = 32;


        BOOL r = TRUE;
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

- (bool) initializeFlautoPlayerFocus: (AudioFocus)audioFocus
                category: (SessionCategory)category
                mode: (SessionMode)mode
                audioFlags: (int)flags
                audioDevice: (AudioDevice)device
{
        return setAudioFocus:audioFocus category:category mode:mode audioFlags:flags audioDevice:device;
}

- (void)releaseFlautoPlayer
{
       if (hasFocus)
                [[AVAudioSession sharedInstance]  setActive: FALSE error:nil] ;
}


@end
