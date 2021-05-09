//
//  Flauto.h
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

#ifndef FlutterSound_h
#define FlutterSound_h

#import <Flutter/Flutter.h>
#import <AVFoundation/AVFoundation.h>
#import <tau_core/Flauto.h>

#define FULL_FLAVOR

@interface FlutterSound : NSObject <FlutterPlugin, AVAudioPlayerDelegate>
{
}
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar;

@end

#endif /* FlutterSound_h */
