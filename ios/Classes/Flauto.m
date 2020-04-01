//
//  Flauto.m
//  flauto
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



#import "flauto.h"
#import "FlutterSoundPlayer.h"
#import "FlutterSoundRecorder.h"
#import "TrackPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>


@implementation Flauto
{
}


+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar
{
        FlautoPlayerReg(registrar);
        FlautoRecorderReg(registrar);
        TrackPlayerReg(registrar);
}

@end
