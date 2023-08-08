//
//  AudioRecorder.h
//  
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

#ifndef FlautoRecorder_h
#define FlautoRecorder_h


#import <AVFoundation/AVFoundation.h>
#import "Flauto.h"
 

@protocol FlautoRecorderCallback <NSObject>
- (void)openRecorderCompleted: (bool)success;
- (void)closeRecorderCompleted: (bool)success;
- (void)startRecorderCompleted: (bool)success;
- (void)stopRecorderCompleted: (NSString*)path success:(bool)success;
- (void)resumeRecorderCompleted: (bool)success;
- (void)pauseRecorderCompleted: (bool)success;
- (void)updateRecorderProgressDbPeakLevel: normalizedPeakLevel duration: duration;
- (void)recordingData: (NSData*)data;
- (void)log: (t_LOG_LEVEL)level msg: (NSString*)msg;
@end

@interface FlautoRecorder  : NSObject <AVAudioRecorderDelegate>
{
        NSObject<FlautoRecorderCallback>* m_callBack;
}
- (FlautoRecorder*)init: (NSObject<FlautoRecorderCallback>*) callback;
- (bool)initializeFlautoRecorder;

- (bool)isEncoderSupported:(t_CODEC)codec ;
- (void)releaseFlautoRecorder;

- (bool)startRecorderCodec: (t_CODEC)codec
                toPath: (NSString*)path
                channels: (int)numChannels
                sampleRate: (long)sampleRate
                bitRate: (long)bitRate;
                
- (void)stopRecorder;
- (void)setSubscriptionDuration: (long)millisec;
- (void)pauseRecorder;
- (void)resumeRecorder;
- (bool)deleteRecord: (NSString*)path;
- (NSString*)getRecordURL: (NSString*)path;
- (void)recordingData: (NSData*)data;
- (int)getStatus;
- (void)logDebug: (NSString*)msg;


@end

#endif /* FlautoRecorder_h */
