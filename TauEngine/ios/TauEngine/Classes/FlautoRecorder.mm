//
//  AudioRecorder.m
//  flutter_sound
//
//  Created by larpoux on 02/05/2020.
//
/*
 * Copyright 2018, 2019, 2020 Dooboolab.
 *
 * This file is part of the Tau project.
 *
 * Tau is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License version 3 (LGPL-V3), as published by
 * the Free Software Foundation.
 *
 * Tau is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with the Tau project.  If not, see <https://www.gnu.org/licenses/>.
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



AudioRecInterface* audioRec;


@implementation FlautoRecorder
{
        //NSURL *audioFileURL;
        NSTimer* dbPeakTimer;
        NSTimer* recorderTimer;
        double subscriptionDuration;
        NSString* path;
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

- (bool)initializeFlautoRecorder:
               (t_AUDIO_FOCUS)focus
                category: (t_SESSION_CATEGORY)category
                mode: (t_SESSION_MODE)mode
                audioFlags: (int)audioFlags
                audioDevice: (t_AUDIO_DEVICE)audioDevice
{
        BOOL r = [self setAudioFocus: focus category: category mode: mode audioFlags: audioFlags audioDevice: audioDevice ];
        [m_callBack openAudioSessionCompleted: r];
        return r;
}

- (bool)isEncoderSupported:(t_CODEC)codec 
{
        return  _isIosEncoderSupported[codec] ;
}


- (void)releaseFlautoRecorder
{
        NSLog(@"IOS:--> releaseFlautoPlayer");
        NSLog(@"IOS:<-- releaseFlautoPlayer");
}



- (bool)startRecorderCodec: (t_CODEC)codec
                toPath: (NSString*)path
                channels: (int)numChannels
                sampleRate: (long)sampleRate
                bitRate: (long)bitRate
                audioSource: (t_AUDIO_SOURCE) audioSource
{
        AVAudioSession* audioSession = [AVAudioSession sharedInstance];
        NSArray<AVAudioSessionPortDescription*>* availableInputs = [audioSession availableInputs];
        //bool found = false;
        if (tabSessionPort[audioSource] != 0)
        {
                for (AVAudioSessionPortDescription* portDescr in availableInputs)
                {
                        AVAudioSessionPort port = [portDescr portType];
                        if ([port isEqual:tabSessionPort[audioSource]])
                        {
                                [audioSession setPreferredInput: portDescr error: nil ];
                                break;
                                //found = true;
                        }
                }
        }

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

        return true;
}


- (void)stopRecorder
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
}

- (void)pauseRecorder
{
        audioRec ->pauseRecorder();
        [self stopRecorderTimer];
}

- (void)resumeRecorder
{
        audioRec ->resumeRecorder();
        [self startRecorderTimer];
}



- (void)updateRecorderProgress:(NSTimer*) atimer
{
        assert (recorderTimer == atimer);
        NSNumber* duration = audioRec ->recorderProgress();
        NSNumber * normalizedPeakLevel = audioRec ->dbPeakProgress();
        [m_callBack updateRecorderProgressDbPeakLevel: normalizedPeakLevel duration: duration];
}
 


@end


//---------------------------------------------------------------------------------------------
 
