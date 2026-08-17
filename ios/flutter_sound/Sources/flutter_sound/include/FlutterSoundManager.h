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



//
//  FlautoManager.h
//  Pods
//
//  Created by larpoux on 14/05/2020.
//

#ifndef FlutterSoundManager_h
#define FlutterSoundManager_h

#import <Flutter/Flutter.h>
#import <AVFoundation/AVFoundation.h>
#import <flutter_sound_core/Flauto.h>

@interface Session : NSObject
{
      int slotNo;
}

- (void)reset: (FlutterMethodCall*)call result: (FlutterResult)result;
- (int) getStatus;
- (Session*) init: (FlutterMethodCall*)call;
- (void) releaseSession;
- (void)invokeMethod: (NSString*)methodName dico: (NSDictionary*)dico ;
- (void)invokeMethod: (NSString*)methodName stringArg: (NSString*)stringArg success: (bool)success;
- (void)invokeMethod: (NSString*)methodName boolArg: (Boolean)boolArg success: (bool)success;
- (void)invokeMethod: (NSString*)methodName numberArg: (NSNumber*)arg success: (bool)success;
- (int)getSlotNo;
- (void)freeSlot: (int)slotNo;
- (void)invokeMethod: (NSString*)methodName arguments: (NSDictionary*)call ;
- (void)log: (t_LOG_LEVEL)level msg: (NSString*) msg;


@end


@interface FlutterSoundManager : NSObject <FlutterPlugin>
{
        FlutterMethodChannel* channel;
}

- (Session*)getSession: (FlutterMethodCall*)call;
- (int) initPlugin: (Session*) session call:(FlutterMethodCall*)call;
- (void) resetPlugin: (FlutterMethodCall*)call result: (FlutterResult)result ;



@end



#endif /* FlutterSoundManager_h */
