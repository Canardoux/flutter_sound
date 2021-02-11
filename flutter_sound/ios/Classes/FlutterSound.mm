//
//  Flauto.m
//  flauto
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





#import "FlutterSound.h"
#import "FlutterSoundPlayerManager.h"
#import "FlutterSoundRecorderManager.h"
#ifdef FULL_FLAVOR
        #import "FlutterSoundFFmpeg.h"
#endif

@implementation FlutterSound
{
}


+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar
{
        FlutterSoundPlayerReg(registrar);
        FlutterSoundRecorderReg(registrar);
        #ifdef FULL_FLAVOR
                FlutterSoundFFmpegReg(registrar);
        #endif
}

@end
