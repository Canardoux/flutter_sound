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


//
//  PlayerEngine.h
//  Pods
//
//  Created by larpoux on 03/09/2020.
//

#ifndef PlayerEngine_h
#define PlayerEngine_h
#import "FlautoManager.h"
#import "FlutterSoundPlayer.h"


@protocol PlayerInterface <NSObject>

       - (bool) startPlayerFromBuffer:  (NSData*)data;
       - (bool) startPlayerFromURL: (NSURL*)url;
       - (long) getDuration;
       - (long) getPosition;
       - (void) stop;
       - (bool) resume;
       - (bool) pause;
       - (bool) setVolume: (double) volume;
       - (bool) seek: (double) pos;
       - (int) getStatus;
       - (int) feed: (NSData*)data;

@end

@interface AudioPlayer : NSObject <PlayerInterface>
{
}
       - (AudioPlayer*) init: (NSObject*)owner; // FlutterSoundPlayer*

       - (bool) startPlayerFromBuffer:  (NSData*)data;
       - (bool) startPlayerFromURL;
       - (long) duration;
       - (long) position;
       - (void) stop;
       - (bool) resume;
       - (bool) pause;
       - (bool) setVolume: (double) volume;
       - (bool) seek: (double) pos;
       - (int) getStatus;
       - (AVAudioPlayer*) getAudioPlayer;
       - (void) setAudioPlayer: (AVAudioPlayer*)thePlayer;
       - (int) feed: (NSData*)data;

@end

#endif /* PlayerEngine_h */
