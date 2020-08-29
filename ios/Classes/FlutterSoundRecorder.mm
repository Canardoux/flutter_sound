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




#import <Foundation/Foundation.h>

#import "FlutterSoundRecorder.h"


class AudioRecInterface
{
public:
        virtual ~AudioRecInterface(){};
        virtual void stopRecorder() = 0;
        virtual void startRecorder( FlutterSoundRecorder* rec) = 0;
        virtual void resumeRecorder() = 0;
        virtual void pauseRecorder() = 0;
        virtual NSNumber* recorderProgress() = 0;
        virtual NSNumber* dbPeakProgress() = 0;

        int16_t maxAmplitude = 0;
};



class AudioRecorderEngine : public AudioRecInterface
{
private:
        AVAudioEngine* engine;
        NSFileHandle * fileHandle;
        AVAudioConverterInputStatus inputStatus = AVAudioConverterInputStatus_NoDataNow;
        long dateCumul = 0;
        long previousTS;

public:


       /* ctor */ AudioRecorderEngine(t_CODEC coder, NSString* path, NSMutableDictionary* audioSettings, Session* session)
        {
                engine = [[AVAudioEngine alloc] init];
                dateCumul = 0;
                previousTS = 0;

                AVAudioInputNode* inputNode = [engine inputNode];
                AVAudioFormat* inputFormat = [inputNode outputFormatForBus: 0];
                NSNumber* nbChannels = audioSettings [AVNumberOfChannelsKey];
                NSNumber* sampleRate = audioSettings [AVSampleRateKey];
                AVAudioFormat* recordingFormat = [[AVAudioFormat alloc] initWithCommonFormat: AVAudioPCMFormatInt16 sampleRate: sampleRate.doubleValue channels: nbChannels.integerValue interleaved: YES];
                AVAudioConverter* converter = [[AVAudioConverter alloc]initFromFormat:inputFormat toFormat:recordingFormat];
                NSFileManager* fileManager = [NSFileManager defaultManager];
                NSURL* fileURL = nil;
                if (path != nil && path != [NSNull null])
                {
                        BOOL success = [fileManager removeItemAtPath:path error:nil];
                        [fileManager createFileAtPath: path contents:nil attributes:nil];
                        fileURL = [[NSURL alloc] initFileURLWithPath: path];
                        fileHandle = [NSFileHandle fileHandleForWritingAtPath: path];
                } else
                {
                        fileHandle = nil;
                }


                [inputNode installTapOnBus: 0 bufferSize: 2048 format: inputFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when)
                {
                        inputStatus = AVAudioConverterInputStatus_HaveData ;
                        AVAudioPCMBuffer* convertedBuffer = [[AVAudioPCMBuffer alloc]initWithPCMFormat:recordingFormat frameCapacity: [buffer frameCapacity]];

        
                        AVAudioConverterInputBlock inputBlock = ^AVAudioBuffer*(AVAudioPacketCount inNumberOfPackets, AVAudioConverterInputStatus *outStatus)
                        {
                                *outStatus = inputStatus;
                                inputStatus =  AVAudioConverterInputStatus_NoDataNow;
                                return buffer;
                        };
                        BOOL r = [converter convertToBuffer: convertedBuffer error: nil withInputFromBlock: inputBlock];
                        int n = [convertedBuffer frameLength];
                        int16_t *const  bb = [convertedBuffer int16ChannelData][0];
                        NSData* b = [[NSData alloc] initWithBytes: bb length: n * 2 ];
                        if (n > 0)
                        {
                                if (fileHandle != nil)
                                {
                                        [fileHandle writeData: b];
                                } else
                                {
                                        //NSDictionary* dic = [[NSMutableDictionary alloc] init];
                                        //[dic setValue: b forKey: @"recordingData"];
                                        NSDictionary* dico = @{ @"slotNo": [NSNumber numberWithInt: [session getSlotNo]], @"recordingData": b,};
                                        [session invokeMethod: @"recordingData" dico: dico];
                                }
                                
                                int16_t* pt = [convertedBuffer int16ChannelData][0];
                                for (int i = 0; i < [buffer frameLength]; ++pt, ++i)
                                {
                                        short curSample = *pt;
                                        if ( curSample > maxAmplitude )
                                        {
                                                maxAmplitude = curSample;
                                        }
                        
                                }
                        }
                }];
        }
         
        /* dtor */virtual ~AudioRecorderEngine()
        {
        
        }

        virtual void startRecorder(FlutterSoundRecorder* rec)
        {
                [engine startAndReturnError: nil];
                previousTS = CACurrentMediaTime() * 1000;
        }
        
        virtual void stopRecorder()
        {
                [engine stop];
                [fileHandle closeFile];
                if (previousTS != 0)
                {
                        dateCumul += CACurrentMediaTime() * 1000 - previousTS;
                        previousTS = 0;
                }
                engine = nil;
        }
        
        virtual void resumeRecorder()
        {
                [engine startAndReturnError: nil];
                previousTS = CACurrentMediaTime() * 1000;
         
        }
        
        virtual void pauseRecorder()
        {
                [engine pause];
                if (previousTS != 0)
                {
                        dateCumul += CACurrentMediaTime() * 1000 - previousTS;
                        previousTS = 0;
                }
         
        }
        
        NSNumber* recorderProgress()
        {
                long r = dateCumul;
                if (previousTS != 0)
                {
                        r += CACurrentMediaTime() * 1000 - previousTS;
                }
                return [NSNumber numberWithInt: r];
        }
        virtual NSNumber* dbPeakProgress()
        {
                double max = (double)maxAmplitude;
                maxAmplitude = 0;
                if (max == 0.0)
                {
                        // if the microphone is off we get 0 for the amplitude which causes
                        // db to be infinite.
                        return [NSNumber numberWithDouble: 0.0];
                }
                
        
                // Calculate db based on the following article.
                // https://stackoverflow.com/questions/10655703/what-does-androids-getmaxamplitude-function-for-the-mediarecorder-actually-gi
                //
                double ref_pressure = 51805.5336;
                double p = max / ref_pressure;
                double p0 = 0.0002;
                double l = log10(p / p0);

                double db = 20.0 * l;

                return [NSNumber numberWithDouble: db];
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
        
        void startRecorder(FlutterSoundRecorder* rec)
        {
                  [audioRecorder setDelegate: rec];
                  [audioRecorder record];
                  [audioRecorder setMeteringEnabled: YES];
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
        
        NSNumber* recorderProgress()
        {
                NSNumber* duration =    [NSNumber numberWithLong: (long)(audioRecorder.currentTime * 1000 )];

                
                [audioRecorder updateMeters];
                return duration;
        }
        virtual NSNumber* dbPeakProgress()
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
		true, // pcm16
		true, // pcm16WAV
		false, // pcm16AIFF
		true, // pcm16CAF
		true, // flac
		true, // aacMP4
                false, // amrNB
                false, // amrWB

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
          @"sound.amr", // amrNB
          @"sound.amr", // amrWB

};

static AudioFormatID formats [] =
{
          kAudioFormatMPEG4AAC          // CODEC_DEFAULT
        , kAudioFormatMPEG4AAC          // CODEC_AAC
        , 0                             // CODEC_OPUS
        , kAudioFormatOpus              // CODEC_CAF_OPUS
        , 0                             // CODEC_MP3
        , 0                             // CODEC_OGG_vorbis
        , 0                             // pcm16
        , kAudioFormatLinearPCM         // pcm16WAV
        , 0                             // pcm16AIFF
        , kAudioFormatLinearPCM         // pcm16CAF
        , kAudioFormatFLAC              // flac
        , kAudioFormatMPEG4AAC          // aacMP4
        , kAudioFormatAMR               // amrNB
        , kAudioFormatAMR_WB            // amrWB
};


AudioRecInterface* audioRec;

@implementation FlutterSoundRecorder
{
        //NSURL *audioFileURL;
        NSTimer* dbPeakTimer;
        NSTimer* recorderTimer;
        double subscriptionDuration;
        NSString* path;
}


- (FlutterSoundRecorder*)init: (FlutterMethodCall*)call
{
        return [super init: call];
}

-(FlautoRecorderManager*) getPlugin
{
        return flautoRecorderManager;
}

- (void)initializeFlautoRecorder : (FlutterMethodCall*)call result:(FlutterResult)result
{
        [self setAudioFocus: call result: result];}

- (void)releaseFlautoRecorder : (FlutterMethodCall*)call result:(FlutterResult)result
{
        [super releaseSession];
        result([NSNumber numberWithBool: YES]);
}

- (void)isEncoderSupported:(t_CODEC)codec result: (FlutterResult)result
{
        NSNumber* b = [NSNumber numberWithBool: _isIosEncoderSupported[codec] ];
        result(b);
}


enum AudioSource {
  defaultSource,
  microphone,
  voiceDownlink, // (if someone can explain me what it is, I will be grateful ;-) )
  camCorder,
  remote_submix,
  unprocessed,
  voice_call,
  voice_communication,
  voice_performance,
  voice_recognition,
  voiceUpLink,
  bluetoothHFP,
  headsetMic,
  lineIn

};

AVAudioSessionPort tabSessionPort [] =
{
        0, // defaultSource
        AVAudioSessionPortBuiltInMic, // microphone
        0, // voiceDownLink
        0, // camcorder
        0, // remote_submix
        0, // unprocessed
        0, //  voice_call,
        0, //  voice_communication,
        0, //  voice_performance,
        0, //  voice_recognition,
        0, //  voiceUpLink,
        AVAudioSessionPortBluetoothHFP, //  bluetoothHFP,
        AVAudioSessionPortHeadsetMic,
        AVAudioSessionPortLineIn,
};



- (void)setAudioFocus: (FlutterMethodCall*)call result: (FlutterResult)result
{
        BOOL r = [self setAudioFocus: call ];
        if (r)
                result((@"setAudioFocus"));
        else
                [FlutterError
                                errorWithCode:@"Audio Player"
                                message:@"Open session failure"
                                details:nil];
}


- (void)startRecorder :(FlutterMethodCall*)call result:(FlutterResult)result
{
           path = (NSString*)call.arguments[@"path"];
           NSNumber* sampleRateArgs = (NSNumber*)call.arguments[@"sampleRate"];
           NSNumber* numChannelsArgs = (NSNumber*)call.arguments[@"numChannels"];
           //NSNumber* iosQuality = (NSNumber*)call.arguments[@"iosQuality"];
           NSNumber* bitRate = (NSNumber*)call.arguments[@"bitRate"];
           NSNumber* codec = (NSNumber*)call.arguments[@"codec"];
           int audioSource = [(NSNumber*)call.arguments[@"audioSource"] intValue];
           
           AVAudioSession* audioSession = [AVAudioSession sharedInstance];
           NSArray<AVAudioSessionPortDescription*>* availableInputs = [audioSession availableInputs];
           bool found = false;
           for (AVAudioSessionPortDescription* portDescr in availableInputs)
           {
                AVAudioSessionPort port = [portDescr portType];
                if ([port isEqual:tabSessionPort[audioSource]])
                {
                        [audioSession setPreferredInput: portDescr error: nil ];
                        found = true;
                }
           }

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

            // If bitrate is defined, we use it, otherwise use the OS default
            if(![bitRate isEqual:[NSNull null]])
            {
                        [audioSettings setValue:[NSNumber numberWithInt: [bitRate intValue]]
                            forKey:AVEncoderBitRateKey];
            }

          if(coder == pcm16)
          {
                if (numChannels != 1)
                {
                              [FlutterError
                                errorWithCode:@"FlutterSoundRecorder"
                                message:@"Raw PCM is supported with only 1 number of channels"
                                details:nil];
                                return;
                }
                audioRec = new AudioRecorderEngine(coder, path, audioSettings, self);
          } else
          {
                audioRec = new avAudioRec( path, audioSettings);
          }
          audioRec ->startRecorder(self);
          [self startRecorderTimer];

           result(path);
}


- (void)stopRecorder:(FlutterResult)result
{
 
          [self stopRecorderTimer];
          if (audioRec != nil)
          {
                try {
                        audioRec -> stopRecorder();
                } catch ( NSException* e) {
                }
                delete audioRec;
                audioRec = nil;
          }
          result(path);
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



// post fix with _FlutterSound to avoid conflicts with common libs including path_provider
- (NSString*) GetDirectoryOfType_FlutterSound: (NSSearchPathDirectory) dir
{
        NSArray* paths = NSSearchPathForDirectoriesInDomains(dir, NSUserDomainMask, YES);
        return [paths.firstObject stringByAppendingString:@"/"];
}


- (void) stopRecorderTimer{
    if (recorderTimer != nil) {
        [recorderTimer invalidate];
        recorderTimer = nil;
    }
}


- (void)setSubscriptionDuration:(FlutterMethodCall*)call result: (FlutterResult)result
{
        NSNumber* milliSec = (NSNumber*)call.arguments[@"duration"];
        subscriptionDuration = [milliSec doubleValue]/1000;
        result(@"setSubscriptionDuration");
}

- (void)pauseRecorder : (FlutterMethodCall*)call result:(FlutterResult)result
{
        audioRec ->pauseRecorder();
        [self stopRecorderTimer];
        result(@"Recorder is Paused");
}

- (void)resumeRecorder : (FlutterMethodCall*)call result:(FlutterResult)result
{
        audioRec ->resumeRecorder();
        [self startRecorderTimer];
        result(@"Recorder is Resumed");
}



- (void)updateRecorderProgress:(NSTimer*) atimer
{
        assert (recorderTimer == atimer);
        NSNumber* duration = audioRec ->recorderProgress();

        NSNumber * normalizedPeakLevel = audioRec ->dbPeakProgress();
        
        NSDictionary* dico = @{ @"slotNo": [NSNumber numberWithInt: slotNo], @"dbPeakLevel": normalizedPeakLevel, @"duration": duration};
        [self invokeMethod:@"updateRecorderProgress" dico: dico];
}
 


@end


//---------------------------------------------------------------------------------------------
 
