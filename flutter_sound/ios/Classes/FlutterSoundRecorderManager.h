//
//  SoundRecorder.h
//  Pods
//
//  Created by larpoux on 24/03/2020.
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



#ifndef FlutterSoundRecorderManager_h
#define FlutterSoundRecorderManager_h


#import <Flutter/Flutter.h>
#import <AVFoundation/AVFoundation.h>
//#import "Flauto.h"
#import "FlutterSoundManager.h"

extern void FlutterSoundRecorderReg(NSObject<FlutterPluginRegistrar>* registrar);


@interface FlutterSoundRecorderManager : FlutterSoundManager
{
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar;
- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result;
@end

extern FlutterSoundRecorderManager* flutterSoundRecorderManager; // Singleton

#endif /* FlutterSoundRecorderManager_h */
