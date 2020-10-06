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





#import "FlautoPlayer.h"
#import "PlayerEngine.h"
#import "FlautoTrackPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import "PlayerEngine.h"
#import "Track.h"



#define IS_STOPPED 0
#define IS_PLAYING 1
#define IS_PAUSED 2



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
        FlautoPlayerCallback* m_callBack;
        NSObject<PlayerEngineInterface>*  m_playerEngine;
 

}

- (t_PLAYER_STATUS)getPlayerState
{
        if ( m_playerEngine == nil )
                return PLAYER_IS_STOPPED;
        return [m_playerEngine getStatus];
}



- (bool)isDecoderSupported: (t_CODEC)codec
{
        return _isIosDecoderSupported[codec];
}



- (void)initializeFlautoPlayer: (int)toto
{
        NSLog(@"IOS:--> initializeFlautoPlayer");
        /* TODO
        BOOL r = [self setAudioFocus: call ];
        [self invokeMethod:@"openAudioSessionCompleted" boolArg: r];

        if (r)
                result( [self getPlayerStatus]);
        else
                [FlutterError
                                errorWithCode:@"Audio Player"
                                message:@"Open session failure"
                                details:nil];
        */
        NSLog(@"IOS:<-- initializeFlautoPlayer");
}



- (void)updateProgress:(NSTimer*) atimer
{
        dispatch_async(dispatch_get_main_queue(),
        ^{
                // TODO NSNumber *position = [NSNumber numberWithLong: [self ->m_playerEngine getPosition]];
                // TODO NSNumber *duration = [NSNumber numberWithLong: [self ->m_playerEngine getDuration]];
                // TODO NSDictionary* dico = @{ @"slotNo": [NSNumber numberWithInt: slotNo], @"position": position, @"duration": duration, @"playerStatus": [self getPlayerStatus] };
                // TODO [self invokeMethod:@"updateProgress" dico: dico];
        });
}


- (void)startTimer
{
        NSLog(@"IOS:--> startTimer");
        [self stopTimer];
        dispatch_async(dispatch_get_main_queue(), ^{ // ??? Why Async ?  (no async for recorder)
        self ->timer = [NSTimer scheduledTimerWithTimeInterval: self ->subscriptionDuration
                                           target:self
                                           selector:@selector(updateProgress:)
                                           userInfo:nil
                                           repeats:YES];
        });
        NSLog(@"IOS:<-- startTimer");
}


- (void) stopTimer{
        NSLog(@"IOS:--> stopTimer");
        if (timer != nil) {
                [timer invalidate];
                timer = nil;
        }
        NSLog(@"IOS:<-- stopTimer");}



- (bool)startPlayerCodec: (t_CODEC)codec
        fromURI: (NSString*)path
        fromDataBuffer: (NSData*)dataBuffer
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
                m_playerEngine = [[AudioEngine alloc] init: self ]; // TODOaudioSettings: call.arguments];
        else
                m_playerEngine = [[AudioPlayer alloc]init: self];
        if ([dataBuffer class] != [NSNull class])
        {
                b = [m_playerEngine startPlayerFromBuffer: dataBuffer];
                if (!b)
                {
                        [self stopPlayer];
                } else
                {
                        [self startTimer];
                        // TODO // long duration = [m_playerEngine getDuration];
                        // TODO // int d = (int)duration;
                        // TODO // NSNumber* nd = [NSNumber numberWithInt: d];
                        // TODO // NSDictionary* dico = @{ @"slotNo": [NSNumber numberWithInt: slotNo], @"state":  [self getPlayerStatus], @"duration": nd };
                        // TODO //[self invokeMethod:@"startPlayerCompleted" dico: dico ];

                        // TODO //result([self getPlayerStatus]);
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
                                                // TODO //long duration = [self ->m_playerEngine getDuration];
                                                // TODO //int d = (int)duration;
                                                // TODO //NSNumber* nd = [NSNumber numberWithInt: d];
                                                // TODO //NSDictionary* dico = @{ @"slotNo": [NSNumber numberWithInt: slotNo], @"state":  [self getPlayerStatus], @"duration": nd };
                                                // TODO //[self invokeMethod:@"startPlayerCompleted" dico: dico ];
                                        }
                                        //return b;
                                }];

                        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
                        // TODO // NSString *filePath = audioFileURL.absoluteString;
                        [downloadTask resume];
                        [self startTimer];
                        NSLog(@"IOS:<-- startPlayer");
                        return true;

                } else
                {
                        b = [m_playerEngine startPlayerFromURL: audioFileURL];
                }
        } else
        {
                b = [m_playerEngine startPlayerFromURL: nil];
        }
        if (b)
        {
                /* TODO
                long duration = [m_playerEngine getDuration];
                int d = (int)duration;
                NSNumber* nd = [NSNumber numberWithInt: d];
                NSDictionary* dico = @{ @"slotNo": [NSNumber numberWithInt: slotNo], @"state":  [self getPlayerStatus], @"duration": nd };
                [self invokeMethod:@"startPlayerCompleted" dico: dico ];
                */
                [self startTimer];
        }
        NSLog(@"IOS:<-- startPlayer");
        return b;
}

- (bool)startPlayerFromTrack: (Track*)track
{
        assert(false);
}






- (bool)pausePlayer
{
        NSLog(@"IOS:--> pause");
        if (timer != nil)
        {
                [timer invalidate];
                timer = nil;
        }
        if ([self getStatus] == IS_PLAYING)
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


          bool b =  ( [self getStatus] == IS_PAUSED);
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
        bool b = ([self getStatus] == IS_PLAYING);
        if (!b)
        {
                 NSLog(@"IOS: AudioPlayer : cannot resume!!!");
        }
        NSLog(@"IOS:<-- resume");
        return b;
}


- (void)setUIProgressBar: (double)call
{
        assert(false);
}

- (void)nowPlaying: (Track*)track
{
        assert(false);
}


/* TODO


- (void)setAudioFocus: (FlutterMethodCall*)call result: (FlutterResult)result
{
        NSLog(@"IOS:--> setAudioFocus");
        BOOL r = [self setAudioFocus: call ];
        if (r)
                result([self getPlayerStatus]);
        else
                [FlutterError
                                errorWithCode:@"Audio Player"
                                message:@"Open session failure"
                                details:nil];
        NSLog(@"IOS:<-- setAudioFocus");
       
}


- (void)releaseFlautoPlayer: (FlutterMethodCall*)call result: (FlutterResult)result
{
        NSLog(@"IOS:--> releaseFlautoPlayer");
        [super releaseSession];
        result([self getPlayerStatus]);
        NSLog(@"IOS:<-- releaseFlautoPlayer");
}
*/

- (bool)setCategory: (NSString*)categ mode:(NSString*)mode options:(int)options
{
       NSLog(@"IOS:--> setCategory");
         // Able to play in silent mode
        BOOL b = [[AVAudioSession sharedInstance]
                setCategory:  categ // AVAudioSessionCategoryPlayback
                mode: mode
                options: options
                error: nil];
        if (b){}

      NSLog(@"IOS:<-- setCategory");
      return b;
}


- (bool)setActive:(BOOL)enabled
{
       BOOL b = [[AVAudioSession sharedInstance]  setActive:enabled error:nil] ;
       return b;
}


- (void)stopPlayer
{
        NSLog(@"IOS:--> stopPlayer");
        [self stopTimer];
        if ( ([self getStatus] == IS_PLAYING) || ([self getStatus] == IS_PAUSED) )
        {
                NSLog(@"IOS: ![audioPlayer stop]");
                [m_playerEngine stop];
        }
        m_playerEngine = nil;
        NSLog(@"IOS:<-- stopPlayer");
}



/*
- (void)startPlayer:(FlutterMethodCall*)call result: (FlutterResult)result
{
        NSLog(@"IOS:--> startPlayer");
        bool b = FALSE;
        if (!hasFocus) // We always acquire the Audio Focus (It could have been released by another session)
        {
                hasFocus = TRUE;
                b = [[AVAudioSession sharedInstance]  setActive: hasFocus error:nil] ;
        }

        [self stopPlayer]; // To start a fresh new playback

        NSString* path = (NSString*)call.arguments[@"fromURI"];
        t_CODEC codec = (t_CODEC)([(NSNumber*)call.arguments[@"codec"] intValue]);
        if ( (path == nil ||  [path class] == [NSNull class] ) && codec == pcm16)
                player = [[AudioPlayerEngine alloc] init: self audioSettings: call.arguments];
        else
                player = [[AudioPlayer alloc]init: self];
        FlutterStandardTypedData* dataBuffer = (FlutterStandardTypedData*)call.arguments[@"fromDataBuffer"];
        if ([dataBuffer class] != [NSNull class])
        {
                b = [player startPlayerFromBuffer:  [dataBuffer data] ];
                if (!b)
                {
                        [self stopPlayer];
                        [FlutterError
                        errorWithCode:@"Audio Player"
                        message:@"Play failure"
                        details:nil];
                } else
                {
                        [self startTimer];
                        long duration = [player getDuration];
                        int d = (int)duration;
                        NSNumber* nd = [NSNumber numberWithInt: d];
                        NSDictionary* dico = @{ @"slotNo": [NSNumber numberWithInt: slotNo], @"state":  [self getPlayerStatus], @"duration": nd };
                        [self invokeMethod:@"startPlayerCompleted" dico: dico ];

                        result([self getPlayerStatus]);
                }
                NSLog(@"IOS:<-- startPlayer");
                return;
        }

        bool isRemote = false;
   
        if (path != [NSNull null])
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
                                dataTaskWithURL:audioFileURL completionHandler:^(NSData *data, NSURLResponse *response, NSError* error)
                        {

                                // We must create a new Audio Player instance to be able to play a different Url
                                bool b = [player startPlayerFromBuffer: data];
                                if (!b)
                                {
                                        [self stopPlayer];
                                        return;
                                }
                                long duration = [player getDuration];
                                int d = (int)duration;
                                NSNumber* nd = [NSNumber numberWithInt: d];
                                NSDictionary* dico = @{ @"slotNo": [NSNumber numberWithInt: slotNo], @"state":  [self getPlayerStatus], @"duration": nd };
                                [self invokeMethod:@"startPlayerCompleted" dico: dico ];
                                return;
                        }];

                        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
                        NSString *filePath = audioFileURL.absoluteString;
                        [downloadTask resume];
                        [self startTimer];
                        result([self getPlayerStatus]);
                        NSLog(@"IOS:<-- startPlayer");
                        return;

                } else
                {
                        b = [player startPlayerFromURL: audioFileURL];
                }
        } else
        {
                b = [player startPlayerFromURL: nil];
        }
        if (b)
        {
                long duration = [player getDuration];
                int d = (int)duration;
                NSNumber* nd = [NSNumber numberWithInt: d];
                NSDictionary* dico = @{ @"slotNo": [NSNumber numberWithInt: slotNo], @"state":  [self getPlayerStatus], @"duration": nd };
                [self invokeMethod:@"startPlayerCompleted" dico: dico ];
                [self startTimer];
                result([self getPlayerStatus]);
        } else
        {
                        [self stopPlayer];
                        result([FlutterError
                        errorWithCode:@"Audio Player"
                        message:@"Play failure"
                        details:nil]);
        }
        NSLog(@"IOS:<-- startPlayer");
}
*/



- (void)needSomeFood: (int) ln
{
        // TODO //[self invokeMethod:@"needSomeFood" numberArg: [NSNumber numberWithInt: ln] ];
}

- (bool)pause
{
          NSLog(@"IOS:--> pause");
          if (timer != nil)
          {
              [timer invalidate];
              timer = nil;
          }
          if ([self getStatus] == IS_PLAYING)
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


          bool b =  ( [self getStatus] == IS_PAUSED);
          if (!b)
          {
                NSLog(@"IOS: AudioPlayer : cannot pause!!!");
          }

          NSLog(@"IOS:<-- pause");
          return b;
 }

- (bool)resume
{
        NSLog(@"IOS:--> resume");
        /*
        long position =   [player getPosition];
        long duration =   [player getDuration];
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
        bool b;
        {

                // if ( [self getStatus] == IS_PAUSED ) // (after a long pause with the lock screen, the status is not "PAUSED"
                {
                       // [audioPlayer setDelegate: self]; // TRY
                        NSLog(@"IOS: play!");
                        b = [m_playerEngine resume];
                } //else
                {
                        //NSLog(@"IOS: ~play! (status is not paused)" );
                }
                [self startTimer];
        }
        b = ([self getStatus] == IS_PLAYING);
        if (!b)
        {
                 NSLog(@"IOS: AudioPlayer : cannot resume!!!");
        }
        NSLog(@"IOS:<-- resume");
        return b;
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
                // TODO // [self invokeMethod:@"audioPlayerFinishedPlaying" numberArg: [self getPlayerStatus]];
                NSLog(@"IOS:<-- ^audioPlayerFinishedPlaying");
         });

       NSLog(@"IOS:<-- @audioPlayerDidFinishPlaying");
}

- (t_PLAYER_STATUS)getStatus
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

