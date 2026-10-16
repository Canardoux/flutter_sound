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
#import "./include/flutter_sound_core/Flauto.h"
#import "./include/flutter_sound_core/FlautoPlayerEngine.h"
#import "./include/flutter_sound_core/FlautoPlayer.h"

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

       -(void) startPlayerFromBuffer: (NSData*) dataBuffer
       {
                NSError* error = [[NSError alloc] init];
                [self setAudioPlayer:  [[AVAudioPlayer alloc] initWithData: dataBuffer error: &error]];
                [self getAudioPlayer].delegate = flautoPlayer;
       }

       -(void)  startPlayerFromURL: (NSURL*) url codec: (t_CODEC)codec channels: (int)numChannels  interleaved: (BOOL)interleaved sampleRate: (long)sampleRate bufferSize: (long)bufferSize

       {
                [self setAudioPlayer: [[AVAudioPlayer alloc] initWithContentsOfURL: url error: nil] ];
                [self getAudioPlayer].delegate = flautoPlayer;
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

        -(bool)  play
        {
                bool b = [ [self getAudioPlayer] play];
                return b;
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


       -(bool)  setVolume: (double) volume fadeDuration:(NSTimeInterval)fadeDuration // volume is between 0.0 and 1.0
       {
               if (fadeDuration == 0)
                     [ [self getAudioPlayer] setVolume: volume ];
               else
                       [ [self getAudioPlayer] setVolume: volume fadeDuration: fadeDuration];
               return true;
       }

       -(bool)  setPan: (double) pan
       {
                [self getAudioPlayer].pan=pan;
                return  true;
       }


        -(bool)  setSpeed: (double) speed // speed is between 0.0 and 1.0 to go slower
        {
                [self getAudioPlayer].enableRate = true ; // Probably not always !!!!
                [self getAudioPlayer].rate = speed ;
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


        - (int) feed: (NSArray*)data interleaved: (BOOL)interleaved;
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
        AVAudioFormat* inputFormat;
        AVAudioFormat* outputFormat;
        AVAudioUnitTimePitch* timePitchUnit;
        AVAudioOutputNode* outputNode;
        AVAudioConverter* converter;
        CFTimeInterval mStartPauseTime ; // The time when playback was paused
        CFTimeInterval systemTime ; //The time when  StartPlayer() ;
        double mPauseTime ; // The number of seconds during the total Pause mode
        NSArray<NSData*>* waitingBlock;
        long m_sampleRate ;
        int  m_numChannels;
        long m_bufferSize;
        BOOL m_interleaved;
        t_CODEC m_codec;
}

       - (AudioEngine*)init: (FlautoPlayer*)owner
                    codec: (t_CODEC)codec
                    channels: (int)numChannels
                    interleaved: (bool)interleaved
                    sampleRate: (long)sampleRate
 
       {
                m_sampleRate = sampleRate;
                m_numChannels= numChannels;
                m_interleaved = interleaved;
                m_codec = codec;

                flutterSoundPlayer = owner;
                waitingBlock = nil;
                engine = [[AVAudioEngine alloc] init];
                outputNode = [engine outputNode];
                timePitchUnit = [[AVAudioUnitTimePitch alloc] init];
                [timePitchUnit setRate:1];
           
                outputFormat = [outputNode inputFormatForBus: 0];

                AVAudioCommonFormat commonFormat = (m_codec == pcmFloat32) ? AVAudioPCMFormatFloat32 : AVAudioPCMFormatInt16;
                inputFormat = [[AVAudioFormat alloc] initWithCommonFormat: commonFormat sampleRate: (double)m_sampleRate channels: m_numChannels interleaved: m_interleaved];
                assert([inputFormat channelCount] == m_numChannels);
                assert([inputFormat isInterleaved] == m_interleaved);

           /*
                AVAudioFormat* format = [outputNode inputFormatForBus: 0];
                int outputChannelCount = [format channelCount];
                int outputSampleRate = [format sampleRate];
                bool outputIsInterleaved = [format isInterleaved];
                AVAudioCommonFormat outputCommonFormat = [format commonFormat];
                outputFormat =  [ [AVAudioFormat alloc] initWithCommonFormat: outputCommonFormat
                                          sampleRate: outputSampleRate
                                          channels: outputChannelCount
                                          interleaved: outputIsInterleaved];
            */
                playerNode = [[AVAudioPlayerNode alloc] init];

                [engine attachNode: playerNode];

                [engine attachNode: timePitchUnit];

                [engine connect: playerNode to: engine.mainMixerNode format: outputFormat];
                [engine connect: engine.mainMixerNode to: timePitchUnit format: outputFormat];
                [engine connect: timePitchUnit to: outputNode format: outputFormat];
                bool b = [engine startAndReturnError: nil];
                if (!b)
                {
                        [flutterSoundPlayer logDebug: @"Cannot start the audio engine"];
                }

                mPauseTime = 0.0; // Total number of seconds in pause mode
                mStartPauseTime = -1; // Not in paused mode
                systemTime = CACurrentMediaTime(); // The time when started
                return [super init];
       }

       -(void) startPlayerFromBuffer: (NSData*) dataBuffer
       {
           NSArray* d = @[dataBuffer];
           [self feed: d interleaved: true] ;
       }
        static int ready = 0;

       -(void)  startPlayerFromURL: (NSURL*) url codec: (t_CODEC)codec channels:  (int)numChannels  interleaved: (BOOL)interleaved  sampleRate: (long)sampleRate bufferSize: (long)bufferSize
       {
                assert(url == nil || url ==  (id)[NSNull null]);
                m_sampleRate = sampleRate;
                m_numChannels= numChannels;
                m_bufferSize = bufferSize;
                m_interleaved = interleaved;
                m_codec = codec;
                ready = 0;
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
                        if (timePitchUnit != nil)
                             {
                                     timePitchUnit = nil;
                             }
                        [engine stop];
                        engine = nil;
                    
                        if (converter != nil)
                        {
                            converter = nil; // ARC will dealloc the converter (I hope ;-) )
                        }
                }
       }

        -(bool) play
        {
                [playerNode play];
                return true;

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
        - (int) feed: (NSArray*)data interleaved: (bool)interleaved
        {
                //NSMutableArray* data = [[NSMutableArray alloc] init];
                //NSData* d = data[0];
                //assert (audioData.count > 0); // Something wrong
                if (ready < NB_BUFFERS  )
                {
                        int ln = (int)[data[0] length]; // number of bytes to feed
                        int frameSize; // The size in bytes of each frame.
                        if (m_codec == pcm16)
                        {
                            frameSize = 2 * m_numChannels;
                        } else
                        if (m_codec == pcmFloat32)
                        {
                            frameSize = 4 * m_numChannels;
                        } else
                        {
                            assert(false);
                        }
                        int frameCount = ln / frameSize;
                        if (!interleaved)
                        {
                            frameCount = frameCount * m_numChannels; // WHY ???
                        }
                        //int sampleCount = interleaved ? frameCount * m_numChannels : frameCount;

                        AVAudioPCMBuffer* thePCMInputBuffer =  [[AVAudioPCMBuffer alloc] initWithPCMFormat: inputFormat frameCapacity: frameCount*2];// !!!!!
                        if (interleaved)
                        {
                            if (m_codec == pcm16)
                            {
                                memcpy((unsigned char*)(thePCMInputBuffer.int16ChannelData[0]), [data[0] bytes], ln); // Here we suppose that the input data are always interleaved
                            } else
                            if (m_codec == pcmFloat32)
                            {
                                memcpy((unsigned char*)(thePCMInputBuffer.floatChannelData[0]), [data[0] bytes], ln); // Here we suppose that the input data are always interleaved
                            } else
                            {
                                assert(false);
                            }
                        } else
                        {
                            for (int channel = 0; channel < m_numChannels; ++channel)
                            {
                                if (m_codec == pcm16)
                                {
                                    memcpy((unsigned char*)(thePCMInputBuffer.int16ChannelData[channel]), [data[channel] bytes], ln);
                                } else
                                if (m_codec == pcmFloat32)
                                {
                                    memcpy((unsigned char*)(thePCMInputBuffer.floatChannelData[channel]), [data[channel] bytes], ln);
                                } else
                                {
                                    assert(false);
                                }
                            }
                        }
                        thePCMInputBuffer.frameLength = frameCount;
                    
                        static bool hasData = true;
                        hasData = true;
                        AVAudioConverterInputBlock inputBlock = ^AVAudioBuffer*(AVAudioPacketCount inNumberOfPackets, AVAudioConverterInputStatus* outStatus)
                        {
                                *outStatus = hasData ? AVAudioConverterInputStatus_HaveData : AVAudioConverterInputStatus_NoDataNow;
                                hasData = false;
                                return thePCMInputBuffer;
                        };
                    
                        //int output_channels = [outputFormat channelCount];
                        AVAudioPCMBuffer* thePCMOutputBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat: outputFormat frameCapacity: 8*frameCount]; // I don't understand why multiplied by 8!
                        thePCMOutputBuffer.frameLength = 0;

                        if (converter == nil) 
                        {
                                converter = [[AVAudioConverter alloc]initFromFormat: inputFormat toFormat: outputFormat];
                        }

                        NSError* error;
                        [converter convertToBuffer: thePCMOutputBuffer error: &error withInputFromBlock: inputBlock];
                        
                        //int numberOfConvertedFrames = thePCMOutputBuffer.frameLength;
                    
                        ++ready ; // The number of waiting packets to be sent by the Device
                        [playerNode scheduleBuffer: thePCMOutputBuffer  completionHandler:
                        ^(void)
                        {
                                dispatch_async(dispatch_get_main_queue(),
                                ^{
                                        --ready; // The Device has sent its packet. One less to send.
                                        assert(ready < NB_BUFFERS || !interleaved);
                                        if (self ->waitingBlock != nil)
                                        {
                                                NSArray<NSData*>* blk = self ->waitingBlock;
                                                self ->waitingBlock = nil;
                                                int ln = (int)[blk[0] length];
                                                int l = [self feed: blk interleaved: interleaved]; // Recursion here
                                                assert (l == ln);
                                                [self ->flutterSoundPlayer needSomeFood: ln];
                                        }
                                        if (ready == 0) // Nothing more to play. Send an indication to the App
                                        {
                                                [self ->flutterSoundPlayer  audioPlayerDidFinishPlaying: true];

                                        }
                                });

                        }];
                        return ln;
                
                } else
                {
                        assert (ready == NB_BUFFERS || !interleaved);
                        // !!! assert(waitingBlock == nil);
                        waitingBlock = data;
                        return 0;
                }
         }



   
-(bool)  setVolume: (double) volume fadeDuration: (NSTimeInterval)fadeDuration
{
        engine.mainMixerNode.volume = volume;
        if (playerNode == nil || playerNode ==  (id)[NSNull null]) return false;
        [playerNode setVolume: volume];

        //TODO: implement fadeDuration programmatically since its not available on playerNode
        return true;
}

-(bool)  setPan: (double) pan
{
        if (playerNode == nil || playerNode ==  (id)[NSNull null]) return false;

        //TODO
        return true;
}


-(bool)  setSpeed: (double) rate // range: 1/32 -> 32
{
         if (timePitchUnit == nil || timePitchUnit ==  (id)[NSNull null]) return false;
         if (rate < 1/32 || rate > 32) return false;
         [timePitchUnit setRate: rate];
         return true;
}

@end

// ---------------------------------------------------------------------------------------------------------------------------------------------------------------


@implementation AudioEngineFromMic
{
        FlautoPlayer* flutterSoundPlayer; // Owner
        AVAudioEngine* engine;
        CFTimeInterval mStartPauseTime ; // The time when playback was paused
        CFTimeInterval systemTime ; //The time when  StartPlayer() ;
        double mPauseTime ; // The number of seconds during the total Pause mode
        NSData* waitingBlock;
        long m_sampleRate ;
        int  m_numChannels;
}

       - (AudioEngineFromMic*)init: (FlautoPlayer*)owner
       {
               //engine = [[AVAudioEngine alloc] init];
                flutterSoundPlayer = owner;
                return [super init];
       }
       

       -(void) startPlayerFromBuffer: (NSData*) dataBuffer
       {
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

       -(void)  startPlayerFromURL: (NSURL*) url codec: (t_CODEC)codec channels: (int)numChannels interleaved: (BOOL)interleaved sampleRate: (long)sampleRate bufferSize: (long)bufferSize
       {
                assert(url == nil || url ==  (id)[NSNull null]);

                m_sampleRate = sampleRate;
                m_numChannels= numChannels;

               waitingBlock = nil;
               //AVAudioEngine* engine = [[AVAudioEngine alloc] init];
               engine = [[AVAudioEngine alloc] init];
               AVAudioInputNode* inputNode = [engine inputNode];
               AVAudioOutputNode* outputNode = [engine outputNode];
               //[engine attachNode:inputNode];
               
               //if (enableVoiceProcessing) {
                       if (@available(iOS 13.0, *)) {
                               NSError* err;
                               if (![inputNode setVoiceProcessingEnabled: YES error: &err]) {
                                       [flutterSoundPlayer logDebug: [NSString stringWithFormat:@"error enabling voiceProcessing => %@", err]];
                               } else {
                                       [flutterSoundPlayer logDebug: @"VoiceProcessing enabled"];
                               }
                               if (![outputNode setVoiceProcessingEnabled: YES error: &err]) {
                                       [flutterSoundPlayer logDebug: [NSString stringWithFormat:@"error enabling voiceProcessing => %@", err]];
                               } else {
                                       [flutterSoundPlayer logDebug: @"VoiceProcessing enabled"];
                               }

                       } else {
                               [flutterSoundPlayer logDebug: @"WARNING! VoiceProcessing is only available on iOS13+"];
                       }
               

// ================================

               AVAudioFormat* outputFormat = [[AVAudioFormat alloc] initStandardFormatWithSampleRate:
                                                                         48000
                                                                          channels: 2
                                                                       ];
               /*
               AVAudioPCMBuffer* buffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat: outputFormat
                                                                        frameCapacity: (AVAudioFrameCount)bufferSize];
               buffer.frameLength = (AVAudioFrameCount)buffer.frameCapacity;
               int nbChannel = [
                       buffer.format channelCount
               ];
               double sr = [buffer.format sampleRate];
               //memset(buffer.int16ChannelData[0], 0, buffer.frameLength * outputFormat.streamDescription->mBytesPerFrame); // zero fill
               //AVAudioMixerNode *mainMixer = [engine mainMixerNode];

           // The following line results in a kAudioUnitErr_FormatNotSupported -10868 error
              // [engine connect: inputNode to: outputNode format:buffer.format];
 */
// =======================
               //AVAudioFormat* format = [inputNode outputFormatForBus: 0];
               [engine connect: inputNode to: outputNode format: outputFormat];
               
                mPauseTime = 0.0; // Total number of seconds in pause mode
		mStartPauseTime = -1; // Not in paused mode
		systemTime = CACurrentMediaTime(); // The time when started
                ready2 = 0;
       }


       -(void)  stop
       {

                if (engine != nil)
                {
                         [engine stop];
                        engine = nil;
                }
       }

        -(bool) play
        {
                NSError* err;
                bool b = [engine startAndReturnError: &err];
                if (!b)
                {
                        NSString* s = err.localizedDescription;
                        [flutterSoundPlayer logDebug: [NSString stringWithFormat:@"Cannot start the audio engine => %@", err]];
                        [flutterSoundPlayer logDebug: s];
                }
                return b;
        }

       -(bool)  resume
       {
                return false;
       }

       -(bool)  pause
       {
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
                return PLAYER_IS_PLAYING; // ??? Not sure !!!
       }


        -(bool)  setVolume: (double) volume fadeDuration: (NSTimeInterval) fadeDuration // TODO
        {
                return true; // TODO
        }

        -(bool)  setPan: (double) pan // TODO
        {
                return true; // TODO
        }

        -(bool)  setSpeed: (double) speed // TODO
        {
                return true; // TODO
        }

        - (int) feed: (NSArray*)data interleaved: (BOOL)interleaved
        {
                return 0;
        }


//-------------------------------------------------------------------------------------------------------------------------------------------



@end
