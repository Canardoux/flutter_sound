//
//  SoundRecorder.h
//  Pods
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

#ifndef FlautoRecorder_h
#define FlautoRecorder_h


#import <Flutter/Flutter.h>
#import <AVFoundation/AVFoundation.h>
#import "Flauto.h"

extern void FlautoRecorderReg(NSObject<FlutterPluginRegistrar>* registrar);


@interface FlautoRecorderManager : NSObject
{
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar;
- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result;
- (void)invokeMethod: (NSString*)methodName arguments: (NSDictionary*)call;
- (void)freeSlot: (int)slotNo;
@end



@interface FlutterSoundRecorder : NSObject <AVAudioPlayerDelegate>
{
}

- (FlautoRecorderManager*) getPlugin;
- (FlutterSoundRecorder*)init: (int)aSlotNo;

- (void)isEncoderSupported:(t_CODEC)codec result: (FlutterResult)result;
- (void)startRecorder :(FlutterMethodCall*)call result:(FlutterResult)result;
- (void)stopRecorder:(FlutterResult)result;
- (void)setDbPeakLevelUpdate:(double)intervalInSecs result: (FlutterResult)result;
- (void)setDbLevelEnabled:(BOOL)enabled result: (FlutterResult)result;
- (void)initializeFlautoRecorder : (FlutterMethodCall*)call result:(FlutterResult)result;
- (void)releaseFlautoRecorder : (FlutterMethodCall*)call result:(FlutterResult)result;
- (void)setSubscriptionDuration:(double)duration result: (FlutterResult)result;
- (void)pauseRecorder : (FlutterMethodCall*)call result:(FlutterResult)result;
- (void)resumeRecorder : (FlutterMethodCall*)call result:(FlutterResult)result;

@end

#endif /* FlautoRecorder_h */
