/*
 * Copyright 2018, 2019, 2020 Dooboolab.
 *
 * This file is part of the Tau project.
 *
 * Tau is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License version 3 (LGPL-V3), as published by
 * the Free Software Foundation.
 *
 * Tau is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with the Tau project.  If not, see <https://www.gnu.org/licenses/>.
 */


#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#import "FlautoSession.h"

@implementation FlautoSession


- (bool) setAudioFocus:
                (t_AUDIO_FOCUS)audioFocus
                category: (t_SESSION_CATEGORY)category
                mode: (t_SESSION_MODE)mode
                audioFlags: (int)audioFlags
                audioDevice: (t_AUDIO_DEVICE)audioDevice

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
                //AVAudioSessionCategoryAudioProcessing
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
                //AVAudioSessionModeVoicePrompt,
        };



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
                        case requestFocus:
                        case  abandonFocus:
                        case doNotRequestFocus:
                        case requestFocusAndStopOthers: sessionCategoryOption |= 0; break; // NOOP
                }
                
                if (audioFlags & outputToSpeaker)
                        sessionCategoryOption |= AVAudioSessionCategoryOptionDefaultToSpeaker;
                if (audioFlags & allowAirPlay)
                        sessionCategoryOption |= AVAudioSessionCategoryOptionAllowAirPlay;
                 if (audioFlags & allowBlueTooth)
                        sessionCategoryOption |= AVAudioSessionCategoryOptionAllowBluetooth;
                if (audioFlags & allowBlueToothA2DP)
                        sessionCategoryOption |= AVAudioSessionCategoryOptionAllowBluetoothA2DP;

                
                switch (audioDevice)
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
                r = [[AVAudioSession sharedInstance]  setActive: (audioFocus != abandonFocus) error:nil] ;
        }
        return r;
}

- (bool) initializeFlautoPlayerFocus: (t_AUDIO_FOCUS)audioFocus
                category: (t_SESSION_CATEGORY)category
                mode: (t_SESSION_MODE)mode
                audioFlags: (int)audioFlags
                audioDevice: (t_AUDIO_DEVICE)audioDevice
{
        return [self setAudioFocus: audioFocus category: category mode: mode audioFlags: audioFlags audioDevice: audioDevice];
}

- (void)releaseFlautoPlayer
{
       if (hasFocus)
                [[AVAudioSession sharedInstance]  setActive: FALSE error:nil] ;
       hasFocus = false;
}


@end
