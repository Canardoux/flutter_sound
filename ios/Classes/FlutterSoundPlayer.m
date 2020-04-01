/*
 * This file is part of Flutter-Sound (Flauto).
 *
 *   Flutter-Sound (Flauto) is free software: you can redistribute it and/or modify
 *   it under the terms of the Lesser GNU General Public License
 *   version 3 (LGPL3) as published by the Free Software Foundation.
 *
 *   Flutter-Sound (Flauto) is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the Lesser GNU General Public License
 *   along with Flutter-Sound (Flauto).  If not, see <https://www.gnu.org/licenses/>.
 */



#import "FlutterSoundPlayer.h"
#import <AVFoundation/AVFoundation.h>



static FlutterMethodChannel* _channel;
NSMutableArray* flautoPlayerSlots;


static bool _isIosDecoderSupported [] =
{
    true, // DEFAULT
    true, // AAC
    false, // OGG/OPUS
    true, // CAF/OPUS
    true, // MP3
    false, // OGG/VORBIS
    true, // WAV/PCM
};


//--------------------------------------------------------------------------------------------



@implementation FlautoPlayerManager
{
 }

static FlautoPlayerManager* flautoPlayerManager; // Singleton


+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar
{
        _channel = [FlutterMethodChannel methodChannelWithName:@"com.dooboolab.flutter_sound_player"
                                        binaryMessenger:[registrar messenger]];
        assert (flautoPlayerManager == nil);
        flautoPlayerManager = [[FlautoPlayerManager alloc] init];
        [registrar addMethodCallDelegate:flautoPlayerManager channel:_channel];
}


- (FlautoPlayerManager*)init
{
        self = [super init];
        flautoPlayerSlots = [[NSMutableArray alloc] init];
        return self;
}

extern void FlautoPlayerReg(NSObject<FlutterPluginRegistrar>* registrar)
{
        [FlautoPlayerManager registerWithRegistrar: registrar];
}

- (void)invokeMethod: (NSString*)methodName arguments: (NSDictionary*)call
{
        [_channel invokeMethod: methodName arguments: call ];
}

- (void)freeSlot: (int)slotNo
{
        flautoPlayerSlots[slotNo] = [NSNull null];
}


- (FlautoPlayerManager*)getManager
{
        return flautoPlayerManager;
}


- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result
{
        int slotNo = [call.arguments[@"slotNo"] intValue];
        assert ( (slotNo >= 0) && (slotNo <= [flautoPlayerSlots count]));
        
        if (slotNo == [flautoPlayerSlots count])
        {
               [flautoPlayerSlots addObject: [NSNull null]];
        }

        FlutterSoundPlayer* aFlautoPlayer = flautoPlayerSlots[slotNo];
        
        if ([@"initializeMediaPlayer" isEqualToString:call.method])
        {
                assert (flautoPlayerSlots[slotNo] ==  [NSNull null] );
                aFlautoPlayer = [[FlutterSoundPlayer alloc] init: slotNo];
                flautoPlayerSlots[slotNo] = aFlautoPlayer;
                [aFlautoPlayer initializeFlautoPlayer: call result:result];
        } else
        
        if ([@"releaseMediaPlayer" isEqualToString:call.method])
        {
                [aFlautoPlayer releaseFlautoPlayer: call result:result];
                [flautoPlayerSlots replaceObjectAtIndex:slotNo withObject:[NSNull null]];
                flautoPlayerSlots[slotNo] = [NSNull null];
        } else
        
        if ([@"isDecoderSupported" isEqualToString:call.method])
        {
                NSNumber* codec = (NSNumber*)call.arguments[@"codec"];
                [aFlautoPlayer isDecoderSupported:[codec intValue] result:result];
        } else
        
        if ([@"startPlayer" isEqualToString:call.method])
        {
                NSString* path = (NSString*)call.arguments[@"path"];
                [aFlautoPlayer startPlayer:path result:result];
        } else
        
        if ([@"startPlayerFromBuffer" isEqualToString:call.method])
        {
                FlutterStandardTypedData* dataBuffer = (FlutterStandardTypedData*)call.arguments[@"dataBuffer"];
                [aFlautoPlayer startPlayerFromBuffer:dataBuffer result:result];
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
                NSNumber* sec = (NSNumber*)call.arguments[@"sec"];
                [aFlautoPlayer seekToPlayer:sec result:result];
        } else
        
        if ([@"setSubscriptionDuration" isEqualToString:call.method])
        {
                NSNumber* sec = (NSNumber*)call.arguments[@"sec"];
                [aFlautoPlayer setSubscriptionDuration:[sec doubleValue] result:result];
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
        
        {
                result(FlutterMethodNotImplemented);
        }
}


@end

//---------------------------------------------------------------------------------------------


@implementation FlutterSoundPlayer
{
        NSURL *audioFileURL;
        //AVAudioPlayer* audioPlayer; // In the interface
        NSTimer *timer;
        double subscriptionDuration;
        int slotNo;
}


- (FlutterSoundPlayer*)init: (int)aSlotNo
{
        slotNo = aSlotNo;
        return self;
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


- (void)invokeMethod: (NSString*)methodName stringArg: (NSString*)stringArg
{
        NSDictionary* dic = @{ @"slotNo": [NSNumber numberWithInt: slotNo], @"arg": stringArg};
        [[self getPlugin] invokeMethod: methodName arguments: dic ];
}


- (void)initializeFlautoPlayer: (FlutterMethodCall*)call result: (FlutterResult)result
{
        isPaused = false;
        result([NSNumber numberWithBool: YES]);
}

- (void)releaseFlautoPlayer: (FlutterMethodCall*)call result: (FlutterResult)result
{
        [[self getPlugin]freeSlot: slotNo];
        result(@"The player has been successfully released");

}

- (void)setCategory: (NSString*)categ mode:(NSString*)mode options:(int)options result:(FlutterResult)result
{
        // Able to play in silent mode
        BOOL b = [[AVAudioSession sharedInstance]
                setCategory:  categ // AVAudioSessionCategoryPlayback
                mode: mode
                options: options
                error: nil];
        setCategoryDone = BY_USER;
        setActiveDone = NOT_SET;
        NSNumber* r = [NSNumber numberWithBool: b];
        result(r);
}

- (void)setActive:(BOOL)enabled result:(FlutterResult)result
{
        if (enabled)
        {
                if (setActiveDone != NOT_SET)
                { // Already activated. Nothing todo;
                        setActiveDone = BY_USER;
                        result(0);
                        return;
                }
                setActiveDone = BY_USER;

        } else
        {
                if (setActiveDone == NOT_SET)
                { // Already desactivated
                        result(0);
                        return;
                }
                setActiveDone = NOT_SET;
        }
        BOOL b = [[AVAudioSession sharedInstance]  setActive:enabled error:nil] ;
        NSNumber* r = [NSNumber numberWithBool: b];
        result(r);
}



- (void)startPlayer:(NSString*)path result: (FlutterResult)result
{
        bool isRemote = false;
        if ([path class] == [NSNull class])
        {
                audioFileURL = [NSURL fileURLWithPath:[ [self GetDirectoryOfType_FlutterSound:NSCachesDirectory] stringByAppendingString:@"sound.aac"]];
        } else
        {
                NSURL *remoteUrl = [NSURL URLWithString:path];
                if(remoteUrl && remoteUrl.scheme && remoteUrl.host)
                {
                        audioFileURL = remoteUrl;
                        isRemote = true;
                } else
                {
                        audioFileURL = [NSURL URLWithString:path];
                }
          }
          // Able to play in silent mode
          if (setCategoryDone == NOT_SET)
          {
                  [[AVAudioSession sharedInstance]
                      setCategory: AVAudioSessionCategoryPlayback
                      error: nil];
                   setCategoryDone = FOR_PLAYING;
          }
          // Able to play in background
          if (setActiveDone == NOT_SET)
          {
                  [[AVAudioSession sharedInstance] setActive: YES error: nil];
                  setActiveDone = FOR_PLAYING;
          }

          isPaused = false;

          if (isRemote)
          {
                NSURLSessionDataTask *downloadTask = [[NSURLSession sharedSession]
                        dataTaskWithURL:audioFileURL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                {

                        // We must create a new Audio Player instance to be able to play a different Url
                        audioPlayer = [[AVAudioPlayer alloc] initWithData:data error:nil];
                        audioPlayer.delegate = self;

                        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];

                        bool b = [self->audioPlayer play];
                        if (!b)
                        {
                                [self stopPlayer];
                                ([FlutterError
                                errorWithCode:@"Audio Player"
                                message:@"Play failure"
                                details:nil]);

                        }
                }];

                [self startTimer];
                NSString *filePath = self->audioFileURL.absoluteString;
                result(filePath);
                [downloadTask resume];
        } else
        {
                // if (!audioPlayer) { // Fix sound distoring when playing recorded audio again.
                audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioFileURL error:nil];
                audioPlayer.delegate = self;
                // }
                bool b = [audioPlayer play];
                if (!b)
                {
                        [self stopPlayer];
                        ([FlutterError
                                errorWithCode:@"Audio Player"
                                message:@"Play failure"
                                details:nil]);
                } else
                {
                        [self startTimer];
                        NSString *filePath = audioFileURL.absoluteString;
                        result(filePath);
                }
        }
}


- (void)startPlayerFromBuffer:(FlutterStandardTypedData*)dataBuffer result: (FlutterResult)result
{
        audioPlayer = [[AVAudioPlayer alloc] initWithData: [dataBuffer data] error: nil];
        audioPlayer.delegate = self;
        // Able to play in silent mode
        if (setCategoryDone == NOT_SET)
        {
                [[AVAudioSession sharedInstance]
                setCategory: AVAudioSessionCategoryPlayback
                error: nil];
                setCategoryDone = FOR_PLAYING;
        }
        // Able to play in background
        if (setActiveDone == NOT_SET)
        {
                [[AVAudioSession sharedInstance] setActive: YES error: nil];
                setActiveDone = FOR_PLAYING;
        }
        isPaused = false;
        bool b = [audioPlayer play];
        if (!b)
        {
                [self stopPlayer];
                ([FlutterError
                        errorWithCode:@"Audio Player"
                        message:@"Play failure"
                        details:nil]);
        } else
        {
                [self startTimer];
                result(@"Playing from buffer");
        }
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
        if ( (setActiveDone != BY_USER) && (setActiveDone != NOT_SET) )
        {
                [[AVAudioSession sharedInstance] setActive: NO error: nil];
                setActiveDone = NOT_SET;
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
          if ( (setActiveDone != BY_USER) && (setActiveDone != NOT_SET) ) {
              [[AVAudioSession sharedInstance] setActive: NO error: nil];
              setActiveDone = NOT_SET;
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
                        if (setActiveDone == NOT_SET) {
                                [[AVAudioSession sharedInstance] setActive: YES error: nil];
                                setActiveDone = FOR_PLAYING;
                        }
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
                NSString *filePath = audioFileURL.absoluteString;
                result(filePath);
        } else
        {
                result([FlutterError
                         errorWithCode:@"Audio Player"
                         message:@"resume failed"
                         details:nil]);
        }
   }
}

- (void)seekToPlayer:(nonnull NSNumber*) time result: (FlutterResult)result
{
        if (audioPlayer)
        {
                audioPlayer.currentTime = [time doubleValue] / 1000;
                [self updateProgress:nil];
                result([time stringValue]);
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
        NSNumber *duration = [NSNumber numberWithDouble:audioPlayer.duration * 1000];
        NSNumber *currentTime = [NSNumber numberWithDouble:audioPlayer.currentTime * 1000];

        // [LARPOUX] I do not understand why ...
        // if ([duration intValue] == 0 && timer != nil) {
        //   [self stopTimer];
        //   return;
        // }

        NSString* status = [NSString stringWithFormat:@"{\"duration\": \"%@\", \"current_position\": \"%@\"}", [duration stringValue],                         [currentTime stringValue]];
        [self invokeMethod:@"updateProgress" stringArg:status];
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


- (void)setSubscriptionDuration:(double)duration result: (FlutterResult)result
{
        subscriptionDuration = duration;
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
        if ( (setActiveDone != BY_USER) && (setActiveDone != NOT_SET) )
        {
                [[AVAudioSession sharedInstance] setActive: NO error: nil];
                setActiveDone = NOT_SET;
        }

        NSNumber *duration = [NSNumber numberWithDouble:audioPlayer.duration * 1000];
        NSNumber *currentTime = [NSNumber numberWithDouble:audioPlayer.currentTime * 1000];

        NSString* status = [NSString stringWithFormat:@"{\"duration\": \"%@\", \"current_position\": \"%@\"}", [duration stringValue], [currentTime stringValue]];

        [self invokeMethod:@"audioPlayerFinishedPlaying" stringArg: status];
        isPaused = false;
        [self stopTimer];
}
@end
//---------------------------------------------------------------------------------------------

