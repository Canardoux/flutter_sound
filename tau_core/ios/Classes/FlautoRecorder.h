//
//  AudioRecorder.h
//  
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

#ifndef FlautoRecorder_h
#define FlautoRecorder_h


#import <AVFoundation/AVFoundation.h>
#import "Flauto.h"
#import "FlautoSession.h"
 

@protocol FlautoRecorderCallback <NSObject>
- (void)openRecorderCompleted: (bool)success;
- (void)closeRecorderCompleted: (bool)success;
- (void)startRecorderCompleted: (bool)success;
- (void)stopRecorderCompleted: (NSString*)path success:(bool)success;
- (void)resumeRecorderCompleted: (bool)success;
- (void)pauseRecorderCompleted: (bool)success;
- (void)updateRecorderProgressDbPeakLevel: normalizedPeakLevel duration: duration;
- (void)recordingData: (NSData*)data;
@end

@interface FlautoRecorder  : FlautoSession <  AVAudioRecorderDelegate>
{
        NSObject<FlautoRecorderCallback>* m_callBack;
}
- (FlautoRecorder*)init: (NSObject<FlautoRecorderCallback>*) callback;
- (bool)initializeFlautoRecorder:
               (t_AUDIO_FOCUS)focus
                category: (t_SESSION_CATEGORY)category
                mode: (t_SESSION_MODE)mode
                audioFlags: (int)audioFlags
                audioDevice: (t_AUDIO_DEVICE)audioDevice;

- (bool)isEncoderSupported:(t_CODEC)codec ;
- (void)releaseFlautoRecorder;

- (bool)startRecorderCodec: (t_CODEC)codec
                toPath: (NSString*)path
                channels: (int)numChannels
                sampleRate: (long)sampleRate
                bitRate: (long)bitRate
                audioSource: (t_AUDIO_SOURCE) audioSource;
                
- (void)stopRecorder;
- (void)setSubscriptionDuration: (long)millisec;
- (void)pauseRecorder;
- (void)resumeRecorder;
- (bool)deleteRecord: (NSString*)path;
- (NSString*)getRecordURL: (NSString*)path;
- (void)recordingData: (NSData*)data;
- (int)getStatus;


@end

#endif /* FlautoRecorder_h */
