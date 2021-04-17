//
//  AudioRecorder.h
//  
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


#ifndef FlutterSoundRecorder_h
#define FlutterSoundRecorder_h


#import <Flutter/Flutter.h>
#import <AVFoundation/AVFoundation.h>
#import "FlutterSoundRecorderManager.h"
#import <tau_core/Flauto.h>
#import <tau_core/FlautoRecorder.h>


@interface FlutterSoundRecorder  : Session<FlautoRecorderCallback>
{
        FlautoRecorder* flautoRecorder;
}
// Callback
- (void)updateRecorderProgressDbPeakLevel: normalizedPeakLevel duration: duration;
- (void)recordingData: (NSData*)data;

// Interface
- (FlutterSoundRecorderManager*) getPlugin;
- (Session*) init: (FlutterMethodCall*)call;
- (int)getStatus;

- (void)reset: (FlutterMethodCall*)call result: (FlutterResult)result;
- (void)isEncoderSupported:(t_CODEC)codec result: (FlutterResult)result;
- (void)startRecorder :(FlutterMethodCall*)call result:(FlutterResult)result;
- (void)stopRecorder:(FlutterResult)result;
- (void)setDbPeakLevelUpdate:(double)intervalInSecs result: (FlutterResult)result;
//- (void)setDbLevelEnabled:(BOOL)enabled result: (FlutterResult)result;
- (void)openRecorder : (FlutterMethodCall*)call result:(FlutterResult)result;
- (void)closeRecorder : (FlutterMethodCall*)call result:(FlutterResult)result;
- (void)setSubscriptionDuration:(FlutterMethodCall*)call result: (FlutterResult)result;
- (void)setAudioFocus: (FlutterMethodCall*)call result: (FlutterResult)result;
- (void)pauseRecorder : (FlutterMethodCall*)call result:(FlutterResult)result;
- (void)resumeRecorder : (FlutterMethodCall*)call result:(FlutterResult)result;
- (void)deleteRecord: (FlutterMethodCall*)call result: (FlutterResult)result;
- (void)getRecordURL: (FlutterMethodCall*)call result: (FlutterResult)result;
 
@end

#endif /* FlutterSoundRecorder_h */
