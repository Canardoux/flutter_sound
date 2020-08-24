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





#import "FlutterSoundPlayer.h"
#import "TrackPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import "FlautoPlayerManager.h"



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
};




@implementation FlutterSoundPlayer
{
        //AVAudioPlayer* audioPlayer; // In the interface
        NSTimer *timer;
        double subscriptionDuration;
}


- (FlutterSoundPlayer*)init: (FlutterMethodCall*)call
{
        return [super init: call];
}

- (void)isDecoderSupported:(t_CODEC)codec result: (FlutterResult)result
{
        NSLog(@"IOS:--> isDecoderSupported");
        NSNumber*  b = [NSNumber numberWithBool: _isIosDecoderSupported[codec] ];
        result(b);
        NSLog(@"IOS:<-- isDecoderSupported");
}



-(FlautoPlayerManager*) getPlugin
{
        return flautoPlayerManager;
}


- (void)initializeFlautoPlayer: (FlutterMethodCall*)call result: (FlutterResult)result
{
        NSLog(@"IOS:--> initializeFlautoPlayer");
        BOOL r = [self setAudioFocus: call ];
        [self invokeMethod:@"openAudioSessionCompleted" boolArg: r];

        if (r)
                result( [self getPlayerStatus]);
        else
                [FlutterError
                                errorWithCode:@"Audio Player"
                                message:@"Open session failure"
                                details:nil];
        NSLog(@"IOS:<-- initializeFlautoPlayer");
}


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

- (void)setCategory: (NSString*)categ mode:(NSString*)mode options:(int)options result:(FlutterResult)result
{
       NSLog(@"IOS:--> setCategory");
         // Able to play in silent mode
        BOOL b = [[AVAudioSession sharedInstance]
                setCategory:  categ // AVAudioSessionCategoryPlayback
                mode: mode
                options: options
                error: nil];

        if (b)
                result([self getPlayerStatus]);
        else
                [FlutterError
                                errorWithCode:@"Audio Player"
                                message:@"setCategory failure"
                                details:nil];
      NSLog(@"IOS:<-- setCategory");
}

- (void)setActive:(BOOL)enabled result:(FlutterResult)result
{
        NSLog(@"IOS:--> setActive");
        BOOL b = [[AVAudioSession sharedInstance]  setActive:enabled error:nil] ;
        if (b)
                result([self getPlayerStatus]);
        else
                [FlutterError
                                errorWithCode:@"Audio Player"
                                message:@"setActive failure"
                                details:nil];
       NSLog(@"IOS:<-- setActive");
}


- (void)stopPlayer:(FlutterMethodCall*)call  result:(FlutterResult)result
{
        NSLog(@"IOS:--> stopPlayer");
        [self stopPlayer];
        NSNumber* status = [self getPlayerStatus];
        result(status);
        NSLog(@"IOS:<-- stopPlayer - status = %s" , [[status stringValue] cString]);
}



- (void)getPlayerState:(FlutterMethodCall*)call result: (FlutterResult)result
{
                result([self getPlayerStatus]);
}




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
        FlutterStandardTypedData* dataBuffer = (FlutterStandardTypedData*)call.arguments[@"fromDataBuffer"];
        if ([dataBuffer class] != [NSNull class])
        {
                audioPlayer = [[AVAudioPlayer alloc] initWithData: [dataBuffer data] error: nil];
                audioPlayer.delegate = self;
                b = [audioPlayer play];
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
                        long duration = (long)(audioPlayer.duration * 1000);
                        int d = (int)duration;
                        NSNumber* nd = [NSNumber numberWithInt: d];
                        [self invokeMethod:@"startPlayerCompleted" numberArg: nd ];
                        result([self getPlayerStatus]);
                }
                NSLog(@"IOS:<-- startPlayer");
                return;
        }

        bool isRemote = false;
        if ([path class] == [NSNull class])
        {
                [self stopPlayer];
                result([FlutterError
                errorWithCode:@"Audio Player"
                message:@"Play failure"
                details:nil]);
                NSLog(@"IOS:<-- startPlayer");
                return;

        }
        NSURL *remoteUrl = [NSURL URLWithString: path];
        NSURL *audioFileURL = [NSURL URLWithString:path];
        
        if (remoteUrl && remoteUrl.scheme && remoteUrl.host)
        {
                audioFileURL = remoteUrl;
                isRemote = true;
        }

          if (isRemote)
          {
                NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession]
                        dataTaskWithURL:audioFileURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                {

                        // We must create a new Audio Player instance to be able to play a different Url
                        audioPlayer = [[AVAudioPlayer alloc] initWithData:data error:nil];
                        audioPlayer.delegate = self;


                        BOOL b = [self ->audioPlayer play];
                        if (!b)
                        {
                                [self stopPlayer];
                                result([FlutterError
                                errorWithCode:@"Audio Player"
                                message:@"Play failure"
                                details:nil]);

                        }
                }];

                [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
                NSString *filePath = audioFileURL.absoluteString;
                [downloadTask resume];
                b = true;
        } else
        {
                audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioFileURL error:nil];
                audioPlayer.delegate = self;
                b = [audioPlayer play];
        }
         if (b)
        {
                long duration = (long)(audioPlayer.duration * 1000);
                int d = (int)duration;
                NSNumber* nd = [NSNumber numberWithInt: d];
                [self invokeMethod:@"startPlayerCompleted" numberArg: nd ];
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


- (void)startPlayerFromTrack:(FlutterMethodCall*)call result: (FlutterResult)result
{
                       result([FlutterError
                                errorWithCode:@"Audio Player"
                                message:@"Start Player From Track failure"
                                details:nil]);
}

- (void)nowPlaying:(FlutterMethodCall*)call result: (FlutterResult)result
{
                       result([FlutterError
                                errorWithCode:@"Audio Player"
                                message:@"Now Playing failure"
                                details:nil]);
}


- (void)setUIProgressBar:(FlutterMethodCall*)call result: (FlutterResult)result;
{
                       result([FlutterError
                                errorWithCode:@"Audio Player"
                                message:@"setUIProgressBar failure"
                                details:nil]);
}


- (void)stopPlayer
{
        NSLog(@"IOS:--> stopPlayer");
        [self stopTimer];
        if ( ([self getStatus] == IS_PLAYING) || ([self getStatus] == IS_PAUSED) )
        {
                NSLog(@"IOS: ![audioPlayer stop]");
                [audioPlayer stop];
        }
        audioPlayer = nil;
        NSLog(@"IOS:<-- stopPlayer");
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
                [audioPlayer pause];
           }
          else
                NSLog(@"IOS: audioPlayer is not Playing");

         long duration =  (long)(audioPlayer.duration * 1000);
         long position = (long)(audioPlayer.currentTime * 1000);
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
        long duration =  (long)(audioPlayer.duration * 1000);
        long position = (long)(audioPlayer.currentTime * 1000);
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
        {

                if ( [self getStatus] == IS_PAUSED )
                {
                       // [audioPlayer setDelegate: self]; // TRY
                        NSLog(@"IOS: play!");
                        bool b = [audioPlayer play];
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

- (void)pausePlayer:(FlutterResult)result
{
        NSLog(@"IOS:--> pausePlayer");
        if ([self pause])
        {
                result([self getPlayerStatus]);
        } else
        {
                       result([FlutterError
                                  errorWithCode:@"Audio Player"
                                  message:@"audioPlayer pause failure"
                                  details:nil]);

        }
        NSLog(@"IOS:<-- pausePlayer");
}

- (void)resumePlayer:(FlutterResult)result
{
        NSLog(@"IOS:--> resumePlayer");
        if ([self resume])
        {
                result([self getPlayerStatus]);
        } else
        {
                       result([FlutterError
                                  errorWithCode:@"Audio Player"
                                  message:@"audioPlayer resumePlayer failure"
                                  details:nil]);

        }
         NSLog(@"IOS:<-- resumePlayer");

}

- (void)seekToPlayer:(FlutterMethodCall*)call result: (FlutterResult)result
{
        NSLog(@"IOS:--> seekToPlayer");
        if (audioPlayer)
        {
                NSNumber* milli = (NSNumber*)call.arguments[@"duration"];
                double t = [milli doubleValue];
                audioPlayer.currentTime = t / 1000.0;
                [self updateProgress:nil];
                result([self getPlayerStatus]);
        } else
        {
                result([FlutterError
                        errorWithCode:@"Audio Player"
                        message:@"player is not set"
                        details:nil]);
        }
         NSLog(@"IOS:<-- seekToPlayer");
}

- (void)setVolume:(double) volume result: (FlutterResult)result
{
        NSLog(@"IOS:--> setVolume");
        if (audioPlayer)
        {
                [audioPlayer setVolume: volume];
                result([self getPlayerStatus]);
        } else
        {
                result([FlutterError
                        errorWithCode:@"Audio Player"
                        message:@"player is not set"
                        details:nil]);
        }
        NSLog(@"IOS:<-- setVolume");
}


- (void) stopTimer{
        NSLog(@"IOS:--> stopTimer");
        if (timer != nil) {
                [timer invalidate];
                timer = nil;
        }
        NSLog(@"IOS:<-- stopTimer");}


- (void)updateProgress:(NSTimer*) atimer
{
dispatch_async(dispatch_get_main_queue(), ^{
        NSNumber *duration = [NSNumber numberWithLong: (long)(audioPlayer.duration * 1000)];
        NSNumber *position = [NSNumber numberWithLong: (long)(audioPlayer.currentTime * 1000)];
        NSDictionary* dico = @{ @"slotNo": [NSNumber numberWithInt: slotNo], @"position": position, @"duration": duration, @"playerStatus": [self getPlayerStatus] };
        [self invokeMethod:@"updateProgress" dico: dico];
});
}

- (void)getProgress:(FlutterMethodCall*)call result: (FlutterResult)result
{
        NSLog(@"IOS:--> getProgress");
        NSNumber *duration = [NSNumber numberWithLong: (long)(audioPlayer.duration * 1000)];
        NSNumber *position = [NSNumber numberWithLong: (long)(audioPlayer.currentTime * 1000)];
        NSDictionary* dico = @{ @"slotNo": [NSNumber numberWithInt: slotNo], @"position": position, @"duration": duration, @"playerStatus": [self getPlayerStatus] };
        result(dico);
        NSLog(@"IOS:--> getProgress");

}


- (void)startTimer
{
        NSLog(@"IOS:--> startTimer");
        [self stopTimer];
        dispatch_async(dispatch_get_main_queue(), ^{ // ??? Why Async ?  (no async for recorder)
        self -> timer = [NSTimer scheduledTimerWithTimeInterval:subscriptionDuration
                                           target:self
                                           selector:@selector(updateProgress:)
                                           userInfo:nil
                                           repeats:YES];
        });
        NSLog(@"IOS:<-- startTimer");
}


- (void)setSubscriptionDuration:(FlutterMethodCall*)call  result: (FlutterResult)result
{
        NSLog(@"IOS:--> setSubscriptionDuration");
        NSNumber* milliSec = (NSNumber*)call.arguments[@"milliSec"];
        subscriptionDuration = [milliSec doubleValue]/1000;
        result([self getPlayerStatus]);
        NSLog(@"IOS:<-- setSubscriptionDuration");
}


// post fix with _FlutterSound to avoid conflicts with common libs including path_provider
- (NSString*) GetDirectoryOfType_FlutterSound: (NSSearchPathDirectory) dir
{
        NSArray* paths = NSSearchPathForDirectoriesInDomains(dir, NSUserDomainMask, YES);
        return [paths.firstObject stringByAppendingString:@"/"];
}


- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
        NSLog(@"IOS:--> @audioPlayerDidFinishPlaying");
        [self stopTimer];
        audioPlayer = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"IOS:--> ^audioPlayerFinishedPlaying");
                [self invokeMethod:@"audioPlayerFinishedPlaying" numberArg: [self getPlayerStatus]];
                NSLog(@"IOS:<-- ^audioPlayerFinishedPlaying");
         });

       NSLog(@"IOS:<-- @audioPlayerDidFinishPlaying");
}

- (int)getStatus
{
        if (  audioPlayer == nil)
                return IS_STOPPED;
        if ( [audioPlayer isPlaying])
                return IS_PLAYING;
        return IS_PAUSED;
}

- (NSNumber*)getPlayerStatus
{
        return [NSNumber numberWithInt: [self getStatus]];
}
@end
//---------------------------------------------------------------------------------------------

