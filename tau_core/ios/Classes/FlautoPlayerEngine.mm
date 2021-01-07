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

//
//  PlayerEngine.h
//  Pods
//
//  Created by larpoux on 03/09/2020.
//
#import "Flauto.h"
#import "FlautoPlayerEngine.h"
#import "FlautoPlayer.h"

@implementation AudioPlayerFlauto
{
        FlautoPlayer* flautoPlayer; // Owner
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



       - (AudioPlayerFlauto*)init: (FlautoPlayer*)owner
       {
                flautoPlayer = owner;
                return [super init];
       }

       -(bool) startPlayerFromBuffer: (NSData*) dataBuffer
       {
                NSError* error = [[NSError alloc] init];
                [self setAudioPlayer:  [[AVAudioPlayer alloc] initWithData: dataBuffer error: &error]];
                [self getAudioPlayer].delegate = flautoPlayer;
                bool b = [[self getAudioPlayer] play];
                return b;
       }

       -(bool)  startPlayerFromURL: (NSURL*) url codec: (t_CODEC)codec channels: (int)numChannels sampleRate: (long)sampleRate

       {
                [self setAudioPlayer: [[AVAudioPlayer alloc] initWithContentsOfURL: url error: nil] ];
                [self getAudioPlayer].delegate = flautoPlayer;
                bool b = [ [self getAudioPlayer] play];
                return b;
        }


       -(long)  getDuration
       {
                double duration =  [self getAudioPlayer].duration;
                return (long)(duration * 1000.0);
       }

       -(long)  getPosition
       {
                double position = [self getAudioPlayer].currentTime ;
                return (long)( position * 1000.0);
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

       -(t_PLAYER_STATE)  getStatus
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
        CFTimeInterval mStartPauseTime ; // The time when playback was paused
	CFTimeInterval systemTime ; //The time when  StartPlayer() ;
        double mPauseTime ; // The number of seconds during the total Pause mode
        NSData* waitingBlock;
        long m_sampleRate ;
        int  m_numChannels;
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

       -(bool)  startPlayerFromURL: (NSURL*) url codec: (t_CODEC)codec channels: (int)numChannels sampleRate: (long)sampleRate
       {
                assert(url == nil || url ==  (id)[NSNull null]);
                m_sampleRate = sampleRate;
                m_numChannels= numChannels;
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

       -(int)  getStatus
       {
                if (engine == nil)
                        return PLAYER_IS_STOPPED;
                if (mStartPauseTime > 0)
                        return PLAYER_IS_PAUSED;
                if ( [playerNode isPlaying])
                        return PLAYER_IS_PLAYING;
                return PLAYER_IS_PLAYING; // ??? Not sure !!!
       }

        #define NB_BUFFERS 4
        - (int) feed: (NSData*)data
        {
                if (ready < NB_BUFFERS )
                {
                        int ln = (int)[data length];
                        int frameLn = ln/2;
                        int frameLength =  8*frameLn;// Two octets for a frame (Monophony, INT Linear 16)

                        playerFormat = [[AVAudioFormat alloc] initWithCommonFormat: AVAudioPCMFormatInt16 sampleRate: (double)m_sampleRate channels: m_numChannels interleaved: NO];

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
                         // if (r == AVAudioConverterOutputStatus_HaveData || true)
                        {
                                ++ready ;
                                [playerNode scheduleBuffer: thePCMOutputBuffer  completionHandler:
                                ^(void)
                                {
                                        dispatch_async(dispatch_get_main_queue(),
                                        ^{
                                                --ready;
                                                assert(ready < NB_BUFFERS);
                                                if (self ->waitingBlock != nil)
                                                {
                                                        NSData* blk = self ->waitingBlock;
                                                        self ->waitingBlock = nil;
                                                        int ln = (int)[blk length];
                                                        int l = [self feed: blk]; // Recursion here
                                                        assert (l == ln);
                                                        [self ->flutterSoundPlayer needSomeFood: ln];
                                                }
                                        });

                                }];
                                return ln;
                        }
                } else
                {
                        assert (ready == NB_BUFFERS);
                        assert(waitingBlock == nil);
                        waitingBlock = data;
                        return 0;
                }
         }

-(bool)  setVolume: (long) volume // TODO
{
        return true; // TODO
}

@end

// ---------------------------------------------------------------------------------------------------------------------------------------------------------------


@implementation AudioEngineFromMic
{
        FlautoPlayer* flutterSoundPlayer; // Owner
        AVAudioEngine* engine;
        AVAudioPlayerNode* playerNode;
        AVAudioFormat* playerFormat;
        AVAudioFormat* outputFormat;
        AVAudioOutputNode* outputNode;
        CFTimeInterval mStartPauseTime ; // The time when playback was paused
	CFTimeInterval systemTime ; //The time when  StartPlayer() ;
        double mPauseTime ; // The number of seconds during the total Pause mode
        NSData* waitingBlock;
        long m_sampleRate ;
        int  m_numChannels;
}

       - (AudioEngineFromMic*)init: (FlautoPlayer*)owner
       {
                flutterSoundPlayer = owner;
                waitingBlock = nil;
                engine = [[AVAudioEngine alloc] init];
                
                AVAudioInputNode* inputNode = [engine inputNode];
                //AVAudioFormat* inputFormat = [inputNode outputFormatForBus: 0];

                outputNode = [engine outputNode];
                outputFormat = [outputNode inputFormatForBus: 0];
                

                [engine connect: inputNode to: outputNode format: outputFormat];
                return [super init];
       }
       

       -(bool) startPlayerFromBuffer: (NSData*) dataBuffer
       {
                 return false;
       }
        static int ready2 = 0;

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

       -(bool)  startPlayerFromURL: (NSURL*) url codec: (t_CODEC)codec channels: (int)numChannels sampleRate: (long)sampleRate
       {
                assert(url == nil || url ==  (id)[NSNull null]);
                m_sampleRate = sampleRate;
                m_numChannels= numChannels;
                bool b = [engine startAndReturnError: nil];
                if (!b)
                {
                        NSLog(@"Cannot start the audio engine");
                }

                mPauseTime = 0.0; // Total number of seconds in pause mode
		mStartPauseTime = -1; // Not in paused mode
		systemTime = CACurrentMediaTime(); // The time when started
                //previousTS = CACurrentMediaTime() * 1000;
                ready2 = 0;
                //[playerNode play];
                return true;
       }


       -(void)  stop
       {

                if (engine != nil)
                {
                        //if (playerNode != nil)
                        {
                                //[playerNode stop];
                                // Does not work !!! // [engine detachNode:  playerNode];
                                //playerNode = nil;
                         }
                        [engine stop];
                        engine = nil;
                }
                //if (previousTS != 0)
                {
                        //dateCumul += CACurrentMediaTime() * 1000 - previousTS;
                        //previousTS = 0;
                }
       }

       -(bool)  resume
       {
		//if (mStartPauseTime >= 0)
			//mPauseTime += CACurrentMediaTime() - mStartPauseTime;
		//mStartPauseTime = -1;

                //[engine startAndReturnError: nil];
		//[playerNode play];
                //previousTS = CACurrentMediaTime() * 1000;
                return false;
       }

       -(bool)  pause
       {
		//mStartPauseTime = CACurrentMediaTime();
		//[playerNode pause];
                //[engine pause];
                //if (previousTS != 0)
                {
                        //dateCumul += CACurrentMediaTime() * 1000 - previousTS;
                        //previousTS = 0;
                }
                return false;
       }


       -(bool)  seek: (double) pos
       {
                return false;
       }

       -(int)  getStatus
       {
                if (engine == nil)
                        return PLAYER_IS_STOPPED;
                //if (mStartPauseTime > 0)
                        //return PLAYER_IS_PAUSED;
                //if ( [playerNode isPlaying])
                        //return PLAYER_IS_PLAYING;
                return PLAYER_IS_PLAYING; // ??? Not sure !!!
       }


        -(bool)  setVolume: (long) volume // TODO
        {
                return true; // TODO
        }

       - (int) feed: (NSData*)data
       {
        return 0;
       }


//-------------------------------------------------------------------------------------------------------------------------------------------



@end
