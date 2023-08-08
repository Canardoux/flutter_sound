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




#ifndef FlutterSoundPlayer_h
#define FlutterSoundPlayer_h



#import <Flutter/Flutter.h>
#import <AVFoundation/AVFoundation.h>
#import <flutter_sound_core/FlautoPlayer.h>
#import <flutter_sound_core/Flauto.h>
#include "FlutterSoundManager.h"
#include "FlutterSoundPlayerManager.h"

@interface FlutterSoundPlayer : Session<FlautoPlayerCallback>
{
        FlautoPlayer* flautoPlayer;
        FlutterSoundPlayerManager* flutterSoundPlayerManager;

}


- (void)reset: (FlutterMethodCall*)call result: (FlutterResult)result;
- (int)getStatus;
- (FlutterSoundPlayerManager*) getPlugin;
//- (void)setPlayerManager: (FlutterSoundPlayerManager*)pm;
- (Session*) init: (FlutterMethodCall*)call playerManager: (FlutterSoundPlayerManager*)pm;
- (void)isDecoderSupported:(t_CODEC)codec result: (FlutterResult)result;
- (void)pausePlayer:(FlutterResult)result;
- (void)resumePlayer:(FlutterResult)result;
- (void)startPlayer:(FlutterMethodCall*)path result: (FlutterResult)result;
- (void)startPlayerFromMic:(FlutterMethodCall*)path result: (FlutterResult)result;
- (void)getProgress:(FlutterMethodCall*)call result: (FlutterResult)result;
- (void)seekToPlayer:(FlutterMethodCall*) time result: (FlutterResult)result;
- (void)setSubscriptionDuration:(FlutterMethodCall*)call result: (FlutterResult)result;
- (void)setVolume:(double) volume fadeDuration:(NSTimeInterval)duration result: (FlutterResult)result;
- (void)setSpeed:(double) speed  result: (FlutterResult)result;
- (void)openPlayer: (FlutterMethodCall*)call result: (FlutterResult)result;
- (void)closePlayer: (FlutterMethodCall*)call result: (FlutterResult)result;
- (void)getPlayerState:(FlutterMethodCall*)call result: (FlutterResult)result;
- (void)stopPlayer:(FlutterMethodCall*)call  result:(FlutterResult)result;
- (void)feed:(FlutterMethodCall*)call result: (FlutterResult)result;
- (void)setLogLevel: (FlutterMethodCall*)call result: (FlutterResult)result;

@end

#endif // FlutterSoundPlayer_h

