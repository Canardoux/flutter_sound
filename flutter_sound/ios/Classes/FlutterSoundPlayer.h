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



#ifndef FlutterSoundPlayer_h
#define FlutterSoundPlayer_h



#import <Flutter/Flutter.h>
#import <AVFoundation/AVFoundation.h>
#import <tau_core/FlautoPlayer.h>
#import <tau_core/Flauto.h>
#include "FlutterSoundManager.h"
#include "FlutterSoundPlayerManager.h"

@interface FlutterSoundPlayer : Session<FlautoPlayerCallback>
{
        FlautoPlayer* flautoPlayer;
}


- (void)reset: (FlutterMethodCall*)call result: (FlutterResult)result;
- (int)getStatus;
- (FlutterSoundPlayerManager*) getPlugin;
- (Session*) init: (FlutterMethodCall*)call;
- (void)isDecoderSupported:(t_CODEC)codec result: (FlutterResult)result;
- (void)pausePlayer:(FlutterResult)result;
- (void)resumePlayer:(FlutterResult)result;
- (void)startPlayer:(FlutterMethodCall*)path result: (FlutterResult)result;
- (void)startPlayerFromMic:(FlutterMethodCall*)path result: (FlutterResult)result;
- (void)getProgress:(FlutterMethodCall*)call result: (FlutterResult)result;
- (void)startPlayerFromTrack:(FlutterMethodCall*)call result: (FlutterResult)result;
- (void)seekToPlayer:(FlutterMethodCall*) time result: (FlutterResult)result;
- (void)setSubscriptionDuration:(FlutterMethodCall*)call result: (FlutterResult)result;
- (void)setVolume:(double) volume result: (FlutterResult)result;
- (void)setCategory: (FlutterMethodCall*)call result:(FlutterResult)result;
- (void)setActive: (FlutterMethodCall*)call result:(FlutterResult)result;
- (void)openPlayer: (FlutterMethodCall*)call result: (FlutterResult)result;
- (void)closePlayer: (FlutterMethodCall*)call result: (FlutterResult)result;
- (void)setAudioFocus: (FlutterMethodCall*)call result: (FlutterResult)result;
- (void)setUIProgressBar:(FlutterMethodCall*)call result: (FlutterResult)result;
- (void)nowPlaying:(FlutterMethodCall*)call result: (FlutterResult)result;
- (void)getPlayerState:(FlutterMethodCall*)call result: (FlutterResult)result;
- (void)stopPlayer:(FlutterMethodCall*)call  result:(FlutterResult)result;
- (void)feed:(FlutterMethodCall*)call result: (FlutterResult)result;

@end

#endif // FlutterSoundPlayer_h

