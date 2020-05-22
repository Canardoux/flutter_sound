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

#ifndef FlautoManager_h
#define FlautoManager_h

#import <Flutter/Flutter.h>
#import <AVFoundation/AVFoundation.h>
#import "Flauto.h"

@interface Session : NSObject <AVAudioPlayerDelegate, AVAudioRecorderDelegate>
{
      int slotNo;
      BOOL hasFocus;
}

- (Session*) init: (FlutterMethodCall*)call;
- (void) releaseSession;
- (void)invokeMethod: (NSString*)methodName dico: (NSDictionary*)dico;
- (void)invokeMethod: (NSString*)methodName stringArg: (NSString*)stringArg;
- (void)invokeMethod: (NSString*)methodName boolArg: (Boolean)boolArg;
- (void)invokeMethod: (NSString*)methodName numberArg: (NSNumber*)arg;
- (void)setAudioFocus: (FlutterMethodCall*)call result: (FlutterResult)result;


@end


@interface FlautoManager : NSObject<FlutterPlugin>
{
        FlutterMethodChannel* channel;
}

- (Session*)getSession: (FlutterMethodCall*)call;
- (void) initPlugin: (Session*) session slot:(int)slotNo;




@end



#endif /* FlautoManager_h */
