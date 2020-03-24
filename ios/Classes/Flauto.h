/*
 * This file is part of Flauto.
 *
 *   Flauto is free software: you can redistribute it and/or modify
 *   it under the terms of the Lesser GNU General Public License
 *   version 3 (LGPL3) as published by the Free Software Foundation.
 *
 *   Flauto is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the Lesser GNU General Public License
 *   along with Flauto.  If not, see <https://www.gnu.org/licenses/>.
 */

#import <Flutter/Flutter.h>
#import <AVFoundation/AVFoundation.h>
#import "FlutterSoundPlugin.h"

@interface Flauto : FlutterSoundPlugin // NSObject<FlutterPlugin, AVAudioPlayerDelegate>

- (FlutterMethodChannel *)getChannel;

@end
extern Flauto *flautoModule; // Singleton
