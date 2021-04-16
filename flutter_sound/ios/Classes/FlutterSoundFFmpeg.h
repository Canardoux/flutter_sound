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


#define FULL_FLAVOR
#ifdef FULL_FLAVOR

#import <Flutter/Flutter.h>
#import <mobileffmpeg/MobileFFmpegConfig.h>

/**
 * Flutter FFmpeg Plugin
 */
@interface FlutterSoundFFmpeg : NSObject<FlutterPlugin,FlutterStreamHandler,LogDelegate,StatisticsDelegate> {
        FlutterSoundFFmpeg* flutterSoundFFmpeg; // Singleton
}

@end

extern void FlutterSoundFFmpegReg(NSObject<FlutterPluginRegistrar>* registrar);

#endif // FULL_FLAVOR
