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


#import <Flutter/Flutter.h>
#import <AVFoundation/AVFoundation.h>
#import "FlautoManager.h"
#import "Flauto.h"


extern void FlautoPlayerReg(NSObject<FlutterPluginRegistrar>* registrar);
//extern NSMutableArray* flautoPlayerSlots;


@interface FlautoPlayerManager : FlautoManager
{
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar;
- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result;
//- (void)invokeMethod: (NSString*)methodName arguments: (NSDictionary*)call;
//- (void)freeSlot: (int)slotNo;
@end

@interface FlutterSoundPlayer : Session
{
        AVAudioPlayer *audioPlayer;
        bool isPaused ;
}

- (FlautoPlayerManager*) getPlugin;
- (Session*) init: (FlutterMethodCall*)call;
//- (void) releaseSession;


- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag;
- (void)isDecoderSupported:(t_CODEC)codec result: (FlutterResult)result;
- (void)updateProgress:(NSTimer *)timer;
- (void)startTimer;
- (void)stopPlayer;
- (void)pausePlayer:(FlutterResult)result;
- (void)resumePlayer:(FlutterResult)result;
- (void)stopTimer;
- (void)pause;
- (bool)resume;
- (void)startPlayer:(NSString*)path result: (FlutterResult)result;
- (void)startPlayerFromTrack:(FlutterMethodCall*)call result: (FlutterResult)result;
- (void)startPlayerFromBuffer:(FlutterStandardTypedData*)dataBuffer result: (FlutterResult)result;
- (void)seekToPlayer:(nonnull NSNumber*) time result: (FlutterResult)result;
- (void)setSubscriptionDuration:(FlutterMethodCall*)call result: (FlutterResult)result;
- (void)setVolume:(double) volume result: (FlutterResult)result;
- (void)setCategory: (NSString*)categ mode:(NSString*)mode options:(int)options result:(FlutterResult)result;
- (void)setActive:(BOOL)enabled result:(FlutterResult)result;
- (void)initializeFlautoPlayer: (FlutterMethodCall*)call result: (FlutterResult)result;
- (void)releaseFlautoPlayer: (FlutterMethodCall*)call result: (FlutterResult)result;
- (void)setAudioFocus: (FlutterMethodCall*)call result: (FlutterResult)result;


@end


