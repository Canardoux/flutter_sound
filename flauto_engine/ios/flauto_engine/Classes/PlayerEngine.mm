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
#import "PlayerEngine.h"
#import "FlautoPlayer.h"


@implementation AudioPlayer
{
        FlautoPlayer* flutterSoundPlayer; // Owner
        AVAudioPlayer* player;
}

       - (AVAudioPlayer*) getAudioPlayer
       {
                return player;
       }
       
        - (void) setAudioPlayer: (AVAudioPlayer*)thePlayer
        {
                player = thePlayer;
        }


       - (AudioPlayer*)init: (FlautoPlayer*)owner
       {
                flutterSoundPlayer = owner;
                return [super init];
       }
       
       -(bool) startPlayerFromBuffer: (NSData*) dataBuffer
       {
                NSError* error = [[NSError alloc] init];
                [self setAudioPlayer:  [[AVAudioPlayer alloc] initWithData:dataBuffer error: &error]];
                // TODO // [self getAudioPlayer].delegate = flutterSoundPlayer;
                bool b = [[self getAudioPlayer] play];
                return b;
       }
       
       -(bool)  startPlayerFromURL: (NSURL*) url
       {
                [self setAudioPlayer: [[AVAudioPlayer alloc] initWithContentsOfURL: url error:nil] ];
                // TODO // [self getAudioPlayer].delegate = flutterSoundPlayer;
                bool b = [ [self getAudioPlayer] play];
                return b;
        }

       
       -(long)  getDuration
       {
                long duration = (long)( [self getAudioPlayer].duration * 1000);
                return duration;
       }
       
       -(long)  getPosition
       {
                long position = (long)( [self getAudioPlayer].currentTime * 1000);
                return position;
       }
       
       -(void)  stop
       {
                [ [self getAudioPlayer] stop];
                  [self setAudioPlayer: nil];
       }
       
       -(bool)  resume
       {
                bool b = [ [self getAudioPlayer] play];
                return b;
       }
        
       -(bool)  pause
       {
                [ [self getAudioPlayer] pause];
                return true;
       }
       
             
       -(bool)  setVolume: (long) volume
       {
                [ [self getAudioPlayer] setVolume: ((double)volume)/1000];
                return true;
       }
 
       
       -(bool)  seek: (double) pos
       {
                [self getAudioPlayer].currentTime = pos / 1000.0;
                return true;
       }
       
       -(t_PLAYER_STATUS)  getStatus
       {
                if (  [self getAudioPlayer] == nil )
                        return PLAYER_IS_STOPPED;
                if ( [ [self getAudioPlayer] isPlaying])
                        return PLAYER_IS_PLAYING;
                return PLAYER_IS_PAUSED;
       }
       
       
        - (int) feed: (NSData*)data
        {
                return -1;
        }

@end


// ---------------------------------------------------------------------------------------------------------------------------------------------------------------


@implementation AudioEngine
{
        FlautoPlayer* flutterSoundPlayer; // Owner
        AVAudioEngine* engine;
        AVAudioPlayerNode* playerNode;
        AVAudioFormat* playerFormat;
        AVAudioFormat* outputFormat;
        AVAudioOutputNode* outputNode;
        NSNumber* sampleRate;
        NSNumber* nbChannels;
        CFTimeInterval mStartPauseTime ; // The time when playback was paused
	CFTimeInterval systemTime ; //The time when  StartPlayer() ;
        double mPauseTime ; // The number of seconds during the total Pause mode
        NSData* waitingBlock;


}

       - (AudioEngine*)init: (FlautoPlayer*)owner
       {
                flutterSoundPlayer = owner;
                waitingBlock = nil;
                engine = [[AVAudioEngine alloc] init];
                outputNode = [engine outputNode];
                outputFormat = [outputNode inputFormatForBus: 0];
                playerNode = [[AVAudioPlayerNode alloc] init];
                
                [engine attachNode: playerNode];
                // TODO nbChannels = audioSettings [@"numChannels"];
                // TODO sampleRate = audioSettings [@"sampleRate"];
 
                [engine connect: playerNode to: outputNode format: outputFormat];
                bool b = [engine startAndReturnError: nil];
                if (!b)
                {
                        NSLog(@"Cannot start the audio engine");
                }
 
                mPauseTime = 0.0; // Total number of seconds in pause mode
		mStartPauseTime = -1; // Not in paused mode
		systemTime = CACurrentMediaTime(); // The time when started
                return [super init];
       }
       
       -(bool) startPlayerFromBuffer: (NSData*) dataBuffer
       {
                 return [self feed: dataBuffer] > 0;
       }
        static int ready = 0;
       
       -(bool)  startPlayerFromURL: (NSURL*) url
       {
                assert(url == nil || url ==  (id)[NSNull null]);
                ready = 0;
                [playerNode play];
                return true;
       }

       
       -(long)  getDuration
       {
		return [self getPosition]; // It would be better if we add what is in the input buffers and not still played
       }
       
       -(long)  getPosition
       {
		double time ;
		if (mStartPauseTime >= 0) // In pause mode
			time =   mStartPauseTime - systemTime - mPauseTime ;
		else
			time = CACurrentMediaTime() - systemTime - mPauseTime;
		return (long)(time * 1000);
       }
       
       -(void)  stop
       {
 
                if (engine != nil)
                {
                        if (playerNode != nil)
                        {
                                [playerNode stop];
                                // Does not work !!! // [engine detachNode:  playerNode];
                                playerNode = nil;
                         }
                        [engine stop];
                        engine = nil;
                }
       }
       
       -(bool)  resume
       {
		if (mStartPauseTime >= 0)
			mPauseTime += CACurrentMediaTime() - mStartPauseTime;
		mStartPauseTime = -1;

		[playerNode play];
                return true;
       }
        
       -(bool)  pause
       {
		mStartPauseTime = CACurrentMediaTime();
		[playerNode pause];
                return true;
       }
       
          
       -(bool)  seek: (double) pos
       {
                return false;
       }
       
       -(int)  getStatus // TODO
       {
                if (engine == nil)
                        return PLAYER_IS_STOPPED;
                if (mStartPauseTime > 0)
                        return PLAYER_IS_PAUSED;
                if ( [playerNode isPlaying])
                        return PLAYER_IS_PLAYING;
                return PLAYER_IS_PLAYING; // ??? Not sure !!!
       }
       
        #define NB_BUFFERS 3
        - (int) feed: (NSData*)data
        {
                if (ready < NB_BUFFERS )
                {
                        int ln = (int)[data length];
                        int frameLn = ln/2;
                        int frameLength =  8*frameLn;// Two octets for a frame (Monophony, INT Linear 16)
                        
                        playerFormat = [[AVAudioFormat alloc] initWithCommonFormat: AVAudioPCMFormatInt16 sampleRate: sampleRate.doubleValue channels: nbChannels.intValue interleaved: NO];
   
                        AVAudioPCMBuffer* thePCMInputBuffer =  [[AVAudioPCMBuffer alloc] initWithPCMFormat: playerFormat frameCapacity: frameLn];
                        memcpy((unsigned char*)(thePCMInputBuffer.int16ChannelData[0]), [data bytes], ln);
                        thePCMInputBuffer.frameLength = frameLn;
                        static bool hasData = true;
                        hasData = true;
                        AVAudioConverterInputBlock inputBlock = ^AVAudioBuffer*(AVAudioPacketCount inNumberOfPackets, AVAudioConverterInputStatus* outStatus)
                        {
                                *outStatus = hasData ? AVAudioConverterInputStatus_HaveData : AVAudioConverterInputStatus_NoDataNow;
                                hasData = false;
                                return thePCMInputBuffer;
                        };
                        
                        AVAudioPCMBuffer* thePCMOutputBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat: outputFormat frameCapacity: frameLength];
                        thePCMOutputBuffer.frameLength = 0;

                        AVAudioConverter* converter = [[AVAudioConverter alloc]initFromFormat: playerFormat toFormat: outputFormat];
                        NSError* error;
                        [converter convertToBuffer: thePCMOutputBuffer error: &error withInputFromBlock: inputBlock];
                         // TODO if (r == AVAudioConverterOutputStatus_HaveData || true)
                         {
                                ++ready ;
                                [playerNode scheduleBuffer: thePCMOutputBuffer  completionHandler:
                                ^(void)
                                {
                                        --ready;
                                        if (self ->waitingBlock != nil)
                                        {
                                                [self feed: self ->waitingBlock]; // Recursion here
                                                self ->waitingBlock = nil;
                                                // TODO // [flutterSoundPlayer needSomeFood: ln];
                                        }

                                }];
                                return ln;
                         } //else
                         /* TODO
                         {
                                 if (error != nil)
                                 {
                                        NSString* f = @"%s : %s : %s";
                                        NSString* s1 = [error localizedDescription];
                                        NSString* s2 = [error localizedFailureReason];
                                        NSString* s3 = [error localizedRecoverySuggestion];
                                        NSLog(f, s1, s2, s3);
                                 }
                                 return 0;
                        }
                        */
               
                }
                assert(waitingBlock == nil);
                waitingBlock = data;
                return 0;
         }

  -(bool)  setVolume: (long) volume // TODO
       {
                return true; // TODO
       }
  


@end


