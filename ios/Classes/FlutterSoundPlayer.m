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


//--------------------------------------------------------------------------------------------



@implementation FlautoPlayerManager
{
}

static FlautoPlayerManager* flautoPlayerManager; // Singleton


+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar
{
        FlutterMethodChannel* aChannel = [FlutterMethodChannel methodChannelWithName:@"com.dooboolab.flutter_sound_player"
                                        binaryMessenger:[registrar messenger]];
        assert (flautoPlayerManager == nil);
        flautoPlayerManager = [[FlautoPlayerManager alloc] init];
        flautoPlayerManager ->channel = aChannel;
        [registrar addMethodCallDelegate:flautoPlayerManager channel: aChannel];
}


- (FlautoPlayerManager*)init
{
        self = [super init];
        return self;
}

extern void FlautoPlayerReg(NSObject<FlutterPluginRegistrar>* registrar)
{
        [FlautoPlayerManager registerWithRegistrar: registrar];
}

- (FlautoPlayerManager*)getManager
{
        return flautoPlayerManager;
}


- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result
{
         FlutterSoundPlayer* aFlautoPlayer = (FlutterSoundPlayer*)[ self getSession: call];
        
        if ([@"initializeMediaPlayer" isEqualToString:call.method])
        {
                aFlautoPlayer = [[FlutterSoundPlayer alloc] init: call];
                [aFlautoPlayer initializeFlautoPlayer: call result:result];
        } else
        
        if ([@"initializeMediaPlayerWithUI" isEqualToString:call.method])
        {
                aFlautoPlayer = [[TrackPlayer alloc] init: call];
                [aFlautoPlayer initializeFlautoPlayer: call result:result];
        } else
 
        if ([@"releaseMediaPlayer" isEqualToString:call.method])
        {
                [aFlautoPlayer releaseFlautoPlayer: call result:result];
         } else
        
        if ([@"setAudioFocus" isEqualToString:call.method])
        {
                [aFlautoPlayer setAudioFocus: call result:result];
        } else

        
        if ([@"isDecoderSupported" isEqualToString:call.method])
        {
                NSNumber* codec = (NSNumber*)call.arguments[@"codec"];
                [aFlautoPlayer isDecoderSupported:[codec intValue] result:result];
        } else
        
        if ([@"startPlayer" isEqualToString:call.method])
        {
                [aFlautoPlayer startPlayer: call result:result];
        } else
        
        if ([@"startPlayerFromTrack" isEqualToString:call.method])
        {
                 [aFlautoPlayer startPlayerFromTrack: call result:result];
        } else

        if ([@"stopPlayer" isEqualToString:call.method])
        {
                [aFlautoPlayer stopPlayer];
                result(@"stop play");
        } else
          
        if ([@"pausePlayer" isEqualToString:call.method])
        {
                [aFlautoPlayer pausePlayer:result];
        } else
          
        if ([@"resumePlayer" isEqualToString:call.method])
        {
                [aFlautoPlayer resumePlayer:result];
        } else
          
        if ([@"seekToPlayer" isEqualToString:call.method])
        {
                //NSNumber* sec = (NSNumber*)call.arguments[@"sec"];
                [aFlautoPlayer seekToPlayer:call result:result];
        } else
        
        if ([@"setSubscriptionDuration" isEqualToString:call.method])
        {
                //NSNumber* sec = (NSNumber*)call.arguments[@"sec"];
                [aFlautoPlayer setSubscriptionDuration:call result:result];
        } else
        
        if ([@"setVolume" isEqualToString:call.method])
        {
                NSNumber* volume = (NSNumber*)call.arguments[@"volume"];
                [aFlautoPlayer setVolume:[volume doubleValue] result:result];
        } else
        
        if ([@"iosSetCategory" isEqualToString:call.method])
        {
                NSString* categ = (NSString*)call.arguments[@"category"];
                NSString* mode = (NSString*)call.arguments[@"mode"];
                NSNumber* options = (NSNumber*)call.arguments[@"options"];
                [aFlautoPlayer setCategory: categ mode: mode options: [options intValue] result:result];
        } else
        
        if ([@"setActive" isEqualToString:call.method])
        {
                BOOL enabled = [call.arguments[@"enabled"] boolValue];
                [aFlautoPlayer setActive:enabled result:result];
        } else
        
        if ( [@"getResourcePath" isEqualToString:call.method] )
        {
                result( [[NSBundle mainBundle] resourcePath]);
        } else

        {
                result(FlutterMethodNotImplemented);
        }
}


@end

//---------------------------------------------------------------------------------------------


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
        NSNumber*  b = [NSNumber numberWithBool: _isIosDecoderSupported[codec] ];
        result(b);
}



-(FlautoPlayerManager*) getPlugin
{
        return flautoPlayerManager;
}


- (void)initializeFlautoPlayer: (FlutterMethodCall*)call result: (FlutterResult)result
{
        isPaused = false;
        [self setAudioFocus: call result: result];
}

- (void)releaseFlautoPlayer: (FlutterMethodCall*)call result: (FlutterResult)result
{
 
      
        result([NSNumber numberWithBool: TRUE]);
        [super releaseSession];
}

- (void)setCategory: (NSString*)categ mode:(NSString*)mode options:(int)options result:(FlutterResult)result
{
        // Able to play in silent mode
        BOOL b = [[AVAudioSession sharedInstance]
                setCategory:  categ // AVAudioSessionCategoryPlayback
                mode: mode
                options: options
                error: nil];
        NSNumber* r = [NSNumber numberWithBool: b];
        result(r);
}

- (void)setActive:(BOOL)enabled result:(FlutterResult)result
{
        BOOL b = [[AVAudioSession sharedInstance]  setActive:enabled error:nil] ;
        NSNumber* r = [NSNumber numberWithBool: b];
        result(r);
}



- (void)startPlayer:(FlutterMethodCall*)call result: (FlutterResult)result
{
        bool b = FALSE;
        isPaused = false;
        if (!hasFocus) // We always acquire the Audio Focus (It could have been released by another session)
        {
                hasFocus = TRUE;
                b = [[AVAudioSession sharedInstance]  setActive: hasFocus error:nil] ;
        }
 

        NSString* path = (NSString*)call.arguments[@"fromURI"];
        FlutterStandardTypedData* dataBuffer = (FlutterStandardTypedData*)call.arguments[@"fromDataBuffer"];
        if ([dataBuffer class] != [NSNull class])
        {
                audioPlayer = [[AVAudioPlayer alloc] initWithData: [dataBuffer data] error: nil];
                audioPlayer.delegate = self;
                isPaused = false;
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
                }
                result([NSNumber numberWithBool: b]);
                return;
        }
        
        bool isRemote = false;
        if ([path class] == [NSNull class])
        {
                [self stopPlayer];
                ([FlutterError
                errorWithCode:@"Audio Player"
                message:@"Play failure"
                details:nil]);
                //result([NSNumber numberWithBool: FALSE]);
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
                                ([FlutterError
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
                [self startTimer];
                result([NSNumber numberWithBool: b]);
        } else
        {
                        [self stopPlayer];
  
                        [FlutterError
                                errorWithCode:@"Audio Player"
                                message:@"Play failure"
                                details:nil];
        }
}


- (void)startPlayerFromTrack:(FlutterMethodCall*)call result: (FlutterResult)result
{
                       ([FlutterError
                                errorWithCode:@"Audio Player"
                                message:@"Start Player From Track failure"
                                details:nil]);
                        //result([NSNumber numberWithBool: FALSE]);
}

- (void)stopPlayer
{
        [self stopTimer];
        isPaused = false;
        if (audioPlayer)
        {
                [audioPlayer stop];
                audioPlayer = nil;
        }
}

- (void)pause
{
          [audioPlayer pause];
          isPaused = true;
          if (timer != nil)
          {
              [timer invalidate];
              timer = nil;
          }
 }

- (bool)resume
{
        isPaused = true;

        bool b = false;
        if ( [audioPlayer isPlaying] )
        {
                printf("audioPlayer is already playing!\n");
        } else
        {
                b = [audioPlayer play];
                if (b)
                {
                        [self startTimer];
                } else
                {
                        printf("resume : resume failed!\n");
                }
        }
        return b;
}

- (void)pausePlayer:(FlutterResult)result
{
        if (audioPlayer)
        {
                 if (! [audioPlayer isPlaying] )
                 {
                        isPaused = false;

                         printf("audioPlayer is not playing!\n");
                         result([FlutterError
                                  errorWithCode:@"Audio Player"
                                  message:@"audioPlayer is not playing"
                                  details:nil]);

                 } else
                 {
                        [self pause];
                        result(@"pause play");
                 }
        } else
        {
                printf("resumePlayer : player is not set\n");
                result([FlutterError
                        errorWithCode:@"Audio Player"
                        message:@"player is not set"
                        details:nil]);
        }
}

- (void)resumePlayer:(FlutterResult)result
{

   isPaused = false;

   if (!audioPlayer)
   {
            printf("resumePlayer : player is not set\n");
            result([FlutterError
                    errorWithCode:@"Audio Player"
                    message:@"player is not set"
                    details:nil]);
            return;
   }
   if ( [audioPlayer isPlaying] )
   {
           printf("audioPlayer is already playing!\n");
           result([FlutterError
                    errorWithCode:@"Audio Player"
                    message:@"audioPlayer is already playing"
                    details:nil]);

   } else
   {
        [[AVAudioSession sharedInstance]  setActive:YES error:nil] ;
        bool b = [self resume];
        if (b)
        {
                //NSString *filePath = audioFileURL.absoluteString;
                result(@"toto");
        } else
        {
                result([FlutterError
                         errorWithCode:@"Audio Player"
                         message:@"resume failed"
                         details:nil]);
        }
   }
}

- (void)seekToPlayer:(FlutterMethodCall*)call result: (FlutterResult)result
{
        if (audioPlayer)
        {
                NSNumber* milli = (NSNumber*)call.arguments[@"duration"];
                double t = [milli doubleValue];
                audioPlayer.currentTime = t / 1000.0;
                [self updateProgress:nil];
                result([milli stringValue]);
        } else
        {
                result([FlutterError
                        errorWithCode:@"Audio Player"
                        message:@"player is not set"
                        details:nil]);
        }
}

- (void)setVolume:(double) volume result: (FlutterResult)result
{
        if (audioPlayer)
        {
                [audioPlayer setVolume: volume];
                result(@"volume set");
        } else
        {
                result([FlutterError
                        errorWithCode:@"Audio Player"
                        message:@"player is not set"
                        details:nil]);
        }
}


- (void) stopTimer{
    if (timer != nil) {
        [timer invalidate];
        timer = nil;
    }
}



- (void)updateProgress:(NSTimer*) atimer
{
        NSNumber *duration = [NSNumber numberWithLong: (long)(audioPlayer.duration * 1000)];
        NSNumber *position = [NSNumber numberWithLong: (long)(audioPlayer.currentTime * 1000)];

        // [LARPOUX] I do not understand why ...
        // if ([duration intValue] == 0 && timer != nil) {
        //   [self stopTimer];
        //   return;
        // }

        //NSString* status = [NSString stringWithFormat:@"{\"duration\": \"%@\", \"current_position\": \"%@\"}", [duration stringValue],                         [currentTime stringValue]];
        NSDictionary* dico = @{ @"slotNo": [NSNumber numberWithInt: slotNo], @"position": position, @"duration": duration};
        [self invokeMethod:@"updateProgress" dico: dico];
//        if (![audioPlayer isPlaying] )
//        {
//                  [self stopPlayer];
//                  return;
//        }

}


- (void)startTimer
{
        [self stopTimer];
        //dispatch_async(dispatch_get_main_queue(), ^{ // ??? Why Async ?  (no async for recorder)
        self -> timer = [NSTimer scheduledTimerWithTimeInterval:subscriptionDuration
                                           target:self
                                           selector:@selector(updateProgress:)
                                           userInfo:nil
                                           repeats:YES];
        //});
}


- (void)setSubscriptionDuration:(FlutterMethodCall*)call  result: (FlutterResult)result
{
        NSNumber* milliSec = (NSNumber*)call.arguments[@"milliSec"];
        subscriptionDuration = [milliSec doubleValue]/1000;
        result(@"setSubscriptionDuration");
}


// post fix with _FlutterSound to avoid conflicts with common libs including path_provider
- (NSString*) GetDirectoryOfType_FlutterSound: (NSSearchPathDirectory) dir
{
        NSArray* paths = NSSearchPathForDirectoriesInDomains(dir, NSUserDomainMask, YES);
        return [paths.firstObject stringByAppendingString:@"/"];
}


- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
        NSLog(@"audioPlayerDidFinishPlaying");

        /*
        NSNumber *duration = [NSNumber numberWithDouble:audioPlayer.duration * 1000];
        NSNumber *currentTime = [NSNumber numberWithDouble:audioPlayer.currentTime * 1000];

        NSString* status = [NSString stringWithFormat:@"{\"duration\": \"%@\", \"current_position\": \"%@\"}", [duration stringValue], [currentTime stringValue]];
        */

        [self invokeMethod:@"audioPlayerFinishedPlaying" stringArg: @"done"];
        isPaused = false;
        [self stopTimer];
}
@end
//---------------------------------------------------------------------------------------------

