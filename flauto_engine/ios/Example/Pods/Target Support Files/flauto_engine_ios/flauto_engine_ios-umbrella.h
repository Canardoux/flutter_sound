#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "AudioSession.h"
#import "FlautoEngine.h"
#import "FlautoPlayer.h"
#import "FlautoRecorder.h"
#import "FlautoTrackPlayer.h"
#import "PlayerEngine.h"
#import "Track.h"

FOUNDATION_EXPORT double flauto_engine_iosVersionNumber;
FOUNDATION_EXPORT const unsigned char flauto_engine_iosVersionString[];

