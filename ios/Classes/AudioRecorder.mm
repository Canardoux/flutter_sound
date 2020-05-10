//
//  AudioRecorder.m
//  flutter_sound
//
//  Created by larpoux on 02/05/2020.
//
/*
 * Copyright 2018, 2019, 2020 Dooboolab.
 *
 * This file is part of Flutter-Sound.
 *
 * Flutter-Sound is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 3, as published by
 * the Free Software Foundation.
 *
 * Flutter-Sound is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Flutter-Sound.  If not, see <https://www.gnu.org/licenses/>.
 */



#import <Foundation/Foundation.h>
#import "AudioRecorder.h"
//#import "AudioRecorderEngine.h"

#import "FlutterSoundRecorder.h"


class AudioRecInterface
{
public:
        virtual ~AudioRecInterface(){};
        virtual void stopRecorder() = 0;
        virtual void startRecorder( FlutterSoundRecorder* rec, bool shouldProcessDbLevel) = 0;
        virtual void resumeRecorder() = 0;
        virtual void pauseRecorder() = 0;
        virtual NSString* recorderProgress() = 0;
        virtual NSNumber* dbPeakProgress() = 0;
        double maxAmplitude = 0;
};



class AudioRecorderEngine : public AudioRecInterface
{
private:
        AVAudioEngine* engine;
        AVAudioMixerNode* mixerNode;
        AVAudioFormat* tapFormat;
        AVAudioFile* audioFile;
        AVAudioInputNode* inputNode;
        AVAudioOutputNode* outputNode;
        AVAudioFormat* inputFormat;
public:
        /* ctor */ AudioRecorderEngine(t_CODEC coder, NSString* path, NSMutableDictionary* audioSettings)
        {
                engine = [[AVAudioEngine alloc] init];
                mixerNode = [engine mainMixerNode];
                inputNode = [engine inputNode];
                outputNode = [engine outputNode];
                inputFormat = [inputNode inputFormatForBus: 0];
                [engine connect:inputNode to: mixerNode format: inputFormat];
                [engine disconnectNodeInput:outputNode];
                NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:path];
                tapFormat = [mixerNode outputFormatForBus: 0];
                NSDictionary* settings = [tapFormat settings];
                NSNumber* floatKey =  settings[@"AVLinearPCMIsFloatKey"] ;
                BOOL isFloat = ([floatKey intValue] == 1);
                
                
                //[settings setValue: [NSNumber numberWithInt: kAudioFormatLinearPCM] forKey:@"AVFormatIDKey"];
                
                //[settings setValue: audioSettings[ @"AVSampleRateKey"] forKey:@"AVSampleRateKey"];
                //[settings setValue: audioSettings[ @"AVNumberOfChannelsKey"] forKey:@"AVNumberOfChannelsKey"];
                //AVAudioCommonFormat* outputFormat =   [ AVAudioCommonFormat   initWithCommonFormat: AVAudioPCMFormatInt16 sampleRate:[AVAudioSession sharedInstance].sampleRate channels:AVAudioChannelCount(1) interleaved:false];
                //NSMutableDictionary *audioSettings2 = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                         //[NSNumber numberWithFloat: [AVAudioSession sharedInstance].sampleRate],AVSampleRateKey,
                                         //[NSNumber numberWithInt: kAudioFormatLinearPCM ],AVFormatIDKey,
                                         //[NSNumber numberWithInt: 1 ],AVNumberOfChannelsKey,
                                         //[NSNumber numberWithInt: ],AVEncoderAudioQualityKey,
                                         //nil];
               //AVAudioPCMBuffer* buffer = [[AVAudioPCMBuffer alloc]initWithPCMFormat:inputFormat frameCapacity: engine.manualRenderingMaximumFrameCount ];
                 
                
                
                
                audioFile = [[AVAudioFile alloc] initForWriting:fileURL settings: settings/*audioSettings2*/ error:nil];
                         
                [mixerNode installTapOnBus:0 bufferSize:4096 format: tapFormat block:
                        ^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when)
                        {
                                //NSLog(@"writing");
                                [audioFile writeFromBuffer: buffer error:nil];
                                if (isFloat)
                                {
                                        float*  _Nonnull  pt = *[buffer floatChannelData];
                                        for (int i = 0; i < [buffer frameLength]; ++pt, ++i)
                                        {
                                                double v = (double)(*pt);
                                                if (v > maxAmplitude)
                                                        maxAmplitude = v;
                                        }
                                }
                        }
                ];
           }
        
        /* dtor */virtual ~AudioRecorderEngine()
        {
        
        }

          virtual void startRecorder(FlutterSoundRecorder* rec, bool shouldProcessDbLevel)
        {
                [engine startAndReturnError: nil];
        }
        
        virtual void stopRecorder()
        {
                [engine stop];
                audioFile = nil;
                engine = nil;
        }
        
        virtual void resumeRecorder()
        {
                [engine startAndReturnError: nil];
         
        }
        
        virtual void pauseRecorder()
        {
                //[engine stop];
                [engine pause];
         
        }
        
        virtual NSString* recorderProgress()
        {
                return 0;
        }
        
        virtual NSNumber* dbPeakProgress()
        {
                double r = 100*maxAmplitude;
		maxAmplitude = 0;
		return [NSNumber numberWithDouble: r];

        }

};


class avAudioRec : public AudioRecInterface
{
        AVAudioRecorder* audioRecorder;
public:
        /* ctor */avAudioRec( NSString* path, NSMutableDictionary *audioSettings)
        {
        
                  NSURL *audioFileURL;
                  {
                        audioFileURL = [NSURL fileURLWithPath: path];
                  }

                 audioRecorder = [[AVAudioRecorder alloc]
                                        initWithURL:audioFileURL
                                        settings:audioSettings
                                        error:nil];

                  
        }
        
        /* dtor */virtual ~avAudioRec()
        {
                [audioRecorder stop];
        }
        
        void startRecorder(FlutterSoundRecorder* rec, bool shouldProcessDbLevel)
        {
                  [audioRecorder setDelegate: rec];
                  [audioRecorder record];
                  [audioRecorder setMeteringEnabled:shouldProcessDbLevel];
                  [audioRecorder setMeteringEnabled: (shouldProcessDbLevel == YES)];
        }
        
        void stopRecorder()
        {
                [audioRecorder stop];
        }
        
        void resumeRecorder()
        {
                [audioRecorder record];
        }
        
        void pauseRecorder()
        {
                [audioRecorder pause];

        }
        
        NSString* recorderProgress()
        {
                NSNumber *currentTime = [NSNumber numberWithDouble:audioRecorder.currentTime * 1000];
                [audioRecorder updateMeters];
                NSString* status = [NSString stringWithFormat:@"{\"current_position\": \"%@\"}", [currentTime stringValue]];
                return status;
        }
        
        NSNumber* dbPeakProgress()
        {
                NSNumber* normalizedPeakLevel = [NSNumber numberWithDouble:MIN(pow(10.0, [audioRecorder peakPowerForChannel:0] / 20.0) * 160.0, 160.0)];
                return normalizedPeakLevel;
        }
};


static bool _isIosEncoderSupported [] =
{
     		true, // DEFAULT
		true, // aacADTS
		false, // opusOGG
		true, // opusCAF
		false, // MP3
		false, // vorbisOGG
		false, // pcm16
		true, // pcm16WAV
		false, // pcm16AIFF
		true, // pcm16CAF
		true, // flac
		true, // aacMP4

};

static NSString* defaultExtensions [] =
{
          @"sound.aac", // defaultCodec
          @"sound.aac", // aacADTS
          @"sound.opus", // opusOGG
          @"sound_opus.caf", // opusCAF
          @"sound.mp3", // mp3
          @"sound.ogg", // vorbisOGG
          @"sound.pcm", // pcm16
          @"sound.wav", // pcm16WAV
          @"sound.aiff", // pcm16AIFF
          @"sound_pcm.caf", // pcm16CAF
          @"sound.flac", // flac
          @"sound.mp4", // aacMP4

};

static AudioFormatID formats [] =
{
          kAudioFormatMPEG4AAC        // CODEC_DEFAULT
        , kAudioFormatMPEG4AAC        // CODEC_AAC
        , 0                        // CODEC_OPUS
        , kAudioFormatOpus        // CODEC_CAF_OPUS
        , 0                       // CODEC_MP3
        , 0                        // CODEC_OGG_vorbis
        , 0    // pcm16
        , kAudioFormatLinearPCM   // pcm16WAV
        , 0    // pcm16AIFF
        , kAudioFormatLinearPCM  // pcm16CAF
        , kAudioFormatFLAC // flac
        , kAudioFormatMPEG4AAC // aacMP4

};


AudioRecInterface* audioRec;

@implementation FlutterSoundRecorder
{
        //NSURL *audioFileURL;
        NSTimer* dbPeakTimer;
        NSTimer* recorderTimer;
        t_SET_CATEGORY_DONE setCategoryDone;
        t_SET_CATEGORY_DONE setActiveDone;
        double dbPeakInterval;
        bool shouldProcessDbLevel;
        double subscriptionDuration;
        int slotNo;
        NSString* path;
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

/*
- (FlutterMethodChannel*) getChannel
{
        return _channel;
}
*/
- (void)isEncoderSupported:(t_CODEC)codec result: (FlutterResult)result
{
        NSNumber* b = [NSNumber numberWithBool: _isIosEncoderSupported[codec] ];
        result(b);
}



- (void)startRecorder :(FlutterMethodCall*)call result:(FlutterResult)result
{
           path = (NSString*)call.arguments[@"path"];
           NSNumber* sampleRateArgs = (NSNumber*)call.arguments[@"sampleRate"];
           NSNumber* numChannelsArgs = (NSNumber*)call.arguments[@"numChannels"];
           //NSNumber* iosQuality = (NSNumber*)call.arguments[@"iosQuality"];
           NSNumber* bitRate = (NSNumber*)call.arguments[@"bitRate"];
           NSNumber* codec = (NSNumber*)call.arguments[@"codec"];

           t_CODEC coder = aacADTS;
           if (![codec isKindOfClass:[NSNull class]])
           {
                   coder = (t_CODEC)([codec intValue]);
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

          NSMutableDictionary *audioSettings = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                         [NSNumber numberWithFloat: sampleRate],AVSampleRateKey,
                                         [NSNumber numberWithInt: formats[coder] ],AVFormatIDKey,
                                         [NSNumber numberWithInt: numChannels ],AVNumberOfChannelsKey,
                                         //[NSNumber numberWithInt: [iosQuality intValue]],AVEncoderAudioQualityKey,
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
          //if (path == NULL)
          {
                        //audioFileURL = [NSURL fileURLWithPath:[ [self GetDirectoryOfType_FlutterSound: NSCachesDirectory]
                        //stringByAppendingString:defaultExtensions[coder] ]];
          }
          
          if(formats[coder] == 0)
          {
                audioRec = new AudioRecorderEngine(coder, path, audioSettings);
          } else
          {
                audioRec = new avAudioRec( path, audioSettings);
          }
          audioRec ->startRecorder(self, shouldProcessDbLevel);
           [self startRecorderTimer];

          if(shouldProcessDbLevel == true)
          {
                [self startDbTimer];
          }

          //NSString *filePath = self->audioFileURL.path;
          result(path);
}


- (void)stopRecorder:(FlutterResult)result
{
          audioRec -> stopRecorder();

          [self stopDbPeakTimer];
          [self stopRecorderTimer];
          delete audioRec;

          //AVAudioSession *audioSession = [AVAudioSession sharedInstance];

          //NSString *filePath = audioFileURL.absoluteString;
          result(path);
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
        shouldProcessDbLevel = (enabled == YES);
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
        audioRec ->pauseRecorder();
        [self stopDbPeakTimer];
        [self stopRecorderTimer];
        result(@"Recorder is Paused");
}

- (void)resumeRecorder : (FlutterMethodCall*)call result:(FlutterResult)result
{
        audioRec ->resumeRecorder();
        [self startDbTimer];
        [self startRecorderTimer];
        result(@"Recorder is Resumed");
}



- (void)updateRecorderProgress:(NSTimer*) atimer
{
        assert (recorderTimer == atimer);
        NSString* status = audioRec ->recorderProgress();
        if (status != nil) // Temporary !!!!
                [self invokeMethod:@"updateRecorderProgress" stringArg: status];
}


- (void)updateDbPeakProgress:(NSTimer*) atimer
{
        assert (dbPeakTimer == atimer);
        NSNumber * normalizedPeakLevel = audioRec ->dbPeakProgress();
        if (normalizedPeakLevel != nil) // Temporary !!!
                [self invokeMethod:@"updateDbPeakProgress" numberArg: normalizedPeakLevel];
}


@end


//---------------------------------------------------------------------------------------------
 
