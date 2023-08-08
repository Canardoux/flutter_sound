//
//  FlautoManager.m
//  flutter_sound
//
//  Created by larpoux on 14/05/2020.
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





#import <Foundation/Foundation.h>
#import "FlutterSoundManager.h"
#import <flutter_sound_core/Flauto.h>


@implementation FlutterSoundManager
{
        NSMutableArray* flautoPlayerSlots;
}

- (FlutterSoundManager*)init
{
        self = [super init];
        flautoPlayerSlots = [[NSMutableArray alloc] init];
        return self;
}

- (int) initPlugin: (Session*) session call:(FlutterMethodCall*)call
{
        int slotNo = [call.arguments[@"slotNo"] intValue];
        assert ( (slotNo >= 0) && (slotNo < [flautoPlayerSlots count]));
        assert (flautoPlayerSlots[slotNo] ==  [NSNull null] );
        flautoPlayerSlots[slotNo] = session;
        return slotNo;
}

- (void)freeSlot: (int)slotNo
{
        flautoPlayerSlots[slotNo] = [NSNull null];
        [flautoPlayerSlots replaceObjectAtIndex:slotNo withObject:[NSNull null]];
}

- (Session*)getSession: (FlutterMethodCall*)call
{

        int slotNo = [call.arguments[@"slotNo"] intValue];
        assert ( (slotNo >= 0) && (slotNo <= [flautoPlayerSlots count]));
        
        if (slotNo == [flautoPlayerSlots count])
        {
               [flautoPlayerSlots addObject: [NSNull null]];
        }

        return  flautoPlayerSlots[slotNo];
}


- (void)invokeMethod: (NSString*)methodName arguments: (NSDictionary*)call
{
        [channel invokeMethod: methodName arguments: call ];
}


- (void) resetPlugin: (FlutterMethodCall*)call result: (FlutterResult)result
{

        for (int i = 0; i < [flautoPlayerSlots count]; ++i)
        {
                if ( flautoPlayerSlots[i] != [NSNull null] )
                {
                        NSLog (@"iOS: resetPlugin");
                        Session* session =  flautoPlayerSlots[i];
                        [ session reset: call result: result];
                }
        }
        flautoPlayerSlots = [[NSMutableArray alloc] init];
        result( [NSNumber numberWithInt: 0]);

}


@end



//-------------------------------------------------------------------------------------------------------------------------------------------------------



@implementation Session
{
  
}


- (void)log: (t_LOG_LEVEL)level msg: (NSString*) msg
{
        NSNumber* nlevel = [NSNumber numberWithInt: level];
    
        NSDictionary* dico = @{ @"slotNo": [NSNumber numberWithInt: self ->slotNo], @"state": [NSNumber numberWithInt: -1], @"level": nlevel, @"msg": msg };
        [self invokeMethod: @"log" dico: dico  ];
}


-(FlutterSoundManager*) getPlugin
{
        return nil; // Implented in subclass
}

- (Session*) init: (FlutterMethodCall*)call
{
        slotNo = [[self getPlugin] initPlugin: self call: call];
        return [super init];
}

- (int) getSlotNo
{
        return slotNo;
}

- (void) releaseSession
{
        [self log: DBG msg: @"iOS: ---> releaseSession"];
 
        [[self getPlugin]freeSlot: slotNo];
        [self log: DBG msg: @"iOS: <--- releaseSession"];
}

- (void)invokeMethod: (NSString*)methodName stringArg: (NSString*)stringArg success: (bool)success
{
        NSObject* obj = stringArg;
        if (obj == nil)
                obj = [NSNull null];
        NSDictionary* dic =
        @{
                @"slotNo": [NSNumber numberWithInt: slotNo],
                @"arg": obj,
                @"state": [NSNumber numberWithInt:([self getStatus])],
                @"success": [NSNumber numberWithBool: success]
                
        };
        NSString* s = [NSString stringWithFormat: @"iOS: invokeMethod %@ - state=%i", methodName, [self getStatus] ];
        [self log: DBG msg: s];
        [[self getPlugin] invokeMethod: methodName arguments: dic ];
}


- (void)invokeMethod: (NSString*)methodName dico: (NSDictionary*)dico
{
        [[self getPlugin] invokeMethod: methodName arguments: dico ];
}


- (void)invokeMethod: (NSString*)methodName boolArg: (Boolean)boolArg success: (bool)success
{
        NSDictionary* dic =
        @{
                @"slotNo": [NSNumber numberWithInt: slotNo],
                @"arg": [NSNumber numberWithBool: boolArg] ,
                @"state": [NSNumber numberWithInt:([self getStatus])],
                @"success": [NSNumber numberWithBool: success]
        };
        NSString* s = [NSString stringWithFormat: @"iOS: invokeMethod %@ - state=%i", methodName, [self getStatus] ];
        [self log: DBG msg: s];

        [[self getPlugin] invokeMethod: methodName arguments: dic ];
}


- (void)invokeMethod: (NSString*)methodName numberArg: (NSNumber*)arg success: (bool)success
{
        NSDictionary* dic =
        @{
                @"slotNo": [NSNumber numberWithInt: slotNo],
                @"arg": arg,
                @"state": [NSNumber numberWithInt:([self getStatus])],
                @"success": [NSNumber numberWithBool: success]
        };
        NSString* s = [NSString stringWithFormat: @"iOS: invokeMethod %@ - state=%i", methodName, [self getStatus] ];
        [self log: DBG msg: s];

        [[self getPlugin] invokeMethod: methodName arguments: dic ];
}


@end

//---------------------------------------------------------------------------------------------------------------------------------------------------------------------
