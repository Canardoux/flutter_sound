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

@interface Session : NSObject
{
      int slotNo;
      BOOL hasFocus;
}
- (int) getStatus;
- (Session*) init: (FlutterMethodCall*)call;
- (void) releaseSession;
- (void)invokeMethod: (NSString*)methodName dico: (NSDictionary*)dico;
- (void)invokeMethod: (NSString*)methodName stringArg: (NSString*)stringArg;
- (void)invokeMethod: (NSString*)methodName boolArg: (Boolean)boolArg;
- (void)invokeMethod: (NSString*)methodName numberArg: (NSNumber*)arg;
- (BOOL)setAudioFocus: (FlutterMethodCall*)call ;
- (int)getSlotNo;
- (void)freeSlot: (int)slotNo;
- (void)invokeMethod: (NSString*)methodName arguments: (NSDictionary*)call;


@end


@interface FlutterSoundManager : NSObject <FlutterPlugin>
{
        FlutterMethodChannel* channel;
}

- (Session*)getSession: (FlutterMethodCall*)call;
- (int) initPlugin: (Session*) session call:(FlutterMethodCall*)call;



@end



#endif /* FlutterSoundManager_h */
