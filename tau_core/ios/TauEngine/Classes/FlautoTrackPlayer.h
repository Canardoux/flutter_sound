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
 
#ifndef TrackPlayer_h
#define TrackPlayer_h


#import "FlautoPlayer.h"



@interface FlautoTrackPlayer : FlautoPlayer
{

}
- (FlautoTrackPlayer*)init: (NSObject<FlautoPlayerCallback>*) callback;
- (bool)startPlayerFromTrack: (FlautoTrack*)track canPause: (bool)canPause canSkipForward: (bool)canSkipForward canSkipBackward: (bool)canSkipBackward
        progress: (NSNumber*)progress duration: (NSNumber*)duration removeUIWhenStopped: (bool)removeUIWhenStopped defaultPauseResume: (bool)defaultPauseResume;
- (void)seekToPlayer: (long)time;
- (void)releaseFlautoPlayer;
- (void)setUIProgressBar: (NSNumber*)pos duration: (NSNumber*)duration;
- (void)nowPlaying: (FlautoTrack*)track canPause: (bool)canPause canSkipForward: (bool)canSkipForward canSkipBackward: (bool)canSkipBackward
                defaultPauseResume: (bool)defaultPauseResume progress: (NSNumber*)progress duration: (NSNumber*)duration;


@end

#endif // TrackPlayer_h

