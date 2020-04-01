//
//  SoundRecorder.m
//  flauto
//
//  Created by larpoux on 24/03/2020.
//
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



#import "FlutterSoundRecorder.h"
#import "flauto.h" // Just to register it
#import <AVFoundation/AVFoundation.h>


static FlutterMethodChannel* _channel;


static bool _isIosEncoderSupported [] =
{
    true, // DEFAULT
    true, // AAC
    false, // OGG/OPUS
    true, // CAF/OPUS
    false, // MP3
    false, // OGG/VORBIS
    false, // WAV/PCM
};

static NSString* defaultExtensions [] =
{
          @"sound.aac"         // CODEC_DEFAULT
          @"sound.aac"         // CODEC_AAC
        , @"sound.opus"        // CODEC_OPUS
        , @"sound.caf"        // CODEC_CAF_OPUS
        , @"sound.mp3"        // CODEC_MP3
        , @"sound.ogg"        // CODEC_VORBIS
        , @"sound.wav"        // CODE_PCM
};

static AudioFormatID formats [] =
{
          kAudioFormatMPEG4AAC        // CODEC_DEFAULT
        , kAudioFormatMPEG4AAC        // CODEC_AAC
        , 0                        // CODEC_OPUS
        , kAudioFormatOpus        // CODEC_CAF_OPUS
        , 0                        // CODEC_MP3
        , 0                        // CODEC_OGG
        , 0                        // CODEC_PCM
};



FlutterMethodChannel* _flautoRecorderChannel;


//---------------------------------------------------------------------------------------------



@implementation FlautoRecorderManager
{
        NSMutableArray* flautoRecorderSlots;
}

static FlautoRecorderManager* flautoRecorderManager; // Singleton


+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar
{
        _channel = [FlutterMethodChannel methodChannelWithName:@"com.dooboolab.flutter_sound_recorder"
                                        binaryMessenger:[registrar messenger]];
        assert (flautoRecorderManager == nil);
        flautoRecorderManager = [[FlautoRecorderManager alloc] init];
        [registrar addMethodCallDelegate:flautoRecorderManager channel:_channel];
}


- (FlautoRecorderManager*)init
{
        self = [super init];
        flautoRecorderSlots = [[NSMutableArray alloc] init];
        return self;
}

extern void FlautoRecorderReg(NSObject<FlutterPluginRegistrar>* registrar)
{
        [FlautoRecorderManager registerWithRegistrar: registrar];
}



- (void)invokeMethod: (NSString*)methodName arguments: (NSDictionary*)call
{
        [_channel invokeMethod: methodName arguments: call ];
}


- (void)freeSlot: (int)slotNo
{
        flautoRecorderSlots[slotNo] = [NSNull null];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result
{
        int slotNo = [call.arguments[@"slotNo"] intValue];
        assert ( (slotNo >= 0) && (slotNo <= [flautoRecorderSlots count]));
        if (slotNo == [flautoRecorderSlots count])
        {
                 [flautoRecorderSlots addObject: [NSNull null] ];
        }
        FlutterSoundRecorder* aFlautoRecorder = flautoRecorderSlots[slotNo];
        
        if ([@"initializeFlautoRecorder" isEqualToString:call.method])
        {
                assert (flautoRecorderSlots[slotNo] ==  [NSNull null] );
                aFlautoRecorder = [[FlutterSoundRecorder alloc] init: slotNo];
                flautoRecorderSlots[slotNo] =aFlautoRecorder;
                [aFlautoRecorder initializeFlautoRecorder: call result:result];
        } else
         
        if ([@"releaseFlautoRecorder" isEqualToString:call.method])
        {
                [aFlautoRecorder releaseFlautoRecorder:call result:result];
        } else
         
        if ([@"isEncoderSupported" isEqualToString:call.method])
        {
                NSNumber* codec = (NSNumber*)call.arguments[@"codec"];
                [aFlautoRecorder isEncoderSupported:[codec intValue] result:result];
        } else
        
        if ([@"startRecorder" isEqualToString:call.method])
        {
                     [aFlautoRecorder startRecorder:call result:result];
        } else
        
        if ([@"stopRecorder" isEqualToString:call.method])
        {
                [aFlautoRecorder stopRecorder: result];
        } else
        
        if ([@"setDbPeakLevelUpdate" isEqualToString:call.method])
        {
                NSNumber* intervalInSecs = (NSNumber*)call.arguments[@"intervalInSecs"];
                [aFlautoRecorder setDbPeakLevelUpdate:[intervalInSecs doubleValue] result:result];
        } else
        
        if ([@"setDbLevelEnabled" isEqualToString:call.method])
        {
                BOOL enabled = [call.arguments[@"enabled"] boolValue];
                [aFlautoRecorder setDbLevelEnabled:enabled result:result];
        } else
        
        if ([@"setSubscriptionDuration" isEqualToString:call.method])
        {
                NSNumber* sec = (NSNumber*)call.arguments[@"sec"];
                [aFlautoRecorder setSubscriptionDuration:[sec doubleValue] result:result];
        } else
        
        if ([@"pauseRecorder" isEqualToString:call.method])
        {
                [aFlautoRecorder pauseRecorder:call result:result];
        } else
        
        if ([@"resumeRecorder" isEqualToString:call.method])
        {
                [aFlautoRecorder resumeRecorder:call result:result];
        } else
        
        {
                result(FlutterMethodNotImplemented);
        }
}


@end
//---------------------------------------------------------------------------------------------


@implementation FlutterSoundRecorder
{
        NSURL *audioFileURL;
        AVAudioRecorder* audioRecorder;
        NSTimer* dbPeakTimer;
        NSTimer* recorderTimer;
        t_SET_CATEGORY_DONE setCategoryDone;
        t_SET_CATEGORY_DONE setActiveDone;
        double dbPeakInterval;
        bool shouldProcessDbLevel;
        double subscriptionDuration;
        int slotNo;

}


- (FlutterSoundRecorder*)init: (int)aSlotNo
{
        slotNo = aSlotNo;
        return self;
}



-(FlautoRecorderManager*) getPlugin
{
        return flautoRecorderManager;
}


- (void)invokeMethod: (NSString*)methodName stringArg: (NSString*)stringArg
{
        NSDictionary* dic = @{ @"slotNo": [NSNumber numberWithInt: slotNo], @"arg": stringArg};
        [[self getPlugin] invokeMethod: methodName arguments: dic ];
}


- (void)invokeMethod: (NSString*)methodName numberArg: (NSNumber*)arg
{
        NSDictionary* dic = @{ @"slotNo": [NSNumber numberWithInt: slotNo], @"arg": arg};
        [[self getPlugin] invokeMethod: methodName arguments: dic ];
}


- (void)initializeFlautoRecorder : (FlutterMethodCall*)call result:(FlutterResult)result
{
        dbPeakInterval = 0.8;
        shouldProcessDbLevel = false;
        result([NSNumber numberWithBool: YES]);
}

- (void)releaseFlautoRecorder : (FlutterMethodCall*)call result:(FlutterResult)result
{
        [[self getPlugin] freeSlot: slotNo];
        slotNo = -1;
        result([NSNumber numberWithBool: YES]);
}

- (FlutterMethodChannel*) getChannel
{
        return _channel;
}

- (void)isEncoderSupported:(t_CODEC)codec result: (FlutterResult)result
{
        NSNumber* b = [NSNumber numberWithBool: _isIosEncoderSupported[codec] ];
        result(b);
}



- (void)startRecorder :(FlutterMethodCall*)call result:(FlutterResult)result
{
           NSString* path = (NSString*)call.arguments[@"path"];
           NSNumber* sampleRateArgs = (NSNumber*)call.arguments[@"sampleRate"];
           NSNumber* numChannelsArgs = (NSNumber*)call.arguments[@"numChannels"];
           NSNumber* iosQuality = (NSNumber*)call.arguments[@"iosQuality"];
           NSNumber* bitRate = (NSNumber*)call.arguments[@"bitRate"];
           NSNumber* codec = (NSNumber*)call.arguments[@"codec"];

           t_CODEC coder = CODEC_AAC;
           if (![codec isKindOfClass:[NSNull class]])
           {
                   coder = [codec intValue];
           }

           float sampleRate = 44100;
           if (![sampleRateArgs isKindOfClass:[NSNull class]])
           {
                sampleRate = [sampleRateArgs integerValue];
           }

           int numChannels = 2;
           if (![numChannelsArgs isKindOfClass:[NSNull class]])
           {
                numChannels = [numChannelsArgs integerValue];
           }



          if ([path class] == [NSNull class])
          {
                audioFileURL = [NSURL fileURLWithPath:[ [self GetDirectoryOfType_FlutterSound: NSCachesDirectory] stringByAppendingString:defaultExtensions[coder] ]];
          } else
          {
                audioFileURL = [NSURL fileURLWithPath: path];
          }
          NSMutableDictionary *audioSettings = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                         [NSNumber numberWithFloat: sampleRate],AVSampleRateKey,
                                         [NSNumber numberWithInt: formats[coder] ],AVFormatIDKey,
                                         [NSNumber numberWithInt: numChannels ],AVNumberOfChannelsKey,
                                         [NSNumber numberWithInt: [iosQuality intValue]],AVEncoderAudioQualityKey,
                                         nil];

            // If bitrate is defined, the use it, otherwise use the OS default
            if(![bitRate isEqual:[NSNull null]])
            {
                        [audioSettings setValue:[NSNumber numberWithInt: [bitRate intValue]]
                            forKey:AVEncoderBitRateKey];
            }

          // Setup audio session
          if ((setCategoryDone == NOT_SET) || (setCategoryDone == FOR_PLAYING) )
          {
                AVAudioSession *session = [AVAudioSession sharedInstance];
                [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
                setCategoryDone = FOR_RECORDING;
          }

          // set volume default to speaker
          UInt32 doChangeDefaultRoute = 1;
          AudioSessionSetProperty(kAudioSessionProperty_OverrideCategoryDefaultToSpeaker, sizeof(doChangeDefaultRoute), &doChangeDefaultRoute);

          // set up for bluetooth microphone input
          UInt32 allowBluetoothInput = 1;
          AudioSessionSetProperty (kAudioSessionProperty_OverrideCategoryEnableBluetoothInput,sizeof (allowBluetoothInput),&allowBluetoothInput);

          audioRecorder = [[AVAudioRecorder alloc]
                                initWithURL:audioFileURL
                                settings:audioSettings
                                error:nil];

          [audioRecorder setDelegate:self];
          [audioRecorder record];
          [self startRecorderTimer];

          [audioRecorder setMeteringEnabled:shouldProcessDbLevel];
          if(shouldProcessDbLevel == true)
          {
                [self startDbTimer];
          }

          NSString *filePath = self->audioFileURL.path;
          result(filePath);
}


- (void)stopRecorder:(FlutterResult)result
{
          [audioRecorder stop];

          [self stopDbPeakTimer];
          [self stopRecorderTimer];

          AVAudioSession *audioSession = [AVAudioSession sharedInstance];

          NSString *filePath = audioFileURL.absoluteString;
          result(filePath);
}

- (void) stopDbPeakTimer
{
        if (self -> dbPeakTimer != nil)
        {
               [dbPeakTimer invalidate];
               self -> dbPeakTimer = nil;
        }
}


- (void)startRecorderTimer
{
        [self stopRecorderTimer];
        //dispatch_async(dispatch_get_main_queue(), ^{
        recorderTimer = [NSTimer scheduledTimerWithTimeInterval: subscriptionDuration
                                           target:self
                                           selector:@selector(updateRecorderProgress:)
                                           userInfo:nil
                                           repeats:YES];
        //});
}



- (void)setDbPeakLevelUpdate:(double)intervalInSecs result: (FlutterResult)result
{
        dbPeakInterval = intervalInSecs;
        result(@"setDbPeakLevelUpdate");
}

- (void)setDbLevelEnabled:(BOOL)enabled result: (FlutterResult)result
{
        shouldProcessDbLevel = enabled == YES;
        result(@"setDbLevelEnabled");
}


// post fix with _FlutterSound to avoid conflicts with common libs including path_provider
- (NSString*) GetDirectoryOfType_FlutterSound: (NSSearchPathDirectory) dir
{
        NSArray* paths = NSSearchPathForDirectoriesInDomains(dir, NSUserDomainMask, YES);
        return [paths.firstObject stringByAppendingString:@"/"];
}


- (void)startDbTimer
{
        // Stop Db Timer
        [self stopDbPeakTimer];
        //dispatch_async(dispatch_get_main_queue(), ^{
        self -> dbPeakTimer = [NSTimer scheduledTimerWithTimeInterval:dbPeakInterval
                                                        target:self
                                                        selector:@selector(updateDbPeakProgress:)
                                                        userInfo:nil
                                                        repeats:YES];
        //});
}


- (void) stopRecorderTimer{
    if (recorderTimer != nil) {
        [recorderTimer invalidate];
        recorderTimer = nil;
    }
}


- (void)setSubscriptionDuration:(double)duration result: (FlutterResult)result
{
        subscriptionDuration = duration;
        result(@"setSubscriptionDuration");
}

- (void)pauseRecorder : (FlutterMethodCall*)call result:(FlutterResult)result
{
        [audioRecorder pause];

        [self stopDbPeakTimer];
        [self stopRecorderTimer];
        result(@"Recorder is Paused");
}

- (void)resumeRecorder : (FlutterMethodCall*)call result:(FlutterResult)result
{
        bool b = [audioRecorder record];
        [self startDbTimer];
        [self startRecorderTimer];
        result([NSNumber numberWithBool: b]);
}



- (void)updateRecorderProgress:(NSTimer*) atimer
{
        assert (recorderTimer == atimer);
        NSNumber *currentTime = [NSNumber numberWithDouble:audioRecorder.currentTime * 1000];
        [audioRecorder updateMeters];

        NSString* status = [NSString stringWithFormat:@"{\"current_position\": \"%@\"}", [currentTime stringValue]];
        [self invokeMethod:@"updateRecorderProgress" stringArg: status];
}


- (void)updateDbPeakProgress:(NSTimer*) atimer
{
        assert (dbPeakTimer == atimer);
        NSNumber *normalizedPeakLevel = [NSNumber numberWithDouble:MIN(pow(10.0, [audioRecorder peakPowerForChannel:0] / 20.0) * 160.0, 160.0)];
        [self invokeMethod:@"updateDbPeakProgress" numberArg: normalizedPeakLevel];
}


@end


//---------------------------------------------------------------------------------------------

