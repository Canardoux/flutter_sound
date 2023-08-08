//
//  AudioRecorder.m
//  flutter_sound
//
//  Created by larpoux on 02/05/2020.
//
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


#import <Foundation/Foundation.h>

#import "Flauto.h"
#import "FlautoRecorder.h"
#import "FlautoRecorderEngine.h"


//-------------------------------------------------------------------------------------------------------------------------------------

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
                
                false, // pcm8
                false, // pcmFloat32
                false, // pcmWebM
                false, // opusWebM
                false, // vorbisWebM

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
          @"sound.amrwb", // amrWB
          @"sound.pcm8", // pcm8
          @"sound.pcmF32", // pcmFloat32
          @"sound.webm", // pcmWebM
          @"sound_opus.webm", // opusWebM
          @"sound_vorbis.webm", // vorbisWebM

          

};

static AudioFormatID formats [] =
{
          kAudioFormatMPEG4AAC          // CODEC_DEFAULT
        , kAudioFormatMPEG4AAC          // CODEC_AAC
        , 0                             // CODEC_OPUS
        , kAudioFormatOpus              // CODEC_CAF_OPUS
        , 0                             // CODEC_MP3
        , 0                             // CODEC_OGG_vorbis
        , kAudioFormatLinearPCM         // pcm16
        , kAudioFormatLinearPCM         // pcm16WAV
        , 0                             // pcm16AIFF
        , kAudioFormatLinearPCM         // pcm16CAF
        , kAudioFormatFLAC              // flac
        , kAudioFormatMPEG4AAC          // aacMP4
        , kAudioFormatAMR               // amrNB
        , kAudioFormatAMR_WB            // amrWB
        , 0                             // pcm8
        , 0                             // pcmFloat32
        , 0                             // pcmWebM
        , 0                             // opusWebM
        , 0                             // vorbisWebM
};


AVAudioSessionPort tabSessionPort [] =
{
        0, // defaultSource
        0, // microphone
        0, // voiceDownLink
        0, // camcorder
        0, // remote_submix
        0, // unprocessed
        0, //  voice_call,
        0, //  voice_communication,
        0, //  voice_performance,
        0, //  voice_recognition,
        0, //  voiceUpLink,
        0, //  bluetoothHFP,
        0,
        0,
};



AudioRecInterface* audioRec;


@implementation FlautoRecorder
{
        NSTimer* dbPeakTimer;
        NSTimer* recorderTimer;
        double subscriptionDuration;
        NSString* m_path;
}

- (void)recordingData: (NSData*)data
{
        [m_callBack recordingData: data];
}


- (FlautoRecorder*)init: (NSObject<FlautoRecorderCallback>*) callback
{
        m_callBack = callback;
        return [super init];
}

- (bool)initializeFlautoRecorder
{
        [m_callBack openRecorderCompleted: YES];
        return YES;
}

- (bool)isEncoderSupported:(t_CODEC)codec 
{
        return  _isIosEncoderSupported[codec] ;
}


- (void)releaseFlautoRecorder
{
        [self logDebug:  @"IOS:--> releaseFlautoRecorder"];

        [ self stop];
        [m_callBack closeRecorderCompleted: true];
        [self logDebug:  @"IOS:<-- releaseFlautoRecorder"];

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

- (bool)startRecorderCodec: (t_CODEC)codec
                toPath: (NSString*)path
                channels: (int)numChannels
                sampleRate: (long)sampleRate
                bitRate: (long)bitRate
{
        NSMutableDictionary* audioSettings = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 [NSNumber numberWithLong: sampleRate], AVSampleRateKey,
                                 [NSNumber numberWithInt: formats[codec] ], AVFormatIDKey,
                                 [NSNumber numberWithInt: numChannels ], AVNumberOfChannelsKey,
                         nil];

        // If bitrate is defined, we use it, otherwise use the OS default
        if(bitRate > 0)
        {
                [audioSettings setValue:[NSNumber numberWithLong: bitRate]
                    forKey:AVEncoderBitRateKey];
        }
 
        path = [self getpath: path];
        m_path = path;

        if(codec == pcm16)
        {
                if (numChannels != 1)
                {
                                return false;
                }
                audioRec = new AudioRecorderEngine(codec, path, audioSettings, self);
        } else
        {
                audioRec = new avAudioRec(codec, path, audioSettings, self);
        }
        audioRec ->startRecorder();
        [self startRecorderTimer];
        [m_callBack startRecorderCompleted: true];

        return true;
}

- (void)stop
{
          [self logDebug:  @"iOS: ---> stop (flautoRecorder)"];

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
          [self logDebug:  @"iOS: <--- stop (flautoRecorder)"];

}

- (void)stopRecorder
{
          [self logDebug:  @"iOS: ---> stopRecorder (FlautoRecorder)"];
          [self stop];
          NSString* url = [self getUrl: m_path];
          [m_callBack stopRecorderCompleted: url success: YES];
          m_path = nil;
          [self logDebug:  @"iOS: <--- stopRecorder (FlautoRecorder)"];
}

- (void)logDebug: (NSString*)msg
{
        [m_callBack log: DBG msg: msg];
}

- (bool)deleteRecord: (NSString*)path
{
        NSString* url = [self getUrl: path];
        if (url != NULL)
        {
                NSFileManager *fileManager = [NSFileManager defaultManager];
                NSError *error;
                BOOL success = [fileManager removeItemAtPath: url error: &error];
                return success;
        }
        return false;
  
}


- (NSString*)getRecordURL: (NSString*)path
{
        NSString* url = [self getUrl: path];
        return url;
}


- (void)startRecorderTimer
{
        [self stopRecorderTimer];
        if (subscriptionDuration > 0)
        {
                recorderTimer = [NSTimer scheduledTimerWithTimeInterval: subscriptionDuration
                                                   target:self
                                                   selector:@selector(updateRecorderProgress:)
                                                   userInfo:nil
                                                   repeats:YES];
        }    
}



// post fix with _FlutterSound to avoid conflicts with common libs including path_provider
- (NSString*) GetDirectoryOfType_FlutterSound: (NSSearchPathDirectory) dir
{
        NSArray* paths = NSSearchPathForDirectoriesInDomains(dir, NSUserDomainMask, YES);
        return [paths.firstObject stringByAppendingString:@"/"];
}


- (void) stopRecorderTimer
{
        if (recorderTimer != nil)
        {
                [recorderTimer invalidate];
                recorderTimer = nil;
        }
}


- (void)setSubscriptionDuration: (long)millisec
{
        subscriptionDuration = ((double)millisec)/1000.0;
        if (audioRec != nil)
        {
                [self startRecorderTimer];
        }

}

- (void)pauseRecorder
{
        audioRec ->pauseRecorder();
        [self stopRecorderTimer];
        [m_callBack pauseRecorderCompleted: true];
}

- (void)resumeRecorder
{
        audioRec ->resumeRecorder();
        [self startRecorderTimer];
        [m_callBack resumeRecorderCompleted: true];
}



- (void)updateRecorderProgress:(NSTimer*) atimer
{
        assert (recorderTimer == atimer);
        NSNumber* duration = audioRec ->recorderProgress();
        NSNumber * normalizedPeakLevel = audioRec ->dbPeakProgress();
        [m_callBack updateRecorderProgressDbPeakLevel: normalizedPeakLevel duration: duration];
}
 
- (int)getStatus
{
        int r = 0;
        if (audioRec != nil)
            r = audioRec ->getStatus();
        return r;
}

@end


//---------------------------------------------------------------------------------------------
 
