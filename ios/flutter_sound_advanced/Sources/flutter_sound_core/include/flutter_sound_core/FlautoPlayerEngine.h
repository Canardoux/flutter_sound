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



//
//  PlayerEngine.h
//  Pods
//
//  Created by larpoux on 03/09/2020.
//

#ifndef PlayerEngine_h
#define PlayerEngine_h


#include "Flauto.h"
#import <AVFoundation/AVFoundation.h>

@protocol FlautoPlayerEngineInterface <NSObject>

       - (void) startPlayerFromBuffer:  (NSData*)data ;
       - (void) startPlayerFromURL: (NSURL*) url codec: (t_CODEC)codec channels: (int)numChannels interleaved: (BOOL)interleaved sampleRate: (long)sampleRate bufferSize: (long)bufferSize ;
       - (long) getDuration;
       - (long) getPosition;
       - (void) stop;
       - (bool) play;
       - (bool) resume;
       - (bool) pause;
       - (bool) setVolume: (double) volume fadeDuration: (NSTimeInterval)fadeDuration; // Volume is between 0.0 and 1.0
       - (bool) setPan: (double) pan; // Pan is between -1.0 and 1.0
       - (bool) setSpeed: (double) speed ; // Speed is between 0.0 and 1.0 to go slower
       - (bool) seek: (double) pos;
       - (t_PLAYER_STATE) getStatus;
       - (int) feed: (NSArray*)data interleaved: (BOOL)interleaved;

@end

@interface AudioPlayerFlauto : NSObject  <FlautoPlayerEngineInterface>
{
}
       - (AudioPlayerFlauto*) init: (NSObject*)owner ;// FlutterSoundPlayer*
       - (void) startPlayerFromBuffer:  (NSData*)data ;
       - (void) startPlayerFromURL: (NSURL*) url codec: (t_CODEC)codec channels: (int)numChannels interleaved: (BOOL)interleaved sampleRate: (long)sampleRate bufferSize: (long)bufferSize;
       - (void) stop;
       - (bool) play;
       - (bool) resume;
       - (bool) pause;
       - (bool) setVolume: (double) volume fadeDuration: (NSTimeInterval)duration ;// Volume is between 0.0 and 1.0
       - (bool) setPan: (double) pan; // Pan is between -1.0 and 1.0
       - (bool) setSpeed: (double) speed ;// Volume is between 0.0 and 1.0
       - (bool) seek: (double) pos;
       - (t_PLAYER_STATE) getStatus;
       - (AVAudioPlayer*) getAudioPlayer;
       - (void) setAudioPlayer: (AVAudioPlayer*)thePlayer;
       - (int) feed: (NSArray*)data interleaved: (BOOL)interleaved;

@end


@interface AudioEngine  : NSObject <FlautoPlayerEngineInterface>
{
        // TODO FlutterSoundPlayer* flutterSoundPlayer; // Owner
}
       - (AudioEngine*) init: (NSObject*)owner
                        codec: (t_CODEC)codec 
                        channels: (int)numChannels
                        interleaved: (BOOL)interleaved 
                        sampleRate: (long)sampleRate;
                        ; 

       - (void) startPlayerFromBuffer:  (NSData*)data ;
       - (void) startPlayerFromURL: (NSURL*) url codec: (t_CODEC)codec channels: (int)numChannels interleaved: (BOOL)interleaved sampleRate: (long)sampleRate bufferSize: (long)bufferSize;
       - (bool) play;
       - (void) stop;
       - (bool) resume;
       - (bool) pause;
       - (bool) setVolume: (double) volume  fadeDuration:(NSTimeInterval)duration ;
       - (bool) setPan: (double) pan;
       - (bool) setSpeed: (double) speed ;
       - (bool) seek: (double) pos;
       - (int)  getStatus;
       - (int) feed: (NSArray*)data interleaved: (BOOL)interleaved;

@end


@interface AudioEngineFromMic  : NSObject <FlautoPlayerEngineInterface>
{
        // TODO FlutterSoundPlayer* flutterSoundPlayer; // Owner
}
       - (AudioEngineFromMic*) init: (NSObject*)owner; // FlutterSoundPlayer*

       - (void) startPlayerFromBuffer:  (NSData*)data ;
       - (void) startPlayerFromURL: (NSURL*) url codec: (t_CODEC)codec channels: (int)numChannels interleaved: (BOOL)interleaved sampleRate: (long)sampleRate bufferSize: (long)bufferSize ;
       - (void) stop;
       - (bool) play;
       - (bool) resume;
       - (bool) pause;
       - (bool) setVolume: (double) volume  fadeDuration:(NSTimeInterval)duration ;
       - (bool) setPan: (double) pan ;       
       - (bool) setSpeed: (double) speed;
       - (bool) seek: (double) pos;
       - (int) getStatus;
       - (int) feed: (NSArray*)data interleaved: (BOOL)interleaved;

@end



#endif /* PlayerEngine_h */
