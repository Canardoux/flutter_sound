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



#import <AVFoundation/AVFoundation.h>


#import "Flauto.h"
#import "FlautoPlayerEngine.h"
#import "FlautoPlayer.h"
//#import "FlautoTrackPlayer.h"
#import "FlautoTrack.h"




static bool _isIosDecoderSupported [] =
{
		true, // DEFAULT
		true, // aacADTS
		true, // opusOGG
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
  

};


//-------------------------------------------------------------------------------------------------------------------------------

@implementation FlautoPlayer
{
        NSTimer* timer;
        double subscriptionDuration;
  

}

- (FlautoPlayer*)init: (NSObject<FlautoPlayerCallback>*) callback
{
        m_callBack = callback;
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



- (bool)initializeFlautoPlayerFocus:
                (t_AUDIO_FOCUS)focus
                category: (t_SESSION_CATEGORY)category
                mode: (t_SESSION_MODE)mode
                audioFlags: (int)audioFlags
                audioDevice: (t_AUDIO_DEVICE)audioDevice
{
        NSLog(@"IOS:--> initializeFlautoPlayer");
        BOOL r = [self setAudioFocus: focus category: category mode: mode audioFlags: audioFlags audioDevice: audioDevice ];
        [m_callBack openAudioSessionCompleted: r];
        NSLog(@"IOS:<-- initializeFlautoPlayer");
        return r;
}


- (void)releaseFlautoPlayer
{
        NSLog(@"IOS:--> releaseFlautoPlayer");
        NSLog(@"IOS:<-- releaseFlautoPlayer");
}


- (bool)setCategory: (NSString*)categ mode:(NSString*)mode options:(int)options
{
        NSLog(@"IOS:--> setCategory");
        BOOL b = [[AVAudioSession sharedInstance]
                setCategory:  categ // AVAudioSessionCategoryPlayback
                mode: mode
                options: options
                error: nil];
        if (b){}

      NSLog(@"IOS:<-- setCategory");
      return b;
}



- (bool)setActive: (BOOL)enabled
{
       BOOL b = [[AVAudioSession sharedInstance]  setActive:enabled error:nil] ;
       return b;
}


- (void)stopPlayer
{
        NSLog(@"IOS:--> stopPlayer");
        [self stopTimer];
        if ( ([self getStatus] == PLAYER_IS_PLAYING) || ([self getStatus] == PLAYER_IS_PAUSED) )
        {
                NSLog(@"IOS: ![audioPlayer stop]");
                [m_playerEngine stop];
        }
        m_playerEngine = nil;
        NSLog(@"IOS:<-- stopPlayer");
}



- (bool)startPlayerCodec: (t_CODEC)codec
        fromURI: (NSString*)path
        fromDataBuffer: (NSData*)dataBuffer
        channels: (int)numChannels
        sampleRate: (long)sampleRate
{
        NSLog(@"IOS:--> startPlayer");
        bool b = FALSE;
        if (!hasFocus) // We always acquire the Audio Focus (It could have been released by another session)
        {
                hasFocus = TRUE;
                b = [[AVAudioSession sharedInstance]  setActive: hasFocus error:nil] ;
        }

        [self stopPlayer]; // To start a fresh new playback

        if ( (path == nil ||  [path class] == [NSNull class] ) && codec == pcm16)
                m_playerEngine = [[AudioEngine alloc] init: self ];
        else
                m_playerEngine = [[AudioPlayer alloc]init: self];
        if (dataBuffer != nil)
        {
                b = [m_playerEngine startPlayerFromBuffer: dataBuffer ];
                if (!b)
                {
                        [self stopPlayer];
                } else
                {
                        [self startTimer];
                        long duration = [m_playerEngine getDuration];
                        [ m_callBack startPlayerCompleted: duration];
                }
                NSLog(@"IOS:<-- startPlayer");
                return b;
        }

        bool isRemote = false;
   
        if (path != (id)[NSNull null])
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
                                        bool b = [self ->m_playerEngine startPlayerFromBuffer: data];
                                        if (!b)
                                        {
                                                [self stopPlayer];
                                        } else
                                        {
                                                [self startTimer];
                                                long duration = [self ->m_playerEngine getDuration];
                                                [ self ->m_callBack startPlayerCompleted: duration];
                                        }
                                }];

                        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
                        [downloadTask resume];
                        //[self startTimer];
                        NSLog(@"IOS:<-- startPlayer");
                        return true;

                } else
                {
                        b = [m_playerEngine startPlayerFromURL: audioFileURL codec: codec channels: numChannels sampleRate: sampleRate];
                }
        } else
        {
                b = [m_playerEngine startPlayerFromURL: nil codec: codec channels: numChannels sampleRate: sampleRate];
        }
        if (b)
        {
                [self startTimer];
                long duration = [m_playerEngine getDuration];
                [ m_callBack startPlayerCompleted: duration];
        }
        NSLog(@"IOS:<-- startPlayer");
        return b;
}


- (void)needSomeFood: (int)ln
{
        [m_callBack needSomeFood: ln];
}

- (void)updateProgress: (NSTimer*)atimer
{
         dispatch_async(dispatch_get_main_queue(), ^{
                long position = [self ->m_playerEngine getPosition];
                long duration = [self ->m_playerEngine getDuration];
                [self ->m_callBack updateProgressPositon: position duration: duration];
         });
}


- (void)startTimer
{
        NSLog(@"IOS:--> startTimer");
        [self stopTimer];
        dispatch_async(dispatch_get_main_queue(),
        ^{ // ??? Why Async ?  (no async for recorder)
                self ->timer = [NSTimer scheduledTimerWithTimeInterval: self ->subscriptionDuration
                                           target:self
                                           selector:@selector(updateProgress:)
                                           userInfo:nil
                                           repeats:YES];
        });
        NSLog(@"IOS:<-- startTimer");
}


- (void) stopTimer
{
        NSLog(@"IOS:--> stopTimer");
        if (timer != nil) {
                [timer invalidate];
                timer = nil;
        }
        NSLog(@"IOS:<-- stopTimer");
        
}


- (bool)startPlayerFromTrack: (Track*)track canPause: (bool)canPause canSkipForward: (bool)canSkipForward canSkipBackward: (bool)canSkipBackward
        progress: (NSNumber*)progress duration: (NSNumber*)duration removeUIWhenStopped: (bool)removeUIWhenStopped defaultPauseResume: (bool)defaultPauseResume;
{
        assert(false);
}


- (bool)pausePlayer
{
        NSLog(@"IOS:--> pausePlayer");
        if (timer != nil)
        {
                [timer invalidate];
                timer = nil;
        }
        if ([self getStatus] == PLAYER_IS_PLAYING)
        {
                [m_playerEngine pause];
        }
        else
                NSLog(@"IOS: audioPlayer is not Playing");

         /*
         long position =   [m_playerEngine getPosition];
         long duration =   [m_playerEngine getDuration];
         if (duration - position < 80) // PATCH [LARPOUX]
          {
                NSLog (@"IOS: !patch [LARPOUX]");
                [self stopPlayer];
                dispatch_async(dispatch_get_main_queue(), ^{
                        NSLog(@"IOS:--> ^audioPlayerFinishedPlaying");
                        [self invokeMethod:@"audioPlayerFinishedPlaying" numberArg: [self getPlayerStatus]];
                        NSLog(@"IOS:<-- ^audioPlayerFinishedPlaying");
                 });

          }
          */


          bool b =  ( [self getStatus] == PLAYER_IS_PAUSED);
          if (!b)
          {
                NSLog(@"IOS: AudioPlayer : cannot pause!!!");
          }

          NSLog(@"IOS:<-- pause");
          return b;

}






- (bool)resumePlayer
{
        NSLog(@"IOS:--> resume");
        // long position =   [m_playerEngine getPosition];
        // long duration =   [m_playerEngine getDuration];
        /*
        if (duration - position < 80) // PATCH [LARPOUX]
        {
                NSLog (@"IOS: !patch [LARPOUX]");
                [self stopPlayer];
                dispatch_async(dispatch_get_main_queue(), ^{
                        NSLog(@"IOS:--> ^audioPlayerFinishedPlaying");
                        [self invokeMethod:@"audioPlayerFinishedPlaying" numberArg: [self getPlayerStatus]];
                        NSLog(@"IOS:<-- ^audioPlayerFinishedPlaying");
                 });

        } else
        */
        {

                // if ( [self getStatus] == IS_PAUSED ) // (after a long pause with the lock screen, the status is not "PAUSED"
                {
                       // [audioPlayer setDelegate: self]; // TRY
                        NSLog(@"IOS: play!");
                        bool b = [m_playerEngine resume];
                        if (b){}
                } //else
                {
                        //NSLog(@"IOS: ~play! (status is not paused)" );
                }
                [self startTimer];
        }
        bool b = ([self getStatus] == PLAYER_IS_PLAYING);
        if (!b)
        {
                 NSLog(@"IOS: AudioPlayer : cannot resume!!!");
        }
        NSLog(@"IOS:<-- resume");
        return b;
}




- (void)setUIProgressBar: (NSNumber*)pos duration: (NSNumber*)duration
{
        assert(false);
}

- (void)nowPlaying: (Track*)track canPause: (bool)canPause canSkipForward: (bool)canSkipForward canSkipBackward: (bool)canSkipBackward
                defaultPauseResume: (bool)defaultPauseResume progress: (NSNumber*)progress duration: (NSNumber*)duration

{
        assert(false);
}




- (int)feed:(NSData*)data
{
		try
		{
                        int r = [m_playerEngine feed: data];
			return r;
		} catch (NSException* e)
		{
                        return -1;
  		}

}




- (void)seekToPlayer: (long)t
{
        NSLog(@"IOS:--> seekToPlayer");
        if (m_playerEngine != nil)
        {
                [m_playerEngine seek: t];
                [self updateProgress: nil];
        } else
        {
        }
         NSLog(@"IOS:<-- seekToPlayer");
}



- (void)setVolume:(double) volume
{
        NSLog(@"IOS:--> setVolume");
        if (m_playerEngine)
        {
                [m_playerEngine setVolume: volume ];
        } else
        {
        }
        NSLog(@"IOS:<-- setVolume");
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
        NSLog(@"IOS:--> getProgress");
        NSNumber *position = [NSNumber numberWithLong: [m_playerEngine getPosition]];
        NSNumber *duration = [NSNumber numberWithLong: [m_playerEngine getDuration]];
        NSDictionary* dico = @{ @"position": position, @"duration": duration, @"playerStatus": [self getPlayerStatus] };
        NSLog(@"IOS:--> getProgress");
        return dico;

}


- (void)setSubscriptionDuration: (long)d
{
        NSLog(@"IOS:--> setSubscriptionDuration");
        subscriptionDuration = ((double)d)/1000;
        NSLog(@"IOS:<-- setSubscriptionDuration");
}


// post fix with _FlutterSound to avoid conflicts with common libs including path_provider
- (NSString*) GetDirectoryOfType_FlutterSound: (NSSearchPathDirectory) dir
{
        NSArray* paths = NSSearchPathForDirectoriesInDomains(dir, NSUserDomainMask, YES);
        return [paths.firstObject stringByAppendingString:@"/"];
}


- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)thePlayer successfully:(BOOL)flag
{
        NSLog(@"IOS:--> @audioPlayerDidFinishPlaying");
        [self stopTimer];
        [m_playerEngine stop];
        m_playerEngine = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"IOS:--> ^audioPlayerFinishedPlaying");
                [self ->m_callBack  audioPlayerDidFinishPlaying: true];
                NSLog(@"IOS:<-- ^audioPlayerFinishedPlaying");
         });

       NSLog(@"IOS:<-- @audioPlayerDidFinishPlaying");
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
@end
//---------------------------------------------------------------------------------------------

