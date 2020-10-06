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



#ifndef FlutterSoundPlayer_h
#define FlutterSoundPlayer_h



#import <AVFoundation/AVFoundation.h>
#import "AudioSession.h"
#import "FlautoEngine.h"
#import "Track.h"

typedef enum
{
        PLAYER_NOT_INITIALIZED,
        PLAYER_IS_STOPPED,
        PLAYER_IS_PLAYING,
        PLAYER_IS_PAUSED
} t_PLAYER_STATUS;


@interface FlautoPlayerCallback  : NSObject
{
         
}
@end


@interface FlautoPlayer  : AudioSession
{
         
}

           
- (t_PLAYER_STATUS)getPlayerState;
- (bool)isDecoderSupported: (t_CODEC)codec ;

- (bool)startPlayerCodec: (t_CODEC)codec
        fromURI: (NSString*)path
        fromDataBuffer: (NSData*)dataBuffer;
        
- (bool)startPlayerFromTrack: (Track*)track;

- (void)stopPlayer;
- (bool)pausePlayer;
- (bool)resumePlayer;
- (void)seekToPlayer: (long)time;
- (void)setSubscriptionDuration: (long)call ;
- (void)setVolume: (double)volume ;
- (bool)setCategory: (NSString*)categ mode:(NSString*)mode options:(int)options ;
- (bool)setActive:(BOOL)enabled ;
- (void)setUIProgressBar: (double)call;
- (void)nowPlaying: (Track*)track ;
- (NSDictionary*)getProgress ;
- (int)feed: (NSData*)data;



/*
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag;
- (void)updateProgress:(NSTimer *)timer;
- (void)startTimer;
- (void)stopTimer;
- (void)startPlayerFromBuffer:(FlutterStandardTypedData*)dataBuffer result: (FlutterResult)result;
- (NSNumber*)getPlayerStatus;
- (int)getStatus;
- (long)getPosition;
- (long)getDuration;
- (void)needSomeFood: (int) ln;
*/

@end

#endif // FlutterSoundPlayer_h

