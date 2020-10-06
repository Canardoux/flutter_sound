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
#import "FlautoPlayer.h"


@protocol PlayerEngineInterface <NSObject>

       - (bool) startPlayerFromBuffer:  (NSData*)data;
       - (bool) startPlayerFromURL: (NSURL*)url;
       - (long) getDuration;
       - (long) getPosition;
       - (void) stop;
       - (bool) resume;
       - (bool) pause;
       - (bool) setVolume: (long) volume;
       - (bool) seek: (double) pos;
       - (t_PLAYER_STATUS) getStatus;
       - (int) feed: (NSData*)data;

@end

@interface AudioPlayer : NSObject <PlayerEngineInterface>
{
}
       - (AudioPlayer*) init: (NSObject*)owner; // FlutterSoundPlayer*

       - (bool) startPlayerFromBuffer:  (NSData*)data;
       // TODO - (bool) startPlayerFromURL;
       // TODO - (long) duration;
       // TODO - (long) position;
       - (void) stop;
       - (bool) resume;
       - (bool) pause;
       - (bool) setVolume: (long) volume;
       - (bool) seek: (double) pos;
       - (t_PLAYER_STATUS) getStatus;
       //- (AVAudioPlayer*) getAudioPlayer;
       - (int) feed: (NSData*)data;

@end


@interface AudioEngine  : NSObject <PlayerEngineInterface>
{
        // TODO FlutterSoundPlayer* flutterSoundPlayer; // Owner
}
       - (AudioEngine*) init: (NSObject*)owner; // FlutterSoundPlayer*

       - (bool) startPlayerFromBuffer:  (NSData*)data;
       // TODO - (bool) startPlayerFromURL;
       // TODO - (long) duration;
       // TODO - (long) position;
       - (void) stop;
       - (bool) resume;
       - (bool) pause;
       - (bool) setVolume: (long) volume;
       - (bool) seek: (double) pos;
       - (int) getStatus;
       //- (AVAudioPlayer*) getAudioPlayer;
       - (int) feed: (NSData*)data;

@end



#endif /* PlayerEngine_h */
