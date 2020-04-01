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

#import <Flutter/Flutter.h>
#import <AVFoundation/AVFoundation.h>
#import "Flauto.h"

/*

typedef enum
{
        IS_STOPPED,
        IS_PLAYING,
        IS_PAUSED,
        IS_RECORDING,
} t_AUDIO_STATE;
*/

extern void FlautoPlayerReg(NSObject<FlutterPluginRegistrar>* registrar);
extern NSMutableArray* flautoPlayerSlots;


@interface FlautoPlayerManager : NSObject<FlutterPlugin>
{
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar;
- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result;
- (void)invokeMethod: (NSString*)methodName arguments: (NSDictionary*)call;
- (void)freeSlot: (int)slotNo;
@end

@interface FlutterSoundPlayer : NSObject <AVAudioPlayerDelegate>
{
        AVAudioPlayer *audioPlayer;
        bool isPaused ;
        t_SET_CATEGORY_DONE setCategoryDone;
        t_SET_CATEGORY_DONE setActiveDone;
}

- (FlautoPlayerManager*) getPlugin;
- (FlutterSoundPlayer*)init: (int)aSlotNo;

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag;
- (void)isDecoderSupported:(t_CODEC)codec result: (FlutterResult)result;
- (void)updateProgress:(NSTimer *)timer;
- (void)startTimer;
- (void)stopPlayer;
- (void)pausePlayer:(FlutterResult)result;
- (void)resumePlayer:(FlutterResult)result;
- (void)stopTimer;
- (void)pause;
- (bool)resume;
- (void)startPlayer:(NSString*)path result: (FlutterResult)result;
- (void)startPlayerFromBuffer:(FlutterStandardTypedData*)dataBuffer result: (FlutterResult)result;
- (void)seekToPlayer:(nonnull NSNumber*) time result: (FlutterResult)result;
- (void)setSubscriptionDuration:(double)duration result: (FlutterResult)result;
- (void)setVolume:(double) volume result: (FlutterResult)result;
- (void)setCategory: (NSString*)categ mode:(NSString*)mode options:(int)options result:(FlutterResult)result;
- (void)setActive:(BOOL)enabled result:(FlutterResult)result;
- (void)initializeFlautoPlayer: (FlutterMethodCall*)call result: (FlutterResult)result;
- (void)releaseFlautoPlayer: (FlutterMethodCall*)call result: (FlutterResult)result;
@end


//extern FlutterSoundPlugin *flutterSoundModule; // Singleton
