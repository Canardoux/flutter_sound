//
//  SoundRecorder.m
//  flauto
//
//  Created by larpoux on 24/03/2020.
//
/*
 * This file is part of Flauto.
 *
 *   Flauto is free software: you can redistribute it and/or modify
 *   it under the terms of the Lesser GNU General Public License
 *   version 3 (LGPL3) as published by the Free Software Foundation.
 *
 *   Flauto is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the Lesser GNU General Public License
 *   along with Flauto.  If not, see <https://www.gnu.org/licenses/>.
 */



#import "FlautoRecorder.h"
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


@interface FlautoRecorderManager : NSObject
{
        FlautoRecorder* theFlautoRecorder; // Temporary !!!!!!!!!!!
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar;
@end



@implementation FlautoRecorderManager
{
}

FlutterMethodChannel* _flautoRecorderChannel;


+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar
{
        _channel = [FlutterMethodChannel methodChannelWithName:@"xyz.canardoux.flauto_recorder"
                                        binaryMessenger:[registrar messenger]];
        FlautoRecorderManager* instance = [[FlautoRecorderManager alloc] init];
        [registrar addMethodCallDelegate:instance channel:_channel];
}


extern void FlautoRecorderReg(NSObject<FlutterPluginRegistrar>* registrar)
{
        [FlautoRecorderManager registerWithRegistrar: registrar];
}




- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result
{
         if ([@"initializeFlautoRecorder" isEqualToString:call.method])
         {
                theFlautoRecorder = [[FlautoRecorder alloc] init];
                [theFlautoRecorder initializeFlautoRecorder: call result:result];
         } else
         
         if ([@"releaseFlautoRecorder" isEqualToString:call.method])
         {
                [theFlautoRecorder releaseFlautoRecorder:call result:result];
         } else
         
        if ([@"isEncoderSupported" isEqualToString:call.method])
        {
                NSNumber* codec = (NSNumber*)call.arguments[@"codec"];
                [FlautoRecorder isEncoderSupported:[codec intValue] result:result];
        } else
        
        if ([@"startRecorder" isEqualToString:call.method])
        {
                     [theFlautoRecorder startRecorder:call result:result];
        } else
        
        if ([@"stopRecorder" isEqualToString:call.method])
        {
                [theFlautoRecorder stopRecorder: result];
        } else
        
        if ([@"setDbPeakLevelUpdate" isEqualToString:call.method])
        {
                NSNumber* intervalInSecs = (NSNumber*)call.arguments[@"intervalInSecs"];
                [theFlautoRecorder setDbPeakLevelUpdate:[intervalInSecs doubleValue] result:result];
        } else
        
        if ([@"setDbLevelEnabled" isEqualToString:call.method])
        {
                BOOL enabled = [call.arguments[@"enabled"] boolValue];
                [theFlautoRecorder setDbLevelEnabled:enabled result:result];
        } else
        
        if ([@"setSubscriptionDuration" isEqualToString:call.method])
        {
                NSNumber* sec = (NSNumber*)call.arguments[@"sec"];
                [theFlautoRecorder setSubscriptionDuration:[sec doubleValue] result:result];
        } else
        
        {
                result(FlutterMethodNotImplemented);
        }
}


@end
//---------------------------------------------------------------------------------------------


@implementation FlautoRecorder
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

}


- (void)initializeFlautoRecorder : (FlutterMethodCall*)call result:(FlutterResult)result
{
        dbPeakInterval = 0.8;
        shouldProcessDbLevel = false;
}

- (void)releaseFlautoRecorder : (FlutterMethodCall*)call result:(FlutterResult)result
{
}

- (FlutterMethodChannel*) getChannel
{
        return _channel;
}

+ (void)isEncoderSupported:(t_CODEC)codec result: (FlutterResult)result
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


- (void)updateRecorderProgress:(NSTimer*) atimer
{
        assert (recorderTimer == atimer);
        NSNumber *currentTime = [NSNumber numberWithDouble:audioRecorder.currentTime * 1000];
        [audioRecorder updateMeters];

        NSString* status = [NSString stringWithFormat:@"{\"current_position\": \"%@\"}", [currentTime stringValue]];
        [[self getChannel] invokeMethod:@"updateRecorderProgress" arguments:status];
}


- (void)updateDbPeakProgress:(NSTimer*) atimer
{
        assert (dbPeakTimer == atimer);
        NSNumber *normalizedPeakLevel = [NSNumber numberWithDouble:MIN(pow(10.0, [audioRecorder peakPowerForChannel:0] / 20.0) * 160.0, 160.0)];
        [[ self getChannel] invokeMethod:@"updateDbPeakProgress" arguments:normalizedPeakLevel];
}


@end


//---------------------------------------------------------------------------------------------

