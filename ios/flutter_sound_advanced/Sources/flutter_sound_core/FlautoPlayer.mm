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


#import <AVFoundation/AVFoundation.h>


#import "./include/flutter_sound_core/Flauto.h"
#import "./include/flutter_sound_core/FlautoPlayerEngine.h"
#import "./include/flutter_sound_core/FlautoPlayer.h"


static bool _isIosDecoderSupported [] =
{
		true, // DEFAULT
		true, // aacADTS
		false, // opusOGG
		true, // opusCAF
		true, // MP3
		false, // vorbisOGG
		false, // pcm16
		true, // pcm16WAV
		true, // pcm16AIFF
		true, // pcm16CAF
		true, // flac
		true, // aacMP4
        false, // amrNB
        false, // amrWB
        false, //pcm8,
        false, //pcmFloat32,
        false, // pcmWebM
        false, // opusWebM
        false, // vorbisWebM
        true, // pcmFloat32WAV


};


//-------------------------------------------------------------------------------------------------------------------------------

@implementation FlautoPlayer
{
        NSTimer* timer;
        double subscriptionDuration;
        double latentVolume;
        double latentSpeed;
        double latentPan;
        long latentSeek;
 
}

- (FlautoPlayer*)init: (NSObject<FlautoPlayerCallback>*) callback
{
        m_callBack = callback;
        latentVolume = -1.0;
        latentPan = -2.0;
        latentSpeed = -1.0;
        latentSeek = -1;
        subscriptionDuration = 0;
        timer = nil;
        return [super init];
}


- (t_PLAYER_STATE)getPlayerState
{
        if ( m_playerEngine == nil )
                return PLAYER_IS_STOPPED;
        return [m_playerEngine getStatus];
}



- (bool)isDecoderSupported: (t_CODEC)codec
{
        return _isIosDecoderSupported[codec];
}




- (void)releaseFlautoPlayer
{
        [self logDebug: @"IOS:--> releaseFlautoPlayer"];

        [ self stop];
        [self logDebug:  @"IOS:<-- releaseFlautoPlayer"];
}


- (void)stop
{
        [self stopTimer];
        if ( ([self getStatus] == PLAYER_IS_PLAYING) || ([self getStatus] == PLAYER_IS_PAUSED) )
        {
                [self logDebug:  @"IOS: ![audioPlayer stop]"];
                [m_playerEngine stop];
        }
        m_playerEngine = nil;

}


- (void)stopPlayer
{
        [self logDebug:  @"IOS:--> stopPlayer"];
        [self stop];
        [m_callBack stopPlayerCompleted: YES];
        [self logDebug:  @"IOS:<-- stopPlayer"];

}

- (bool)startPlayerFromMicSampleRate: (long)sampleRate nbChannels: (int)nbChannels interleaved: (BOOL)interleaved bufferSize: (long)bufferSize enableVoiceProcessing: (bool)enableVoiceProcessing
{
        [self logDebug:  @"IOS:--> startPlayerFromMicSampleRate"];
        [self stop]; // To start a fresh new playback
        AudioEngineFromMic* engine = [[AudioEngineFromMic alloc] init: self ];
        m_playerEngine = engine;
        [engine startPlayerFromURL: nil codec: (t_CODEC)0 channels: nbChannels interleaved: (BOOL)interleaved sampleRate: sampleRate bufferSize: (long)bufferSize ];
        bool b = [m_playerEngine play];
        if (b)
        {
                        [ m_callBack startPlayerCompleted: true duration: 0];
        }
        [self logDebug:  @"IOS:<-- startPlayerFromMicSampleRate"];
        return b; // TODO
}



- (NSString*) getpath:  (NSString*)path
{
         if ((path == nil)|| ([path class] == [[NSNull null] class]))
                return nil;
        if (![path containsString: @"/"]) // Temporary file
        {
                path = [NSTemporaryDirectory() stringByAppendingPathComponent: path];
        }
        return path;
}

- (NSString*) getUrl: (NSString*)path
{
         if ((path == nil)|| ([path class] == [[NSNull null] class]))
                return nil;
        path = [self getpath: path];
        NSURL* url = [NSURL URLWithString: path];
        return [url absoluteString];
}


- (bool)startPlayerCodec: (t_CODEC)codec
        fromURI: (NSString*)path
        fromDataBuffer: (NSData*)dataBuffer
        channels: (int)numChannels
        interleaved: (BOOL)interleaved
        sampleRate: (long)sampleRate
        bufferSize: (long)bufferSize
{
        [self logDebug:  @"IOS:--> startPlayer"];
        bool b = FALSE;
        [self stop]; // To start a fresh new playback

    if ( (path == nil ||  [path class] == [NSNull class] ) && (codec == pcm16 || codec == pcmFloat32) ) // Play From Stream
        m_playerEngine = [[AudioEngine alloc] init: self codec: codec channels: numChannels interleaved: interleaved sampleRate: sampleRate];
        else
                m_playerEngine = [[AudioPlayerFlauto alloc]init: self];
        
        if (dataBuffer != nil)
        {
                [m_playerEngine startPlayerFromBuffer: dataBuffer];
                bool b = [self play];

                if (!b)
                {
                        [self stop];
                } else
                {

                        [self startTimer];
                        long duration = [m_playerEngine getDuration];
                        [ m_callBack startPlayerCompleted: true duration: duration];
                }
                [self logDebug:  @"IOS:<-- startPlayer]"];

                return b;
        }
        path = [self getpath: path];
        bool isRemote = false;

        if (path != (id)[NSNull null] && path != nil)
        {
                NSURL* remoteUrl = [NSURL URLWithString: path];
                NSURL* audioFileURL = [NSURL URLWithString:path];

                if (remoteUrl && remoteUrl.scheme && remoteUrl.host)
                {
                        audioFileURL = remoteUrl;
                        isRemote = true;
                }

                  if (isRemote)
                  {
                        NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession]
                                dataTaskWithURL:audioFileURL completionHandler:
                                ^(NSData* data, NSURLResponse *response, NSError* error)
                                {

                                        // We must create a new Audio Player instance to be able to play a different Url
                                        //int toto = data.length;
                                        [self ->m_playerEngine startPlayerFromBuffer: data ];
                                        bool b = [self play];

                                        if (!b)
                                        {
                                                [self stop];
                                        } else
                                        {
                                                [self startTimer];
                                                long duration = [self ->m_playerEngine getDuration];
                                                [ self ->m_callBack startPlayerCompleted: true duration: duration];
                                        }
                                }];

                        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
                        [downloadTask resume];
                        [self logDebug:  @"IOS:<-- startPlayer"];

                        return true;

                } else
                {
                        [m_playerEngine startPlayerFromURL: audioFileURL codec: codec          channels: numChannels      interleaved: interleaved       sampleRate: sampleRate       bufferSize: (long)bufferSize];
                }
        } else
        {
                [m_playerEngine startPlayerFromURL: nil codec: codec channels: numChannels interleaved: interleaved sampleRate: sampleRate bufferSize: (long)bufferSize];
        }
        b = [self play];

        if (b)
        {
                 [self startTimer];
                long duration = [m_playerEngine getDuration];
                [ m_callBack startPlayerCompleted: true duration: duration];
        }
        [self logDebug: @"IOS:<-- startPlayer"];
        return b;
}

- (bool) play
{
        if (latentPan>=-1){
                [self setPan: latentPan];
        }
        if (latentVolume >= 0)
                [self setVolume: latentVolume fadeDuration: 0];
        if (latentSpeed >= 0)
        {
                [self setSpeed: latentSpeed] ;
        }
        if (latentSeek >= 0)
        {
                [self seekToPlayer: latentSeek] ;
        }
        
        return  [m_playerEngine play];

}

- (void)needSomeFood: (int)ln // Called from the engine, not from the app
{
        dispatch_async(dispatch_get_main_queue(),
        ^{
                [self ->m_callBack needSomeFood: ln];
         });
}
- (void)audioPlayerDidFinishPlaying: (BOOL)flag
{
        dispatch_async(dispatch_get_main_queue(),
        ^{
                [self ->m_callBack audioPlayerDidFinishPlaying: flag];
         });

}


- (void)nothingMoreToPlay
{
        
}

- (void)updateProgress: (NSTimer*)atimer
{
                long position = [self ->m_playerEngine getPosition];
                long duration = [self ->m_playerEngine getDuration];
                [self ->m_callBack updateProgressPosition: position duration: duration];
}


- (void)startTimer
{
        [self logDebug:  @"IOS:--> startTimer"];

        [self stopTimer];
        if (subscriptionDuration > 0)
        {
                dispatch_async(dispatch_get_main_queue(),
                ^{ // ??? Why Async ?  (no async for recorder)
                        self ->timer = [NSTimer scheduledTimerWithTimeInterval: self ->subscriptionDuration
                                                   target:self
                                                   selector:@selector(updateProgress:)
                                                   userInfo:nil
                                                   repeats:YES];
                });
        }
        [self logDebug:  @"IOS:<-- startTimer"];

}


- (void) stopTimer
{
        [self logDebug:  @"IOS:--> stopTimer"];

        if (timer != nil) {
                [timer invalidate];
                timer = nil;
        }
        [self logDebug:  @"IOS:<-- stopTimer"];
}



- (bool)pausePlayer
{
        [self logDebug:  @"IOS:--> pausePlayer"];

 
        if (timer != nil)
        {
                [timer invalidate];
                timer = nil;
        }
        if ([self getStatus] == PLAYER_IS_PLAYING )
        {
                        [m_playerEngine pause];
        }
        else
                [self logDebug:  @"IOS: audioPlayer is not Playing"];

          [m_callBack pausePlayerCompleted: YES];
          [self logDebug:  @"IOS:<-- pause"];

          return true;

}






- (bool)resumePlayer
{
        [self logDebug:  @"IOS:--> resumePlayer"];
        bool b = [m_playerEngine resume];
        if (!b){}
        
            
        [self startTimer];
        [self logDebug:  @"IOS:<-- resumePlayer"];

        [m_callBack resumePlayerCompleted: b];
        return b;
}





- (int)feed:(NSArray*)data interleaved: (BOOL)interleaved
{
		try
		{
            int r = [m_playerEngine feed: data interleaved: interleaved];
            return r;
		} catch (NSException* e)
		{
            return -1;
  		}
}



- (void)seekToPlayer: (long)t
{
        [self logDebug: @"IOS:--> seekToPlayer"];
        if (m_playerEngine != nil)
        {
                latentSeek = -1;
                [m_playerEngine seek: t];
                [self updateProgress: nil];
        } else
        {
                latentSeek = t;
        }
        [self logDebug:  @"IOS:<-- seekToPlayer"];
}



- (void)setVolume:(double) volume fadeDuration:(NSTimeInterval)duration // volume is between 0.0 and 1.0
{
        [self logDebug:  @"IOS:--> setVolume"];
        latentVolume = volume;
        if (m_playerEngine)
        {
                [m_playerEngine setVolume: volume fadeDuration: duration];
        } else
        {
        }
        [self logDebug: @"IOS:<-- setVolume"];
}

- (void)setPan:(double) pan // speed is between 0.0 and 1.0 to slow and 1.0 to n to accelearate
{
        [self logDebug:  @"IOS:--> setPan"];
        latentPan = pan;
        if (m_playerEngine )
        {
                [m_playerEngine setPan: pan ];
        } else
        {
        }
        [self logDebug: @"IOS:<-- setPan"];
}


- (void)setSpeed:(double) speed // speed is between 0.0 and 1.0 to slow and 1.0 to n to accelearate
{
        [self logDebug:  @"IOS:--> setSpeed"];
        latentSpeed = speed;
        if (m_playerEngine )
        {
                [m_playerEngine setSpeed: speed ];
        } else
        {
        }
        [self logDebug: @"IOS:<-- setSpeed"];
}



- (long)getPosition
{
        return [m_playerEngine getPosition];
}

- (long)getDuration
{
         return [m_playerEngine getDuration];
}


- (NSDictionary*)getProgress
{
        [self logDebug:  @"IOS:--> getProgress"];

        NSNumber *position = [NSNumber numberWithLong: [m_playerEngine getPosition]];
        NSNumber *duration = [NSNumber numberWithLong: [m_playerEngine getDuration]];
        NSDictionary* dico = @{ @"position": position, @"duration": duration, @"playerStatus": [self getPlayerStatus] };
        [self logDebug:  @"IOS:<-- getProgress"];
        return dico;

}


- (void)setSubscriptionDuration: (long)d
{
        [self logDebug:  @"IOS:--> setSubscriptionDuration"];

        subscriptionDuration = ((double)d)/1000;
        if (m_playerEngine != nil)
        {
                [self startTimer];
        }
        [self logDebug:  @"IOS:<-- setSubscriptionDuration"];

}


// post fix with _FlutterSound to avoid conflicts with common libs including path_provider
- (NSString*) GetDirectoryOfType_FlutterSound: (NSSearchPathDirectory) dir
{
        NSArray* paths = NSSearchPathForDirectoriesInDomains(dir, NSUserDomainMask, YES);
        return [paths.firstObject stringByAppendingString:@"/"];
}


- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)thePlayer successfully:(BOOL)flag
{
        [self logDebug:  @"IOS:--> @audioPlayerDidFinishPlaying"];

        dispatch_async(dispatch_get_main_queue(), ^{
                // Whe don't stop the player. This is Flutter responsibility
                //[self stopTimer];
                //[ self ->m_playerEngine stop];
                //self ->m_playerEngine = nil;
                [self logDebug:  @"IOS:--> ^audioPlayerFinishedPlaying"];

                [self ->m_callBack  audioPlayerDidFinishPlaying: true];
                [self logDebug:  @"IOS:<-- ^audioPlayerFinishedPlaying"];
         });
 
         [self logDebug:  @"IOS:<-- @audioPlayerDidFinishPlaying"];
}

- (t_PLAYER_STATE)getStatus
{
        if ( m_playerEngine == nil )
                return PLAYER_IS_STOPPED;
        return [m_playerEngine getStatus];
}

- (NSNumber*)getPlayerStatus
{
        return [NSNumber numberWithInt: [self getStatus]];
}


- (void)logDebug: (NSString*)msg
{
        [m_callBack log: DBG msg: msg];
}


@end
//---------------------------------------------------------------------------------------------

